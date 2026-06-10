#!/usr/bin/env python3

import re
import sys
import subprocess
from pathlib import Path

# Input directory contains all generated VCFs
inputdir = Path(sys.argv[1])

# Output directory where the sample sheet will be written
outputdir = Path(sys.argv[2])

# Desired sample (for instance, NA12877)
sample = sys.argv[3]

#  Sample sheet header
header = "id,test_vcf,caller,refdist,chunksize,normshift,normdist,normsizediff,maxdist,typeignore,dup_to_ins,pctsize,pctseq,pctovl,evaluationmode,subsample"

# Getting the header number of columns
header_len = len(header.split(','))

with open(outputdir.joinpath(f'{sample}.csv'), 'w') as out:
    
    print(header, file=out)

    # We glob all VCF files that have the given sample name in their name.
    for vcf in sorted(inputdir.glob(f'*{sample}*.vcf.gz')):

        parent_dir = vcf.parent.resolve().absolute()

        # ID will be the VCF name without extension
        vcfid = vcf.name.replace('.vcf.gz', '')
        try:
            # We use bcftools view to access the VCF header and get the sample name for the VCF
            # We assume that bcftools is in the PATH
            cmd = f'bcftools view -h {vcf.absolute().as_posix()}'
            output = subprocess.run(cmd, capture_output=True, text=True, shell=True, check=True)
            last_row = output.stdout.split('\n')[-2]
            values = last_row.split('\t')
            sample = values[9]
        except:
            import traceback
            traceback.print_exc()

        # We expect that the VCF file name has the following standard
        # <CONFIGURATIONNAME>_<SAMPLE>_<CALLER>.vcf.gz

        # Getting the caller name
        caller = vcfid.split('_')[-1]

        # Creating the row with the relevant information
        row = [''] * header_len
        # ID
        row[0] = vcfid
        # TEST VCF
        row[1] = parent_dir.joinpath(vcf.name).as_posix()
        # CALLER
        row[2] = caller
        # SAMPLE NAME INSIDE OF THE VCF
        row[header_len - 1] = sample

        # Priting the row
        print(','.join(row), file=out)
