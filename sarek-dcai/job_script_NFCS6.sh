#!/bin/bash
#SBATCH --job-name=sarek_bwa_cpucluster
#SBATCH --output=sarek_bwa_cpucluster_%j.out
#SBATCH --error=sarek_bwa_cpucluster_%j.err
#SBATCH --account=ACCOUNT_NAME
#SBATCH --partition=QUEUE_NAME
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gpus=0
#SBATCH --mem=8G
#SBATCH --time=12:00:00
#SBATCH --container-mounts=/path/to/project:/path/to/project

cd /path/to/project/runs2/sarek_bwa_cpucluster || exit 1

ml load Nextflow/25.10.2

export NXF_OFFLINE=true

nextflow run -config /path/to/project/config/cpu.config /path/to/project/src/sarek -offline \
   --input /path/to/project/data/project2_samplesheet.csv \
   --seq_platform Illumina \
   --fasta /path/to/project/data/references/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set_maskedGRC_exclusions.fasta \
   --fasta_fai /path/to/project/data/references/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set_maskedGRC_exclusions.fasta.fai \
   --aligner bwa-mem2 \
   --bwa /path/to/project/data/references/GRCh38/BWAIndex/ \
   --bwamem2 /path/to/project/data/references/GRCh38/BWAmem2Index/ \
   --tools deepvariant,haplotypecaller,strelka,cnvkit \
   --skip_tools baserecalibrator \
   --genome false \
   --igenomes_ignore true \
   --igenomes_base false \
   --snpeff_cache '.' \
   --vep_cache '.'\
   --outdir /path/to/project/runs2/sarek_bwa_cpucluster/results
