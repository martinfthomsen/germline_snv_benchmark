# Truthset preprocessing

## Data download

### Family truthset

Following instructions from the [Platinum Pedigree Datasets repository](https://github.com/Platinum-Pedigree-Consortium/Platinum-Pedigree-Datasets), we obtained the following files:

- `variants/small_variant_truthset/GRCh38/CEPH1463.GRCh38.family-truthset.ov.vcf.gz`
- `variants/small_variant_truthset/GRCh38/CEPH1463.GRCh38.family-truthset.ov.vcf.gz.tbi`
- `variants/small_variant_truthset/GRCh38/hq_regions_final.bed.gz`

### Additional bed files

Using the [UCSC Table Browser](https://genome.ucsc.edu/cgi-bin/hgTables), we obtained the following bed files:

- `encode_blacklist_v2.bed`
  - *Genome*: `Human (hg38)`
  - *Group*: `Mapping and Sequencing`
  - *Track*: `Problematic Regions`
  - *Table*: `ENCODE Blacklist V2 (encBlacklist)`
  - *Region*: `Genome`
  - *Output format*: `BED - browser extensible data`

- `ucsc_unusual_regions.bed`
  - *Genome*: `Human (hg38)`
  - *Group*: `Mapping and Sequencing`
  - *Track*: `Problematic Regions`
  - *Table*: `UCSC Unusual Regions (comments)`
  - *Region*: `Genome`
  - *Output format*: `BED - browser extensible data`

Both files were bgziped: `encode_blacklist_v2.bed.gz` and `ucsc_unusual_regions.bed.gz`

### Reference genome

We downloaded the file `Homo_sapiens_assembly38.fasta.gz` from [Broad Institute's GATK github repository](https://github.com/broadinstitute/gatk). File `src/test/resources/large/Homo_sapiens_assembly38.fasta.gz` and we uncompressed it.

## Preprocessing

We preprocessed the truthset VCF to:

- generate one truthset VCF per family member (NA12877 NA12878 NA12879 NA12881 NA12882 NA12885 NA12886)

- generate one truthset VCF per family member excluding private calls from deep variant and dragen

- subset the VCFs to keep variants that are in the regions defined in the BED files `encode_blacklist_v2.bed.gz` and `ucsc_unusual_regions.bed.gz`

The script [preprocess.sh](./preprocess.sh) generates the data listed above. It also "cleans" the bed files to keep only the chromosomes 1 to 22 plus X.

**Note**: you must adapted the script for your environment by replacing the values that are enclosed by `<>`.
