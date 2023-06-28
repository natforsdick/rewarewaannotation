process BRAKER3 {
    tag "${meta.id}"
    label 'process_medium'

    conda "bioconda::braker3=3.0.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/braker3:3.0.3--hdfd78af_0':
        'quay.io/biocontainers/braker3:3.0.3--hdfd78af_0' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("${prefix}/braker.gtf")      , emit: gtf
    tuple val(meta), path("${prefix}/braker.codingseq"), emit: cds
    tuple val(meta), path("${prefix}/braker.aa")       , emit: aa
    tuple val(meta), path("${prefix}/hintsfile.gff")   , emit: hintsfile
    tuple val(meta), path("${prefix}/braker.gff3")     , emit: gff3     , optional: true
    path "versions.yml"                                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    braker.pl \\
        --genome ${fasta} \\
        --species ${prefix} \\
        --workingdir ${prefix} \\
        --threads ${task.cpus} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
         braker3: \$(braker.pl --version 2>&1 | sed 's/^.*BRAKER3 v//; s/ .*\$//')
    END_VERSIONS
    """
}
