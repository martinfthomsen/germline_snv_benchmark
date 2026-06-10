#!/usr/bin/env python3

import sys
from pathlib import Path

# Reading command line arguments

# Directory where all bed files can be found
BED_FILE_PATH = Path(sys.argv[1]).resolve().absolute()
# Directory where all individual truthset VCF files can be found
TS_FILE_PATH = Path(sys.argv[2]).resolve().absolute()
# Directory where all individual truthset VCF files (without private calls) can be found
TS_FILE_PATH_NOPRIV = Path(sys.argv[3]).resolve().absolute()
# Sample sheet directory
SS_DIR = Path(sys.argv[4]).resolve().absolute()
# Path for the FASTA file
FASTA = Path(sys.argv[5]).resolve().absolute()
# Base output directory for the pipeline execution
BASE_OUT_DIR = Path(sys.argv[6]).resolve().absolute()
# Directory where the configuration files will be written
CFG_DIR = Path(sys.argv[7]).resolve().absolute()

# We assume that the template file is together with this script
TEMPLATE = Path(__file__).parent.joinpath('template.config').read_text()

# Checking if the fasta.fai is in the same location of the FASTA file
FAI = FASTA.parent.joinpath(FASTA.name + '.fai')
if not FAI.exists():
    print(f'[ERROR] We expect that the file {FAI} is together with the file {FASTA}')
    sys.exit(1)

# Create the bed file mapping
BED = {
    "BL": f"{BED_FILE_PATH}/encode_blacklist_v2.chr1-22andX.sorted.bed.gz",
    "UR": f"{BED_FILE_PATH}/ucsc_unusual_regions.chr1-22andX.sorted.bed.gz",
    "HQ": f"{BED_FILE_PATH}/hq_regions_final.chr1-22andX.sorted.bed.gz"
}

# Bed description mapping
BED_DESC = {
    "BL": "Encode Blacklist",
    "UR": "UCSC unusual regions",
    "HQ": "High quality regions"
}

# Truthset mapping
TS = {
    "NA12877-BL": f"{TS_FILE_PATH}/NA12877_encode_blacklist_v2.vcf.gz",
    "NA12877-UR": f"{TS_FILE_PATH}/NA12877_ucsc_unusual_regions.vcf.gz",
    "NA12877-HQ": f"{TS_FILE_PATH}/NA12877.vcf.gz",
    "NA12878-BL": f"{TS_FILE_PATH}/NA12878_encode_blacklist_v2.vcf.gz",
    "NA12878-UR": f"{TS_FILE_PATH}/NA12878_ucsc_unusual_regions.vcf.gz",
    "NA12878-HQ": f"{TS_FILE_PATH}/NA12878.vcf.gz",
    "NA12879-BL": f"{TS_FILE_PATH}/NA12879_encode_blacklist_v2.vcf.gz",
    "NA12879-UR": f"{TS_FILE_PATH}/NA12879_ucsc_unusual_regions.vcf.gz",
    "NA12879-HQ": f"{TS_FILE_PATH}/NA12879.vcf.gz",
    "NA12881-BL": f"{TS_FILE_PATH}/NA12881_encode_blacklist_v2.vcf.gz",
    "NA12881-UR": f"{TS_FILE_PATH}/NA12881_ucsc_unusual_regions.vcf.gz",
    "NA12881-HQ": f"{TS_FILE_PATH}/NA12881.vcf.gz",
    "NA12882-BL": f"{TS_FILE_PATH}/NA12882_encode_blacklist_v2.vcf.gz",
    "NA12882-UR": f"{TS_FILE_PATH}/NA12882_ucsc_unusual_regions.vcf.gz",
    "NA12882-HQ": f"{TS_FILE_PATH}/NA12882.vcf.gz",
    "NA12885-BL": f"{TS_FILE_PATH}/NA12885_encode_blacklist_v2.vcf.gz",
    "NA12885-UR": f"{TS_FILE_PATH}/NA12885_ucsc_unusual_regions.vcf.gz",
    "NA12885-HQ": f"{TS_FILE_PATH}/NA12885.vcf.gz",
    "NA12886-BL": f"{TS_FILE_PATH}/NA12886_encode_blacklist_v2.vcf.gz",
    "NA12886-UR": f"{TS_FILE_PATH}/NA12886_ucsc_unusual_regions.vcf.gz",
    "NA12886-HQ": f"{TS_FILE_PATH}/NA12886.vcf.gz"
}

