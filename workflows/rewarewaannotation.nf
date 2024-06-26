/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { validateParameters; paramsHelp; paramsSummaryLog; paramsSummaryMap; fromSamplesheet } from 'plugin/nf-validation'

def valid_params = []

def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
def summary_params = paramsSummaryMap(workflow)

// Print help message if needed
if (params.help) {
    def String command = "nextflow run ${workflow.manifest.name} --input samplesheet.csv -profile singularity"
    log.info logo + paramsHelp(command) + citation + NfcoreTemplate.dashedLine(params.monochrome_logs)
    System.exit(0)
}

// Validate input parameters
if (params.validate_params) {
    validateParameters()
}

// Print parameter summary log to screen
log.info logo + paramsSummaryLog(workflow) + citation

WorkflowRewarewaannotation.initialise(params, log)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local, kherronism/nf-modules and nf-core/modules
//
include { FASTQ_QC_ALIGN_STATS              } from '../subworkflows/local/fastq_qc_align_stats/main'
include { FASTA_QC_MASKING                  } from '../subworkflows/local/fasta_qc_masking/main'
include { FASTA_ANNOTATION_QC_BRAKER3_BUSCO } from '../subworkflows/local/fasta_annotation_qc_braker3_busco/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { CAT_FASTQ                   } from '../modules/nf-core/cat/fastq/main'
include { GUNZIP                      } from '../modules/nf-core/gunzip/main'
include { GAWK as GAWK_FASTAHEADER    } from '../modules/nf-core/gawk/main'
include { MULTIQC                     } from '../modules/nf-core/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow REWAREWAANNOTATION {

    ch_versions = Channel.empty()

    //
    // Create input channel from input samplesheet and provided params
    //
    Channel
        .fromSamplesheet("input")
        .map {
            meta, fastq_1, fastq_2 ->
                if (!fastq_2) {
                    return [ meta + [ single_end:true ], [ fastq_1 ] ]
                } else {
                    return [ meta + [ single_end:false ], [ fastq_1, fastq_2 ] ]
                }
        }
        .branch {
            meta, fastqs ->
                single  : fastqs.size() == 1
                    return [ meta, fastqs.flatten() ]
                multiple: fastqs.size() > 1
                    return [ meta, fastqs.flatten() ]
        }
        .set { ch_fastq }

    //
    // MODULE: Concatenate FastQ files from same sample if required
    //
    CAT_FASTQ (
        ch_fastq.multiple
    )
    .reads
    .mix(ch_fastq.single)
    .set { ch_reads }
    ch_versions = ch_versions.mix(CAT_FASTQ.out.versions.first().ifEmpty(null))

    //
    // MODULE: Uncompress genome fasta if required
    //
    if (params.assembly.endsWith(".gz")) {
        ch_assembly = GUNZIP ( [ [id: params.assembly_name ], file(params.assembly) ] ).gunzip
        ch_versions = ch_versions.mix(GUNZIP.out.versions)
    } else {
        ch_assembly = Channel.value( [[id: params.assembly_name], file(params.assembly)] )
    }

    //
    // MODULE: Select only the first column in the genome fasta header.
    //
    GAWK_FASTAHEADER (
        ch_assembly,
        []
    )
    ch_assembly_clean_header = GAWK_FASTAHEADER.out.output
    ch_versions              = ch_versions.mix(GAWK_FASTAHEADER.out.versions)

    //
    // Create lineages channel for multiple busco runs
    //
    ch_lineages = Channel.of(params.busco_lineages.split(',')).map{ it.trim() }

    //
    // SUBWORKFLOW: Read QC and trim adapters with TrimGalore!
    //
    skip_hard_trimming = (params.extra_trimgalore_hardtrim_args == null) ? true : params.skip_hard_trimming
    FASTQ_QC_ALIGN_STATS (
        ch_reads,
        ch_assembly_clean_header,
        params.align_reads_together,
        params.skip_fastqc,
        params.skip_trimming,
        skip_hard_trimming,
        params.skip_read_alignment,
        params.skip_picard_alignment_metrics
    )
    ch_versions = ch_versions.mix(FASTQ_QC_ALIGN_STATS.out.versions)

    //
    // SUBWORKFLOW: Genome BUSCO QC and genome masking with RepeatModeler and RepeatMasker
    //
    FASTA_QC_MASKING(
        ch_assembly_clean_header,
        ch_lineages,
        params.skip_busco_genome,
        params.skip_genome_masking
    )
    ch_versions = ch_versions.mix(FASTA_QC_MASKING.out.versions)

    //
    // SUBWORKFLOW: Genome annotation with BRAKER3 and annotation QC with BUSCO
    //
    FASTA_ANNOTATION_QC_BRAKER3_BUSCO (
        FASTA_QC_MASKING.out.fasta_masked,
        FASTQ_QC_ALIGN_STATS.out.bam_sorted.collect(),
        ch_lineages,
        params.skip_busco_annotation,
        params.skip_agat_stats
    )

    //
    // Module: DumpSoftwareVersions
    //
    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowRewarewaannotation.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    methods_description    = WorkflowRewarewaannotation.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description)
    ch_methods_description = Channel.value(methods_description)

    MULTIQC (
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList().ifEmpty([]),
        CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect().ifEmpty([]),
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'),
        ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'),
        ch_multiqc_logo.toList().ifEmpty([]),
        FASTQ_QC_ALIGN_STATS.out.raw_fastqc_zip.collect{it[1]}.ifEmpty([]),
        FASTQ_QC_ALIGN_STATS.out.trim_log.collect{it[1]}.ifEmpty([]),
        FASTQ_QC_ALIGN_STATS.out.trim_fastqc_zip.collect{it[1]}.ifEmpty([]),
        FASTQ_QC_ALIGN_STATS.out.hardtrim_log.collect{it[1]}.ifEmpty([]),
        FASTQ_QC_ALIGN_STATS.out.hardtrim_fastqc_zip.collect{it[1]}.ifEmpty([]),
        FASTQ_QC_ALIGN_STATS.out.star_align_log_final.collect{it[1]}.ifEmpty([]),
        FASTQ_QC_ALIGN_STATS.out.metrics.collect{it[1]}.ifEmpty([]),
        FASTA_QC_MASKING.out.busco_genome_short_summaries_txt.collect{it[1]}.ifEmpty([]),
        FASTA_ANNOTATION_QC_BRAKER3_BUSCO.out.busco_annotation_short_summaries_txt.collect{it[1]}.ifEmpty([])
    )
    multiqc_report = MULTIQC.out.report.toList()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
