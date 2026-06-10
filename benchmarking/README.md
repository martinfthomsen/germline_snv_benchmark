# Benchmarking

To run the benchmark we renamed all VCFs to respect the following name format:

- `<CONFIGURATIONNAME>_<SAMPLENAME>_<CALLER>.vcf.gz`
- `<CONFIGURATIONNAME>_<SAMPLENAME>_<CALLER>.vcf.gz.tbi`

where:

- `<CONFIGURATIONNAME>` is the name/code of the configuration used to generate the VCF (pipeline version, HPC environment, etc). Example: `MDX1-NGC`.

- `<SAMPLENAME>` is one of the individual sample names (NA12877, NA12878, NA12879, NA12881, NA12882, NA12885, or NA12886).

- `<CALLER>` is the name/code of the caller used to generate the file. Example: `HC` (for HaplotypeCaller).

We used the [nf-core_variantbenchmarking](https://nf-co.re/variantbenchmarking) version `1.3.0`.

The workflow consists in 3 steps:

1. [Generate the sample sheeet](#generation-of-the-sample-sheet) for a given family member

2. [Generate the configuration files](#generation-of-the-configuration)

3. [Launch the pipeline](#launch-the-pipeline)

## Generation of the sample sheet

The script [create_sample_sheets.py](./create_sample_sheets.py) can be used to create the sample sheet files that are necessary for the benchmarking pipeline.

```bash
# Script usage:
python create_sample_sheets.py <INPUTDIR> <OUTPUTDIR> <SAMPLENAME>
# where:
# - <INPUTDIR> is the directory that contains all VCFs results for the sample <SAMPLENAME> following the naming format described above
# - <OUTPUTDIR> is the directory where the sample sheet <SAMPLENAME>.csv will be written
# - <SAMPLENAME> is the name of the desired sample name (NA12877, NA12878, NA12879, NA12881, NA12882, NA12885, or NA12886)
```

You must call this script for each one of the family members that you want to benchmark.

## Generation of the configuration

Before launching the benchmark pipeline, you must create a configuration file that setup its behavior. 

The script [create_config.py](./create_config.py) creates all necessary configuration files for all combinations: samples, truthset VCFs (Full and NoPrivate) and bed files.

```bash
# Script usage
python create_config.py <BED_FILE_PATH> <TS_FILE_PATH> <TS_FILE_PATH_NOPRIV> <SS_DIR> <FASTA> <BASE_OUT_DIR> <CFG_DIR> 
# where:
# - <BED_FILE_PATH> is the directory where we have the 3 bed files (see truthset-preprocessing)
# - <TS_FILE_PATH> is the directory where we have the full truthset for each sample (see truthset-preprocessing)
# - <TS_FILE_PATH_NOPRIV> is the directory where we have the truthset without private calls for each sample (see truthset-preprocessing)
# - <SS_DIR> is the directory where the sample sheets can be found (see Generation of the sample sheet)
# - <FASTA> is the path for the reference genome FASTA file (note, we expect that the FAI file is together with it)
# - <BASE_OUT_DIR> is the path for the directory that will receive the benchmark pipeline results
# - <CFG_DIR> is the directory where the configuration files will be stored
```

Notes:

- The script expect to find the 3 following bed files inside of the directory `<BED_FILE_PATH>` (as generated in the thruset-preprocessing step):
  - `encode_blacklist_v2.chr1-22andX.sorted.bed.gz`
  - `ucsc_unusual_regions.chr1-22andX.sorted.bed.gz`
  - `hq_regions_final.chr1-22andX.sorted.bed.gz`

- The script expect to find VCF files with the following name formats in the directories `<TS_FILE_PATH>` and `<TS_FILE_PATH_NOPRIV>` (as generated in the thruset-preprocessing step) for each one of the family members:
  - `<SAMPLE>_encode_blacklist_v2.vcf.gz` (and its tbi index)
  - `<SAMPLE>_ucsc_unusual_regions.vcf.gz` (and its tbi index)
  - `<SAMPLE>.vcf.gz` (and its tbi index)

- The script expects that the fai index file is together with the give `<FASTA>` file

- The script will generate configuration files wit the following name pattern `<SAMPLE>_<BED>_<TSTYPE>.config` where:
  - `<SAMPLE>` is one of the family member names (NA12877, NA12878, NA12879, NA12881, NA12882, NA12885, or NA12886)
  - `<BED>` is one of the following:
    - `BL` for Encode Blacklist
    - `UR` for UCSC unusual regions
    - `HQ` for High quality regions
  - `<TSTYPE>` is the type of truthset:
    - `Full-TS` for the truthset with all variants
    - `NoPrivTS` for the truthset without private variants (deep variant and dragen)

- The script will pre-create the directories for the pipeline execution inside of the directory `<BASE_OUT_DIR>` followin the structure `<BASE_OUT_DIR>/<SAMPLE>/<TSTYPE>/<BED>` where the values `<SAMPLE>`, `<TSTYPE>` and `<BED>` are the same as in the configuration file name pattern.

## Launch the pipeline

To launch the benchmark pipeline, you must call it for each of the configuration files that you generated in the previous step.

Below, an template for the pipeline execution for a given configuration file.

```bash
# Setting up your nextflow environment
# NXF_PLUGINS_DIR is the directory where you have the nextflow plugins
rsync -a ${NXF_PLUGINS_DIR} ${HOME}/.nextflow

# We are assuming that nextflow is in the PATH
nextflow run <NFCORE_VARIANTBENCHMARK_PATH> -resume -c <YOUR_OWN_ENV_CONFIG> -c <CONFIG_FILE>
# where:
# - <NFCORE_VARIANTBENCHMARK_PATH> this is the location where you installed the nf-core_variantbenchmarking pipeline
# - <YOUR_OWN_ENV_CONFIG> this is the file that configures your enviroment (if needed).
#   - you can configure things like, resourceLimits, process executor, define outdir name, etc.
# - <CONFIG_FILE> this is the configuration file generated in the previous step.
```

# Keeping only PASS variants

To ensure that all your VCFs contains only `PASS` variants before running the nf-core_variantbenchmarking pipeline, you can pre-process them with these commands:

```bash
# Assuming bcftools in the PATH
mkdir -p <ONLY_PASS_DIR>
for i in <ALL_VARIANTS_DIR>/*.gz; do
    vcf=$(basename $i)
    bcftools view -f PASS,. -O z --write-index -o <ONLY_PASS_DIR>/${vcf} ${i}
done
# where:
# - ALL_VARIANTS_DIR is the directory where you have all unfiltered VCFs
# - ONLY_PASS_DIR is the directory where you will store the only PASS variants VCFs.
```

# Keeping only variants that are smaller than 50bp

You might also consider to discard from this analyses the variants that are longer than 50bp. To do this, you must run these commands:

```bash
# Assuming bcftools in the PATH
mkdir -p <SMALL_SIZES_DIR>
for i in <ALL_SIZES_DIR>/*.gz; do
    vcf=$(basename $i)
    bcftools view -i '(ILEN > -51 && ILEN < 51 || type="snp")' -O z --write-index -o <SMALL_SIZES_DIR>/${vcf} ${i}
done
# where:
# - ALL_SIZES_DIR is the directory where you have all VCFs whose variants were not filtered by size
# - SMALL_SIZES_DIR is the directory where you will store the VCFs containing variants smaller than 50bp
```
