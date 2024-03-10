#!/bin/bash -l
#SBATCH --job-name=rewarewaannotation
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --ntasks-per-node=1
#SBATCH --time 120:00:00

#SBATCH --output=slurm-%x-%A-%a.log

# run from current directory
cd $SLURM_SUBMIT_DIR

# command to use
module load singularity
module load anaconda

conda activate nextflow

nextflow run kherronism/rewarewaannotation \
   -params-file rewarewa_params.yml \
   -profile sonic \
   -resume

