
# install images to images directory
singularity build images/nanofilt.sif docker://jdelling7igfl/nanofilt:2.8.0
singularity build images/seqkit.sif docker://nanozoo/seqkit:2.6.1--022e008
singularity build images/cutadapt.sif docker://olistr12/cutadapt:4.9
singularity build images/porechop.sif docker://biocontainers/porechop:v0.2.4dfsg-1-deb_cv1
singularity build images/vsearch.sif docker://olistr12/vsearch:2.28.1
singularity build images/r_env.sif docker://olistr12/r_env:0.0.7
singularity build images/bbmap.sif docker://nanozoo/bbmap:38.86--9ebcbfa
singularity build images/blast.sif docker://ncbi/blast:2.16.0


# notes if you get error that not enough space to install image
# note could be either mkdir /tmp or mkdir /tmp but no slash seemed to work
mkdir tmp 
export TMP=~/tmp
echo $TMP
export TMPDIR=~/tmp
echo $TMPDIR
export SINGULARITY_TMPDIR=~/tmp
echo $SINGULARITY_TMPDIR



# instructions for using singularity on Amarel

## start interactive shell session (can customize resources)
srun -p main -N 1 -c 2 -n 1 --mem 10GB -t 05:00:00 --pty /bin/bash

## load singularity module
module purge
module load singularity/3.1.0
