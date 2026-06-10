#!/bin/bash
#PBS -A <PBS_ACCOUNT>
#PBS -N sentieon_na128x
#PBS -l walltime=12:00:00
#PBS -l ncpus=190
#PBS -l mem=2000GB
#PBS -t 0-6
#PBS -j oe

set -euo pipefail

# -----------------------------
# User-configurable paths
# Replace every <...> placeholder with a path/value for your environment.
# -----------------------------
# Directory holding the paired-end FASTQs listed in R1_FILES below
FASTQ_ROOT="<FASTQ_DIR>"
# Directory that will receive the per-sample results
OUT_ROOT="<OUTPUT_DIR>"

# Sentieon DNAscope model bundle (e.g. DNAscopeMGIWGS2.1.bundle)
MODEL="<SENTIEON_MODEL_BUNDLE>"
# GRCh38 reference FASTA (e.g. Homo_sapiens_assembly38.fasta); needs .fai and a BWA index alongside it
REF="<HG38_REF_GENOME_FASTA>"
# WGS calling regions BED (e.g. GATK wgs_calling_regions.hg38.bed)
BED="<WGS_CALLING_REGIONS_BED>"
# Known sites VCF (e.g. GATK dbsnp_138.hg38.vcf.gz)
DBSNP="<DBSNP_VCF>"

# Sequencing center code written to the read group (RG CN tag)
SEQ_CENTER="<SEQUENCING_CENTER>"

# -----------------------------
# Modules / env
# All modules below are EasyBuild modules (note the toolchain suffixes, e.g.
# -GCCcore-13.3.0, -GCC-13.3.0, -foss-2024a). The exact EasyConfigs are public,
# so the same software stack can be rebuilt elsewhere with EasyBuild.
# -----------------------------
cd "${PBS_O_WORKDIR:-$PWD}"

ml purge
ml sentieon-genomics
ml jemalloc/5.3.0-GCCcore-13.3.0
ml ISA-L/2.31.0
ml sentieon-cli
ml SAMtools/1.21-GCC-13.3.0
ml MultiQC/1.28-foss-2024a
ml Perl-bundle-CPAN/5.38.2-GCCcore-13.3.0
ml BLAKE3-C/1.6.1-GCCcore-13.3.0

# Sentieon license server as host:port (or a path to a license file)
export SENTIEON_LICENSE="<SENTIEON_LICENSE_SERVER>"
[[ -n "${SENTIEON_LICENSE:-}" ]] || { echo "ERROR: SENTIEON_LICENSE not set"; exit 2; }

# -----------------------------
# Sample list
# -----------------------------
R1_FILES=(
  "NA12877_2209.v4.2.4.grc38_R1.fastq.gz"
  "NA12878_2188.v4.2.4.grc38_R1.fastq.gz"
  "NA12879_2216.v4.2.4.grc38_R1.fastq.gz"
  "NA12881_2211.v4.2.4.grc38_R1.fastq.gz"
  "NA12882_2212.v4.2.4.grc38_R1.fastq.gz"
  "NA12885_2217.v4.2.4.grc38_R1.fastq.gz"
  "NA12886_2189.v4.2.4.grc38_R1.fastq.gz"
)

IDX="${PBS_ARRAYID:-${PBS_ARRAY_INDEX:-0}}"
R1_NAME="${R1_FILES[$IDX]}"
R2_NAME="${R1_NAME/_R1.fastq.gz/_R2.fastq.gz}"

R1_SRC="${FASTQ_ROOT}/${R1_NAME}"
R2_SRC="${FASTQ_ROOT}/${R2_NAME}"

[[ -s "$R1_SRC" ]] || { echo "ERROR: Missing R1: $R1_SRC" >&2; exit 1; }
[[ -s "$R2_SRC" ]] || { echo "ERROR: Missing R2: $R2_SRC" >&2; exit 1; }

# -----------------------------
# Reference preflight (accept .amb or .64.amb)
# -----------------------------
for f in "$MODEL" "$REF" "$BED" "$DBSNP"; do
  [[ -s "$f" ]] || { echo "ERROR: Missing required file: $f" >&2; exit 2; }
done
[[ -s "${REF}.fai" ]] || { echo "ERROR: Missing ${REF}.fai" >&2; exit 2; }

if [[ -s "${REF}.amb" && -s "${REF}.ann" && -s "${REF}.bwt" && -s "${REF}.pac" && -s "${REF}.sa" ]]; then
  :
elif [[ -s "${REF}.64.amb" && -s "${REF}.64.ann" && -s "${REF}.64.bwt" && -s "${REF}.64.pac" && -s "${REF}.64.sa" ]]; then
  :
else
  echo "ERROR: Missing BWA index set for $REF (expected .amb... or .64.amb...)" >&2
  exit 2
fi

