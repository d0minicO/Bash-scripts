#!/bin/bash

## bash script to verify .fastq.gz file integrity
## pass -d argument /path/to/data
## script will perform checksums and compare with .md5 files for all .fastq.gz files in this directory 
## written by Dominic D.G. Owens


# Function to show usage
usage() {
    echo "Usage: $0 -d <dir>"
    echo "Options:"
    echo "   -d   Directory containing .fastq.gz and .fastq.gz.md5 files"
    echo "   -h   Display this help message"
    exit 1
}

# Parse command line options
while getopts ":d:h" opt; do
    case "${opt}" in
        d)
            dir=${OPTARG}
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

# If no directory was specified, show usage
if [[ -z "${dir}" ]]; then
    usage
fi

# Change to the directory
cd "${dir}" || exit

# Iterate over each .fastq.gz file in the directory
for file in *.fastq.gz; do
    # Calculate the MD5 checksum of the file
    calculated_checksum=$(md5sum "${file}" | awk '{ print $1 }')

    # Extract the expected checksum from the .md5 file
    md5_file="${file}.md5"
    if [[ -f "${md5_file}" ]]; then
        expected_checksum=$(awk '{ print $1 }' "${md5_file}")

        # Compare the calculated and expected checksums and print a message
        if [[ "${calculated_checksum}" == "${expected_checksum}" ]]; then
            echo "${file}: CHECKSUM MATCH - Calculated MD5 Checksum is ${calculated_checksum}"
        else
            echo "${file}: CHECKSUM MISMATCH - Expected ${expected_checksum}, but got ${calculated_checksum}"
        fi
    else
        echo "${file}: MISSING .md5 FILE"
    fi
done
