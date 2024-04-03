#!/bin/bash -l
#SBATCH --job-name=annotation
#SBATCH --account=ACCOUNTID # set to NeSI account ID
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --ntasks-per-node=1
#SBATCH --mem=3G
#SBATCH --time 02:00:00 # as yet unclear how long a full run with 1 Gb genome will take - perhaps up to 5-00:00:00
#SBATCH --mail-user=EMAIL # insert user email
#SBATCH --mail-type=ALL
#SBATCH --output=slurm-%x-%A-%a.log

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
