
# step 1: transfer pod5 folder(s) to server

## if zipped, unzip
tar -xvzf data/balbina/BalbinaRun02_YawanawaRun01.tar.gz -C data/balbina/
tar -xvzf data/balbina/BalbinaRun03.tar.gz -C data/balbina

## sometimes need to unzip the pod5 files (if they are pod5.gz)
mkdir data/balbina/BalbinaRun02_YawanawaRun01_/BalbinaRun02_YawanawaRun01_/20241001_1042_MN37142_FAY29079_408f14ca/pod5_unzipped
for file in data/balbina/BalbinaRun02_YawanawaRun01_/BalbinaRun02_YawanawaRun01_/20241001_1042_MN37142_FAY29079_408f14ca/pod5/*.gz; do
  gunzip -c "$file" > data/balbina/BalbinaRun02_YawanawaRun01_/BalbinaRun02_YawanawaRun01_/20241001_1042_MN37142_FAY29079_408f14ca/pod5_unzipped/$(basename "$file" .gz)
done

mkdir data/balbina/BalbinaRun03_/BalbinaRun03_/20241002_2034_MN37142_FAY29028_e6d26a31/pod5_unzipped
for file in data/balbina/BalbinaRun03_/BalbinaRun03_/20241002_2034_MN37142_FAY29028_e6d26a31/pod5/*.gz; do
  gunzip -c "$file" > data/balbina/BalbinaRun03_/BalbinaRun03_/20241002_2034_MN37142_FAY29028_e6d26a31/pod5_unzipped/$(basename "$file" .gz)
done



# download most recent dorado version for x64 linux: https://github.com/nanoporetech/dorado
## download dorado
wget https://cdn.oxfordnanoportal.com/software/analysis/dorado-0.8.0-linux-x64.tar.gz
## unzip
tar -xvzf dorado-0.8.0-linux-x64.tar.gz

# check dorado basecaller help
dorado-0.8.0-linux-x64/bin/dorado basecaller --help


# download desired models (sometimes needed), see github page for model options
mkdir ~/dorado_models

dorado-0.8.0-linux-x64/bin/dorado download --verbose \
--model dna_r10.4.1_e8.2_400bps_sup@v5.0.0 --directory ~/dorado_models


# before and during basecalling, check gpu usage (if someone else is using it, need to wait)
watch -n 0.5 nvidia-smi


# call hac or sup basecaller exported as bam to preserve attributes of reads, including barcode
time dorado-0.8.0-linux-x64/bin/dorado basecaller \
--no-trim --recursive \
dorado_models/dna_r10.4.1_e8.2_400bps_sup@v5.0.0 \
data/balbina/BalbinaRun02_YawanawaRun01_/BalbinaRun02_YawanawaRun01_/20241001_1042_MN37142_FAY29079_408f14ca/pod5_unzipped > \
data/balbina/BalbinaRun02_YawanawaRun01_sup.bam

time dorado-0.8.0-linux-x64/bin/dorado basecaller \
--no-trim --recursive \
dorado_models/dna_r10.4.1_e8.2_400bps_sup@v5.0.0 \
data/balbina/BalbinaRun03_/BalbinaRun03_/20241002_2034_MN37142_FAY29028_e6d26a31/pod5_unzipped > \
data/balbina/BalbinaRun03_sup.bam


# demultiplexing

## help
dorado-0.8.0-linux-x64/bin/dorado demux --help

## run demux (careful with --threads; check with htop)
mkdir data/balbina/BalbinaRun02_YawanawaRun01_sup_demux
time dorado-0.8.0-linux-x64/bin/dorado demux \
--no-trim \
--kit-name EXP-PBC096 \
--threads 50 --output-dir data/balbina/BalbinaRun02_YawanawaRun01_sup_demux \
--emit-fastq data/balbina/BalbinaRun02_YawanawaRun01_sup.bam

mkdir data/balbina/BalbinaRun03_sup_demux
time dorado-0.8.0-linux-x64/bin/dorado demux \
--no-trim \
--kit-name EXP-PBC096 \
--threads 50 --output-dir data/balbina/BalbinaRun03_sup_demux \
--emit-fastq data/balbina/BalbinaRun03_sup.bam



# label each read with barcode

## barcode labeller function (paste in terminal)
label_barcode_fastq_files() {
    local directory="$1"
    local out_directory="$2"
    mkdir -p "$out_directory"
    for file in "$directory"*.fastq; do
        barcode=$(basename "$file" | sed 's/.*_barcode\([0-9]*\)\.fastq/\1/')
        basename_temp=$(basename "$file" .fastq)
        awk -v barcode="$barcode" 'NR%4==1{$0=$0" barcode=barcode" barcode}1' "$file" > \
        "${out_directory}/${basename_temp}_labeled.fastq"
    done
}

## call barcode labeller function
## remember to add / at the end of the directory
label_barcode_fastq_files "data/balbina/BalbinaRun02_YawanawaRun01_sup_demux/" "data/balbina/BalbinaRun02_YawanawaRun01_sup_demux_labelled/"
label_barcode_fastq_files "data/balbina/BalbinaRun03_sup_demux/" "data/balbina/BalbinaRun03_sup_demux_labelled/"

# cat into one fastq
cat data/balbina/BalbinaRun02_YawanawaRun01_sup_demux_labelled/*.fastq > \
data/balbina/BalbinaRun02_YawanawaRun01_sup_demux.fastq

cat data/balbina/BalbinaRun03_sup_demux_labelled/*.fastq > \
data/balbina/BalbinaRun03_sup_demux.fastq

head data/balbina/BalbinaRun02_YawanawaRun01_sup_demux.fastq
tail data/balbina/BalbinaRun02_YawanawaRun01_sup_demux.fastq

head data/balbina/BalbinaRun03_sup_demux.fastq
tail data/balbina/BalbinaRun03_sup_demux.fastq

# .gz fastq file for transfering
gzip -c data/balbina/BalbinaRun02_YawanawaRun01_sup_demux.fastq > \
data/balbina/BalbinaRun02_YawanawaRun01_sup_demux.fastq.gz

gzip -c data/balbina/BalbinaRun03_sup_demux.fastq > \
data/balbina/BalbinaRun03_sup_demux.fastq.gz




# # use sam tools to convert to fastq format with attributes: https://www.htslib.org/doc/samtools-fasta.html

# ## get samtools image
# singularity build images/samtools.sif docker://staphb/samtools:1.21


# ## run samtools
# singularity exec images/samtools.sif \
# samtools fastq -T '*' \
# data/balbina/BalbinaRun02_YawanawaRun01_sup_demux_bam/cf82efaef04669b6f13ba6e2539feacf8932eec2_EXP-PBC096_barcode95.bam > \
# data/balbina/test.fastq

# head data/balbina/BalbinaRun02_YawanawaRun01_sup.fastq
# tail data/balbina/BalbinaRun02_YawanawaRun01_sup.fastq



