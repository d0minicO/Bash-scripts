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
barcodes=(TTCGCGCGTAACGACGTACCGT CGCGATACGACCGCGTTACGCG CGACGTTAACGCGTTTCGTACG CGCGACTATCGCGCGTAACGCG CCGTACGTCGTGTCGAACGACG CGATACGCGTTGGTACGCGTAA TAGTTCGCGACACCGTTCGTCG TCGACGCGTAAACGGTACGTCG TTATCGCGTCGCGACGGACGTA CGATCGTACGATAGCGTACCGA CGCATATCGCGTCGTACGACCG ACGTTCGACCGCGGTCGTACGA ACGATTCGACGATCGTCGACGA CGATAGTCGCGTCGCACGATCG CGCCGATTACGTGTCGCGCGTA ATCGTACCGCGCGTATCGGTCG CGTTCGAACGTTCGTCGACGAT TCGCGATTACGATGTCGCGCGA ACGCGAATCGTCGACGCGTATA CGCGATATCACTCGACGCGATA CGCGAAATTCGTATACGCGTCG CGCGATCGGTATCGGTACGCGC GTGATATCGCGTTAACGTCGCG TATCGCGCGAAACGACCGTTCG CCGCGCGTAATGCGCGACGTTA CCGCGATACGACTCGTTCGTCG GTCGCGAACTATCGTCGATTCG CCGCGCGTATAGTCCGAGCGTA CGATACGCCGATCGATCGTCGG CCGCGCGATAAGACGCGTAACG CGATTCGACGGTCGCGACCGTA TTTCGACGCGTCGATTCGGCGA)

# Function to count barcode in a file
count_barcode() {
  barcode=$1
  file=$2
  echo -e "$barcode\t$file\t$(grep -c $barcode "$file")"
}

export -f count_barcode

while read -r r1_file && read -r r2_file; do
    echo "Processing file $r1_file"
    echo "Processing file $r2_file"
    for file in $r1_file $r2_file; do
        printf '%s\n' "${barcodes[@]}" | parallel -j $threads count_barcode {} $file >> $output
    done
done < "$file"
