# Sentieon variant calling (NGC)

This folder holds the variant-calling configuration used to generate the Sentieon VCFs on the **NGC** computational infrastructure. It is one of the pipeline/infrastructure configurations whose output is later benchmarked (see [benchmarking](../benchmarking/)).

## What it does

The script [go.sh](./go.sh) is a PBS array job that runs Sentieon's [`sentieon-cli dnascope`](https://github.com/Sentieon/sentieon-cli) end-to-end (alignment → duplicate marking → variant calling) on the 7 CEPH1463 family members:

```
NA12877 NA12878 NA12879 NA12881 NA12882 NA12885 NA12886
```

The array (`#PBS -t 0-6`) maps each index to one entry of the `R1_FILES` list; the matching `_R2` FASTQ is derived by name. Each sample is processed independently on a 190-core / 2000 GB node.

Key parameters baked into the DNAscope call:

- Model: `DNAscopeMGIWGS2.1.bundle` (MGI WGS)
- `--assay WGS --pcr_free`
- `--collate_align` and `--duplicate_marking markdup`
- Calling regions: GATK `wgs_calling_regions.hg38.bed`
- Known sites: `dbsnp_138.hg38.vcf.gz`
- Reference: `Homo_sapiens_assembly38.fasta` (requires `.fai` **and** a BWA index — the script accepts either the `.amb/.ann/.bwt/.pac/.sa` or the `.64.*` set)

## Runtime behaviour

- **Scratch-first**: FASTQs are copied to `/scratch/${PBS_JOBID}/...`, the whole run happens there, and an `EXIT` trap `rsync`s results, logs, and timing back to `OUT_ROOT`. On success scratch is removed; on failure it is kept for debugging.
- **Read group** is built from the first FASTQ header (`@RG` with `ID=<flowcell>.<lane>.<sample>`, `SM=<sample>`, and `CN` set from `SEQ_CENTER`); falls back to `FCUNKNOWN`/lane `1` if the header can't be parsed.
- Wraps the call in `/usr/bin/time -v` (→ `*.time.txt`) and writes a `sha256sum` of the output VCF.

## Output and the link to benchmarking

Each task writes `${RUN_BASENAME}.vcf.gz` where `RUN_BASENAME` is the FASTQ name minus `_R1.fastq.gz` (e.g. `NA12877_2209.v4.2.4.grc38.vcf.gz`).

> **Note:** this name does **not** match the `<CONFIGURATIONNAME>_<SAMPLENAME>_<CALLER>.vcf.gz` format the benchmarking stage expects (see [benchmarking/README.md](../benchmarking/README.md)). Before feeding these VCFs to `create_sample_sheets.py`, rename them to that 3-field convention, e.g. `NGC-Sentieon_NA12877_DNAscope.vcf.gz` (and its `.tbi`).

## Adapting to your environment

All software is loaded as [EasyBuild](https://easybuild.io/) modules — the `ml` lines carry the toolchain suffixes (e.g. `-GCCcore-13.3.0`, `-GCC-13.3.0`, `-foss-2024a`) that identify the exact public EasyConfigs, so the same stack can be rebuilt elsewhere with EasyBuild rather than relying on NGC's module tree.

The script was written for an HPC with a PBS scheduler and environment modules (`ml`). All site-specific values are `<...>` placeholders that you must replace before running:

- The `#PBS` directives (notably `-A <PBS_ACCOUNT>`) and `ml` module loads for your scheduler/module system.
- `SENTIEON_LICENSE` (`<SENTIEON_LICENSE_SERVER>`, given as `host:port` or a license-file path).
- The values under **User-configurable paths** (`FASTQ_ROOT`, `OUT_ROOT`, `MODEL`, `REF`, `BED`, `DBSNP`, `SEQ_CENTER`) and the `R1_FILES` list to point at your FASTQs.
- `SCRATCH_BASE` (`/scratch/...`) to a fast local scratch path available on your nodes.
