

cat data/florida_cf/fastq/**/*.fastq > data/florida_cf/barcodes-04-10.fastq

head data/florida_cf/barcodes-04-10.fastq
tail data/florida_cf/barcodes-04-10.fastq

singularity exec images/nanofilt.sif \
NanoFilt --q 10 data/florida_cf/barcodes-04-10.fastq > \
data/florida_cf/barcodes-04-10.q10.fastq

singularity exec images/seqkit.sif \
seqkit stats data/florida_cf/barcodes-04-10.fastq 

singularity exec images/seqkit.sif \
seqkit stats data/florida_cf/barcodes-04-10.q10.fastq

singularity exec images/bbmap.sif \
readlength.sh \
in=data/florida_cf/barcodes-04-10.q10.fastq \
out=data/florida_cf/barcodes-04-10.q10.readlength.txt

singularity exec images/r_env.sif \
Rscript scripts/process_read_distribs_CL.R \
--distrib_file=data/florida_cf/barcodes-04-10.q10.readlength.txt \
--output_file=data/florida_cf/barcodes-04-10.q10.readlength.png \
--hmin=300 --hmax=400

singularity exec images/seqkit.sif \
seqkit seq --min-len 300 --max-len 400 \
data/florida_cf/barcodes-04-10.q10.fastq > \
data/florida_cf/barcodes-04-10.q10.l300.L400.fastq

singularity exec images/seqkit.sif \
seqkit stats data/florida_cf/barcodes-04-10.q10.l300.L400.fastq



# For 

# sign into annotate2
wget https://cdn.oxfordnanoportal.com/software/analysis/dorado-0.8.0-linux-x64.tar.gz
tar -xvzf dorado-0.8.0-linux-x64.tar.gz

dorado-0.8.0-linux-x64/bin/dorado basecaller --help

# call hac basecaller exported as bam to preserve attributes of reads, including barcode
dorado-0.8.0-linux-x64/bin/dorado/bin/dorado basecaller --no-trim --recursive hac \
data/Florida_CF/pod5_pass/ > \
data/Florida_CF/basecalled/calls_hac.bam

# use sam tools to convert to fastq format with attributes
# you'll need to install samtools.sif (check docker hub)
singularity exec images/samtools.sif \
samtools fastq -T '*' \
data/SLAM/basecalled/calls_hac.bam > \
data/SLAM/basecalled/calls_hac.fastq

head data/SLAM/basecalled/calls_hac.fastq
tail data/SLAM/basecalled/calls_hac.fastq