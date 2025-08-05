#!/bin/bash
shuf exp/chain/tdnn1_sp/decode_test_sw1_tg/scoring/2.0.5.txt | head -n 200 | sort -t- -k2.1 > trimmed.txt

# Check input
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <keyword_folders_path> <text_file>"
  exit 1
fi

KEYWORD_DIR="$1"
TEXT_FILE="$2"
DEST_DIR="matched_audio"
CSV_FILE="copied_files.csv"

mkdir -p "$DEST_DIR"
echo "Filename,Source Folder" > "$CSV_FILE"  # CSV header

while read -r line; do
  # Skip empty lines
  [ -z "$line" ] && continue

  # Get first word only (e.g., f20-maayongbuntag)
  first_word=$(echo "$line" | awk '{print $1}')

  gender_id="${first_word%%-*}"      # f20
  keyword_name="${first_word#*-}"    # maayongbuntag

  gender="${gender_id:0:1}"          # f
  id="${gender_id:1}"                # 20

  filename="${keyword_name}${id}${gender}.wav"  # e.g., maayongbuntag20f.wav

  match_found=false
  for folder in "$KEYWORD_DIR"/*/; do
    if [ -f "${folder}${filename}" ]; then
      cp "${folder}${filename}" "$DEST_DIR/"
      echo "Copied: $filename"
      echo "$filename,${folder%/}" >> "$CSV_FILE"  # Add to CSV (strip trailing slash)
      match_found=true
      break
    fi
  done

  if ! $match_found; then
    echo "Missing: $filename" >&2
  fi

done < "$TEXT_FILE"

echo "Done. Files copied to $DEST_DIR/"
echo "CSV created: $CSV_FILE"

