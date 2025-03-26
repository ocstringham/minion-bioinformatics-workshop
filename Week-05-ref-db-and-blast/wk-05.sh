
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

### rm duplicates
sort -t$'\t' -k1,1 -u \
data/midori/crabs_midori-12S-subset.txt > \
data/midori/crabs_midori-12S-subset.dd.txt


## rm rows with two or more Ns in sequence (11th column)
# how to do this in crabs https://github.com/gjeunen/reference_database_creator?tab=readme-ov-file#552---filter
awk -F'\t' '$11 !~ /N{2,}/' \
data/midori/crabs_midori-12S-subset.dd.txt > \
data/midori/crabs_midori-12S-subset.dd.noN.txt






## export as fasta and csv
mkdir refdb
mkdir refdb/florida

date=$(date '+%Y-%m-%d')

## to csv
{ echo "seqID,species,taxid,superkingdom,phylum,class,order,family,genus,species2"; \
cat data/midori/crabs_midori-12S-subset.dd.noN.txt | tr '\t' ','; } > \
refdb/florida/refdb_florida_fish_dl_"$date".csv


## to fasta
awk -F'\t' 'BEGIN { OFS="" } NR > 1 \
{ print ">" $1 " species=" $10 "; taxid=" $3 "; class=" $6 ";" "\n" $11 }' \
data/midori/crabs_midori-12S-subset.dd.noN.txt > \
refdb/florida/refdb_florida_fish_dl_"$date".fasta

# ------------------------------------------------------------------------------- #

# Create blast database from reference db FASTA

mkdir blastdb
mkdir blastdb/florida

## generate a taxid map file for the blast database
## this is a file that maps the taxid to the species name, needed for blast to assign taxonomy properly
awk -F "[>;= ]" '/^>/{for(i=1; i<=NF; i++) if($i == "taxid") print $2, $(i+1)}' \
"refdb/florida/refdb_florida_fish_dl_$date.fasta" > \
"blastdb/florida/refdb_florida_fish_dl_$date.taxid.txt"

## run makeblastdb function
singularity exec images/blast.sif \
    makeblastdb -in "refdb/florida/refdb_florida_fish_dl_$date.fasta" \
    -parse_seqids \
    -taxid_map "blastdb/florida/refdb_florida_fish_dl_$date.taxid.txt" \
    -dbtype nucl \
    -out "blastdb/florida/florida_blastdb/florida_blastdb"


## need to add in ncbi taxononmy file to blastdb folder (in order for blast to assign taxonomy properly)

### get taxonomy file
wget https://ftp.ncbi.nlm.nih.gov/blast/db/taxdb.tar.gz
### tar.gz file to directory
tar -xvzf taxdb.tar.gz -C "blastdb/florida/florida_blastdb/"
### rm taxdb.tar.gz (optional)
rm taxdb.tar.gz


# ------------------------------------------------------------------------------- #


# Run blast

## we need to be inside of the blastdb directory to run blast properly (huge bug in blastdb code)
cd blastdb/florida/florida_blastdb/

## run blast
singularity exec ../../../images/blast.sif \
blastn -db florida_blastdb \
-query ../../../data/florida_cf/vsearch/barcodes-04-10.q10.l300.L400.mifish_linked_unlinked.dd.con.sub.fasta \
-outfmt "6 delim=, std qlen slen staxids sscinames scomnames sskingdoms" \
-max_target_seqs 50 \
-out ../../../data/florida_cf/vsearch/barcodes-04-10.q10.l300.L400.mifish_linked_unlinked.dd.con.sub.blastn.csv \
-num_threads 8

# look at the blast output
# What do cols mean? https://www.metagenomics.wiki/tools/blast/blastn-output-format-6



# ------------------------------------------------------------------------------- #