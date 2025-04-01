# ============================================================================ #
# CLEANING BLAST OUTPUT 
#
# Comments were made with the help of AI (AnthropicAI)
# ============================================================================ #

# The script takes raw BLAST (Basic Local Alignment Search Tool) results that
# match DNA sequences to a reference database and performs these key steps:
# 1. Loads and cleans all input files
# 2. Filters for high-quality matches
# 3. Assigns taxonomy to each sequence cluster
# 4. Counts the number of reads per barcode
# 5. Creates summary tables for analysis (at the cluster level and the taxa level)
#
# We will end with one file that has the final taxa for each cluster
# and another file that has a list of all unique taxa

# ============================================================================ #
# SETUP
# ============================================================================ #

# Load required libraries (packages)
# If you get errors here, you need to install these packages first using:
# install.packages(c("dplyr", "tidyr", "stringr"))

library(dplyr)     # For data manipulation (filtering, joining tables, etc.)
library(tidyr)     # For reshaping data (pivoting, separating columns, etc.)
library(stringr)   # For working with text strings (replacing text, matching patterns)

# ============================================================================ #
# FILE PREPARATION
# ============================================================================ #

# Before running this analysis, you need these four input files:
#
# 1. BLAST output file: Results from comparing our sequences to a reference database
#    (barcodes-04-10.q10.l300.L400.mifish_linked_unlinked.dd.con.sub.blastn.csv)
#
# 2. Reference database: Contains taxonomy information for each reference sequence
#    (refdb_florida_fish_dl_2025-03-26.csv)
#
# 3. Barcode key file: Maps sequence IDs to sample barcodes (which sample they came from)
#    (barcodes-04-10.q10.l300.L400.mifish_linked_unlinked.dd.att.txt)
#
# 4. Cluster key file: Shows which sequences were grouped together by similarity
#    (barcodes-04-10.q10.l300.L400.mifish_linked_unlinked.dd.clusters.uc)
#
# This script assumes all files are in the "Downloads/florida_cf" directory.
# If your files are elsewhere, update the file paths below.
#
# If you haven't already installed R and RStudio, you'll need to do that first,
# then install the packages listed above.

# ============================================================================ #
# DATA IMPORT AND CLEANING
# ============================================================================ #

# 1. IMPORT BLAST RESULTS
# BLAST is a tool that finds regions of similarity between biological sequences.
# It compares our unknown sequences to a database of known sequences.

# Path to the BLAST results file - update this if your file is in a different location
blast_path = "~/../Downloads/florida_cf/barcodes-04-10.q10.l300.L400.mifish_linked_unlinked.dd.con.sub.blastn.csv"

# Read the BLAST results into R - this loads the data into memory
# header=F means the file doesn't have column names in the first row
# na.strings tells R which values should be treated as missing data
blast = read.csv(blast_path, header = F, na.strings = c("N/A", "NA"))

# Assign column names to the BLAST results
# These are standard BLAST output columns plus some additional ones:
# - qseqid: Query sequence ID (our unknown sequence)
# - sseqid: Subject sequence ID (matching reference sequence)
# - pident: Percentage identity (how well they match, 0-100%)
# - length: Alignment length
# - staxids: Taxonomy ID of the matching sequence
# - sscinames: Scientific name of the matching sequence
colnames(blast) = c('qseqid', 'sseqid', 'pident', 'length', 'mismatch', 
                    'gapopen', 'qstart', 'qend', 'sstart', 'send', 'evalue', 'bitscore', 'qlen', 'slen',
                    'staxids', 'sscinames', 'scomnames', 'sskingdoms')

# Convert taxonomy IDs to character type (text) instead of numeric
# This is important because IDs are labels, not numbers to calculate with
blast$staxids = as.character(blast$staxids)

# To see the structure of your data, uncomment this line by removing the #
# str(blast)

# ============================================================================ #

# 2. IMPORT TAXONOMY REFERENCE DATABASE
# This database contains the full taxonomic information (family, genus, species, etc.)
# for each reference sequence.

# Path to the reference database file
taxa_key_path = "~/../Downloads/florida_cf/refdb_florida_fish_dl_2025-03-26.csv"

# Read the taxonomy reference database
taxa_key = read.csv(taxa_key_path)

# Convert taxonomy ID to character type (text)
taxa_key$taxid = as.character(taxa_key$taxid)

# Clean up the reference database:
# 1. Remove the sequence column (we don't need the actual DNA sequences)
# 2. Keep only one row per taxonomy ID (some species may have multiple entries)
taxa_key1 = 
  taxa_key %>% 
  select(-sequence) %>% 
  distinct(taxid, .keep_all = TRUE)

# To view the first few rows of this data, uncomment this line:
# or click the object in the RStudio Environment pane
# head(taxa_key1)

# ============================================================================ #

