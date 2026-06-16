# Sarek variant calling (DCAI)
This repository contains examples of the workflows, and configuration files used to evaluate NF-CORE 
Sarek Pipeline running on DCAI infrastructure.

The nf-core is a community-driven effort to build a curated set of analysis pipelines using
Nextflow as workflow manager [27]. Among these pipelines, the sarek pipeline is designed for
variant calling in whole genome or targeted sequencing data [41, 42].
This workflow supports execution across diverse compute environments and employs container
technology, such as Docker and Singularity, which simplify installation and ensure reproducibility.
The workflow provides a diverse set of configuration possibilities for both alignment and vari-
ant calling steps. For the alignment task, we considered the following tools: bwa-mem, bwa-mem2, 
or Parabricks fq2bam. For the variant calling step, we considered the following tools: 
**HC** = GATK HaplotypeCaller, **DV** = DeepVariant, and **ST** = Strelka2.
OBS: CNVKit was also run, but it was decided not to include this in the benchmark.

For this study, we tested seven distinct configurations (NFCS1 to NFCS7) on DCAI infrastructure:
1. **NFCS1**: nf-core/sarek(v3.7.0) was downloaded and configured for execution in a gpu-cluster
   (Gefion HPC - GeP). Out-of-box configuration for alignment and variant calling. No performance
   optimisation, interval BED files, or resources files were provided to the pipeline. Base quality
   score recalibration was disabled. Alignment was performed with bwa-mem2 and the following
   variant callers were activated: HC, DV, and ST.
3. **NFCS2**: Configuration similar to NFCS1 but resources files were provided and base quality
   score recalibration was enabled. BSQR configurations was based on the default provided by the
   Pipeline through their igenomes configuration.
4. **NFCS3**: Configuration similar to NFCS2 but the aligner was set to bwa-mem.
5. **NFCS4**: Configuration similar to NFCS2 but with some suggested adjustments for performance
   optimisation: nucleotides_per_second were set to 200000, which should affect the internal
   algorithm for defining intervals. trim_fastq was set, normalize_vcfs was set, snv_consensus_calling
   was set and consensus_min_count was set to 3.
6. **NFCS5**: Configuration similar to NFCS2 but the aligner was set to Parabricks fq2bam.
7. **NFCS6**: Configuration similar to NFCS1 but configured for execution in a cpu-cluster.
8. **NFCS7**: Configuration similar to NFCS2 but configured for execution in a cpu-cluster.


## Data
All short-read samples analysed in the benchmark are available from the Platinum Pedigree: Illumina Mapped Data (GRCh38)

The samples used were:
```
NA12877 NA12878 NA12879 NA12881 NA12882 NA12885 NA12886
```

The reference genome we use on clinical samples is a masked version of GRCh38:
GCA_000001405.15_GRCh38_no_alt_analysis_set_maskedGRC_exclusions.fasta

As Sarek need a specific sample sheet pointing to the files, this was created. The samplesheet has 7 entries, one for
each sample. Each entry lists: Patient ID, Sample ID, Lane ID, path to fastq file 1, path to fastq file 2.


## Configuration
To run nextflow pipelines, a user must first configure their environment. As the pipeline ran in an offline environment
on the DCAI infrastructure it was critical that the tool was configured to run in offline mode. This meant that a lot 
of container links had to be manually overwritten to point to the local location.

As Nextflow does not support Pyxis, we had to use the apptainer. The Nextflow implementation of Apptainer went for an 
approach that wipes the whole environment, which then breaks the environment dependencies used by the Sarek pipeline, 
such as calls programs that does not use the full path the program location. To resolve this, manuel environment 
overrides had to be implemented.
The parameters for Apptainer was also specified in the config file.

Some processes also experienced resource deficiency challenges. To get around this, the resource specification for 
these processes were manually configured


## Download Containers
As the pipeline ran in an offline environment on the DCAI infrastructure it was critical that all the needed resources 
for the Sarek pipeline was downloaded and available beforehand. This is one of the more challenging aspects of Running 
Nextflow pipelines in offline environments. The tool is by default setup to try and fetch everything from the internet.
As it is not possible to do so directly, and nextflow does not support the use of enroot and squashing, all the contains,
around 54, had to be manually downloaded and squashed. These were all stored in a separate directory for images.
A few of the images contained errors/bug that meant they could not run on the DCAI infrastructure. Alternative containers
running the same software versions for these were identified, downloaded and used in the pipeline.


## Experiment/Workflow Design
The DCAI DGX nodes are available through a Slurm cluster. So to run the jobs a job script was created and submitted for 
each of the 7 listed pipelines.

The pipeline calls do not really use any resources, as it is primarily a wrapper for the actual calls. As such, the jobs was 
scheduled for only a single CPU and 8 GB RAM, and enough wall time to outlive the whole process.

The pipeline is executed from the dedicated run directory.

Nextflow is installed natively through an environment module on DCAI, so the script loads Nextflow/25.10.2 before running nextflow.

As the pipeline ran in an offline environment on the DCAI infrastructure it was important to tell Nextflow to run in offline mode. 
This was done by setting NXF_OFFLINE=true.

Each job runs the nextflow pipeline which is configured to submit its subjobs to the same slurm cluster.

The input to the pipeline is the forementioned samplesheet, and file path to the reference file and other resources.
Additionally, the pipeline needs to know what tools to run. here we selected deepvariant,haplotypecaller,strelka and cnvkit.

As we do not want to use the built in igenomes references, these were switched off and ignored. All necessary references were 
provided manually pointing to the locally stored resources.

Data is stored on the network drive, along with the output files. No effort was made to move or store anything on temporary storage.

A run directory was created per sample for the job script, logs and all output files.

Each job script was submitted through sbatch.

The assessment of runtime is extracted from Slurm through sacctc.
