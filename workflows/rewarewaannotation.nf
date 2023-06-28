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
//include { FASTA_QC_MASKING                  } from '../subworkflows/local/fasta_qc_masking/main'
//include { FASTA_ANNOTATION_QC_BRAKER3_BUSCO } from '../subworkflows/local/genome_annotation/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
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
    // Create input channel from input file provided through params.input
    //
    ch_reads = Channel.fromPath(params.input)
        | splitCsv( header: true, quote: '\"' )
        | map { row -> [[id: row.sample_id, single_end: false], [file(row.file1), file(row.file2)]] }

    ch_assembly = Channel.value([[id: params.assembly_name], file(params.assembly)])

    //
    // SUBWORKFLOW: Read QC and trim adapters with TrimGalore!
    //
    skip_hard_trimming = (params.extra_trimgalore_hardtrim_args == null) ? true : params.skip_hard_trimming
    FASTQ_QC_ALIGN_STATS (
        ch_reads,
        ch_assembly,
        params.skip_fastqc,
        params.skip_trimming,
        skip_hard_trimming,
        params.skip_read_alignment,
        params.skip_picard_alignment_metrics
    )

    //
    // SUBWORKFLOW: Read QC and trim adapters with TrimGalore!
    //
    // FASTA_QC_MASKING()

    //
    // SUBWORKFLOW: Read QC and trim adapters with TrimGalore!
    //
    // FASTA_ANNOTATION_QC_BRAKER3_BUSCO ()

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

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())

    // Adding untrimmed read QC
    ch_multiqc_files = ch_multiqc_files.mix(FASTQ_QC_ALIGN_STATS.out.raw_fastqc_zip.collect{it[1]}.ifEmpty([]))
    if (!params.skip_trimming) {
        // Adding trimmed read QC
        ch_multiqc_files = ch_multiqc_files.mix(FASTQ_QC_ALIGN_STATS.out.trim_fastqc_zip.collect{it[1]}.ifEmpty([]))
        ch_multiqc_files = ch_multiqc_files.mix(FASTQ_QC_ALIGN_STATS.out.trim_log.collect{it[1]}.ifEmpty([]))
        if (!params.skip_hard_trimming) {
            // Adding hard trimmmed read QC
            ch_multiqc_files = ch_multiqc_files.mix(FASTQ_QC_ALIGN_STATS.out.hardtrim_fastqc_zip.collect{it[1]}.ifEmpty([]))
            ch_multiqc_files = ch_multiqc_files.mix(FASTQ_QC_ALIGN_STATS.out.hardtrim_log.collect{it[1]}.ifEmpty([]))
        }
    }
    // Adding BAM QC
    if (!params.skip_read_alignment) {
        ch_multiqc_files = ch_multiqc_files.mix(FASTQ_QC_ALIGN_STATS.out.metrics.collect{it[1]}.ifEmpty([]))
    }
    // Adding BUSCO genome assessment
    //if (!params.skip_busco_genome) {
    //    ch_multiqc_files = ch_multiqc_files.mix(FASTA_QC_MASKING.out.busco_summary.collect{it[1]}.ifEmpty([]))
    //}
    // Adding BUSCO annotation assessment
    //if (!parma.skip_busco_annotation) {
    //    ch_multiqc_files = ch_multiqc_files.mix(FASTA_ANNOTATION_QC_BRAKER3_BUSCO.out.busco_summary.collect{it[1]}.ifEmpty([]))
    //}

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
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
