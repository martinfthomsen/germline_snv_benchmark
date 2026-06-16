#!/bin/bash
#SBATCH --job-name=NA128XX-haplotypecaller-RUN_NAME
#SBATCH --output=NA128XX-haplotypecaller_%j.out
#SBATCH --error=NA128XX-haplotypecaller_%j.err
#SBATCH --account=ACCOUNT_NAME
#SBATCH --partition=QUEUE_NAME
#SBATCH --nodes=1
#SBATCH --ntasks=56
#SBATCH --gpus=2
#SBATCH --mem=500G
#SBATCH --time=2:00:00
#SBATCH --dependency=afterany:205815
#SBATCH --container-image=/path/to/project/img/nvidia+clara+clara-parabricks+4.6.0-1.sqsh
#SBATCH --container-mounts=/path/to/project:/path/to/project
cd /path/to/project/run_directory/NA128XX
pbrun haplotypecaller \
    --num-gpus 2 \
    --in-bam NA128XX_2XXX.v4.2.4.grc38.pb.fq2bam.bam \
    --ref /path/to/project/data/references/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set_maskedGRC_exclusions.fasta \
    --out-variants NA128XX_2XXX.v4.2.4.grc38.pb.haplotypecaller.vcf
