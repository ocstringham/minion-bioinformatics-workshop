
# for windows ppl who had problems with using ssh terminal inside vscode, try PuTTY: https://www.putty.org/

# concat multiple fastqs files from multiple directories into one file
cat data/florida_cf/fastq/**/*.fastq > \
data/florida_cf/barcodes-04-10.fastq

# quality filter
singularity exec images/nanofilt.sif \
NanoFilt --q 10 data/florida_cf/barcodes-04-10.fastq > \
data/florida_cf/barcodes-04-10.q10.fastq

## view stats
singularity exec images/seqkit.sif \
seqkit stats data/florida_cf/barcodes-04-10.fastq

singularity exec images/seqkit.sif \
seqkit stats data/florida_cf/barcodes-04-10.q10.fastq



# length filter

## check empirical length distribution
singularity exec images/bbmap.sif \
readlength.sh \
in=data/florida_cf/barcodes-04-10.q10.fastq \
out=data/florida_cf/barcodes-04-10.q10.readlength.txt


## check distrib visually (need to make scripts directory and copy process_read_distribs_CL.R there)
singularity exec images/r_env.sif \
Rscript scripts/process_read_distribs_CL.R \
--distrib_file=data/florida_cf/barcodes-04-10.q10.readlength.txt \
--output_file=data/florida_cf/barcodes-04-10.q10.readlength.png \
--hmin=300 --hmax=400


## filter by read length
singularity exec images/seqkit.sif \
seqkit seq --min-len 300 --max-len 400 \
data/florida_cf/barcodes-04-10.q10.fastq > \
data/florida_cf/barcodes-04-10.q10.l300.L400.fastq

## check stats
singularity exec images/seqkit.sif \
seqkit stats data/florida_cf/barcodes-04-10.q10.l300.L400.fastq


# cutadapt 

## before using many cpu cores/ram, check cluster resources
htop

## linked primer #1
singularity exec images/cutadapt.sif \
cutadapt -g GTCGGTAAAACTCGTGCCAGC...CAAACTGGGATTAGATACCCCACTATG \
--cores 4 -e 0.2 --no-indels --discard-untrimmed \
data/florida_cf/barcodes-04-10.q10.fastq > \
data/florida_cf/barcodes-04-10.q10.mifish_linked_1.fastq

### check stats and length distrib
singularity exec images/seqkit.sif \
seqkit stats data/florida_cf/barcodes-04-10.q10.mifish_linked_1.fastq

singularity exec images/bbmap.sif \
readlength.sh \
data/florida_cf/barcodes-04-10.q10.mifish_linked_1.fastq \
out=data/florida_cf/barcodes-04-10.q10.mifish_linked_1.txt

singularity exec images/r_env.sif \
Rscript scripts/process_read_distribs_CL.R \
--distrib_file=data/florida_cf/barcodes-04-10.q10.mifish_linked_1.txt \
--output_file=data/florida_cf/barcodes-04-10.q10.mifish_linked_1.png \
--hmin=163 --hmax=185


## linked primer #2
singularity exec images/cutadapt.sif \
cutadapt -g CATAGTGGGGTATCTAATCCCAGTTTG...GCTGGCACGAGTTTTACCGAC \
--cores 4 -e 0.2 --no-indels --discard-untrimmed \
data/florida_cf/barcodes-04-10.q10.fastq > \
data/florida_cf/barcodes-04-10.q10.mifish_linked_2.fastq


## unlinked #1
-g GTCGGTAAAACTCGTGCCAGC

## unlinked #2
-a GCTGGCACGAGTTTTACCGAC 

## unlinked #3
-g CATAGTGGGGTATCTAATCCCAGTTTG 


## unlinked #4
-a CAAACTGGGATTAGATACCCCACTATG



# combine linked and unlinked reads

## linked
cat data/florida_cf/barcodes-04-10.q10.mifish_linked_1.fastq data/florida_cf/barcodes-04-10.q10.mifish_linked_2.fastq > \
data/florida_cf/barcodes-04-10.q10.mifish_linked.fastq

## unlinked
cat data/florida_cf/barcodes-04-10.q10.mifish_unlinked_1.fastq data/florida_cf/barcodes-04-10.q10.mifish_unlinked_2.fastq \
data/florida_cf/barcodes-04-10.q10.mifish_unlinked_3.fastq data/florida_cf/barcodes-04-10.q10.mifish_unlinked_4.fastq > \
data/florida_cf/barcodes-04-10.q10.mifish_unlinked.fastq



# Cutadapt automated
singularity exec images/r_env.sif \
Rscript scripts/run_cutadapt_CL.R \
--input_file data/florida_cf/barcodes-04-10.q10.fastq \
--primer_fasta data/primers/mifish_primer.fasta \
--output_path_linked data/florida_cf/barcodes-04-10.q10.mifish_linked.fastq \
--output_path_unlinked data/florida_cf/barcodes-04-10.q10.mifish_unlinked.fastq \
--cutadapt_error_rate 0.2 \
--n_cores 4




