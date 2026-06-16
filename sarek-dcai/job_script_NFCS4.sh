#!/bin/bash
#SBATCH --job-name=sarek_bwa_gpucluster4
#SBATCH --output=sarek_bwa_gpucluster4_%j.out
#SBATCH --error=sarek_bwa_gpucluster4_%j.err
#SBATCH --account=ACCOUNT_NAME
#SBATCH --partition=QUEUE_NAME
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gpus=0
#SBATCH --mem=8G
#SBATCH --time=12:00:00

cd /path/to/project/runs2/sarek_bwa_gpucluster4 || exit 1

ml load Nextflow/25.10.2

export NXF_OFFLINE=true

nextflow run -config /path/to/project/config/gpu.config /path/to/project/src/sarek -offline \
   --input /path/to/project/data/project2_samplesheet.csv \
   --seq_platform Illumina \
   --fasta /path/to/project/data/references/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set_maskedGRC_exclusions.fasta \
   --fasta_fai /path/to/project/data/references/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set_maskedGRC_exclusions.fasta.fai \
   --aligner bwa-mem2 \
   --bwa /path/to/project/data/references/GRCh38/BWAIndex/ \
   --bwamem2 /path/to/project/data/references/GRCh38/BWAmem2Index/ \
   --tools deepvariant,haplotypecaller,strelka,cnvkit \
   --skip_tools baserecalibrator \
   --dbsnp /path/to/project/data/GATKBundle/Homo_sapiens_assembly38.dbsnp138.vcf.gz \
   --dbsnp_tbi /path/to/project/data/GATKBundle/Homo_sapiens_assembly38.dbsnp138.vcf.gz.tbi \
   --dbsnp_vqsr '--resource:dbsnp,known=false,training=true,truth=false,prior=2.0 Homo_sapiens_assembly38.dbsnp138.vcf.gz' \
   --known_indels /path/to/project/data/GATKBundle/{Mills_and_1000G_gold_standard.indels.hg38,Homo_sapiens_assembly38.known_indels}.vcf.gz \
   --known_indels_tbi /path/to/project/data/GATKBundle/{Mills_and_1000G_gold_standard.indels.hg38,Homo_sapiens_assembly38.known_indels}.vcf.gz.tbi \
   --known_indels_vqsr '--resource:gatk,known=false,training=true,truth=true,prior=10.0 Homo_sapiens_assembly38.known_indels.vcf.gz --resource:mills,known=false,training=true,truth=true,prior=10.0 Mills_and_1000G_gold_standard.indels.hg38.vcf.gz' \
   --known_snps /path/to/project/data/GATKBundle/1000G_phase1.snps.high_confidence.hg38.vcf.gz \
   --known_snps_tbi /path/to/project/data/GATKBundle/1000G_phase1.snps.high_confidence.hg38.vcf.gz.tbi \
   --known_snps_vqsr '--resource:1000G,known=false,training=true,truth=true,prior=10.0 1000G_phase1.snps.high_confidence.hg38.vcf.gz' \
   --nucleotides_per_second 200000 \
   --normalize_vcfs \
   --snv_consensus_calling \
   --consensus_min_count 3 \
   --trim_fastq \
   --genome false \
   --igenomes_ignore true \
   --igenomes_base false \
   --snpeff_cache '.' \
   --vep_cache '.'\
   --outdir /path/to/project/runs2/sarek_bwa_gpucluster4/results
