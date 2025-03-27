library(dplyr)
library(tidyr)
library(stringr)

# 1. Transfer over files to your computer: blast output, csv of local ref db
# list them here
# remind to install R/RStudio and above packages if not already installed
# can also use AnnotateWin if don't want to use your computer


# ---------------------------------------------------------------------------- #

# Load in blast results
blast_path = "~/../Downloads/florida_cf/barcodes-04-10.q10.l300.L400.mifish_linked_unlinked.dd.con.sub.blastn.csv"
blast = read.csv(blast_path, header = F, na.strings = c("N/A", "NA"))
colnames(blast) = c('qseqid', 'sseqid', 'pident', 'length', 'mismatch', 
                         'gapopen', 'qstart', 'qend', 'sstart', 'send', 'evalue', 'bitscore', 'qlen', 'slen',
                         'staxids', 'sscinames', 'scomnames', 'sskingdoms')
## convert staxids to character (easier to work with for IDs)
blast$staxids = as.character(blast$staxids)


# ---------------------------------------------------------------------------- #

# Load in all upstream taxonomy (from our local ref db csv file)
taxa_key_path = "~/../Downloads/florida_cf/refdb_florida_fish_dl_2025-03-26.csv"
taxa_key = read.csv(taxa_key_path)

## convert taxid to char
taxa_key$taxid = as.character(taxa_key$taxid)


## we only need this as a key to upstream taxonomy per each taxid, 
## so let's remove duplicates (remember same species can have > 1 entries in local refdb)
taxa_key1 = 
  taxa_key %>% 
  select(-sequence) %>% 
  distinct(taxid, .keep_all = T)

## look at data frame - did it import correctly? 
## No because we forgot to add a column name for sequence, let's do that now


# ---------------------------------------------------------------------------- #

# Load in barcode key (ie seqkit tabulate before clustering)
# file that says what the barcode is of every read
barcode_key_path = "~/../Downloads/florida_cf/barcodes-04-10.q10.l300.L400.mifish_linked_unlinked.dd.att.txt"
barcode_key = read.csv(barcode_key_path, sep = "\t", header = F)

## look at data frame, import messed things up lets fix.
## We only need the ID and the barcode so let's focus on that

## split first column into two columns: id and barcode
barcode_key1 = 
  barcode_key %>% 
  select(V1) %>% 
  separate(V1, c("id", "barcode"), sep = "\\s")

## now we don't want barcode=barcode04, we just want barcode04
barcode_key1$barcode = str_replace_all(barcode_key1$barcode, "barcode=", "")


# ---------------------------------------------------------------------------- #

# load in cluster key
# file that says which reads are in which cluster
# cluster key contains the name of the cluster (named after the centroid sequence)
# along with the ids of the seqs that belong in the cluster
cluster_key_path = "~/../Downloads/florida_cf/barcodes-04-10.q10.l300.L400.mifish_linked_unlinked.dd.clusters.uc"
cluster_key = read.csv(cluster_key_path, sep = "\t")
# https://drive5.com/usearch/manual/opt_uc.html
colnames(cluster_key) = c("record_type", "cluster_no", "centroid_len", 
                              "p_simil_cen", "match_orientation", "not_used",
                              "not_used2", "compress_align", "query_lab", "con_lab")

# it's kind of a wonky file. you can read the manual if you want, but here is how to clean it

cluster_key1 = 
  cluster_key %>% 
  ## rm redundant rows
  filter(record_type != "S") %>% 
  ## select relevant columns
  select(cluster_no, query_id = query_lab, con_lab) %>% 
  ## clean consensus id column
  mutate(con_id = ifelse(con_lab == "*", query_id, con_lab)) %>% 
  ## rearrange columns
  select(cluster_no, con_id, query_id, -con_lab)



# ---------------------------------------------------------------------------- #


# summarize blast output at >98% identity and alignment length >100
# we'll only do 98% here but same idea applies for between 95% and 98%


## clean cluster id & subset blast results 
blast_sub = 
  blast %>% 
  ## clean id
  separate(qseqid, c("con_id", "n_reads"), sep = ";") %>%
  mutate(con_id = str_remove(con_id, "centroid=")) %>%
  ## filter
  filter(pident >= 98, length >= 100)



# ---------------------------------------------------------------------------- #


# now let's get the final taxa for each cluster 
# right now we have all blast hits for each cluster in a row
# so, we're converting this to one row per cluster with the final taxa

