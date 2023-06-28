include { BUSCO as BUSCO_ANNOTATION } from '../../../modules/nf-core/busco/main'
include { BRAKER3                   } from '../../../modules/kherronism/braker3/main'

workflow FASTA_ANNOTATION_QC_BRAKER3_BUSCO {

    take:
    ch_bam // channel: [ val(meta), [ bam ] ]

    main:
    ch_versions = Channel.empty()

    BRAKER3 ( )
    ch_versions = ch_versions.mix(BRAKER3.out.versions)

    BUSCO_ANNOTATION ( )
    ch_versions = ch_versions.mix(BUSCO_ANNOTATION.out.versions)

    emit:
    // TODO nf-core: edit emitted channels
    bam      = SAMTOOLS_SORT.out.bam           // channel: [ val(meta), [ bam ] ]
    bai      = SAMTOOLS_INDEX.out.bai          // channel: [ val(meta), [ bai ] ]
    csi      = SAMTOOLS_INDEX.out.csi          // channel: [ val(meta), [ csi ] ]

    versions = ch_versions                     // channel: [ versions.yml ]
}

