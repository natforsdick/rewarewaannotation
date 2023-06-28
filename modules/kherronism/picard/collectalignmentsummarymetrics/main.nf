process PICARD_COLLECTALIGNMENTSUMMARYMETRICS {
    tag "$meta.id"
    label 'process_single'

    conda "bioconda::picard=3.0.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/picard:3.0.0--hdfd78af_1' :
        'biocontainers/picard:3.0.0--hdfd78af_1' }"

    input:
    tuple val(meta), path(bam)
    path fasta

    output:
    tuple val(meta), path("*.txt"), emit: metrics
    path  "versions.yml"          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}.AlignmentSummaryMetric.metrics"
    def reference = fasta ? "--REFERENCE_SEQUENCE ${fasta}" : ""
    """
    picard \\
        CollectAlignmentSummaryMetrics \\
        --INPUT ${bam} \\
        --OUTPUT ${prefix}.txt \\
        ${reference} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        picard: \$(echo \$(picard CollectAlignmentSummaryMetrics --version 2>&1) | grep -o 'Version:.*' | cut -f2- -d:)
    END_VERSIONS
    """
}
