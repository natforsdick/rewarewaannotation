#!/bin/bash -l
#SBATCH --job-name=rata-annotation
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --ntasks-per-node=1
#SBATCH --time 120:00:00

#SBATCH --output=slurm-%x-%A-%a.log

# run from output directory
cd /nesi/nobackup/landcare03691/anno-out/

# NeSI environment
export PATH="$HOME/bin:$PATH"
module load Java/11.0.4 Singularity/3.11.3 Miniconda3/23.10.0-1
nextflow -version
CACHEDIR=/nesi/nobackup/landcare03691/annotation/apptainer
export NXF_SINGULARITY_CACHEDIR=$CACHEDIR
setfacl -b "${NXF_SINGULARITY_CACHEDIR}" ../annotation/rewarewaannotation/main.nf
SINGULARITY_TMPDIR=/nesi/nobackup/landcare03691/tmp-anno
export SINGULARITY_TMPDIR=$SINGULARITY_TMPDIR
setfacl -b "${SINGULARITY_TMPDIR}" ../annotation/rewarewaannotation/main.nf

# to run the full pipeline
nextflow run /nesi/nobackup/landcare03691/annotation/rewarewaannotation/ \
   -params-file /nesi/nobackup/landcare03691/rata_params.yml \
   -profile sonic #,singularity
# to resume a run, append -resume
