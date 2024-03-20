include { REPEATMODELER } from '../../../modules/local/repeatmodeler/main'
include { REPEATMASKER  } from '../../../modules/local/repeatmasker/main'

workflow FASTA_REPEATMASKING_REPEATMODELER_REPEATMASKER {

    take:
    ch_fasta // channel: [ val(meta), [ fasta ] ]

    main:
    ch_versions = Channel.empty()

    rm_db = Channel.empty()
    rm_log = Channel.empty()
    REPEATMODELER (
        ch_fasta
    )
    rm_families = REPEATMODELER.out.rm_families_fa
    rm_log      = REPEATMODELER.out.log
    ch_versions = ch_versions.mix(REPEATMODELER.out.versions)

    fasta_mask = Channel.empty()
    REPEATMASKER (
        ch_fasta,
        rm_families
    )
    fasta_masked = REPEATMASKER.out.fasta_masked
    ch_versions = ch_versions.mix(REPEATMASKER.out.versions)

    emit:
    rm_families
    rm_log
    fasta_masked

    versions = ch_versions
}