# Non-private truthset mapping
TSNOPRIV = {
    "NA12877-BL": f"{TS_FILE_PATH_NOPRIV}/NA12877_encode_blacklist_v2.vcf.gz",
    "NA12877-UR": f"{TS_FILE_PATH_NOPRIV}/NA12877_ucsc_unusual_regions.vcf.gz",
    "NA12877-HQ": f"{TS_FILE_PATH_NOPRIV}/NA12877.vcf.gz",
    "NA12878-BL": f"{TS_FILE_PATH_NOPRIV}/NA12878_encode_blacklist_v2.vcf.gz",
    "NA12878-UR": f"{TS_FILE_PATH_NOPRIV}/NA12878_ucsc_unusual_regions.vcf.gz",
    "NA12878-HQ": f"{TS_FILE_PATH_NOPRIV}/NA12878.vcf.gz",
    "NA12879-BL": f"{TS_FILE_PATH_NOPRIV}/NA12879_encode_blacklist_v2.vcf.gz",
    "NA12879-UR": f"{TS_FILE_PATH_NOPRIV}/NA12879_ucsc_unusual_regions.vcf.gz",
    "NA12879-HQ": f"{TS_FILE_PATH_NOPRIV}/NA12879.vcf.gz",
    "NA12881-BL": f"{TS_FILE_PATH_NOPRIV}/NA12881_encode_blacklist_v2.vcf.gz",
    "NA12881-UR": f"{TS_FILE_PATH_NOPRIV}/NA12881_ucsc_unusual_regions.vcf.gz",
    "NA12881-HQ": f"{TS_FILE_PATH_NOPRIV}/NA12881.vcf.gz",
    "NA12882-BL": f"{TS_FILE_PATH_NOPRIV}/NA12882_encode_blacklist_v2.vcf.gz",
    "NA12882-UR": f"{TS_FILE_PATH_NOPRIV}/NA12882_ucsc_unusual_regions.vcf.gz",
    "NA12882-HQ": f"{TS_FILE_PATH_NOPRIV}/NA12882.vcf.gz",
    "NA12885-BL": f"{TS_FILE_PATH_NOPRIV}/NA12885_encode_blacklist_v2.vcf.gz",
    "NA12885-UR": f"{TS_FILE_PATH_NOPRIV}/NA12885_ucsc_unusual_regions.vcf.gz",
    "NA12885-HQ": f"{TS_FILE_PATH_NOPRIV}/NA12885.vcf.gz",
    "NA12886-BL": f"{TS_FILE_PATH_NOPRIV}/NA12886_encode_blacklist_v2.vcf.gz",
    "NA12886-UR": f"{TS_FILE_PATH_NOPRIV}/NA12886_ucsc_unusual_regions.vcf.gz",
    "NA12886-HQ": f"{TS_FILE_PATH_NOPRIV}/NA12886.vcf.gz"
}

# Auxiliar function to create the configuration and output directory
def create_file_and_dir(pname, pdesc, ss, bout, ts, bedfile):
    # Replacing all strings
    outtext = TEMPLATE
    outtext = outtext.replace('!PROFILENAME!', pname)
    outtext = outtext.replace('!PROFILEDESCRIPTION!', pdesc)
    outtext = outtext.replace('!SAMPLESHEET!', ss.absolute().as_posix())
    outtext = outtext.replace('!OUTDIR!', bout.absolute().as_posix())
    outtext = outtext.replace('!TRUTHID!', sample)
    outtext = outtext.replace('!TRUTHVCF!', ts)
    outtext = outtext.replace('!BEDFILE!', bedfile)
    outtext = outtext.replace('!FASTAPATH!', FASTA.absolute().as_posix())
    outtext = outtext.replace('!FAIPATH!', FAI.absolute().as_posix())

    if not bout.exists():
        # Create the output directory
        bout.mkdir(parents=True, exist_ok=True)

    with open(CFG_DIR.joinpath(oname), 'w') as out:
        print(outtext, file=out)


# Process all sample sheets that are in the sample sheet directory
for ss in sorted(SS_DIR.glob('*.csv')):

    # Getting the sample name
    sample = ss.name.split('.')[0]

    # Profile name prefix is the sample name
    pname_prefix = f'{sample}'
    # Profile description prefix is also the sample name
    pdesc_prefix = f'{sample}'

    # We now iterate over the 3 bed files 
    for bed in {'BL', 'UR', 'HQ'}:

        # Output file prefix is composed by sample name + bed short name
        oname_prefix = f'{sample}_{bed}'

        # Getting the proper bed file
        bedfile = BED[bed]

        # Now, we deal with the Full truthset
        pname = f'{pname_prefix} - {bed} - Full-TS'
        pdesc = f'{pdesc_prefix} - {BED_DESC[bed]} - Full Truth-set'
        oname = f'{oname_prefix}_FullTS.config'
        bout = BASE_OUT_DIR.joinpath(sample, 'Full-TS', bed)
        ts = TS[f'{sample}-{bed}']

        create_file_and_dir(pname, pdesc, ss, bout, ts, bedfile)

        # Now, we do the same of the nopriv truthset
        pname = f'{pname_prefix} - {bed} - NonPriv-TS'
        pdesc = f'{pdesc_prefix} - {BED_DESC[bed]} - Non-Private Truth-set'
        oname = f'{oname_prefix}_NoPrivTS.config'
        bout = BASE_OUT_DIR.joinpath(sample, 'NonPriv-TS', bed)
        ts = TSNOPRIV[f'{sample}-{bed}']
        create_file_and_dir(pname, pdesc, ss, bout, ts, bedfile)
