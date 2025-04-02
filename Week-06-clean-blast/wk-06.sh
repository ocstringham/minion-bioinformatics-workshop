
# need to download blast_compile_results_CL.R and move it the scripts directory in Annoatate2
# download Fake_Sample_Sheet.xlsx and move it to data/florida_cf directory
# download ncbi_lineages_2025-01-08_fish.csv and move it to blastdb/ directory

# Download R image with packages installed
singularity build images/r_env.sif docker://olistr12/r_env:0.0.7

# make new dir to store results
mkdir data/florida_cf/blast

# run R script
singularity exec images/r_env.sif \
Rscript scripts/blast_compile_results_CL.R \
--cluster_key data/florida_cf/vsearch/barcodes-04-10.q10.l300.L400.mifish_linked_unlinked.dd.clusters.uc \
--barcode_key data/florida_cf/barcodes-04-10.q10.l300.L400.mifish_linked_unlinked.dd.att.txt \
--conseq_key data/florida_cf/vsearch/barcodes-04-10.q10.l300.L400.mifish_linked_unlinked.dd.con.sub2.txt \
--blast_results data/florida_cf/vsearch/barcodes-04-10.q10.l300.L400.mifish_linked_unlinked.dd.con.sub.blastn.csv \
--sample_key data/florida_cf/Fake_Sample_Sheet.xlsx \
--primer_name "MiFish" \
--min_alignment_length 100 \
--local_global "local" \
--output_cluster_filepath data/florida_cf/blast/blast_local.MiFish.vs-cluster-0.98.csv \
--output_taxa_filepath data/florida_cf/blast/blast_local.MiFish.vs-cluster-0.98.taxa.csv \
--clusters_matched_filepath data/florida_cf/blast/blast_local.MiFish.vs-cluster-0.98.clusters_matched.txt \
--taxdump_filepath blastdb/ncbi_lineages_2025-01-08_fish.csv \
--custom_taxa_filepath refdb/florida/refdb_florida_fish_dl_2025-03-26.csv