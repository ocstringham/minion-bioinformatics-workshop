# ============================================================================ #
# Cleaning blast output
# We will end with one file that has the final taxa for each cluster
# and another file that has a list of all unique taxa
#
# Comments were made with the help of AI (AnthropicAI)
# ============================================================================ #

# INTRODUCTION
# This script processes environmental DNA (eDNA) data from fish samples collected 
# in Florida. The workflow includes analyzing BLAST results, mapping sequences to 
# taxonomy, and summarizing the data at different levels (by cluster, by barcode,
# and by taxa).

# ============================================================================ #
# SETUP
# ============================================================================ #

# Load required libraries
library(dplyr)     # For data manipulation
library(tidyr)     # For data reshaping
library(stringr)   # For string manipulation

# FILE PREPARATION
# Before running this analysis, you need to transfer several files to your computer:
# - BLAST output file: barcodes-04-10.q10.l300.L400.mifish_linked_unlinked.dd.con.sub.blastn.csv
# - CSV of local reference database: refdb_florida_fish_dl_2025-03-26.csv
# - Barcode key file: barcodes-04-10.q10.l300.L400.mifish_linked_unlinked.dd.att.txt
# - Cluster key file: barcodes-04-10.q10.l300.L400.mifish_linked_unlinked.dd.clusters.uc
#
# I've placed all these files in the "Downloads/florida_cf" directory on my
# computer, but you can put them anywhere you'd like as long as you update the
# file paths in the script below.
#
#
# If you haven't already installed R and RStudio, you'll need to do so along 
# with the packages listed above. Alternatively, you can use AnnotateWin if you 
# prefer not to use your computer.

# ============================================================================ #
# DATA IMPORT AND CLEANING
# ============================================================================ #

# 1. IMPORT BLAST RESULTS
# First, we'll load the BLAST results which contain sequence alignments against a 
# reference database.

# Path to the BLAST results file
blast_path = "~/../Downloads/florida_cf/barcodes-04-10.q10.l300.L400.mifish_linked_unlinked.dd.con.sub.blastn.csv"

# Read the BLAST results into R
blast = read.csv(blast_path, header = F, na.strings = c("N/A", "NA"))

# Assign column names according to BLAST output format 6 + other additional columns
colnames(blast) = c('qseqid', 'sseqid', 'pident', 'length', 'mismatch', 
                    'gapopen', 'qstart', 'qend', 'sstart', 'send', 'evalue', 'bitscore', 'qlen', 'slen',
                    'staxids', 'sscinames', 'scomnames', 'sskingdoms')

# Convert taxonomy IDs to character (easier to work with for IDs)
blast$staxids = as.character(blast$staxids)

# You can uncomment the line below to display the structure of the BLAST results
# str(blast)

# ============================================================================ #

# 2. IMPORT TAXONOMY REFERENCE DATABASE
# Next, we'll load the taxonomy information from our local reference database.

# Path to the reference database
taxa_key_path = "~/../Downloads/florida_cf/refdb_florida_fish_dl_2025-03-26.csv"

# Read the taxonomy reference database
taxa_key = read.csv(taxa_key_path)

# Convert taxonomy ID to character
taxa_key$taxid = as.character(taxa_key$taxid)

# We only need this as a key to map taxonomy IDs to full taxonomy information
# Remove duplicate taxonomy IDs (the same species can have multiple entries in the reference database)
taxa_key1 = 
  taxa_key %>% 
  select(-sequence) %>% 
  distinct(taxid, .keep_all = TRUE)

# You can uncomment the line below to display the structure of the taxonomy key
# or click it in the RStudio Environment pane
# head(taxa_key1)

# ============================================================================ #

# 3. IMPORT BARCODE KEY
# The barcode key maps sequence IDs to barcode identifiers.

# Path to the barcode key file
barcode_key_path = "~/../Downloads/florida_cf/barcodes-04-10.q10.l300.L400.mifish_linked_unlinked.dd.att.txt"

# Read the barcode key file
barcode_key = read.csv(barcode_key_path, sep = "\t", header = F)

# Split the first column into two columns: ID and barcode
barcode_key1 = 
  barcode_key %>% 
  select(V1) %>% 
  separate(V1, c("id", "barcode"), sep = "\\s")

# Remove the "barcode=" prefix from the barcode column
barcode_key1$barcode = str_replace_all(barcode_key1$barcode, "barcode=", "")

# You can uncomment the line below to display the cleaned barcode key
# head(barcode_key1)

# ============================================================================ #

# 4. IMPORT CLUSTER KEY
# The cluster key contains information about which sequences belong to which clusters.

