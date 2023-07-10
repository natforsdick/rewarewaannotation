[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A522.10.1-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

## Introduction

**kherronism/rewarewaannotation** is a bioinformatics pipeline built in Nextflow, originally developed for the annotation of the rewarewa (Knightia excelsa) genome. The pipeline takes paired-end RNA-seq reads as input and conducts QC, trimming and alignment. The target genome is repeat masked prior to both the genome and RNA-seq evidence being given as input to BRAKER3.

Default steps in the pipeline:
1. Merge re-sequenced FastQ files ([`cat`](http://www.linfo.org/cat.html))
1. Read QC ([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))
2. Adapter and quality trimming ([`Trim Galore!`](https://www.bioinformatics.babraham.ac.uk/projects/trim_galore/))
3. Trimmed read QC ([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))
4. OPTIONAL:
   - a. Hardtrimming ([`Trim Galore!`](http://multiqc.info/))
   - b. Hardtrimmed read QC ([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))
4. Alignment ([`STAR`](https://github.com/alexdobin/STAR))
4. Alignment summary metrics ([`picard CollectAlignmentSummaryMetrics`](https://broadinstitute.github.io/picard/))
5. Assembly QC ([`BUSCO`](https://busco.ezlab.org/))
6. Build custom repeat database ([`RepeatModeler`](https://www.repeatmasker.org/RepeatModeler/))
7. Mask repeats in genome assembly ([`RepeatMasker`](https://www.repeatmasker.org/))
8. Genome annotation ([`BRAKER3`](https://github.com/Gaius-Augustus/BRAKER))
9. Annotation QC ([`BUSCO`](https://busco.ezlab.org/))
10. Annotation summary metrics ([`agat spstatistics`](https://agat.readthedocs.io/en/latest/tools/agat_sp_statistics.html))
11. Present QC for raw reads, alignment and annotation ([`MultiQC`](http://multiqc.info/))

## Usage

> **Note**
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how
> to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline)
> with `-profile test` before running the workflow on actual data.

**Pipeline usage is covered more comprehensively on [this page](docs/usage.md)**.

In brief:

Prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
sample_id,file1,file2
SAMPLE_1,SAMPLE_1_R1.fastq.gz,SAMPLE_1_R2.fastq.gz,
SAMPLE_2,SAMPLE_2_R1.fastq.gz,SAMPLE_2_R2.fastq.gz,
<...>
```

Each row represents a pair of fastq files (paired end). This pipeline only accepts paired-end reads. Input files can be compressed or uncompressed. Re-sequenced samples will be merged into a single fastq file at the start of the pipeline.

Now, you can run the pipeline using:
```bash
nextflow run kherronism/rewarewaannotation \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --assembly <ASSEMBLY_FILE> \
   --assembly_name <ASSEMBLY_NAME> \
   --outdir <OUTDIR>
```

You can also `git clone` this repository and then run the pipeline locally:
```bash
nextflow run main.nf \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --assembly <ASSEMBLY_FILE> \
   --assembly_name <ASSEMBLY_NAME> \
   --outdir <OUTDIR>
```

**For a full breakdown of available params for the pipeline see [this page](docs/parameters.md).**

To resume a run, add the [`-resume`](https://nf-co.re/usage/running#resume-a-pipeline) flag and Nextflow will take care of the rest.

To re-run the pipeline with the parameters used for _rewarewa_ (example samplesheet.csv and params file given in [`test-datasets/kniExce`](test-datasets/kniExce) folder):
```bash
  nextflow run kherronism/rewarewaannotation \
   -profile <docker/singularity/.../institute> \
   -params-file test-datasets/kniExec/rewarewa_params.config
```
Also included in [`test-datasets/kniExce`](test-datasets/kniExce) are a few helper files:
- [`environment.yml`](test-datasets/kniExce/environment.yml): For creating a conda environment for Nextflow and nf-core.
- [`rewarewa_params.yml`](test-datasets/kniExce/rewarewa_params.yml): A params file containing the parameters for reproducing the _rewarewa_ annotation.
- [`rewarewa_slurm.sh`](test-datasets/kniExce/rewarewa_slurm.sh): Example of how to submit the pipeline run as a job on a slurm cluster. However, this does require giving Nextflow an additional config file, which is dependent on the set-up of the institutional cluster. See [this page](https://nf-co.re/docs/usage/tutorials/step_by_step_institutional_profile) and [nf-core/configs](https://github.com/nf-core/configs) for more details.
  - As an example, the [`sonic.config`](test-datasets/kniExce/sonic.config) file in [`test-datasets/kniExce`](test-datasets/kniExce) is a config file for the [Sonic HPC](https://www.ucd.ie/itservices/ourservices/researchit/researchcomputing/sonichpc/) cluster.

> **Warning:**
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those
> provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_;
> see [docs](https://nf-co.re/usage/configuration#custom-configuration-files).

**For a breakdown of the outputs of the pipeline see [this page](docs/outputs.md).**

## Credits

Pipeline originally written and implemented by Ann McCartney and ported to Nextflow by Katie Herron.

## Citations

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/master/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
