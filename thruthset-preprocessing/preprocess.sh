#!/usr/bin/env bash

set -euo pipefail

# This script was designed to be run under the HGC HPC environment
# - We purge all modules and load only bcftools (version 1.18, in this case)
# - If you don't use modules, ensure to have bcftools, bgzip and tabix in your PATH
module purge
module load BCFtools/1.18-GCC-12.3.0

# Define the path for your CEPH1463.GRCh38.family-truthset.ov.vcf.gz file
# Example: 
# TS_VCF="./CEPH1463.GRCh38.family-truthset.ov.vcf.gz"
TS_VCF="<TRUTHSET_VCF_PATH>"

# Define the path for your output directory
# Example: 
# OUTPUT_DIR="./"
OUTPUT_DIR="<OUTPUT_DIR_PATH>"

# Define the path for your BED files
# Example:
# IN_BED_1="./hq_regions_final.bed.gz"
# IN_BED_2="./encode_blacklist_v2.bed.gz"
# IN_BED_3="./ucsc_unusual_regions.bed.gz"
IN_BED_1="<HQ_BED_FILE_PATH>"
IN_BED_2="<BLACKLIST_BED_FILE_PATH>"
IN_BED_3="<UNUSUAL_REGIONS_BED_FILE_PATH>"

# Define the path for the Reference Genome
# Example:
# FASTA="./Homo_sapiens_assembly38.fasta"
FASTA="<HG38_REF_GENOME_FASTA_PATH>"

# Path of the directory where cleaned bed files will be stored
PREPROCESSED_BEDS="${OUTPUT_DIR}/preprocessed_bed_files"

# Path for the directory where the individual truthset VCFs will be generated
INDIVIDUAL_TSS="${OUTPUT_DIR}/individual_thrusets"

# Path for the directory where the individual truthset (without variants private to deep variant or dragen) VCFs will be generated
INDIVIDUAL_TSS_NOPRIV="${OUTPUT_DIR}/individual_thrusets_noprivate"

# Create the directories
mkdir -p "${PREPROCESSED_BEDS}" "${INDIVIDUAL_TSS}" "${INDIVIDUAL_TSS_NOPRIV}"

# List of NA samples
SAMPLES=(NA12877 NA12878 NA12879 NA12881 NA12882 NA12885 NA12886)

# Step 1 - BED file cleaning: 
# We keep chr1-22 only. Then we run sort, bgzip, tabix
for bed in ${IN_BED_1} ${IN_BED_2} ${IN_BED_3}; do
    echo "Processing ${bed}"
    name=$(basename ${bed} | cut -f1 -d .)
    zcat "${bed}" \
        | awk 'BEGIN{OFS="\t"} $1 ~ /^chr([1-9]|1[0-9]|2[0-2]|X)$/ {print $1,$2,$3}' \
        | sort -k1,1V -k2,2n -k3,3n \
        | bgzip -c > "${PREPROCESSED_BEDS}/${name}.chr1-22andX.sorted.bed.gz"
    tabix -f -p bed "${PREPROCESSED_BEDS}/${name}.chr1-22andX.sorted.bed.gz"
done

# Step 2 - Split + normalize each sample truth from family VCF
for s in "${SAMPLES[@]}"; do

    echo "Processing ${s}..."

    # keep sample + chr1-22 only
    bcftools view \
             -s "${s}" \
             -r chr1,chr2,chr3,chr4,chr5,chr6,chr7,chr8,chr9,chr10,chr11,chr12,chr13,chr14,chr15,chr16,chr17,chr18,chr19,chr20,chr21,chr22,chrX \
             -Ou "${TS_VCF}" \
        | bcftools norm -m -any -f "${FASTA}" -Oz \
        | bcftools sort -Ou \
        | bcftools +fill-tags -Ou -- -t AC,AN \
        | bcftools view -i 'ALT!="*" && FILTER="PASS"' -Ou \
        | bcftools view -e 'GT="0|0"' -Oz -o "${INDIVIDUAL_TSS}/${s}.vcf.gz"
    tabix -f -p vcf "${INDIVIDUAL_TSS}/${s}.vcf.gz"

    zgrep -v "SOURCES=dragen-ilmn;" "${INDIVIDUAL_TSS}/${s}.vcf.gz" | grep -v "SOURCES=dv-hifi;" | bgzip -c > "${INDIVIDUAL_TSS_NOPRIV}/${s}.vcf.gz"
    tabix -f -p vcf "${INDIVIDUAL_TSS_NOPRIV}/${s}.vcf.gz"

done

# Step 3 -  subset with the hard to call BED files
for v in $(ls -1 ${INDIVIDUAL_TSS}/NA?????.vcf.gz ${INDIVIDUAL_TSS_NOPRIV}/NA?????.vcf.gz); do
    echo "Processing ${v}"
    dir=$(dirname $v)
    name=$(basename ${v} | cut -f1 -d .)
    for b in "encode_blacklist_v2" "ucsc_unusual_regions"; do
        bcftools view -R ${PREPROCESSED_BEDS}/${b}.chr1-22andX.sorted.bed.gz -O z -o "${dir}/${name}_${b}.vcf.gz" "${v}"
        tabix -p vcf "${dir}/${name}_${b}.vcf.gz"
    done
done

echo "Done"
