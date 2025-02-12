

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


# linked reads #1
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


# linked reads #2
singularity exec images/cutadapt.sif \
cutadapt -g CATAGTGGGGTATCTAATCCCAGTTTG...GCTGGCACGAGTTTTACCGAC \
--cores 4 -e 0.2 --no-indels --discard-untrimmed \
data/florida_cf/barcodes-04-10.q10.l300.L400.fastq > \
data/florida_cf/barcodes-04-10.q10.l300.L400.mifish_linked_2.fastq

singularity exec images/seqkit.sif \
seqkit stats data/florida_cf/barcodes-04-10.q10.l300.L400.mifish_linked_2.fastq 

singularity exec images/bbmap.sif \
readlength.sh \
in=data/florida_cf/barcodes-04-10.q10.l300.L400.mifish_linked_2.fastq \
out=data/florida_cf/barcodes-04-10.q10.l300.L400.mifish_linked_2.readlength.txt

# unlinked forward primer
singularity exec images/cutadapt.sif \
cutadapt -g GTCGGTAAAACTCGTGCCAGC \
--cores 4 -e 0.2 --no-indels --discard-untrimmed \
data/florida_cf/barcodes-04-10.q10.l300.L400.fastq > \
data/florida_cf/barcodes-04-10.q10.l300.L400.mifish_unlinked_1.fastq

# unlinked rev. comp. forward primer
singularity exec images/cutadapt.sif \
cutadapt -a GCTGGCACGAGTTTTACCGAC \
--cores 4 -e 0.2 --no-indels --discard-untrimmed \
data/florida_cf/barcodes-04-10.q10.l300.L400.fastq > \
data/florida_cf/barcodes-04-10.q10.l300.L400.mifish_unlinked_2.fastq

# unlinked reverse primer
singularity exec images/cutadapt.sif \
cutadapt -g CATAGTGGGGTATCTAATCCCAGTTTG  \
--cores 4 -e 0.2 --no-indels --discard-untrimmed \
data/florida_cf/barcodes-04-10.q10.l300.L400.fastq > \
data/florida_cf/barcodes-04-10.q10.l300.L400.mifish_unlinked_3.fastq

# unlinked rev. comp. reverse primer
singularity exec images/cutadapt.sif \
cutadapt -a CAAACTGGGATTAGATACCCCACTATG \
--cores 4 -e 0.2 --no-indels --discard-untrimmed \
data/florida_cf/barcodes-04-10.q10.l300.L400.fastq > \
data/florida_cf/barcodes-04-10.q10.l300.L400.mifish_unlinked_4.fastq

# combine all unlinked reads
cat data/florida_cf/barcodes-04-10.q10.l300.L400.mifish_unlinked_1.fastq \
data/florida_cf/barcodes-04-10.q10.l300.L400.mifish_unlinked_2.fastq \
data/florida_cf/barcodes-04-10.q10.l300.L400.mifish_unlinked_3.fastq \
data/florida_cf/barcodes-04-10.q10.l300.L400.mifish_unlinked_4.fastq > \
data/florida_cf/barcodes-04-10.q10.l300.L400.mifish_unlinked_all.fastq

## get stats of unlinked reads
singularity exec images/bbmap.sif \
readlength.sh \
in=data/florida_cf/barcodes-04-10.q10.l300.L400.mifish_unlinked_all.fastq \
out=data/florida_cf/barcodes-04-10.q10.l300.L400.mifish_unlinked_all.readlength.txt

singularity exec images/r_env.sif \
Rscript scripts/process_read_distribs_CL.R \
--distrib_file=data/florida_cf/barcodes-04-10.q10.l300.L400.mifish_unlinked_all.readlength.txt \
--output_file=data/florida_cf/barcodes-04-10.q10.l300.L400.mifish_unlinked_all.readlength.png \
--hmin=160 --hmax=185


# Cutadapt automated
singularity exec images/r_env.sif \
Rscript scripts/run_cutadapt_CL.R \
--input_file data/florida_cf/barcodes-04-10.q10.l300.L400.fastq \
--primer_fasta data/primers/mifish_primer.fasta \
--output_path_linked data/florida_cf/barcodes-04-10.q10.l300.L400.mifish_linked_all_v2.fastq \
--output_path_unlinked data/florida_cf/barcodes-04-10.q10.l300.L400.mifish_unlinked_all_v2.fastq \
--cutadapt_error_rate 0.2 \
--n_cores 4


singularity exec images/seqkit.sif \
seqkit stats data/florida_cf/barcodes-04-10.q10.l300.L400.mifish_linked_all_v2.fastq
