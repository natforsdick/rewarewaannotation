include { BUSCO as BUSCO_GENOME                            } from '../../../modules/nf-core/busco/main'
include { FASTA_REPEATMASKING_REPEATMODELER_REPEATMASKER } from '../../../subworkflows/local/fasta_repeatmasking_repeatmodeler_repeatmasker/main'

workflow FASTA_QC_MASKING {

    take:
    ch_fasta // channel: [ val(meta), [ bam ] ]
    ch_lineages
    skip_busco_genome
    skip_genome_masking

    main:
    ch_versions = Channel.empty()

    //
    // Run BUSCO in 'genome' mode to assess genome assembly completeness
    //
    busco_genome_short_summaries_txt = Channel.empty()
    if (!skip_busco_genome){
       BUSCO_GENOME (
           ch_fasta,
           ch_lineages,
           [],
           []
       )
       ch_versions = ch_versions.mix(BUSCO_GENOME.out.versions)
       busco_genome_short_summaries_txt = BUSCO_GENOME.out.short_summaries_txt
    }

    //
    // Soft-mask genome assembly using RepeatModeler and RepeatMasker
    //
    fasta_masked = ch_fasta
    rm_log       = Channel.empty()
    if (!skip_genome_masking){
        FASTA_REPEATMASKING_REPEATMODELER_REPEATMASKER (
            ch_fasta
        )
        fasta_masked = FASTA_REPEATMASKING_REPEATMODELER_REPEATMASKER.out.fasta_masked
        rm_log     = FASTA_REPEATMASKING_REPEATMODELER_REPEATMASKER.out.rm_log
        ch_versions = ch_versions.mix(FASTA_REPEATMASKING_REPEATMODELER_REPEATMASKER.out.versions)
    }

    emit:
    busco_genome_short_summaries_txt
    fasta_masked
    rm_log
    versions = ch_versions                     // channel: [ versions.yml ]
}

