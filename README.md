# Germline SNV Benchmark

This project holds scripts used for pre-processing and benchmarking in the study "Benchmarking open source and commercial germline SNV variant calling pipelines across multiple computational infrastrucures".

## Project content

### Folder thruthset-preprocessing

Here you will find the description and associated code for the thruthset [preprocesing](./thruthset-preprocessing/).

### Folder benchmarking

Here you will find the description and associated code for the SNV variant calling [benchmarking](./benchmarking/).

### Variant calling configurations

These folders hold the per-caller/per-infrastructure scripts used to generate the VCFs that are benchmarked:

- [sentieon-ngc](./sentieon-ngc/) — Sentieon DNAscope (via `sentieon-cli`) on the NGC infrastructure.
- [sarek-ngc](./sarek-ngc/) — nf-core/sarek (Sentieon and GATK tool configurations) on the NGC infrastructure.

