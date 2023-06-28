include { REPEATMODELER } from '../../../modules/kherronism/repeatmodeler/main'
include { REPEATMASKER  } from '../../../modules/kherronism/repeatmasker/main'

workflow FASTA_REPEATMASKING_REPEATMODELER_REPEATMASKER {

    take:
    ch_fasta // channel: [ val(meta), [ fasta ] ]

    main:
    ch_versions = Channel.empty()

    REPEATMODELER ( )
    ch_versions = ch_versions.mix(REPEATMODELER.out.versions)

    REPEATMASKER ()
    ch_versions = ch_versions.mix(REPEATMASKER.out.versions)

    emit:
    // TODO nf-core: edit emitted channels
    bam      = SAMTOOLS_SORT.out.bam           // channel: [ val(meta), [ bam ] ]
    bai      = SAMTOOLS_INDEX.out.bai          // channel: [ val(meta), [ bai ] ]
    csi      = SAMTOOLS_INDEX.out.csi          // channel: [ val(meta), [ csi ] ]

    versions = ch_versions                     // channel: [ versions.yml ]
}

