#!/bin/bash
#SBATCH --job-name=NA128XX-fq2bam-RUN_NAME
#SBATCH --output=NA128XX-fq2bam_%j.out
#SBATCH --error=NA128XX-fq2bam_%j.err
#SBATCH --account=ACCOUNT_NAME
#SBATCH --partition=QUEUE_NAME
#SBATCH --nodes=1
#SBATCH --ntasks=112
#SBATCH --gpus=4
#SBATCH --mem=1000G
#SBATCH --time=2:00:00
#SBATCH --container-image=/path/to/project/img/nvidia+clara+clara-parabricks+4.6.0-1.sqsh
#SBATCH --container-mounts=/path/to/project:/path/to/project
cd /path/to/project/run_directory/NA128XX
pbrun fq2bam \
    --num-gpus 4 \
    --in-fq /path/to/project/data/fastqs/2XXX.v4.2.4.grc38_R1_nsorted.fastq.gz /path/to/project/data/fastqs/2XXX.v4.2.4.grc38_R2_nsorted.fastq.gz \
    --read-group-id RG1 \
    --read-group-sm NA128XX \
    --read-group-pl ILLUMINA \
    --ref /path/to/project/data/references/GRCh38/BWAIndex/GCA_000001405.15_GRCh38_no_alt_analysis_set_maskedGRC_exclusions.fasta \
    --out-bam NA128XX_2XXX.v4.2.4.grc38.pb.fq2bam.bam