# Path to the cluster key file
cluster_key_path = "~/../Downloads/florida_cf/barcodes-04-10.q10.l300.L400.mifish_linked_unlinked.dd.clusters.uc"

# Read the cluster key file
cluster_key = read.csv(cluster_key_path, sep = "\t")

# Assign column names according to the UC format
# See: https://drive5.com/usearch/manual/opt_uc.html for format details
colnames(cluster_key) = c("record_type", "cluster_no", "centroid_len", 
                          "p_simil_cen", "match_orientation", "not_used",
                          "not_used2", "compress_align", "query_lab", "con_lab")

# Clean up the cluster key data
cluster_key1 = 
  cluster_key %>% 
  # Remove redundant "S" record type rows (these are summary lines)
  filter(record_type != "S") %>% 
  # Select only the relevant columns
  select(cluster_no, query_id = query_lab, con_lab) %>% 
  # Clean the consensus ID column (* means the query is the centroid)
  mutate(con_id = ifelse(con_lab == "*", query_id, con_lab)) %>% 
  # Rearrange columns
  select(cluster_no, con_id, query_id, -con_lab)

# You can uncomment the line below to display the cleaned cluster key
# head(cluster_key1)

# ============================================================================ #
# DATA ANALYSIS
# ============================================================================ #

# 1. FILTER BLAST RESULTS
# We'll filter the BLAST results to include only high-quality matches 
# (≥98% identity and alignment length ≥100).

# Clean cluster ID and subset BLAST results
blast_sub = 
  blast %>% 
  # Extract cluster ID and read count from the query sequence ID
  separate(qseqid, c("con_id", "n_reads"), sep = ";") %>%
  mutate(con_id = str_remove(con_id, "centroid=")) %>%
  # Filter for high-quality matches (≥98% identity and alignment length ≥100)
  filter(pident >= 98, length >= 100)

# You can uncomment the line below to display filtered BLAST results
# head(blast_sub)

# ============================================================================ #

# 2. JOIN TAXONOMY INFORMATION
# Now we'll add the full taxonomy information to our BLAST results.

# Join taxonomy information to BLAST results
blast_sub_taxonomy = 
  blast_sub %>% 
  left_join(taxa_key1, by = c("staxids" = "taxid"))

# You can uncomment the line below to display BLAST results with taxonomy
# head(blast_sub_taxonomy)

# ============================================================================ #

# 3. DETERMINE LEAST COMMON ANCESTOR (LCA)
# To handle cases where a sequence matches multiple taxa, we'll determine 
# the Least Common Ancestor (LCA) for each cluster.

# Count the number of distinct taxa at each taxonomic rank for each cluster
n_taxa = 
  blast_sub_taxonomy %>% 
  group_by(con_id) %>% 
  summarise(
    n_species = n_distinct(species2, na.rm = TRUE),
    n_genus = n_distinct(genus, na.rm = TRUE),
    n_family = n_distinct(family, na.rm = TRUE),
    n_order = n_distinct(order, na.rm = TRUE),
    n_class = n_distinct(class, na.rm = TRUE),
    n_phylum = n_distinct(phylum, na.rm = TRUE)
  ) %>% 
  ungroup()

# Apply LCA logic to determine the most specific taxonomic level we can confidently assign
cluster_lca = 
  blast_sub_taxonomy %>% 
  left_join(n_taxa, by = "con_id") %>%
  # Keep only one row per cluster
  distinct(con_id, .keep_all = TRUE) %>% 
  # Determine the lowest common ancestor taxonomy
  mutate(lca = case_when(
    # If there's only one species match, use the species name
    n_species == 1 ~ species,
    # If there's only one genus but multiple species, use the genus name
    n_genus == 1 ~ genus,
    # If there's only one family but multiple genera, use the family name
    n_family == 1 ~ family,
    # If there's only one order but multiple families, use the order name
    n_order == 1 ~ order,
    # If there's only one class but multiple orders, use the class name
    n_class == 1 ~ class,
    # If there's only one phylum but multiple classes, use the phylum name
    n_phylum == 1 ~ phylum,
    # If there are multiple phyla, leave as NA
    TRUE ~ NA_character_
  )) %>% 
  # Record the taxonomic rank used for the LCA
  mutate(rank = case_when(
    n_species == 1 ~ "species",
    n_genus == 1 ~ "genus",
    n_family == 1 ~ "family",
    n_order == 1 ~ "order",
    n_class == 1 ~ "class",
    n_phylum == 1 ~ "phylum",
    TRUE ~ NA_character_
  )) %>%
  # Fix taxonomy to match LCA taxonomy (set higher ranks to NA when appropriate)
  mutate(
    class = ifelse(rank %in% c("phylum"), NA_character_, class),
    order = ifelse(rank %in% c("phylum", "class"), NA_character_, order),
    family = ifelse(rank %in% c("phylum", "class", "order"), NA_character_, family),
    genus = ifelse(rank %in% c("phylum", "class", "order", "family"), NA_character_, genus),
    species = ifelse(rank %in% c("phylum", "class", "order", "family", "genus"), NA_character_, species),
    subspecies = ifelse(rank %in% c("phylum", "class", "order", "family", "genus", "species"), NA_character_, subspecies)
  ) %>%
  # Select relevant columns
  select(con_id, lca, rank, class, order, family, genus, species)

