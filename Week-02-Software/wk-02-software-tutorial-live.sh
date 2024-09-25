# this is a comment

# prints working directory
pwd

# prints the contents of the current directory
ls

# make a image directory
mkdir images

# download seqkit image
singularity build images/seqkit.sif docker://nanozoo/seqkit:2.6.1--022e008

# fix no space error
mkdir tmp
export TMPDIR=~/tmp
export TMP=~/tmp
export SINGULARITY_TMPDIR=~/tmp
echo $TMPDIR
echo $TMP
echo $SINGULARITY_TMPDIR

# go into the container/image
singularity shell images/seqkit.sif

# test seqkit runs
seqkit version

# run container from command line w/o entering
singularity exec images/seqkit.sif seqkit version

# get stats of fastq
# first go into seqkit container: singularity shell images/seqkit.sif
seqkit stats test/florida_cf2-barcode-01-subset.fastq

# length filter
seqkit seq --min-len 50 --max-len 400 test/florida_cf2-barcode-01-subset.fastq > \
test/florida_cf2-barcode-01-subset.l50.L400.fastq

# see stats now of the new file
seqkit stats test/florida_cf2-barcode-01-subset.l50.L400.fastq


