#!/bin/bash

## bash script wrapper for parallel processing of fastq files using trim_galore
## written by Dominic D.G. Owens

usage() {
    echo "Usage: $0 -i input_file -o output_dir -t path_to_trim_galore -p path_to_cutadapt -n num_threads"
    echo
    echo "This script takes an input_file and an output_dir as command-line arguments"
    echo "and processes them using the trim_galore command."
    echo
    echo "Options:"
    echo "  -h  Show this help message and exit"
    echo "  -i  Specify the input_file (text file containing paired-end fq files on adjacent newlines)"
    echo "  -o  Specify the output_dir"
    echo "  -t  Specify the path_to_trim_galore eg /home/dowens/TrimGalore-0.6.10/trim_galore"
    echo "  -p  Specify the path_to_cutadapt eg /home/dowens/MyPythonEnv/bin/cutadapt"
    echo "  -n  Specify the number of threads to use"
}

num_threads=1

while getopts ":hi:o:t:p:n:" opt; do
    case ${opt} in
        h)
            usage
            exit 0
            ;;
        i)
            input_file=$OPTARG
            ;;
        o)
            output_dir=$OPTARG
            ;;
        t)
            path_to_trim_galore=$OPTARG
            ;;
        p)
            path_to_cutadapt=$OPTARG
            ;;
        n)
            num_threads=$OPTARG
            ;;
        \?)
            echo "Invalid option: $OPTARG" 1>&2
            usage
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." 1>&2
            usage
            exit 1
            ;;
    esac
done

if [ -z "$input_file" ] || [ -z "$output_dir" ] || [ -z "$path_to_trim_galore" ]; then
    echo "Input_file, output_dir, and path_to_trim_galore are required." 1>&2
    usage
    exit 1
fi

# Define the process_files function and run it directly in the parallel command
process_files() {
    r1_file=$1
    r2_file=$2
    # Run the trim_galore command
    "${path_to_trim_galore}" --paired --path_to_cutadapt "${path_to_cutadapt}" --quality 20 --length 20 --fastqc -o "$output_dir" "$r1_file" "$r2_file"

    echo "Processed: $r1_file and $r2_file"
}

# Use GNU Parallel to process the files in parallel
# We pass all the required variables to parallel and run the function inline
cat "$input_file" | parallel -j "$num_threads" -N2 process_files {1} {2} ::: "$path_to_trim_galore" "$path_to_cutadapt" "$output_dir"
