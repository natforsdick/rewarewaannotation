include { FASTQC                      } from '../../../modules/nf-core/fastqc/main'
include { TRIMGALORE as TRIMMING      } from '../../../modules/nf-core/trimgalore/main'
include { TRIMGALORE as HARD_TRIMMING } from '../../../modules/nf-core/trimgalore/main'


workflow FASTQ_QC_FASTQC_TRIMGALORE {

    take:
    ch_fastq
    skip_fastqc
    skip_trimming
    skip_hard_trimming

    main:
    ch_versions = Channel.empty()

    fastqc_html = Channel.empty()
    fastqc_zip  = Channel.empty()
    if (!skip_fastqc) {
        FASTQC (
             ch_fastq
        )
        fastqc_html = FASTQC.out.html
        fastqc_zip  = FASTQC.out.zip
        ch_versions = ch_versions.mix(FASTQC.out.versions.first())
    }

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
        trim_html     = TRIMMING.out.html
        trim_zip      = TRIMMING.out.zip
        if (!skip_hard_trimming) {
            HARD_TRIMMING (
                trim_reads
            )
            hardtrim_reads    = HARD_TRIMMING.out.reads
            hardtrim_log      = HARD_TRIMMING.out.log
            hardtrim_unpaired = HARD_TRIMMING.out.unpaired
            hardtrim_html     = HARD_TRIMMING.out.html
            hardtrim_zip      = HARD_TRIMMING.out.zip
        }
        ch_versions = ch_versions.mix(TRIMMING.out.versions.first())
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

