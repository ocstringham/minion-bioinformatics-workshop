
# Make "quick" reference database for Florida fishes

## Get list of Fishes in Florida from GBIF
## I will show you how to do this and will include the csv/txt here

## Download & unzip MIDORI: https://www.reference-midori.info/
mkdir data/midori

wget https://www.reference-midori.info/download/Databases/GenBank261_2024-06-15/RAW/uniq/MIDORI2_UNIQ_NUC_GB261_srRNA_RAW.fasta.gz \
 -O data/midori/midori-12S.tar.gz

gzip -d -c data/midori/midori-12S.tar.gz > \
 data/midori/midori-12S.fasta


## Filter MIDORI to fishes in Florida (using crabs)

### Convert fasta to crabs format (tsv)
### move to convert_midori_to_crabs.sh scripts folder

#### first make sure it has linux based line endings (problem when creating code in windows)
dos2unix scripts/convert_midori_to_crabs.sh 
#### load in function
source scripts/convert_midori_to_crabs.sh 

#### run function
convert_midori_to_crabs \
 data/midori/midori-12S.fasta \
 data/midori/crabs_midori-12S.txt


### Run crabs filter (note crabs is already installed on annotate2 but you can also use an image I made: singularity build images/crabs.sif docker://olistr12/crabs:1.0.7)
### Note: The --include and --exclude parameters can take in either a list of taxa separated by ; or a .txt file containing a single taxon name per line.
### Note: move florida_fish.txt to data/florida_cf folder (or anywhere you want)
crabs --subset \
 --input  data/midori/crabs_midori-12S.txt \
 --output  data/midori/crabs_midori-12S-subset.txt \
 --include 'data/florida_cf/florida_fish.txt'


## export as fasta and csv
mkdir refdb
mkdir refdb/florida

date=$(date '+%Y-%m-%d')

## to csv
{ echo "seqID,species,taxid,superkingdom,phylum,class,order,family,genus,species2"; \
cat data/midori/crabs_midori-12S-subset.txt | tr '\t' ','; } > \
refdb/florida/refdb_florida_fish_dl_"$date".csv


## to fasta
awk -F'\t' 'BEGIN { OFS="" } NR > 1 \
{ print ">" $1 " species=" $10 "; taxid=" $3 "; class=" $6 ";" "\n" $11 }' \
data/midori/crabs_midori-12S-subset.txt > \
refdb/florida/refdb_florida_fish_dl_"$date".fasta

# ------------------------------------------------------------------------------- #

# Create blast database from reference db FASTA

## note need to add in taxononmy file to blastdb folder







# ------------------------------------------------------------------------------- #


# Run blast

## we need to be inside of the blastdb directory to run blast properly (huge bug in blastdb code)
cd blastdb/dir

## run blast
singularity exec images/blast.sif \
blastn -db midori_eukaryota_2021_02_25 \
-query ../../data/florida_cf/barcodes-04-10.q10.mifish_linked_unlinked.dd.att.fasta \
-outfmt "6 delim=, std qlen slen staxids sscinames scomnames sskingdoms" \
-max_target_seqs 50 \
-out ../../data/florida_cf/barcodes-04-10.q10.mifish_linked_unlinked.dd.att.blastn.csv \
-num_threads 8

# look at the blast output
# What do cols mean?

