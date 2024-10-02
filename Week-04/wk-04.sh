
# start from after cutadapt


# -------------------------------------------------------------------- #

# Porechop

# Remove linked reads from unlinked reads fastq

## deduplicate linked reads (just in case)
singularity exec images/seqkit.sif \
seqkit rmdup data/florida_cf/barcodes-04-10.q10.mifish_linked.fastq > \
data/florida_cf/barcodes-04-10.q10.mifish_linked.dd.fastq

## get IDs of linked reads
awk 'NR%4==1 {sub(/^@/, "", $1); print $1}' \
data/florida_cf/barcodes-04-10.q10.mifish_linked.dd.fastq > \
data/florida_cf/barcodes-04-10.q10.mifish_linked.dd.ids.txt


## remove linked reads from unlinked reads
singularity exec images/seqkit.sif \
seqkit grep --invert-match \
-f data/florida_cf/barcodes-04-10.q10.mifish_linked.dd.ids.txt \
data/florida_cf/barcodes-04-10.q10.mifish_unlinked.fastq | \
singularity exec images/seqkit.sif seqkit rmdup > \
data/florida_cf/barcodes-04-10.q10.mifish_unlinked.sub.fastq


# shuffle unlinked reads 
singularity exec images/bbmap.sif \
shuffle.sh in=data/florida_cf/barcodes-04-10.q10.mifish_unlinked.sub.fastq \
out=data/florida_cf/barcodes-04-10.q10.mifish_unlinked.sub.shuf.fastq


# run porechop
singularity exec images/porechop.sif \
porechop --threads 8 --discard_middle \
-i data/florida_cf/barcodes-04-10.q10.mifish_unlinked.sub.shuf.fastq > \
data/florida_cf/barcodes-04-10.q10.mifish_unlinked.sub.shuf.porechop.fastq


# check length distribution after porechop



# -------------------------------------------------------------------- #

# Combine linked and unlinked reads
cat data/florida_cf/barcodes-04-10.q10.mifish_linked.dd.fastq \
data/florida_cf/barcodes-04-10.q10.mifish_unlinked.sub.shuf.porechop.fastq > \
data/florida_cf/barcodes-04-10.q10.mifish_linked_unlinked.fastq

# rm duplicates just in case
singularity exec images/seqkit.sif \
seqkit rmdup data/florida_cf/barcodes-04-10.q10.mifish_linked_unlinked.fastq > \
data/florida_cf/barcodes-04-10.q10.mifish_linked_unlinked.dd.fastq


# -------------------------------------------------------------------- #

# Convert to fasta & Tabulate

## convert to fasta
singularity exec images/seqkit.sif \
seqkit fq2fa data/florida_cf/barcodes-04-10.q10.mifish_linked_unlinked.dd.fastq \
-o data/florida_cf/barcodes-04-10.q10.mifish_linked_unlinked.dd.fasta

## tabulate
### Drop attributes except barcode
awk '/^>/ {split($0, a, " "); printf("%s", a[1]); for (i=2; i<=length(a); i++) { if (match(a[i], /^barcode=|^start_time=/)) printf(" %s", a[i]); } printf("\n"); next} {print}' \
data/florida_cf/barcodes-04-10.q10.mifish_linked_unlinked.dd.fasta > \
data/florida_cf/barcodes-04-10.q10.mifish_linked_unlinked.dd.att.fasta

### tabulate (we'll need this later)
singularity exec images/seqkit.sif \
seqkit fx2tab -l data/florida_cf/barcodes-04-10.q10.mifish_linked_unlinked.dd.att.fasta \
-o data/florida_cf/barcodes-04-10.q10.mifish_linked_unlinked.dd.att.txt


# -------------------------------------------------------------------- #

# Clustering to MOTUs w/vsearch

## mkdir to vsearch outputs
mkdir data/florida_cf/vsearch

## call vsearch cluster_fast
singularity exec images/vsearch.sif \
vsearch --threads 4 \
--cluster_fast data/florida_cf/barcodes-04-10.q10.mifish_linked_unlinked.dd.fasta \
--id 0.98 \
--centroids data/florida_cf/vsearch/barcodes-04-10.q10.mifish_linked_unlinked.dd.cen.fasta \
--consout data/florida_cf/vsearch/barcodes-04-10.q10.mifish_linked_unlinked.dd.con.fasta \
--uc data/florida_cf/vsearch/barcodes-04-10.q10.mifish_linked_unlinked.dd.clusters.uc


## rm clusters with less than 5 reads
singularity exec images/seqkit.sif \
seqkit grep -r -n -p 'seqs=([6-9]|[1-9]\d+)$' \
data/florida_cf/vsearch/barcodes-04-10.q10.mifish_linked_unlinked.dd.con.fasta \
-o data/florida_cf/vsearch/barcodes-04-10.q10.mifish_linked_unlinked.dd.con.sub.fasta

### tabulate

### process tab file to only include centroid and sequence (no headers)




# -------------------------------------------------------------------- #

# BLAST Next!