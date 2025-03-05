## Download & unzip MIDORI: https://www.reference-midori.info/
mkdir data/midori

wget https://www.reference-midori.info/download/Databases/GenBank261_2024-06-15/RAW/uniq/MIDORI2_UNIQ_NUC_GB261_srRNA_RAW.fasta.gz \
 -O data/midori/midori-12S.tar.gz

# uncompress it
gzip -d -c data/midori/midori-12S.tar.gz > \
 data/midori/midori-12S.fasta

 head data/midori/midori-12S.fasta


 #### first make sure it has linux based line endings (problem when creating code in windows)
dos2unix scripts/convert_midori_to_crabs.sh 
#### load in function
source scripts/convert_midori_to_crabs.sh 

#### run function
convert_midori_to_crabs \
 data/midori/midori-12S.fasta \
 data/midori/crabs_midori-12S.txt

# build image for crabs
singularity build images/crabs.sif docker://olistr12/crabs:1.0.7

# run crabs filter
singularity exec images/crabs.sif \
 crabs --subset \
 --input  data/midori/crabs_midori-12S.txt \
 --output  data/midori/crabs_midori-12S-subset.txt \
 --include 'data/florida_cf/florida_fish.txt'

 head data/midori/crabs_midori-12S-subset.txt

 # note some midori seqs have many Ns ... this could be a problem
 