# 3. IMPORT BARCODE KEY
# The barcode key tells us which sample (barcode) each sequence came from.
# This lets us know which fish were found in which sample.

# Path to the barcode key file
barcode_key_path = "~/../Downloads/florida_cf/barcodes-04-10.q10.l300.L400.mifish_linked_unlinked.dd.att.txt"

# Read the barcode key file
# sep = "\t" means it's a tab-delimited file
barcode_key = read.csv(barcode_key_path, sep = "\t", header = F)

# Clean the barcode key:
# 1. Extract only the first column (V1) which contains the ID and barcode
# 2. Split this column into two: "id" and "barcode"
# 3. The split happens at the space character (\s)
barcode_key1 = 
  barcode_key %>% 
  select(V1) %>% 
  separate(V1, c("id", "barcode"), sep = "\\s")

# Remove the "barcode=" prefix from the barcode column
# For example, "barcode=barcode01" becomes just "barcode01"
barcode_key1$barcode = str_replace_all(barcode_key1$barcode, "barcode=", "")

# To view the cleaned barcode key, uncomment this line:
# head(barcode_key1)

# ============================================================================ #

# 4. IMPORT CLUSTER KEY
# The cluster key shows which sequences were grouped together based on similarity.
# Clustering helps reduce redundancy by grouping nearly identical sequences.

# Path to the cluster key file
cluster_key_path = "~/../Downloads/florida_cf/barcodes-04-10.q10.l300.L400.mifish_linked_unlinked.dd.clusters.uc"

# Read the cluster key file
cluster_key = read.csv(cluster_key_path, sep = "\t")

# Assign column names according to the UC format
# This is a standard format used by the USEARCH/VSEARCH clustering tools
# For more details: https://drive5.com/usearch/manual/opt_uc.html
colnames(cluster_key) = c("record_type", "cluster_no", "centroid_len", 
                          "p_simil_cen", "match_orientation", "not_used",
                          "not_used2", "compress_align", "query_lab", "con_lab")

# Clean up the cluster key data:
# 1. Remove "S" record types (these are just summary lines)
# 2. Keep only relevant columns
# 3. Clean up the consensus ID column:
#    - "*" means this sequence is the centroid (representative) of the cluster
#    - When we see "*", use the query_id as the centroid ID
cluster_key1 = 
  cluster_key %>% 
  filter(record_type != "S") %>% 
  select(cluster_no, query_id = query_lab, con_lab) %>% 
  mutate(con_id = ifelse(con_lab == "*", query_id, con_lab)) %>% 
  select(cluster_no, con_id, query_id, -con_lab)

# To view the cleaned cluster key, uncomment this line:
# head(cluster_key1)

# ============================================================================ #
# DATA ANALYSIS
# ============================================================================ #

# 1. FILTER BLAST RESULTS
# We'll keep only high-quality matches to ensure accurate species identification.
# This means matches with:
# - ≥98% sequence identity (very close match)
# - Alignment length ≥100 base pairs (substantial overlap)

# Clean and filter BLAST results:
# 1. Extract cluster ID and read count from the query sequence ID
# 2. Remove "centroid=" prefix from cluster IDs
# 3. Keep only high-quality matches
blast_sub = 
  blast %>% 
  separate(qseqid, c("con_id", "n_reads"), sep = ";") %>%
  mutate(con_id = str_remove(con_id, "centroid=")) %>%
  filter(pident >= 98, length >= 100)

# To view the filtered BLAST results, uncomment this line:
# head(blast_sub)

# ============================================================================ #

# 2. JOIN TAXONOMY INFORMATION
# Now we'll add the full taxonomy information to our BLAST results.
# This connects each match to its complete classification (phylum, class, order, etc.)

# Join taxonomy information to BLAST results
# This is like a database table join, matching "staxids" to "taxid"
blast_sub_taxonomy = 
  blast_sub %>% 
  left_join(taxa_key1, by = c("staxids" = "taxid"))

# To view BLAST results with taxonomy, uncomment this line:
# head(blast_sub_taxonomy)

# ============================================================================ #

# 3. DETERMINE LEAST COMMON ANCESTOR (LCA)
# When a sequence matches multiple species, we need to find their common ancestor.
# For example, if a sequence matches two different bass species, we might only
# be able to confidently say it's a "bass" (genus level) rather than a specific species.

# First, count how many distinct taxa are matched at each taxonomic level for each cluster
n_taxa = 
  blast_sub_taxonomy %>% 
  group_by(con_id) %>% 
  summarise(
    # Count distinct values at each taxonomic level
    n_species = n_distinct(species2, na.rm = TRUE),
    n_genus = n_distinct(genus, na.rm = TRUE),
    n_family = n_distinct(family, na.rm = TRUE),
    n_order = n_distinct(order, na.rm = TRUE),
    n_class = n_distinct(class, na.rm = TRUE),
    n_phylum = n_distinct(phylum, na.rm = TRUE)
  ) %>% 
  ungroup()

