#!/bin/bash -l
#SBATCH --job-name=[NAME]
#SBATCH --account=[ACCOUNTID]
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --ntasks-per-node=1
#SBATCH --time 5-00:00:00 # testing for 300 Mb genome, 2 RNA-seq libraries
#SBATCH --mail-user=[EMAIL]
#SBATCH --mail-type=ALL
#SBATCH --output=slurm-%x-%A-%a.log

# run from output directory - this will contain the rewarewaannotation repo
cd /path/to/nobackup/annotation/

# NeSI environment
module load Java/11.0.4 Singularity/3.11.3
nextflow -version

setfacl -b "${NXF_SINGULARITY_CACHEDIR}" ./rewarewaannotation/main.nf
setfacl -b "${SINGULARITY_TMPDIR}" ./rewarewaannotation/main.nf

# to run the full pipeline
nextflow run /path/to/nobackup/annotation/rewarewaannotation/ \
   -params-file /path/to/nobackup/annotation/rata_params.yml \
   -profile NeSI
# to resume a run, append -resume
