include { BUSCO as BUSCO_GENOME                          } from '../../../modules/nf-core/busco/main'
include { FASTA_REPEATMASKING_REPEATMODELER_REPEATMASKER } from '../../../subworkflows/local/fasta_repeatmasking_repeatmodeler_repeatmasker/main'

workflow FASTA_QC_MASKING {

    take:
    ch_fasta // channel: [ val(meta), [ bam ] ]
    skip_busco_genome
    skip_genome_masking

    main:

    ch_versions = Channel.empty()

    //
    // Run BUSCO in 'genome' mode to assess genome assembly completeness
    //
    if (!skip_busco_genome){
       BUSCO_GENOME ()
       ch_versions = ch_versions.mix(BUSCO_GENOME.out.versions)
    }

    //
    // Soft-mask genome assembly using RepeatModeler and RepeatMasker
    //
    if (!skip_genome_masking){
        FASTA_REPEATMASKING_REPEATMODELER_REPEATMASKER ()
        ch_versions = ch_versions.mix(FASTA_REPEATMASKING_REPEATMODELER_REPEATMASKER.out.versions)
    }

    emit:
    // TODO nf-core: edit emitted channels
    bam      = SAMTOOLS_SORT.out.bam           // channel: [ val(meta), [ bam ] ]
    bai      = SAMTOOLS_INDEX.out.bai          // channel: [ val(meta), [ bai ] ]
    csi      = SAMTOOLS_INDEX.out.csi          // channel: [ val(meta), [ csi ] ]

    versions = ch_versions                     // channel: [ versions.yml ]
}

