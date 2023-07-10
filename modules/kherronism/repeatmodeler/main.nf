process REPEATMODELER {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::repeatmodeler=2.0.4"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/repeatmodeler:2.0.4--pl5321hdfd78af_0':
        'biocontainers/repeatmodeler:2.0.4--pl5321hdfd78af_0' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*-families.fa") , emit: rm_families_fa
    tuple val(meta), path("*-families.stk"), emit: rm_families_stk
    tuple val(meta), path("RM_*/*")        , emit: rm_dir
    tuple val(meta), path("*-rmod.log")    , emit: rm_log
    path "versions.yml"                    , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args1 = task.ext.args1 ?: ''
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = '2.0.4'  // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    """
    BuildDatabase \\
        -name ${prefix} \\
        ${fasta} \\
        ${args1}

    RepeatModeler \\
        -database ${prefix} \\
        -threads ${task.cpus} \\
        ${args2}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        repeatmodeler: ${VERSION}
    END_VERSIONS
    """
}
