[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A522.10.1-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

## Introduction

**rewarewaannotation** is a bioinformatics pipeline built by Ann McArtney and ported into Nextflow by Katie Herron, originally developed for the annotation of the rewarewa (*Knightia excelsa*) genome. The pipeline takes paired-end RNA-seq reads and a genome assembly as input and conducts QC, trimming and alignment. The target genome is repeat masked prior to both the genome and RNA-seq evidence being given as input to BRAKER3.

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

**Pipeline usage is covered more comprehensively on [this page](docs/usage.md)**.

### Preparing to run on NeSI

1. Make a new directory for your annotation workflow. `git clone` this repo. Then make a directory for the annotation output.
   
3. Install NextFlow locally on NeSI as per the [Introduction to Nextflow workshop](https://genomicsaotearoa.github.io/Nextflow_Workshop/session_1/1_introduction/#nextflow-cli) (see 'How to install Nextflow locally'). You may need to load Java:
   
   `module load Java/11.0.4`
   
4. Once you have moved NextFlow to your `$HOME/bin`, check whether it can be found:
   
   `nextflow -version`
   
   If it doesn't return NextFlow version information, you will need to export bin to path:
   
   `export PATH="$HOME/bin:$PATH"`

   It's probably a good idea to add this to your `~/.bashrc`.
   
6. Set up the rest of the environment ready to run the test config. We are running this pipeline with Singularity - please ignore the message regarding it being deprecated on NeSI.
   
   We will need to set up cache and temporary directories (e.g., `/nesi/nobackup/landcare03691/singularity-cache`, `/nesi/nobackup/landcare03691/tmp-anno`, and run `setfacl -b` commands to bypass NeSI security access control on `nobackup` to allow `pull` from online repos. 
   
   For repeat usage, we recommend adding the following to your `~/.bashrc`:

  ```bash
  ## NextFlow set up for annotation pipeline
  export PATH="${HOME}/bin:$PATH"
  export NXF_TEMP=/path/to/tmp-anno
  export NXF_HOME=~/.nextflow
  export NXF_SINGULARITY_CACHEDIR=/path/to/singularity-cache
  export SINGULARITY_CACHEDIR=/path/to/singularity-cache
  export SINGULARITY_TMPDIR=/path/to/tmp-anno
  ```

  Then prior to running the pipeline, you only need to do the following:

   ```bash
   module load Java/11.0.4
   nextflow -version
   module load Singularity/3.11.3
   setfacl -b "${NXF_SINGULARITY_CACHEDIR}" /path/to/rewarewaannotation/main.nf
   setfacl -b "${SINGULARITY_TMPDIR}" /path/to/rewarewaannotation/main.nf
   ```
   
8. Test your setup.
   
   Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data. **Note**: The nextflow process will also make a `.nextflow.log` file which is more detailed than your `anno-test.log`, but if you don't rename it, it will be overwritten.
   
   `nextflow run /path/to/rewarewaannotation/ -profile test,nesi,singularity --outdir results &> anno-test.log`

  The test should spawn multiple slurm jobs during processing. It should complete within around 15 minutes, logging one error, which will be a result of the test dataset being too small to run Braker3 - this is an expected error! 
  
  Example of the end of the `anno-test.log` file:
  
  ```
  -[kherronism/rewarewaannotation] Pipeline completed successfully, but with errored process(es) -
  Completed at: 04-Apr-2024 10:37:43
  Duration    : 8m 21s
  CPU hours   : 0.6 (1.9% failed)
  Succeeded   : 15
  Ignored     : 1
  Failed      : 1
  ```
  Check the `.nextflow.log` file created. Near the end, you will see the Braker3 error: `NOTE: Process `KHERRONISM_REWAREWAANNOTATION:REWAREWAANNOTATION:FASTA_ANNOTATION_QC_BRAKER3_BUSCO:BRAKER3 (GENOME_A)` terminated with an error exit status (1) -- Error is ignored`. If there are no more than one errors reported in the `anno-test.log`, you should be good to go.
   
   You can test resuming the pipeline using `-resume`. 
   
   If testing fails, I recommend cleaning out the singularity cache before starting a new test. This ensures that you are testing the entire pipeline process.
   
   `singularity cache clean`

   You may wish to additionally test that your `params.yml` works correctly when passing your own input data. I recommend making a test `params.yml` and using the following as inputs: extract one scaffold from your genome assembly, and 1000 paired reads from one set of your input RNAseq data files. Test these inputs via the [`NeSI_slurm.sh`](test-datasets/kniExce/NeSI_slurm.sh) script. This will efficiently test that your `params.yml` is formatted correctly, and that your paths to data files are correct, before committing more resources. 

### Setting up to run for your data on NeSI via SLURM

In brief:

Prepare a samplesheet with your RNA-seq input data that looks as follows:

`samplesheet.csv`:

```csv
sample_id,file1,file2
SAMPLE_1,SAMPLE_1_R1.fastq.gz,SAMPLE_1_R2.fastq.gz,
SAMPLE_2,SAMPLE_2_R1.fastq.gz,SAMPLE_2_R2.fastq.gz,
<...>
```

Prepare a `params.yml` file for your input data: [`rewarewa_params.yml`](test-datasets/kniExce/rewarewa_params.yml)

```yml
input                         : 'samplesheet.csv'
outdir                        : 'results'
assembly                      : '<ASSEMBLY_FASTA_PATH>'
assembly_name                 : 'asmName'
busco_lineages                : 'eukaryota_odb10,embryophyta_odb10'
```

Each row represents a pair of fastq files (paired end). This pipeline only accepts paired-end reads. Input files can be compressed or uncompressed. Re-sequenced samples will be merged into a single fastq file at the start of the pipeline.

Now, you can run the pipeline on the command line using:
```bash
nextflow run kherronism/rewarewaannotation \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --assembly <ASSEMBLY_FILE> \
   --assembly_name <ASSEMBLY_NAME> \
   --outdir <OUTDIR>
```

However, we want to make use of the SLURM scheduler and allow NextFlow to make its own arrays to handle the various pipeline steps. 

### Running on SLURM

Along with making your samplesheet, you will need a SLURM script like this example: [`NeSI_slurm.sh`](test-datasets/kniExce/NeSI_slurm.sh). This is loosely based on the [`sonic.config`](test-datasets/kniExce/sonic.config), modified to run on NeSI's SLURM setup. 

**For a full breakdown of available params for the pipeline see [this page](docs/parameters.md).**

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

Pipeline originally written and implemented by Ann McCartney and ported to Nextflow by [Katie Herron](https://github.com/kherronism).

Modifications for use on NeSI by [Nat Forsdick](https://github.com/natforsdick), [Dinindu Senanayake](https://github.com/DininduSenanayake), and [Chris Hakkaart](https://github.com/christopher-hakkaart).

## Citations

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/master/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
