include { TRIMGALORE as TRIMMING      } from '../../../modules/nf-core/trimgalore/main'
include { TRIMGALORE as HARD_TRIMMING } from '../../../modules/nf-core/trimgalore/main'
include { FASTQC as FASTQC_RAW        } from '../../../modules/nf-core/fastqc/main'
include { FASTQC as FASTQC_TRIM       } from '../../../modules/nf-core/fastqc/main'
include { FASTQC as FASTQC_HARDTRIM   } from '../../../modules/nf-core/fastqc/main'

workflow FASTQ_QC_FASTQC_TRIMGALORE {

    take:
    ch_fastq
    skip_fastqc
    skip_trimming
    skip_hard_trimming

    main:
    ch_versions       = Channel.empty()
    trim_reads        = Channel.empty()
    trim_log          = Channel.empty()
    trim_unpaired     = Channel.empty()
    trim_html         = Channel.empty()
    trim_zip          = Channel.empty()
    hardtrim_reads    = Channel.empty()
    hardtrim_log      = Channel.empty()
    hardtrim_unpaired = Channel.empty()
    hardtrim_html     = Channel.empty()
    hardtrim_zip      = Channel.empty()
    if (!skip_trimming) {
        TRIMMING (
            ch_fastq
        )
        trim_reads    = TRIMMING.out.reads
        trim_log      = TRIMMING.out.log
        trim_unpaired = TRIMMING.out.unpaired
        if (!skip_hard_trimming) {
            HARD_TRIMMING (
                trim_reads
            )
            hardtrim_reads    = HARD_TRIMMING.out.reads
            hardtrim_log      = HARD_TRIMMING.out.log
            hardtrim_unpaired = HARD_TRIMMING.out.unpaired
        }
        ch_versions = ch_versions.mix(TRIMMING.out.versions.first())
    }

    fastqc_html = Channel.empty()
    fastqc_zip  = Channel.empty()
    if (!skip_fastqc) {
        FASTQC_RAW (
             ch_fastq
        )
        fastqc_html = FASTQC_RAW.out.html
        fastqc_zip  = FASTQC_RAW.out.zip
        ch_versions = ch_versions.mix(FASTQC_RAW.out.versions.first())
        if (!skip_trimming) {
            FASTQC_TRIM (
             trim_reads
            )
            trim_html   = FASTQC_TRIM.out.html
            trim_zip    = FASTQC_TRIM.out.zip
            ch_versions = ch_versions.mix(FASTQC_TRIM.out.versions.first())
            if(!skip_hard_trimming) {
                FASTQC_HARDTRIM (
                    hardtrim_reads
                )
                hardtrim_html = FASTQC_HARDTRIM.out.html
                hardtrim_zip  = FASTQC_HARDTRIM.out.zip
                ch_versions = ch_versions.mix(FASTQC_HARDTRIM.out.versions.first())
            }
        }
    }

    emit:
    fastqc_html       // channel: [ val(meta), [ html ] ]
    fastqc_zip        // channel: [ val(meta), [ zip ] ]

    trim_reads        // channel: [ val(meta), [ reads ] ]
    trim_log          // channel: [ val(meta), [ txt ] ]
    trim_unpaired     // channel: [ val(meta), [ reads ] ]
    trim_html         // channel: [ val(meta), [ html ] ]
    trim_zip          // channel: [ val(meta), [ zip ] ]

    hardtrim_reads    // channel: [ val(meta), [ reads ] ]
    hardtrim_log      // channel: [ val(meta), [ txt ] ]
    hardtrim_unpaired // channel: [ val(meta), [ reads ] ]
    hardtrim_html     // channel: [ val(meta), [ html ] ]
    hardtrim_zip      // channel: [ val(meta), [ zip ] ]

    versions = ch_versions.ifEmpty(null)  // channel: [ versions.yml ]
}

