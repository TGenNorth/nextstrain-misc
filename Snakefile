rule all:
    input:
        auspice_json = "auspice/ncov.json",
        tip_frequencies_json = "auspice/ncov_tip-frequencies.json"

rule files:
    params:
        auspice_config = "config/auspice_config.json",
        clades = "config/clades.tsv",
        color_schemes = "config/color_schemes.tsv",
        description = "config/description.md",
        lat_longs = "config/lat_longs.tsv",
        reference = "config/reference.gb",
        sequences = "data/sequences.fasta",
        metadata = "data/metadata.tsv"

files = rules.files.params

rule clean_metadata:
    message:
        """
        Cleaning {input.metadata}:
            - remove/fix non-AZ counties
        """
    input:
        metadata = files.metadata
    output:
        metadata = "results/metadata.tsv"
    shell:
        """
        python3 scripts/clean_metadata.py {input.metadata} {output.metadata}
        """

rule fix_colors:
    message:
        """
        Generate color file based on metadata of interest
            - Color AZ County metadata
            - Color Pangolin lineages
        """
    input:
        metadata = rules.clean_metadata.output.metadata,
        color_schemes = files.color_schemes
    output:
        colors = "results/colors.tsv"
    shell:
        """
        python3 scripts/fix_colors.py {input.metadata} {input.color_schemes} {output.colors}
        """

checkpoint partition_sequences:
    input:
        sequences = files.sequences
    output:
        split_sequences = directory("results/split_sequences")
    params:
        sequences_per_group = 150
    shell:
        """
        python3 scripts/partition-sequences.py \
            --sequences {input.sequences} \
            --sequences-per-group {params.sequences_per_group} \
            --output-dir {output.split_sequences}
        """

rule align:
    message:
        """
        Aligning sequences to {input.reference}
          - gaps relative to reference are considered real
        """
    input:
        sequences = "results/split_sequences/{i}.fasta",
        reference = files.reference
    output:
        alignment = "results/split_alignments/{i}.fasta"
    threads: 40
    shell:
        """
        augur align \
            --sequences {input.sequences} \
            --reference-sequence {input.reference} \
            --output {output.alignment} \
            --nthreads {threads} \
            --remove-reference \
            --fill-gaps
        """

def _get_alignments(wildcards):
    checkpoint_output = checkpoints.partition_sequences.get(**wildcards).output[0]
    return expand("results/split_alignments/{i}.fasta",
                  i=glob_wildcards(os.path.join(checkpoint_output, "{i}.fasta")).i)

rule aggregate_alignments:
    message: "Collecting alignments"
    input:
        alignments = _get_alignments
    output:
        alignment = "results/aligned.fasta"
    shell:
        """
        cat {input.alignments} > {output.alignment}
        """

rule mask:
    message:
        """
        Mask bases in alignment
          - masking {params.mask_from_beginning} from beginning
          - masking {params.mask_from_end} from end
          - masking other sites: {params.mask_sites}
        """
    input:
        alignment = rules.aggregate_alignments.output.alignment
    output:
        alignment = "results/masked.fasta"
    params:
        mask_from_beginning = 130,
        mask_from_end = 50,
        mask_sites = "18529 29849 29851 29853"
    shell:
        """
        python3 scripts/mask-alignment.py \
            --alignment {input.alignment} \
            --mask-from-beginning {params.mask_from_beginning} \
            --mask-from-end {params.mask_from_end} \
            --mask-sites {params.mask_sites} \
            --output {output.alignment}
        """

rule tree:
    message: "Building tree"
    input:
        alignment = rules.mask.output.alignment
    output:
        tree = "results/tree_raw.nwk"
    threads: 40
    shell:
        """
        augur tree \
            --alignment {input.alignment} \
            --output {output.tree} \
            --nthreads {threads}
        """