# You can uncomment the line below to display the LCA results
# head(cluster_lca)

# ============================================================================ #

# 4. COMPILE BLAST INFORMATION BY CLUSTER
# Now we'll summarize all the BLAST matches for each cluster.

# Summarize BLAST matches by cluster
blast_by_cluster = 
  blast_sub_taxonomy %>% 
  group_by(con_id) %>%
  summarise(
    # Concatenate all unique taxonomy IDs
    taxids = paste0(sort(unique(staxids)), collapse = ";"),
    # Concatenate all unique percent identity values
    pidents = paste0(sort(unique(pident)), collapse = ";"),
    # Concatenate all unique scientific names
    sscinames = paste0(sort(unique(sscinames)), collapse = ";"),
    # Concatenate all unique common names
    scomnames = paste0(sort(unique(scomnames)), collapse = ";"),
    # Concatenate all unique sequence IDs
    seqIDs = paste0(sort(unique(seqID)), collapse = ";")
  ) %>% 
  ungroup()

# Combine LCA information with BLAST matches
cluster_lca_info = 
  cluster_lca %>% 
  left_join(blast_by_cluster, by = "con_id")

# You can uncomment the line below to display the combined cluster information
# head(cluster_lca_info)

# ============================================================================ #

# 5. COUNT READS PER CLUSTER AND BARCODE
# Now we'll determine how many reads are in each cluster for each barcode.

# Count reads per cluster and barcode
n_reads_per_cluster = 
  cluster_key1 %>% 
  # Join with barcode information
  left_join(barcode_key1, by = c("query_id" = "id")) %>% 
  # Group by cluster ID and barcode
  group_by(con_id, barcode) %>% 
  # Count the number of reads
  summarise(n_reads = n(), .groups = "drop") %>% 
  # Filter to include only clusters with taxonomic assignments
  filter(con_id %in% cluster_lca_info$con_id)

# You can uncomment the line below to display read counts
# head(n_reads_per_cluster)

# ============================================================================ #
# RESULTS SUMMARIZATION
# ============================================================================ #

# 1. SUMMARY BY CLUSTER-BARCODE
# First, we'll create a summary at the cluster-barcode level, which shows all 
# distinct clusters in each barcode.

# Create summary by cluster-barcode
cluster_barcode =
  cluster_lca_info %>% 
  left_join(n_reads_per_cluster, by = "con_id") %>% 
  select(barcode, n_reads, everything(), con_id)

# You can uncomment the line below to display the cluster-barcode summary
# head(cluster_barcode)

# ============================================================================ #

# 2. SUMMARY BY TAXA-BARCODE
# Finally, we'll summarize by taxa-barcode, combining the read counts for the 
# same taxa within each barcode.

# Create summary by taxa-barcode
taxa_barcode = 
  cluster_barcode %>% 
  group_by(lca, rank, class, order, family, genus, species, barcode) %>% 
  summarise(n_reads = sum(n_reads), n_clusters = n(), .groups = "drop") %>% 
  ungroup() %>% 
  select(barcode, n_reads, n_clusters, everything()) %>% 
  arrange(barcode, -n_reads)

# You can uncomment the line below to display the taxa-barcode summary
# head(taxa_barcode)

# ============================================================================ #
# EXPORT RESULTS
# ============================================================================ #

# You can uncomment these lines to export your results to CSV files

# Export cluster-barcode summary
# write.csv(cluster_barcode, "florida_fish_cluster_barcode_summary.csv", row.names = FALSE)

# Export taxa-barcode summary
# write.csv(taxa_barcode, "florida_fish_taxa_barcode_summary.csv", row.names = FALSE)

# ============================================================================ #
# CONCLUSION
# ============================================================================ #

# This analysis pipeline processes eDNA data from Florida fish samples, mapping 
# sequences to taxonomic information and producing summaries at different levels 
# of organization. The final output provides a clear picture of which taxa are 
# present in each barcode and their relative abundance based on read counts.