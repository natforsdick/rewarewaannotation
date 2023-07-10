# Pipeline parameters

Genome annotation pipeline developed for the annotation of the rewarewa (_Knightia excelsa_) genome. This pipeline takes paired-end RNA-seq reads and conducts QC, trimming and alignment to a reference genome. The reference genome is masked before genome annotation with BRAKER using the aligned reads as evidence.

This page outlines the parameters available for this pipeline. They can be set in a custom params `yaml` or `json` file and supplied via `-params-file <file>`. Alternatively or additionally, parameters can be specified directly on the command line when launching the pipeline. For more information, refer to the [nextflow documentation](https://www.nextflow.io/docs/latest/config.html).
## Input/output options

Define where the pipeline should find input data and save output data.

| Parameter | Description | Type | Default | Required |
|-----------|-----------|-----------|-----------|-----------|
| `input` | Path to comma-separated file containing information about the samples in the experiment. <details><summary>Help</summary><small>You will need to create a design file with information about the samples in your experiment before running the pipeline. Use this parameter to specify its location. It has to be a comma-separated file with 3 columns, and a header row.</small></details>| `string` |  | True |
| `assembly` | Path to input assembly to be annotated. | `string` |  | True |
| `assembly_name` | Name of the input assembly to be annotated. | `string` |  | True |
| `busco_lineages` | BUSCO lineage(s) to use for BUSCO analysis. <details><summary>Help</summary><small>For multiple lineages, separate with commas (e.g. `--busco_lineages 'eukaryota_odb10,'mammalia_odb10''`).</small></details>| `string` | eukaryota_odb10 |  |
| `outdir` | The output directory where the results will be saved. You have to use absolute paths to storage on Cloud infrastructure. | `string` |  | True |
| `email` | Email address for completion summary. <details><summary>Help</summary><small>Set this parameter to your e-mail address to get a summary e-mail with details of the run sent to you when the workflow exits. If set in your user config file (`~/.nextflow/config`) then you don't need to specify this on the command line for every run.</small></details>| `string` |  |  |
| `multiqc_title` | MultiQC report title. Printed as page header, used for filename if not otherwise specified. | `string` |  |  |

## TrimGalore options

Parameters for TrimGalore!

| Parameter | Description | Type | Default | Required |
|-----------|-----------|-----------|-----------|-----------|
| `extra_trimgalore_args` | Extra arguments to pass to Trim Galore! command in addition to defaults defined by the pipeline. | `string` |  |  |
| `extra_trimgalore_hardtrim_args` | Arguments to pass to Trim Galore! command for hard-trimming. Required to be specified for hard-trimming of reads. | `string` |  |  |

## STAR options

Parameters for STAR commands.

| Parameter | Description | Type | Default | Required |
|-----------|-----------|-----------|-----------|-----------|
| `extra_star_genomegenerate_args` | Extra arguments to pass to STAR genomeGenerate indexing command in addition to defaults defined by the pipeline. | `string` |  |  |
| `align_reads_together` | Align all reads together in a single command, result is a single BAM file rather than a BAM file per sample. | `boolean` | True |  |
| `extra_star_align_args` | Extra arguments to pass to star alignment command in addition to defaults defined by the pipeline. | `string` |  |  |

## Picard options

Parameters for picard commands.

| Parameter | Description | Type | Default | Required |
|-----------|-----------|-----------|-----------|-----------|
| `extra_picard_alignment_metrics_args` | Extra arguments to pass to picard CollectAlignmentSummaryMetrics command in addition to defaults defined by the pipeline. | `string` |  |  |

## RepeatModeler options

Parameters for RepeatModeler commands.

| Parameter | Description | Type | Default | Required |
|-----------|-----------|-----------|-----------|-----------|
| `repeatmodeler_engine` | The search engine to use for RepeatModeler. | `string` |  |  |
| `extra_repeatmodeler_args` | Extra arguments to pass to the RepeatModeler command in addition to defaults defined by the pipeline. | `string` |  |  |

## RepeatMasker options

Parameters for RepeatMasker commands.

| Parameter | Description | Type | Default | Required |
|-----------|-----------|-----------|-----------|-----------|
| `extra_repeatmasker_args` | Extra arguments to pass to the RepeatMasker command in addition to defaults defined by the pipeline. | `string` | None |  |

## BRAKER options

Parameters for BRAKER commands.

| Parameter | Description | Type | Default | Required |
|-----------|-----------|-----------|-----------|-----------|
| `extra_braker_args` | Extra arguments to pass to the BRAKER command in addition to defaults defined by the pipeline. | `string` | None |  |

## Pipeline options

Parameters used to control which parts of the pipeline are run. Not recommended to change these unless you know what you're doing, chances are things will break.

| Parameter                       | Description                                                    | Type | Default | Required |
|---------------------------------|----------------------------------------------------------------|-----------|---------|-----------|
| `skip_fastqc`                   | Skip FASTQC.                                                   | `boolean` | False   |  |
| `skip_trimming`                 | Skip read trimming.                                            | `boolean` | False        |  |
| `skip_hard_trimming`            | Skip hard-trimming. Requires params.skip_trimming to be false. | `boolean` | False        |  |
| `skip_read_alignment`           | Skip read alignment, BRAKER will use unaligned reads instead.  | `boolean` | False        |  |
| `skip_picard_alignment_metrics` | Skip Picard CollectAlignmentSummaryMetrics.                    | `boolean` | False        |  |
| `skip_genome_masking`           | Skip genome masking.                                           | `boolean` | False        |  |
| `skip_busco_genome`             | Skip BUSCO genome assessment.                                  | `boolean` | False        |  |
| `skip_busco_annotation`         | Skip BUSCO genome annotation assessment.                       | `boolean` | False        |  |
| `skip_agat_stats`               | Skip agat spstatistics.           | `boolean` |         |  |


## Institutional config options

Parameters used to describe centralised config profiles. These should not be edited.

| Parameter | Description | Type | Default | Required |
|-----------|-----------|-----------|-----------|-----------|
| `custom_config_version` | Git commit id for Institutional configs. | `string` | master |  |
| `custom_config_base` | Base directory for Institutional configs. <details><summary>Help</summary><small>If you're running offline, Nextflow will not be able to fetch the institutional config files from the internet. If you don't need them, then this is not a problem. If you do need them, you should download the files from the repo and tell Nextflow where to find them with this parameter.</small></details>| `string` | https://raw.githubusercontent.com/nf-core/configs/master |  |
| `config_profile_name` | Institutional config name. | `string` |  |  |
| `config_profile_description` | Institutional config description. | `string` |  |  |
| `config_profile_contact` | Institutional config contact information. | `string` |  |  |
| `config_profile_url` | Institutional config URL link. | `string` |  |  |

## Max job request options

Set the top limit for requested resources for any single job.

| Parameter | Description | Type | Default | Required |
|-----------|-----------|-----------|-----------|-----------|
| `max_cpus` | Maximum number of CPUs that can be requested for any single job. <details><summary>Help</summary><small>Use to set an upper-limit for the CPU requirement for each process. Should be an integer e.g. `--max_cpus 1`</small></details>| `integer` | 16 |  |
| `max_time` | Maximum amount of time that can be requested for any single job. <details><summary>Help</summary><small>Use to set an upper-limit for the time requirement for each process. Should be a string in the format integer-unit e.g. `--max_time '2.h'`</small></details>| `string` | 240.h |  |

## Generic options

Less common options for the pipeline, typically set in a config file.

| Parameter | Description | Type | Default | Required |
|-----------|-----------|-----------|-----------|-----------|
| `help` | Display help text. | `boolean` |  |  |
| `version` | Display version and exit. | `boolean` |  |  |
| `publish_dir_mode` | Method used to save pipeline results to output directory. <details><summary>Help</summary><small>The Nextflow `publishDir` option specifies which intermediate files should be saved to the output directory. This option tells the pipeline what method should be used to move these files. See [Nextflow docs](https://www.nextflow.io/docs/latest/process.html#publishdir) for details.</small></details>| `string` | copy |  |
| `email_on_fail` | Email address for completion summary, only when pipeline fails. <details><summary>Help</summary><small>An email address to send a summary email to when the pipeline is completed - ONLY sent if the pipeline does not exit successfully.</small></details>| `string` |  |  |
| `plaintext_email` | Send plain-text email instead of HTML. | `boolean` |  |  |
| `max_multiqc_email_size` | File size limit when attaching MultiQC reports to summary emails. | `string` | 25.MB |  |
| `monochrome_logs` | Do not use coloured log outputs. | `boolean` |  |  |
| `hook_url` | Incoming hook URL for messaging service <details><summary>Help</summary><small>Incoming hook URL for messaging service. Currently, MS Teams and Slack are supported.</small></details>| `string` |  |  |
| `multiqc_config` | Custom config file to supply to MultiQC. | `string` |  |  |
| `multiqc_logo` | Custom logo file to supply to MultiQC. File name must also be set in the MultiQC config file | `string` |  |  |
| `multiqc_methods_description` | Custom MultiQC yaml file containing HTML including a methods description. | `string` |  |  |
| `tracedir` | Directory to keep pipeline Nextflow logs and reports. | `string` | ${params.outdir}/pipeline_info |  |
| `validate_params` | Boolean whether to validate parameters against the schema at runtime | `boolean` | True |  |
| `show_hidden_params` | Show all params when using `--help` <details><summary>Help</summary><small>By default, parameters set as _hidden_ in the schema are not shown on the command line when a user runs with `--help`. Specifying this option will tell the pipeline to show all parameters.</small></details>| `boolean` |  |  |
