#!/bin/bash

# Input file
INPUT="Model Transcript.txt"
# Output CSV file
OUTPUT="output.csv"

# Clear the output file if it exists
> "$OUTPUT"

# Process each line
while IFS= read -r line; do
    # Extract the first field (e.g., f6-akoa)
    first_field=$(echo "$line" | awk '{print $1}')
    
    # Separate letter, number, and word
    letter=$(echo "$first_field" | grep -o '^[a-zA-Z]')
    number=$(echo "$first_field" | grep -o '[0-9]\+')
    word=$(echo "$first_field" | cut -d'-' -f2)

    # Construct the new filename
    new_filename="${word}${number}${letter}.wav"

    # Output to CSV
    echo "$new_filename" >> "$OUTPUT"
done < "$INPUT"

