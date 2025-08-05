#!/bin/bash

# Check if correct number of arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 file2.txt"
    exit 1
fi

FILE2="$1"
if [ ! -f "$FILE2" ]; then
    echo "Error: File $FILE2 does not exist"
    exit 1
fi

# Create a temporary file for phonemes
TEMP_PHONEMES=$(mktemp)

# Extract phonemes from the second file, skipping the first word
awk '{for(i=2;i<=NF;i++) print $i}' "$FILE2" | sort -u > "$TEMP_PHONEMES"

# Move the sorted, unique phonemes to the output file
mv "$TEMP_PHONEMES" "${FILE2}.phonemes_sorted"

echo "Sorted phonemes written to ${FILE2}.phonemes_sorted"
