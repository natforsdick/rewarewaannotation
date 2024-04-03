#!/bin/bash -l
#SBATCH --job-name=annotation
#SBATCH --account=ACCOUNTID # set to NeSI account ID
#SBATCH --cpus-per-task=2
#SBATCH --mem=2G
#SBATCH --time 5-00:00:00
#SBATCH --mail-user=EMAIL # insert user email
#SBATCH --mail-type=ALL
#SBATCH --output=slurm-%x-%A-%a.log

# NeSI_slurm.sl 
# Launches annotation pipeline via SLURM
# test of one scaffold (23 Mb) and 1000 paired reads input data takes around 2 hrs

# ensure that paths to cache and tmpdir are functional
setfacl -b "${NXF_SINGULARITY_CACHEDIR}" /path/to/rewarewaannotation/main.nf
setfacl -b "${SINGULARITY_TMPDIR}" /nesi/nobackup/landcare03691/data/output/07-annotation/rewarewaannotation/main.nf

# run from output directory
cd /path/to/outdir/

# NeSI environment
module load Java/11.0.4 Singularity/3.11.3 

nextflow -version

# to run the full pipeline
nextflow run /path/to/rewarewaannotation/ -profile nesi,singularity -params-file /path/to/params.yml
# to resume a run, append -resume to the above

module purge
