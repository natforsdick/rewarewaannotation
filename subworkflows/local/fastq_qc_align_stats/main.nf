include { FASTQ_QC_FASTQC_TRIMGALORE            } from '../../../subworkflows/local/fastq_qc_fastqc_trimgalore/main'
include { FASTQ_INDEX_ALIGN_STAR_SAMTOOLS       } from '../../../subworkflows/local/fastq_index_align_star_samtools/main'
include { PICARD_COLLECTALIGNMENTSUMMARYMETRICS } from '../../../modules/kherronism/picard/collectalignmentsummarymetrics/main'

workflow FASTQ_QC_ALIGN_STATS {

    take:
    ch_fastq
    ch_assembly
    align_reads_together
    skip_fastqc
    skip_trimming
    skip_hard_trimming
    skip_read_alignment
    skip_picard_alignment_metrics

    main:
    ch_versions = Channel.empty()
    //
    // Read QC and trimming
    //
    trim_reads           = Channel.empty()
    raw_fastqc_html      = Channel.empty()
    raw_fastqc_zip       = Channel.empty()
    trim_fastqc_html     = Channel.empty()
    trim_fastqc_zip      = Channel.empty()
    trim_log             = Channel.empty()
    hardtrim_fastqc_html = Channel.empty()
    hardtrim_fastqc_zip  = Channel.empty()
    hardtrim_log        = Channel.empty()

    FASTQ_QC_FASTQC_TRIMGALORE (
        ch_fastq,
        skip_fastqc,
        skip_trimming,
        skip_hard_trimming
    )
    if (!skip_hard_trimming) {
        trim_reads = FASTQ_QC_FASTQC_TRIMGALORE.out.hardtrim_reads
    } else if (!skip_trimming) {
        trim_reads = FASTQ_QC_FASTQC_TRIMGALORE.out.trim_reads
    } else {
        trim_reads = ch_fastq
    }
    raw_fastqc_html      = FASTQ_QC_FASTQC_TRIMGALORE.out.fastqc_html
    raw_fastqc_zip       = FASTQ_QC_FASTQC_TRIMGALORE.out.fastqc_zip
    trim_fastqc_html     = FASTQ_QC_FASTQC_TRIMGALORE.out.trim_html
    trim_fastqc_zip      = FASTQ_QC_FASTQC_TRIMGALORE.out.trim_zip
    trim_log             = FASTQ_QC_FASTQC_TRIMGALORE.out.trim_log
    hardtrim_fastqc_html = FASTQ_QC_FASTQC_TRIMGALORE.out.hardtrim_html
    hardtrim_fastqc_zip  = FASTQ_QC_FASTQC_TRIMGALORE.out.hardtrim_zip
    hardtrim_log         = FASTQ_QC_FASTQC_TRIMGALORE.out.hardtrim_log

    ch_versions = ch_versions.mix(FASTQ_QC_FASTQC_TRIMGALORE.out.versions)

    //
    // Genome indexing and read alignment
    //
    star_index           = Channel.empty()
    star_align_log_final = Channel.empty()
    star_align_log_out   = Channel.empty()
    bam_sorted           = Channel.empty()
    if (!skip_read_alignment) {
        FASTQ_INDEX_ALIGN_STAR_SAMTOOLS (
            trim_reads,
            ch_assembly,
            align_reads_together
        )
        star_index           = FASTQ_INDEX_ALIGN_STAR_SAMTOOLS.out.star_index
        star_align_log_out   = FASTQ_INDEX_ALIGN_STAR_SAMTOOLS.out.star_align_log_out
        star_align_log_final = FASTQ_INDEX_ALIGN_STAR_SAMTOOLS.out.star_align_log_final
        bam_sorted           = FASTQ_INDEX_ALIGN_STAR_SAMTOOLS.out.bam_sorted
        ch_versions          = ch_versions.mix(FASTQ_INDEX_ALIGN_STAR_SAMTOOLS.out.versions)
    }

    //
    // Alignment metrics
    //
    metrics = Channel.empty()
    if (!skip_picard_alignment_metrics || !skip_read_alignment) {
        PICARD_COLLECTALIGNMENTSUMMARYMETRICS (
            bam_sorted,
            ch_assembly.map {it -> it[1]}
        )
        metrics = PICARD_COLLECTALIGNMENTSUMMARYMETRICS.out.metrics
        ch_versions = ch_versions.mix(PICARD_COLLECTALIGNMENTSUMMARYMETRICS.out.versions)
    }

    emit:
    trim_reads            // channel: [ val(meta), [ reads ] ]
    raw_fastqc_html       // channel: [ val(meta), [ html ] ]
    raw_fastqc_zip        // channel: [ val(meta), [ zip ] ]
    trim_fastqc_html      // channel: [ val(meta), [ html ] ]
    trim_fastqc_zip       // channel: [ val(meta), [ zip ] ]
    trim_log              // channel: [ val(meta), [ txt ] ]
    hardtrim_fastqc_html  // channel: [ val(meta), [ html ] ]
    hardtrim_fastqc_zip   // channel: [ val(meta), [ zip ] ]
    hardtrim_log          // channel: [ val(meta), [ txt ] ]
    star_index            // channel: [ val(meta), [ txt ] ]
    star_align_log_final  // channel: [ val(meta), [ txt ] ]
    star_align_log_out    // channel: [ val(meta), [ txt ] ]
    bam_sorted            // channel: [ val(meta), [ bam ] ]
    metrics               // channel: [ val(meta), [ txt ] ]

    versions = ch_versions // channel: [ versions.yml ]
}

