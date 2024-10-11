

# left off at having consensus sequences for each motu



# For the reference database, we will use MIDORI
# MIDORI is a curated database of 12S, 16S, COI for eukaryotes

# It's pretty good, there are better ways but they are way more involved so we'll leave that for another time


# Download MIDORI: https://www.reference-midori.info/



# create blast database from FASTA
## note we could have just downloaded the blast database from MIDORI but it's good to know how to do this since fasta-->blastdb is a common task

## note need to add in taxononmy file to blastdb folder


## also note, need to run the blast function from within this folder (huge bug in blastdb code)


# Tabulate the MIDORI fasta file (we'll need it later)
# Let's use R for this


# Run blast

## we need to be inside of the blastdb directory to run blast properly
cd blastdb/dir

## run blast
singularity exec images/blast.sif \
blastn -db midori_eukaryota_2021_02_25 \
-query ../../data/florida_cf/barcodes-04-10.q10.mifish_linked_unlinked.dd.att.fasta \
-outfmt 6 \
-out ../../data/florida_cf/barcodes-04-10.q10.mifish_linked_unlinked.dd.att.blastn.txt \
-num_threads 8

# look at the blast output
# What do cols mean?

