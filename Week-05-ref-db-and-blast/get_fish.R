
library(readr)
library(dplyr)

# load in pinelands species list from GBIF
df = readr::read_tsv("export-from-gbif.csv")

df %>% distinct(class)
df %>% distinct(taxonRank)

df_sub = 
  df %>% 
  filter(is.na(class) | class %in% c("Elasmobranchii", "Petromyzonti", "Holocephali ")) %>% 
  filter(!taxonRank %in% c("GENUS", "FAMILY", "ORDER", "CLASS", "PHYLUM", "KINGDOM")) %>% 
  filter(!is.na(speciesKey)) %>% 
  distinct(species, .keep_all = TRUE) %>%
  select(species, speciesKey, class, order, family) %>% 
  arrange(species)


# export as txt file with each line a species
writeLines(df_sub$species, "florida_fish.txt")

