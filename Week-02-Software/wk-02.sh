
# create images directory
mkdir images

# install seqkit
singularity build images/seqkit.sif docker://nanozoo/seqkit:2.6.1--022e008

# notes if you get error that not enough space to install image
# note could be either mkdir /tmp or mkdir /tmp but no slash seemed to work
mkdir tmp 
export TMP=~/tmp
echo $TMP
export TMPDIR=~/tmp
echo $TMPDIR
export SINGULARITY_TMPDIR=~/tmp
echo $SINGULARITY_TMPDIR


# transfer file over via winscp/cyberduck

# enter shell 
singularity shell images/seqkit.sif

# run stats
seqkit stats test/florida_cf2-barcode-01-subset.fastq

# run length filtering
seqkit seq --min-len 50 --max-len 400 test/florida_cf2-barcode-01-subset.fastq > test/florida_cf2-barcode-01-subset.l50.L400.fastq

# re-run stats
seqkit stats test/florida_cf2-barcode-01-subset.l50.L400.fastq

