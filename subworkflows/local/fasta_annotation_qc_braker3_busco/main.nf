include { BRAKER3                   } from '../../../modules/kherronism/braker3/main'
include { BUSCO as BUSCO_ANNOTATION } from '../../../modules/nf-core/busco/main'
include { AGAT_SPSTATISTICS         } from '../../../modules/nf-core/agat/spstatistics/main'

workflow FASTA_ANNOTATION_QC_BRAKER3_BUSCO {

    take:
    ch_fasta // channel: [ val(meta), [ fasta ] ]
    ch_bam   // channel: [ val(meta), [ bam ] ]
    ch_lineages
    skip_busco_annotation
    skip_agat_stats

    main:
    ch_versions = Channel.empty()

    BRAKER3 (
        ch_fasta,
        ch_bam.collect{it[1]}.ifEmpty([]),
        [],
        [],
        [],
        []
    )
    braker_gff      = BRAKER3.out.gff3
    braker_proteins = BRAKER3.out.aa
    braker_cds      = BRAKER3.out.cds
    braker_aa       = BRAKER3.out.aa
    ch_versions     = ch_versions.mix(BRAKER3.out.versions)

    busco_annotation_short_summaries_txt = Channel.empty()
    if (!skip_busco_annotation){
       BUSCO_ANNOTATION (
           braker_aa,
           ch_lineages,
           [],
           []
       )
       ch_versions = ch_versions.mix(BUSCO_ANNOTATION.out.versions)
       busco_annotation_short_summaries_txt = BUSCO_ANNOTATION.out.short_summaries_txt
    }

    agat_stats_txt = Channel.empty()
    if (!skip_agat_stats) {
       AGAT_SPSTATISTICS (
           braker_gff,
       )
       ch_versions = ch_versions.mix(AGAT_SPSTATISTICS.out.versions)
       agat_stats_txt = AGAT_SPSTATISTICS.out.stats_txt
    }

    emit:
    braker_gff
    braker_proteins
    braker_cds
    braker_aa
    busco_annotation_short_summaries_txt
    agat_stats_txt

    versions = ch_versions                     // channel: [ versions.yml ]
}

