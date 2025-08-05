#!/bin/bash

# Check if correct number of arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 file1.txt file2.txt output.txt"
    exit 1
fi

FILE1="$1"
FILE2="$2"
OUTPUT="$3"

# Check if files exist
if [ ! -f "$FILE1" ]; then
    echo "Error: File $FILE1 does not exist"
    exit 1
fi

if [ ! -f "$FILE2" ]; then
    echo "Error: File $FILE2 does not exist"
    exit 1
fi

# Create a temporary file to store the symbol mapping
TEMP_MAP=$(mktemp)

# Create integer-to-symbol mapping
while read -r symbol integer; do
    trimmed_symbol=${symbol%??}
    echo "$integer $trimmed_symbol" >> "$TEMP_MAP"
done < "$FILE2"

# Create a temporary file for results
TEMP_RESULT=$(mktemp)

# Process file1 and maintain order
awk -v mapfile="$TEMP_MAP" '
    BEGIN {
        # Load the mapping file
        while ((getline line < mapfile) > 0) {
            split(line, parts, " ");
            int_to_symbol[parts[1]] = parts[2];
        }
        close(mapfile);
        
        # Initialize variables
        current_fileid = "";
        symbols = "";
    }
    
    {
        fileid = $1;
        integer = $5;  # The integer is the 5th field
        
        # If this is a new fileid, output the previous one
        if (fileid != current_fileid && current_fileid != "") {
            print current_fileid, symbols;
            symbols = "";
        }
        
        # Update current_fileid
        current_fileid = fileid;
        
        # Add the symbol for this integer if it exists
        if (integer in int_to_symbol) {
            if (symbols == "") {
                symbols = int_to_symbol[integer];
            } else {
                symbols = symbols " " int_to_symbol[integer];
            }
        }
    }
    
    END {
        # Print the last fileid and its symbols
        if (current_fileid != "") {
            print current_fileid, symbols;
        }
    }
' "$FILE1" > "$TEMP_RESULT"

# Write to output file
cat "$TEMP_RESULT" > "$OUTPUT"

# Clean up temporary files
rm "$TEMP_MAP" "$TEMP_RESULT"

echo "Output written to $OUTPUT"