rule refine:
    message:
        """
        Refining tree
          - estimate timetree
          - use {params.coalescent} coalescent timescale
          - estimate {params.date_inference} node dates
        """
    input:
        tree = rules.tree.output.tree,
        alignment = rules.mask.output,
        metadata = rules.clean_metadata.output.metadata
    output:
        tree = "results/tree.nwk",
        node_data = "results/branch_lengths.json"
    params:
        root = "best",
        clock_rate = 0.0008,
        clock_std_dev = 0.0004,
        coalescent = "skyline",
        date_inference = "marginal",
        divergence_unit = "mutations"
    shell:
        """
        augur refine \
            --tree {input.tree} \
            --alignment {input.alignment} \
            --metadata {input.metadata} \
            --output-tree {output.tree} \
            --output-node-data {output.node_data} \
            --root {params.root} \
            --timetree \
            --clock-rate {params.clock_rate} \
            --clock-std-dev {params.clock_std_dev} \
            --coalescent {params.coalescent} \
            --date-inference {params.date_inference} \
            --divergence-unit {params.divergence_unit} \
            --date-confidence \
            --no-covariance
        """

rule ancestral:
    message:
        """
        Reconstructing ancestral sequences and mutations
          - not inferring ambiguous mutations
        """
    input:
        tree = "results/tree.nwk",
        alignment = rules.mask.output
    output:
        node_data = "results/nt_muts.json"
    params:
        inference = "joint"
    shell:
        """
        augur ancestral \
            --tree {input.tree} \
            --alignment {input.alignment} \
            --output-node-data {output.node_data} \
            --inference {params.inference} \
            --infer-ambiguous
        """

rule translate:
    message: "Translating amino acid sequences"
    input:
        tree = "results/tree.nwk",
        node_data = rules.ancestral.output.node_data,
        reference = files.reference
    output:
        node_data = "results/aa_muts.json"
    shell:
        """
        augur translate \
            --tree {input.tree} \
            --ancestral-sequences {input.node_data} \
            --reference-sequence {input.reference} \
            --output-node-data {output.node_data} \
        """

rule clades:
    message: "Adding internal clade labels"
    input:
        tree = "results/tree.nwk",
        aa_muts = rules.translate.output.node_data,
        nuc_muts = rules.ancestral.output.node_data,
        clades = files.clades
    output:
        clade_data = "results/clades.json"
    shell:
        """
        augur clades --tree {input.tree} \
            --mutations {input.nuc_muts} {input.aa_muts} \
            --clades {input.clades} \
            --output-node-data {output.clade_data}
        """

rule recency:
    message: "Use metadata on submission date to construct submission recency field"
    input:
        metadata = rules.clean_metadata.output.metadata
    output:
        "results/recency.json"
    shell:
        """
        python3 scripts/construct-recency-from-submission-date.py \
            --metadata {input.metadata} \
            --output {output}
        """

rule tip_frequencies:
    message: "Estimating censored KDE frequencies for tips"
    input:
        tree = rules.refine.output.tree,
        metadata = rules.clean_metadata.output.metadata
    output:
        tip_frequencies_json = "auspice/ncov_tip-frequencies.json"
    params:
        min_date = 2020.0,
        pivot_interval = 1,
        narrow_bandwidth = 0.05,
        proportion_wide = 0.0
    shell:
        """
        augur frequencies \
            --method kde \
            --metadata {input.metadata} \
            --tree {input.tree} \
            --min-date {params.min_date} \
            --pivot-interval {params.pivot_interval} \
            --narrow-bandwidth {params.narrow_bandwidth} \
            --proportion-wide {params.proportion_wide} \
            --output {output.tip_frequencies_json}
        """

rule export:
    message: "Exporting data files for auspice"
    input:
        tree = rules.refine.output.tree,
        metadata = rules.clean_metadata.output.metadata,
        branch_lengths = rules.refine.output.node_data,
        nt_muts = rules.ancestral.output.node_data,
        aa_muts = rules.translate.output.node_data,
        auspice_config = files.auspice_config,
        colors = rules.fix_colors.output.colors,
        lat_longs = files.lat_longs,
        description = files.description,
        clades = rules.clades.output.clade_data,
        recency = rules.recency.output
    output:
        auspice_json = "auspice/ncov.json"
    shell:
        """
        augur export v2 \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --node-data {input.branch_lengths} {input.nt_muts} {input.aa_muts} {input.clades} {input.recency} \
            --auspice-config {input.auspice_config} \
            --colors {input.colors} \
            --lat-longs {input.lat_longs} \
            --description {input.description} \
            --output {output.auspice_json}
        """
