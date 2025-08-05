#!/bin/bash

SEARCH_DIRS=("exp/mono/decode" "exp/tri1/decode" "exp/tri2/decode" "exp/tri3/decode" 
"exp/tri3/decode.si/" 
"exp/tri3_mm0.1/decode_eval_1.mdl_sw1_tg" 
"exp/tri3_mm0.1/decode_eval_2.mdl_sw1_tg" 
"exp/tri3_mm0.1/decode_eval_3.mdl_sw1_tg" 
"exp/tri3_mm0.1/decode_eval_4.mdl_sw1_tg"
"exp/tri3_fmmi_b0.1/decode_eval_it1_sw1_tg" 
"exp/tri3_fmmi_b0.1/decode_eval_it2_sw1_tg" 
"exp/tri3_fmmi_b0.1/decode_eval_it3_sw1_tg"
"exp/tri3_fmmi_b0.1/decode_eval_it4_sw1_tg"
"exp/chain/tdnn1_sp/decode_test_sw1_tg" "exp/chain/tdnn1_sp_online/decode_test_sw1_tg"
"exp/chain/tdnn1_sp/decode_demoaug" "exp/chain/tdnn1_sp_online/decode_demoaug" 
)

# Predefined list of directories to search

# Create output file with timestamp
OUTPUT_FILE=/mnt/KINGSTON/Kaldi/kaldi/egs/phoneTest/allBestWERS.txt

# Temporary file to store results
TEMP_RESULTS=$(mktemp)

# Function to find lowest WER in a directory
find_lowest_wer() {
    local dir="$1"
    local output_file="$2"
    
    # Temporary file to store results for this directory
    local TEMP_RESULTS=$(mktemp)
    
    # Find files in scoring subdirectory
    find "$dir" -type f -regextype posix-extended -regex ".*wer_[0-9]+_[0-9]+\.[0-9]+" -print0 | while read -r -d $'\0' filepath; do
        # Extract WER value from the file content
        wer=$(grep -o "%WER [0-9.]*" "$filepath" | awk '{print $2}')
        
        # Ensure it's a valid number
        if [[ "$wer" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            echo "$wer $filepath" >> "$TEMP_RESULTS"
        fi
    done
    
    # If any WER files found, append the lowest to output
    if [ -s "$TEMP_RESULTS" ]; then
        # Sort and get lowest WER file
        lowest=$(sort -g "$TEMP_RESULTS" | head -n 1)
        read -r lowest_wer lowest_file <<< "$lowest"
        
        # Append results to output file
        {
            echo "Directory: $dir"
            echo "Lowest WER: $lowest_wer"
            echo "File: $lowest_file"
            echo "Full content:"
            cat "$lowest_file"
            echo "---"  # Separator between entries
        } >> "$output_file"
        
        echo "Lowest WER for $dir: $lowest_file : $lowest_wer" >&2
    else
        echo "No WER found in $dir" >&2
    fi
    
    # Clean up temporary file
    rm "$TEMP_RESULTS"
}

# Truncate output file (start fresh)
> "$OUTPUT_FILE"

# Loop through predefined directories
for search_dir in "${SEARCH_DIRS[@]}"; do
    # Check if directory exists
    if [ -d "$search_dir" ]; then
        echo "Searching in $search_dir" >&2
        find_lowest_wer "$search_dir" "$OUTPUT_FILE"
    else
        echo "Directory not found: $search_dir" >&2
    fi
done

echo "Results written to $OUTPUT_FILE"
