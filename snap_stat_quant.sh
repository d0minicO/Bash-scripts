#!/usr/bin/env bash

# Help message
usage() {
  echo "Script for quantifying SNAP-CUTANA™ K-MetStat Panel barcodes in parallel"
  echo -e "\n Dominic D. G. Owens, July 2023\n"
  echo "Fastq files should not be gzipped but just plain .fastq format"
  echo "Requires gnu parallel to be installed and working. Run parallel --citation to silence the citation messages"
  echo -e "\n" 
  echo "Usage: $0 -f FILE -j THREADS -o OUTPUT"
  echo "  -f FILE     specify an input text file containing the full path to the fq files each on a new line"
  echo "  -j THREADS  specify the number of threads"
  echo "  -o OUTPUT   specify the output file"
  echo "  -h          display this help message"
  exit 1
}

# Function to clean up temp file
cleanup() {
  if [ -f "temp.txt" ]; then
    rm temp.txt
  fi
}

# Set up trap to ensure cleanup happens
trap cleanup EXIT

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


# Check if output file exists and remove it if it does
if [ -f "$output" ]; then
    echo "Output file $output exists. Overwriting."
    rm "$output"
fi

# Main script
# Barcode identities from https://www.epicypher.com/content/documents/SNAP-CUTANA_K-MetStat_Panel_ShellScript.sh
declare -A barcodes=(
["Unmodified_A"]="TTCGCGCGTAACGACGTACCGT"
["Unmodified_B"]="CGCGATACGACCGCGTTACGCG"
["H3K4me1_A"]="CGACGTTAACGCGTTTCGTACG"
["H3K4me1_B"]="CGCGACTATCGCGCGTAACGCG"
["H3K4me2_A"]="CCGTACGTCGTGTCGAACGACG"
["H3K4me2_B"]="CGATACGCGTTGGTACGCGTAA"
["H3K4me3_A"]="TAGTTCGCGACACCGTTCGTCG"
["H3K4me3_B"]="TCGACGCGTAAACGGTACGTCG"
["H3K9me1_A"]="TTATCGCGTCGCGACGGACGTA"
["H3K9me1_B"]="CGATCGTACGATAGCGTACCGA"
["H3K9me2_A"]="CGCATATCGCGTCGTACGACCG"
["H3K9me2_B"]="ACGTTCGACCGCGGTCGTACGA"
["H3K9me3_A"]="ACGATTCGACGATCGTCGACGA"
["H3K9me3_B"]="CGATAGTCGCGTCGCACGATCG"
["H3K27me1_A"]="CGCCGATTACGTGTCGCGCGTA"
["H3K27me1_B"]="ATCGTACCGCGCGTATCGGTCG"
["H3K27me2_A"]="CGTTCGAACGTTCGTCGACGAT"
["H3K27me2_B"]="TCGCGATTACGATGTCGCGCGA"
["H3K27me3_A"]="ACGCGAATCGTCGACGCGTATA"
["H3K27me3_B"]="CGCGATATCACTCGACGCGATA"
["H3K36me1_A"]="CGCGAAATTCGTATACGCGTCG"
["H3K36me1_B"]="CGCGATCGGTATCGGTACGCGC"
["H3K36me2_A"]="GTGATATCGCGTTAACGTCGCG"
["H3K36me2_B"]="TATCGCGCGAAACGACCGTTCG"
["H3K36me3_A"]="CCGCGCGTAATGCGCGACGTTA"
["H3K36me3_B"]="CCGCGATACGACTCGTTCGTCG"
["H4K20me1_A"]="GTCGCGAACTATCGTCGATTCG"
["H4K20me1_B"]="CCGCGCGTATAGTCCGAGCGTA"
["H4K20me2_A"]="CGATACGCCGATCGATCGTCGG"
["H4K20me2_B"]="CCGCGCGATAAGACGCGTAACG"
["H4K20me3_A"]="CGATTCGACGGTCGCGACCGTA"
["H4K20me3_B"]="TTTCGACGCGTCGATTCGGCGA"
)

# Export the array as a string
declare -p barcodes > temp.txt

# Function to count barcode in a file
count_barcode() {
  source temp.txt # source the temp file
  barcode_name=$1
  barcode=${barcodes[$barcode_name]}
  file=$2
  echo -e "$barcode_name\t$barcode\t$file\t$(grep -c $barcode "$file")"
}

export -f count_barcode

while read -r line; do
    echo "Processing file $line"
    printf '%s\n' "${!barcodes[@]}" | parallel -j $threads count_barcode {} $line >> $output
done < "$file"
