#!/bin/bash

# Print usage help message
usage() {
  echo "Usage: $0 [-d bam_directory] [-t threads] [-h]"
  echo "  -d    Directory containing .bam files to process"
  echo "  -t    Number of threads to use with samtools"
  echo "  -h    Display this help message and exit"
  exit 1
}

# Parse command-line arguments
while getopts ":d:t:h" opt; do
  case ${opt} in
    d)
      bam_directory=$OPTARG
      ;;
    t)
      thr=$OPTARG
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

# Check if necessary arguments are provided
if [ -z "${bam_directory}" ] || [ -z "${thr}" ]; then
    usage
fi

# define a cleanup function to remove temp files even if errors, only if they exist
cleanup() {
    echo "Cleaning up temporary files..."
    if ls temp*.bam 1> /dev/null 2>&1; then
        rm temp*.bam
        echo "Temporary files cleaned up"
    else
        echo "No temporary files to clean up"
    fi
}

trap cleanup EXIT

# Iterate over the BAM files in the directory
for bam_file in "$bam_directory"/*.bam; do
	output_bam="${bam_file%.bam}_proc.bam"
	echo -e "\n\n\nProcessing: $bam_file ::: writing to $output_bam"
	echo "-------$bam_file---------"
	samtools flagstat "$bam_file"
	echo -e "----------------------\n\n"
	# filter unmapped reads and multi-mapping (low quality) alignments
	samtools view --threads "$thr" -b -F 4 -q 1 -o temp1.bam "${bam_file}"
	# query name sort for fixmate
	samtools sort -n --threads $thr temp1.bam -o temp2.bam
	# run fixmate to prepare for markdup
	samtools fixmate -m --threads $thr temp2.bam temp3.bam
	# default sort for markdup
	samtools sort --threads $thr temp3.bam -o temp4.bam
	# markdup to remove PCR duplicates
	samtools markdup -r --threads $thr temp4.bam temp5.bam
	# sort bam file
	samtools sort --threads $thr temp5.bam -o $output_bam
	# index the sorted BAM file
	samtools index -@ $thr $output_bam
	echo "Finished processing $output_bam, requantifying filtered alignments"
    # Clean up temporary files before moving to the next iteration
    cleanup
	echo "-------$output_bam---------"
	# flagstat the output file
	samtools flagstat "$output_bam"
	echo -e "----------------------\n\n\n"
done
