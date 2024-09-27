# convert to fasta
singularity exec images/seqkit.sif \
seqkit fq2fa test3/florida_cf2-barcode-01-subset.fastq > \
test3/florida_cf2-barcode-01-subset.fasta


# call vsearch cluster_fast (works)
singularity exec images/vsearch.sif \
vsearch --threads 4 \
--cluster_fast test3/florida_cf2-barcode-01-subset.fasta \
--centroids test3/cen.fasta \
--id 0.98 \
--consout test3/con.fasta \
--uc test3/clusters.uc