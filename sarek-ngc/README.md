# Sarek variant calling (NGC)

This folder holds the [nf-core/sarek](https://nf-co.re/sarek) `3.7.1` variant-calling configurations run on the **NGC** computational infrastructure. Their output VCFs are later benchmarked (see [benchmarking](../benchmarking/)).

Two calling configurations were run from the same input:

| Script | Aligner | Caller(s) | `--outdir` |
|---|---|---|---|
| [go_only_sentieon.sh](./go_only_sentieon.sh) | `sentieon-bwamem` | `sentieon_dedup`, `sentieon_haplotyper` | `results_final_sentieon_only_no_consensus2` |
| [go_only_gatk.sh](./go_only_gatk.sh) | `bwa-mem` | `haplotypecaller` | `results_final_gatk_only_bwa` |

Both run all 7 CEPH1463 samples in one go via [samplesheet.csv](./samplesheet.csv) (one row per `patient`/`sample`, `lane=1`, R1/R2 FASTQ paths, and `sex` as `XX`/`XY`). The FASTQ paths there use a `<FASTQ_DIR>` placeholder — point it at your own FASTQ directory before running.

## Shared settings

- `-profile singularity` plus a site config `-c <SAREK_HPC_CONFIG>` (replace with your own nf-core/sarek HPC config)
- `--trim_fastq`
- `--process.scratch /dev/shm` (run process work in RAM-backed scratch)
- `--skip_tools baserecalibrator,...` — BQSR is skipped, and each run also skips its caller's variant filtering (`haplotyper_filter` / `haplotypecaller_filter`), so the emitted VCFs are **unfiltered**.

## Per-config differences

- **Sentieon path**: `--split_fastq 200000000` (parallelise across FASTQ chunks) and `--nucleotides_per_second 300000`.
- **GATK path**: no FASTQ splitting and `--nucleotides_per_second 100000` (controls interval scatter sizing).

## Output and the link to benchmarking

Sarek writes VCFs under `<outdir>/variant_calling/<caller>/<sample>/`. Because `--skip_tools` disables the filter steps, these VCFs are unfiltered — see the **"Keeping only PASS variants"** and **"variants smaller than 50bp"** sections of [benchmarking/README.md](../benchmarking/README.md) for the pre-processing to apply.

Before feeding them to `create_sample_sheets.py`, rename to the benchmarking convention `<CONFIGURATIONNAME>_<SAMPLENAME>_<CALLER>.vcf.gz` (e.g. `NGC-Sarek-Sentieon_NA12877_Haplotyper.vcf.gz`, `NGC-Sarek-GATK_NA12877_HC.vcf.gz`).

## Adapting to your environment

At NGC the tooling (Nextflow, nf-core/sarek, Singularity) is provided as [EasyBuild](https://easybuild.io/) modules, whose public EasyConfigs let the same stack be rebuilt elsewhere. The scripts assume `sarek` (nf-core/sarek `3.7.1`) is on `PATH` and that Singularity is available. Replace the `<SAREK_HPC_CONFIG>` placeholder with your own nf-core/sarek HPC config, adjust the profile/scratch path, and replace the `<FASTQ_DIR>` placeholder in `samplesheet.csv`.
