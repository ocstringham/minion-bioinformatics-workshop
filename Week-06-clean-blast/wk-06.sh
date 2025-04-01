

# need to download blast_compile_results_CL.R and move it the scripts directory in Annoatate2

# download ncbi_lineages_2025-01-08_fish.csv and move it to blastdb directory



# run R script
Rscript scripts/blast_compile_results_CL.R \
--cluster_key "$vsearch_uc" \
--barcode_key "$reads_tab" \
--conseq_key "$vsearch_con_sub_tab_edit" \
--blast_results "$blast_output" \
--sample_key "$sample_key" \
--primer_name "MiFish" \
--min_alignment_length 100 \
--local_global "local" \
--output_cluster_filepath "$output_cluster_filepath" \
--output_taxa_filepath "$output_taxa_filepath" \
--clusters_matched_filepath "$clusters_matched_filepath" \
--taxdump_filepath blastdb/ncbi_lineages_2025-01-08_fish.csv \
--custom_taxa_filepath "$local_custom_taxa_loc"