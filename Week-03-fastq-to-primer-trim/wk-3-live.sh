

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

singularity exec images/bbmap.sif \
readlength.sh \
in=data/florida_cf/barcodes-04-10.q10.l300.L400.fastq \
out=data/florida_cf/barcodes-04-10.q10.l300.L400.readlength.txt

singularity exec images/r_env.sif \
Rscript scripts/process_read_distribs_CL.R \
--distrib_file=data/florida_cf/barcodes-04-10.q10.l300.L400.readlength.txt \
--output_file=data/florida_cf/barcodes-04-10.q10.l300.L400.readlength.png \
--hmin=300 --hmax=400

singularity exec images/cutadapt.sif \
cutadapt -g GTCGGTAAAACTCGTGCCAGC...CAAACTGGGATTAGATACCCCACTATG \
--cores 4 -e 0.2 --no-indels --discard-untrimmed \
data/florida_cf/barcodes-04-10.q10.l300.L400.fastq > \
data/florida_cf/barcodes-04-10.q10.l300.L400.mifish_linked_1.fastq

singularity exec images/seqkit.sif \
seqkit stats data/florida_cf/barcodes-04-10.q10.l300.L400.mifish_linked_1.fastq 

singularity exec images/bbmap.sif \
readlength.sh \
in=data/florida_cf/barcodes-04-10.q10.l300.L400.mifish_linked_1.fastq \
out=data/florida_cf/barcodes-04-10.q10.l300.L400.mifish_linked_1.readlength.txt

singularity exec images/r_env.sif \
Rscript scripts/process_read_distribs_CL.R \
--distrib_file=data/florida_cf/barcodes-04-10.q10.l300.L400.mifish_linked_1.readlength.txt \
--output_file=data/florida_cf/barcodes-04-10.q10.l300.L400.mifish_linked_1.readlength.png \
--hmin=160 --hmax=185