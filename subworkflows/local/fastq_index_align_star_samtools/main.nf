include { STAR_GENOMEGENERATE } from '../../../modules/nf-core/star/genomegenerate/main'
include { STAR_ALIGN          } from '../../../modules/nf-core/star/align/main'

workflow FASTQ_INDEX_ALIGN_STAR_SAMTOOLS {

    take:
    ch_reads
    ch_assembly
    align_reads_together

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

    if (align_reads_together) {
        align_reads = ch_reads.map { meta, reads -> reads }
            .collect()
        align_reads_meta = ch_assembly.map {it[0]}
            .concat(align_reads)
            .collect(flat: false)
    } else {
        align_reads_meta = ch_reads
    }

    //
    // Map reads to indexed genome
    //
    STAR_ALIGN (
        align_reads_meta,
        star_index.collect{it[1]},
        [],
        true,
        false,
        false
    )
    star_align_log_out   = STAR_ALIGN.out.log_out
    star_align_log_final = STAR_ALIGN.out.log_final
    bam_sorted           = STAR_ALIGN.out.bam_sorted
    ch_versions          = ch_versions.mix(STAR_ALIGN.out.versions.first())


    emit:
    star_index             // channel: [ val(meta), [ path ] ]
    star_align_log_out     // channel: [ val(meta), [ txt ] ]
    star_align_log_final   // channel: [ val(meta), [ txt ] ]
    bam_sorted             // channel: [ val(meta), [ bam ] ]

    versions = ch_versions // channel: [ versions.yml ]
}