# -----------------------------
# Names / dirs
# -----------------------------
SAMPLE="${R1_NAME%%_*}"
RUN_BASENAME="${R1_NAME%_R1.fastq.gz}"

FINAL_OUT="${OUT_ROOT}/${RUN_BASENAME}"
mkdir -p "$FINAL_OUT"

JOBTAG="${PBS_JOBID:-manual.$$}"
SCRATCH_BASE="/scratch/${JOBTAG}"
WORKDIR="${SCRATCH_BASE}/${RUN_BASENAME}"
mkdir -p "$WORKDIR"

LOG="${WORKDIR}/${RUN_BASENAME}.run.log"
TIMELOG="${WORKDIR}/${RUN_BASENAME}.time.txt"

START_EPOCH="$(date +%s)"
START_ISO="$(date -Is)"

cleanup() {
  rc=$?
  END_EPOCH="$(date +%s)"
  END_ISO="$(date -Is)"
  ELAPSED_SEC=$((END_EPOCH - START_EPOCH))
  ELAPSED_HMS="$(printf '%02d:%02d:%02d' $((ELAPSED_SEC/3600)) $(((ELAPSED_SEC%3600)/60)) $((ELAPSED_SEC%60)))"

  {
    echo "[$END_ISO] END rc=$rc"
    echo "TOTAL_WALLTIME_SECONDS=${ELAPSED_SEC}"
    echo "TOTAL_WALLTIME_HHMMSS=${ELAPSED_HMS}"
  } | tee -a "$LOG" || true

  # Copy everything back (results + logs + timing)
  mkdir -p "$FINAL_OUT"
  rsync -ah --inplace --partial "$WORKDIR/" "$FINAL_OUT/" || true

  # Keep scratch on failure for debugging, clean on success
  if [[ $rc -eq 0 ]]; then
    rm -rf "$SCRATCH_BASE"
  else
    echo "Scratch kept for debug: $SCRATCH_BASE" | tee -a "$FINAL_OUT/${RUN_BASENAME}.run.log" || true
  fi
  exit $rc
}
trap cleanup EXIT

{
  echo "[$START_ISO] START ${RUN_BASENAME}"
  echo "JOB_ID=${PBS_JOBID:-NA} ARRAY_ID=${IDX} HOST=$(hostname)"
  echo "WORKDIR=${WORKDIR}"
  echo "FINAL_OUT=${FINAL_OUT}"
  echo "R1_SRC=${R1_SRC}"
  echo "R2_SRC=${R2_SRC}"
} | tee -a "$LOG"

# -----------------------------
# Stage FASTQs to scratch
# -----------------------------
cp -f "$R1_SRC" "$WORKDIR/$R1_NAME"
cp -f "$R2_SRC" "$WORKDIR/$R2_NAME"

R1_LOCAL="$WORKDIR/$R1_NAME"
R2_LOCAL="$WORKDIR/$R2_NAME"

# -----------------------------
# Build RG from first FASTQ header
# -----------------------------
set +o pipefail
H="$(zcat -f "$R1_LOCAL" | head -n 1 || true)"
set -o pipefail
[[ -n "${H:-}" ]] || { echo "ERROR: Could not read FASTQ header from $R1_LOCAL" | tee -a "$LOG"; exit 1; }

FLOWCELL="$(echo "$H" | cut -d: -f3)"
LANE="$(echo "$H" | cut -d: -f4)"
[[ -n "${FLOWCELL:-}" ]] || FLOWCELL="FCUNKNOWN"
[[ -n "${LANE:-}" ]] || LANE="1"
ID="${FLOWCELL}.${LANE}.${SAMPLE}"
PU="${FLOWCELL}.${LANE}"
LB="Lib1"
PL="ILLUMINA"

# escaped \t required by sentieon-cli wrapper
RG="@RG\\tID:${ID}\\tSM:${SAMPLE}\\tLB:${LB}\\tPL:${PL}\\tPU:${PU}\\tCN:${SEQ_CENTER}"
echo "RG=${RG}" | tee -a "$LOG"

# -----------------------------
# Run entirely in scratch
# -----------------------------
cd "$WORKDIR"

/usr/bin/time -v \
sentieon-cli dnascope \
  -m "$MODEL" \
  -r "$REF" \
  --r1_fastq "$R1_LOCAL" \
  --r2_fastq "$R2_LOCAL" \
  --readgroups "$RG" \
  --assay WGS --pcr_free \
  --collate_align \
  --duplicate_marking markdup \
  --bed "$BED" \
  -d "$DBSNP" \
  "${RUN_BASENAME}.vcf.gz" \
  2> "$TIMELOG"

# Optional checksum in scratch (copied back by trap)
sha256sum "${RUN_BASENAME}.vcf.gz" > "${RUN_BASENAME}.vcf.gz.sha256"
