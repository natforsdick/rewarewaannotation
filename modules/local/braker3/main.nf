process BRAKER3 {
    tag "${meta.id}"
    label 'process_high'

    conda "bioconda::braker3=3.0.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/braker3:3.0.3--hdfd78af_0':
        'depot.galaxyproject.org/singularity/braker3:3.0.3--hdfd78af_0' }"

    input:
    tuple val(meta), path(fasta)
    path bam
    path rnaseq_sets_dirs
    path rnaseq_sets_ids
    path proteins
    path hintsfile

    output:
    tuple val(meta), path("${prefix}/braker.gtf")      , emit: gtf
    tuple val(meta), path("${prefix}/braker.codingseq"), emit: cds
    tuple val(meta), path("${prefix}/braker.aa")       , emit: aa
    tuple val(meta), path("${prefix}/hintsfile.gff")   , emit: hintsfile
    tuple val(meta), path("${prefix}/braker.log")      , emit: log
    tuple val(meta), path("${prefix}/what-to-cite.txt"), emit: citations
    tuple val(meta), path("${prefix}/braker.gff3")     , emit: gff3     , optional: true
    path "versions.yml"                                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix   = task.ext.prefix ?: "${meta.id}"

    def hints    = hintsfile ? "--hints=${hintsfile}" : ''
    def bam      = bam ? "--bam=${bam}" : ''
    def proteins = proteins ? "--prot_seq=${proteins}" : ''
    def rna_dirs = rnaseq_sets_dirs ? "--rnaseq_sets_dirs=${rnaseq_sets_dirs}" : ''
    def rna_ids  = rnaseq_sets_ids ? "--rnaseq_sets_ids=${rnaseq_sets_ids}" : ''
    """
    braker.pl \\
        --genome ${fasta} \\
        --species ${prefix} \\
        --workingdir ${prefix} \\
        --threads ${task.cpus} \\
        --AUGUSTUS_CONFIG_PATH=$AUGUSTUS_CONFIG_PATH \\
        --AUGUSTUS_SCRIPTS_PATH=$AUGUSTUS_SCRIPTS_PATH \\
        ${hints} \\
        ${bam} \\
        ${proteins} \\
        ${rna_dirs} \\
        ${rna_ids} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
         braker3: \$(braker.pl --version 2>&1 | sed 's/^.*BRAKER3 v//; s/ .*\$//')
    END_VERSIONS
    """
}
