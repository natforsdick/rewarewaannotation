include { STAR_GENOMEGENERATE } from '../../../modules/nf-core/star/genomegenerate/main'
include { STAR_ALIGN          } from '../../../modules/nf-core/star/align/main'
include { SAMTOOLS_VIEW       } from '../../../modules/nf-core/samtools/view/main'
include { SAMTOOLS_SORT       } from '../../../modules/nf-core/samtools/sort/main'

workflow FASTQ_INDEX_ALIGN_STAR_SAMTOOLS {

    take:
    ch_reads
    ch_assembly

    main:
    ch_versions = Channel.empty()

    //
    // Index genome
    //
    STAR_GENOMEGENERATE (
        ch_assembly,
        []
    )
    star_index  = STAR_GENOMEGENERATE.out.index
    ch_versions = ch_versions.mix(STAR_GENOMEGENERATE.out.versions.first())

    //
    // Map reads to indexed genome
    //
    STAR_ALIGN (
        ch_reads,
        star_index.collect{it[1]},
        [],
        true,
        false,
        false
    )
    bam_sorted           = STAR_ALIGN.out.bam_sorted
    star_align_log_out   = STAR_ALIGN.out.log_out
    star_align_log_final = STAR_ALIGN.out.log_final
    ch_versions          = ch_versions.mix(STAR_ALIGN.out.versions.first())
//     //
//     // Convert SAM to BAM
//     //
//     SAMTOOLS_VIEW (
//         sam.map { meta, sam -> [meta, sam, ""] },
//         [],
//         []
//     )
//     bam         = SAMTOOLS_VIEW.out.bam
//     ch_versions = ch_versions.mix(SAMTOOLS_VIEW.out.versions.first())
//
//     //
//     // Sort BAM file
//     //
//     SAMTOOLS_SORT (
//         bam
//     )
//     sorted_bam  = SAMTOOLS_SORT.out.bam
//     ch_versions = ch_versions.mix(SAMTOOLS_SORT.out.versions.first())

    emit:
    star_index             // channel: [ val(meta), [ path ] ]
    star_align_log_out     // channel: [ val(meta), [ txt ] ]
    star_align_log_final   // channel: [ val(meta), [ txt ] ]
    bam_sorted             // channel: [ val(meta), [ bam ] ]

    versions = ch_versions // channel: [ versions.yml ]
}

