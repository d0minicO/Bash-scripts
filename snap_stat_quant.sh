#!/usr/bin/env bash

# Help message
usage() {
  echo "Script for quantifying barcodes in fastq files (not gzipped!) for SNAP-CUTANA™ K-MetStat Panel"
  echo "Usage: $0 -f FILE -j THREADS -o OUTPUT"
  echo "  -f FILE     specify an input file"
  echo "  -j THREADS  specify the number of threads"
  echo "  -o OUTPUT   specify the output file"
  echo "  -h          display this help message"
  exit 1
}

# Parse command line arguments
while getopts ":f:j:o:h" opt; do
  case ${opt} in
    f)
      file=$OPTARG
      ;;
    j)
      threads=$OPTARG
      ;;
    o)
      output=$OPTARG
      ;;
    h)
      usage
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      usage
      ;;
  esac
done

# Check if file name is provided
if [[ -z "$file" ]]; then
    echo "Input file is required"
    usage
fi

# Check if thread number is provided
if [[ -z "$threads" ]]; then
    echo "Thread number is required"
    usage
fi

# Check if output file name is provided
if [[ -z "$output" ]]; then
    echo "Output file is required"
    usage
fi

# Main script
# Barcode identities
declare -A barcodes
barcodes=(
["TTCGCGCGTAACGACGTACCGT"]="Unmodified A"
["CGCGATACGACCGCGTTACGCG"]="Unmodified B"
["CGACGTTAACGCGTTTCGTACG"]="H3K4me1 A"
["CGCGACTATCGCGCGTAACGCG"]="H3K4me1 B"
["CCGTACGTCGTGTCGAACGACG"]="H3K4me2 A"
["CGATACGCGTTGGTACGCGTAA"]="H3K4me2 B"
["TAGTTCGCGACACCGTTCGTCG"]="H3K4me3 A"
["TCGACGCGTAAACGGTACGTCG"]="H3K4me3 B"
["TTATCGCGTCGCGACGGACGTA"]="H3K9me1 A"
["CGATCGTACGATAGCGTACCGA"]="H3K9me1 B"
["CGCATATCGCGTCGTACGACCG"]="H3K9me2 A"
["ACGTTCGACCGCGGTCGTACGA"]="H3K9me2 B"
["ACGATTCGACGATCGTCGACGA"]="H3K9me3 A"
["CGATAGTCGCGTCGCACGATCG"]="H3K9me3 B"
["CGCCGATTACGTGTCGCGCGTA"]="H3K27me1 A"
["ATCGTACCGCGCGTATCGGTCG"]="H3K27me1 B"
["CGTTCGAACGTTCGTCGACGAT"]="H3K27me2 A"
["TCGCGATTACGATGTCGCGCGA"]="H3K27me2 B"
["ACGCGAATCGTCGACGCGTATA"]="H3K27me3 A"
["CGCGATATCACTCGACGCGATA"]="H3K27me3 B"
["CGCGAAATTCGTATACGCGTCG"]="H3K36me1 A"
["CGCGATCGGTATCGGTACGCGC"]="H3K36me1 B"
["GTGATATCGCGTTAACGTCGCG"]="H3K36me2 A"
["TATCGCGCGAAACGACCGTTCG"]="H3K36me2 B"
["CCGCGCGTAATGCGCGACGTTA"]="H3K36me3 A"
["CCGCGATACGACTCGTTCGTCG"]="H3K36me3 B"
["GTCGCGAACTATCGTCGATTCG"]="H4K20me1 A"
["CCGCGCGTATAGTCCGAGCGTA"]="H4K20me1 B"
["CGATACGCCGATCGATCGTCGG"]="H4K20me2 A"
["CCGCGCGATAAGACGCGTAACG"]="H4K20me2 B"
["CGATTCGACGGTCGCGACCGTA"]="H4K20me3 A"
["TTTCGACGCGTCGATTCGGCGA"]="H4K20me3 B"
)

# Function to count barcode in a file
count_barcode() {
  barcode=$1
  file=$2
  echo -e "${barcodes[$barcode]}\t$barcode\t$file\t$(grep -c $barcode "$file")"
}

export -f count_barcode

while read -r r1_file && read -r r2_file; do
    echo "Processing file $r1_file"
    echo "Processing file $r2_file"
    for file in $r1_file $r2_file; do
        for barcode in "${!barcodes[@]}"; do
            count_barcode $barcode $file >> $output
        done
    done
done < "$file"