# Apply LCA logic to determine the most specific taxonomic level we can confidently assign
# The LCA is the most specific taxonomic level with only one unique value
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
    # If there are multiple phyla, leave as NA (no common ancestor found)
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
  # Clear higher taxonomy levels when LCA is at a broader level
  # For example, if LCA is at family level, we shouldn't have genus/species info
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

# To view the LCA results, uncomment this line:
# head(cluster_lca)

# ============================================================================ #

# 4. COMPILE BLAST INFORMATION BY CLUSTER
# Now we'll summarize all the BLAST matches for each cluster.
# So, if more than one taxa is in one cluster, we'll have all of them in one row.

# Summarize BLAST matches by cluster
blast_by_cluster = 
  blast_sub_taxonomy %>% 
  group_by(con_id) %>%
  summarise(
    # Concatenate all unique taxonomy IDs with semicolons
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

# To view the combined cluster information, uncomment this line:
# head(cluster_lca_info)

# ============================================================================ #

# 5. COUNT READS PER CLUSTER-BARCODE COMBINATION
# Now we'll determine how many reads are in each each barcode for each cluster.

# Count reads per cluster-barcode combination
n_reads_per_cluster = 
  cluster_key1 %>% 
  # Join with barcode information to know which sample each sequence came from
  left_join(barcode_key1, by = c("query_id" = "id")) %>% 
  # Group by cluster ID and barcode
  group_by(con_id, barcode) %>% 
  # Count the number of reads (sequences) in each group
  summarise(n_reads = n(), .groups = "drop") %>% 
  # Keep only clusters that have taxonomy assignments
  filter(con_id %in% cluster_lca_info$con_id)

# To view the read counts, uncomment this line:
# head(n_reads_per_cluster)

# ============================================================================ #
# RESULTS SUMMARIZATION
# ============================================================================ #

# 1. SUMMARY BY CLUSTER-BARCODE
# First, we'll create a summary at the cluster-barcode level, which shows all 
# distinct clusters in each barcode (sample).

# Create summary by cluster-barcode
cluster_barcode =
  cluster_lca_info %>% 
  left_join(n_reads_per_cluster, by = "con_id") %>% 
  # Rearrange columns to put important info first
  select(barcode, n_reads, everything(), con_id)

# To view the cluster-barcode summary, uncomment this line:
# head(cluster_barcode)

# We can convert this to 'wide' format for easier viewing
cluster_barcode_wide = 
  cluster_barcode %>% 
  # Pivot the data to have each barcode now be a column
  pivot_wider(names_from = barcode, values_from = n_reads) %>% 
  # fill in NAs to 0, only for numeric cols
  mutate(across(where(is.numeric), ~replace_na(., 0)))

# ============================================================================ #

# 2. SUMMARY BY TAXA-BARCODE
# Finally, we'll summarize by taxa-barcode, combining the read counts for the 
# same taxa within each barcode. This gives the total abundance of each fish type
# in each sample.

# Create summary by taxa-barcode
taxa_barcode = 
  cluster_barcode %>% 
  group_by(lca, rank, class, order, family, genus, species, barcode) %>% 
  summarise(
    # Sum read counts across all clusters of the same taxon
    n_reads = sum(n_reads), 
    # Count how many clusters were merged for this taxon
    n_clusters = n(), 
    .groups = "drop"
  ) %>% 
  ungroup() %>% 
  # Rearrange columns to put important info first
  select(barcode, n_reads, n_clusters, everything()) %>% 
  # Sort by barcode and then by number of reads (descending)
  arrange(barcode, -n_reads)

# To view the taxa-barcode summary, uncomment this line:
# head(taxa_barcode)

# Again we can pivot this wide for easier viewing
# if names lca repeats across barcodes, make sure they are only one row
taxa_barcode_wide = 
  taxa_barcode %>% 
  # rm n_clusters for now to make it easier to pivot
  select(-n_clusters) %>% 
  pivot_wider(names_from = barcode, values_from = n_reads) %>% 
  mutate(across(where(is.numeric), ~replace_na(., 0)))

# ============================================================================ #
# EXPORT RESULTS
# ============================================================================ #

# You can uncomment these lines to export your results to CSV files
# These files can be opened in Excel or other programs for further analysis

# Export cluster-barcode summary
# write.csv(cluster_barcode_wide, "~/../Downloads/florida_cf/florida_fish_cluster_barcode_summary.csv", row.names = FALSE)

# Export taxa-barcode summary
# write.csv(taxa_barcode_wide, "~/../Downloads/florida_cf/florida_fish_taxa_barcode_summary.csv", row.names = FALSE)

