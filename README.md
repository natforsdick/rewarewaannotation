[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A522.10.1-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Nextflow Tower](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Nextflow%20Tower-%234256e7)](https://tower.nf/launch?pipeline=https://github.com/nf/rewarewaannotation)

## Introduction

**kherronism/rewarewaannotation** is a bioinformatics pipeline built in Nextflow, originally developed for the annotation of the rewarewa (Knightia excelsa) genome.



<!-- TODO nf-core: Include a figure that guides the user through the major workflow steps. Many nf-core
     workflows use the "tube map" design for that. See https://nf-co.re/docs/contributing/design_guidelines#examples for examples.   -->

Default steps in the pipeline:
1. Read QC ([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))
2. Adapter and quality trimming ([`Trim Galore!`](https://www.bioinformatics.babraham.ac.uk/projects/trim_galore/))
3. Alignment ([`STAR`](https://github.com/alexdobin/STAR))
4. Sort and index alignments ([`SAMtools`](https://sourceforge.net/projects/samtools/files/samtools/))
5. Alignment summary metrics ([`picard CollectAlignmentSummaryMetrics`](https://broadinstitute.github.io/picard/))
6. Build custom repeat database ([`RepeatModeler`](https://www.repeatmasker.org/RepeatModeler/))
7. Mask repeats in genome assembly ([`RepeatMasker`](https://www.repeatmasker.org/))
8. Genome annotation ([`BRAKER3`](https://github.com/Gaius-Augustus/BRAKER)
9. Annotation QC ([`BUSCO`](https://busco.ezlab.org/)
10. Present QC for raw reads, alignment and annotation ([`MultiQC`](http://multiqc.info/))

## Usage

> **Note**
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how
> to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline)
> with `-profile test` before running the workflow on actual data.

<!-- TODO nf-core: Describe the minimum required steps to execute the pipeline, e.g. how to prepare samplesheets.
     Explain what rows and columns represent. For instance (please edit as appropriate):

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
sample,fastq_1,fastq_2
CONTROL_REP1,AEG588A1_S1_L002_R1_001.fastq.gz,AEG588A1_S1_L002_R2_001.fastq.gz
```

Each row represents a fastq file (single-end) or a pair of fastq files (paired end).

-->

Now, you can run the pipeline using:

```bash
nextflow run kherronism/rewarewaannotation \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --outdir <OUTDIR>
```

To resume a run, add the [`-resume`](https://nf-co.re/usage/running#resume-a-pipeline) flag and Nextflow will take care of the rest.

To re-run the pipeline with the parameters used for _rewarewa_ (example samplesheet.csv given in `test-datasets` folder):
```bash
  nextflow run kherronism/rewarewaannotation \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --outdir <OUTDIR> \
   --extra_trimgalore_args "--illumina -j 2" \
   --extra_trimgalore_hard_trim_args "--hardtrim3 100" \
   --extra_star_genomegenerate_args "--genomeSAindexNbases 13"
```

> **Warning:**
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those
> provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_;
> see [docs](https://nf-co.re/usage/configuration#custom-configuration-files).

## Credits

Pipeline originally written and implemented by Ann McCartney and ported to Nextflow by Katie Herron.

## Citations

If you use kherronism/rewarewaannotation for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX)

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](nf-rewarewaannotation/CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/master/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
