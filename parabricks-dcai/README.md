# Parabricks variant calling (DCAI)

This repository contains examples of the workflows, and configuration files used to evaluate NVIDIA Parabricks on NVIDIA 
DGX H100 systems running on DCAI infrastructure.

We evaluated the GPU-accelerated implementations developed by NVIDIA Clara Parabricks
(NVIDIA Corporation) [40], focusing on the Parabricks fq2bam, HaplotypeCaller, and DeepVari-
ant workflows. Within Parabricks, fq2bam constitutes an optimized, end-to-end preprocessing
pipeline from FASTQ to analysis-ready BAM, integrating alignment, sorting, duplicate marking,
and BQSR in a single GPU-enabled workflow with minimized intermediate I/O. The Parabricks
implementations of HaplotypeCaller and DeepVariant are designed to be algorithmically equiv-
alent to their canonical CPU versions, while offloading computationally intensive components to
GPUs through CUDA-based parallelization.

The NVIDIA Clara Parabricks workflows were executed on Gefion, a large-scale NVIDIA
H100 GPU cluster located in Denmark. We used the official Parabricks container image (v4.6.0-1)
obtained from the NVIDIA NGC registry.

Each Gefion compute node is equipped with eight NVIDIA H100 GPUs. For benchmarking,
fq2bam was allocated four GPUs, DeepVariant four GPUs, and HaplotypeCaller two GPUs,
reflecting their differing computational profiles and enabling concurrent GPU utilization within
a single node. All jobs were submitted to the Slurm workload manager as individual batch jobs,
with DeepVariant and HaplotypeCaller configured to start after completing fq2bam.

The pipeline was executed under two configurations: PB1, a direct mode without exter-
nal known-sites resources or base quality score recalibration, and PB2, a recalibrated mode in
which known variant resources were supplied via –knownSites, enabling BQSR during fq2bam
preprocessing and subsequent use of recalibrated data by HaplotypeCaller.


## Data
All short-read samples analysed in the benchmark are available from the Platinum Pedigree: Illumina Mapped Data (GRCh38)

The samples used were:
```
NA12877 NA12878 NA12879 NA12881 NA12882 NA12885 NA12886
```

The reference genome we use on clinical samples is a masked version of GRCh38:
GCA_000001405.15_GRCh38_no_alt_analysis_set_maskedGRC_exclusions.fasta


## Experiment/Workflow Design
The DCAI DGX nodes are available through a Slurm cluster. So to run the jobs a jobs script was created and submitted.

The small GPU scale test showed the most optimal resource allocation for each tool. So rather than taking up a full 
node and waste resources, the job script were configured to use the optimal resources.

As the pipeline needed to run both DeepVariant and HaplotypeCaller, the more optimal approach to run using the predefined 
parabricks end-to-end workflows were not an option. To gain an optimal performance, all the tools were executed with 
individual job scripts, and DeepVariant and HaplotypeCaller was configured to wait for FQ2BAM to complete before running.

Parabricks are not installed natively on the DGX nodes so to access the programs, the scripts would need to run inside a 
container with the programs preinstalled. For that, at the point this benchmark was performed we used the newest version
of the container which is available from NVIDIA [https://catalog.ngc.nvidia.com/orgs/nvidia/teams/clara/containers/clara-parabricks?version=4.6.0-1].
The container was squashed to an image format supported by Pyxis:
nvidia+clara+clara-parabricks+4.6.0-1.sqsh

Data is stored on the network drive, along with the output files. No effort was made to move or store anything on temporary storage.

A run directory was created per sample for the job script, logs and all output files.

The whole project directory was mounted inside the running container using the full path to simplify file paths.

Each job script was submitted through sbatch.

The programs were executed from the dedicated run directories inside the container.

The assessment of runtime is extracted from Slurm through sacctc.