# join taxonomy
blast_sub_taxonomy = 
  blast_sub %>% 
  left_join(taxa_key1, by = c("staxids"="taxid"))


# do a LCA for each cluster

## sum n taxa by ranks by row, to set up LCA
n_taxa = 
  blast_sub_taxonomy %>% 
  group_by(con_id) %>% 
  summarise(n_species = n_distinct(species2, na.rm = T),
            n_genus = n_distinct(genus, na.rm = T),
            n_family = n_distinct(family, na.rm = T),
            n_order = n_distinct(order, na.rm = T),
            n_class = n_distinct(class, na.rm = T),
            n_phylum = n_distinct(phylum, na.rm = T)) %>% 
  ungroup()


## Run logic for LCA
cluster_lca = 
  blast_sub_taxonomy %>% 
  left_join(n_taxa, by = "con_id") %>%
  distinct(con_id, .keep_all = TRUE) %>% 
  mutate(lca = case_when(
    # normal matching
    n_species == 1 ~ species,
    n_genus == 1 ~ genus,
    n_family == 1 ~ family,
    n_order == 1 ~ order,
    n_class == 1 ~ class,
    n_phylum == 1 ~ phylum,
    TRUE ~ NA_character_
  )) %>% 
  mutate(rank = case_when(
    n_species == 1 ~ "species",
    n_genus == 1 ~ "genus",
    n_family == 1 ~ "family",
    n_order == 1 ~ "order",
    n_class == 1 ~ "class",
    n_phylum == 1 ~ "phylum",
    TRUE ~ NA_character_
  )) %>%
  # fix taxonomy to match lca taxonomy (ie add in NA to uppuer taxonomy, if rank is higher than species)
  mutate(class = ifelse(rank %in% c("phylum"), NA_character_, class),
         order = ifelse(rank %in% c("phylum", "class"), NA_character_, order),
         family = ifelse(rank %in% c("phylum", "class", "order"), NA_character_, family),
         genus = ifelse(rank %in% c("phylum", "class", "order", "family"), NA_character_, genus),
         species = ifelse(rank %in% c("phylum", "class", "order", "family", "genus"), NA_character_, species),
         subspecies = ifelse(rank %in% c("phylum", "class", "order", "family", "genus", "species"), NA_character_, subspecies)) %>%
  # rm no lca matches
  # filter(!is.na(lca)) %>%
  select(con_id, lca, rank, class, order, family, genus, species)


## add back in original blast matches
blast_by_cluster = 
  blast_sub_taxonomy %>% 
  group_by(con_id) %>%
  summarise(taxids = paste0(sort(unique(staxids)), collapse = ";"),
            pidents = paste0(sort(unique(pident)), collapse = ";"),
            sscinames = paste0(sort(unique(sscinames)), collapse = ";"),
            scomnames = paste0(sort(unique(scomnames)), collapse = ";"),
            seqIDs = paste0(sort(unique(seqID)), collapse = ";")) %>% 
  ungroup()

## combine with lca
cluster_lca_info = 
  cluster_lca %>% 
  left_join(blast_by_cluster, by = "con_id")
  


# ---------------------------------------------------------------------------- #


# we now want the n reads for each cluster in each barcode
# because some clusters are made of reads from multiple barcodes, see: 0632a8f0-2c95-45c7-a587-f4cab95adc3a

n_reads_per_cluster = 
  cluster_key1 %>% 
  left_join(barcode_key1, by = c("query_id" = "id")) %>% 
  group_by(con_id, barcode) %>% 
  summarise(n_reads = n(), .groups = "drop") %>% 
  # subset to only clusters in the data
  filter(con_id %in% cluster_lca_info$con_id)



# ---------------------------------------------------------------------------- #

# now convert to summary by cluster-barcode (ie all distinct clusters in a barcode)
cluster_barcode =
  cluster_lca_info %>% 
  left_join(n_reads_per_cluster, by = "con_id") %>% 
  select(barcode, n_reads, everything(), con_id)


# ---------------------------------------------------------------------------- #

# summary by taxa-barcode (ie summarize same taxa in barcode)
taxa_barcode = 
  cluster_barcode %>% 
  group_by(lca, rank, class, order, family, genus, species, barcode) %>% 
  summarise(n_reads = sum(n_reads), .groups = "drop") %>% 
  ungroup() %>% 
  select(barcode, n_reads, everything()) %>% 
  arrange(barcode, -n_reads)



