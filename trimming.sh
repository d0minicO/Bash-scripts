#!/bin/bash

usage() {
    echo "Usage: $0 -i input_file -o output_dir -t path_to_trim_galore"
    echo
    echo "This script takes an input_file and an output_dir as command-line arguments"
    echo "and processes them using the trim_galore command."
    echo
    echo "Options:"
    echo "  -h  Show this help message and exit"
    echo "  -i  Specify the input_file (text file containing paired-end fq files on adjacent newlines)"
    echo "  -o  Specify the output_dir"
    echo "  -t  Specify the path_to_trim_galore eg /home/dowens/TrimGalore-0.6.10/trim_galore"
}

while getopts ":hi:o:t:" opt; do
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

while read -r r1_file && read -r r2_file; do
    # Run the trim_galore command
    "${path_to_trim_galore}" --paired --quality 20 --length 20 --cores 4 --fastqc -o "$output_dir" "$r1_file" "$r2_file"

    echo "Processed: $r1_file and $r2_file"
done < "$input_file"

