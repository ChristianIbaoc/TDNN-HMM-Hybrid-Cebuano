#!/usr/bin/env python3
import os
import sys

if len(sys.argv) != 2:
    print("Usage: python3 convert_to_relative.py /path/to/Output.txt")
    sys.exit(1)

input_path = sys.argv[1]
output_path = os.path.join(os.path.dirname(input_path), "RelativeLengths.txt")

with open(input_path, 'r') as infile, open(output_path, 'w') as outfile:
    current_word = None
    syllables = []
    durations = []

    for line in infile:
        stripped = line.strip()
        if not stripped:
            # end of current word
            if current_word and syllables and durations:
                total = sum(durations)
                outfile.write(f"{current_word}\n")
                for s, d in zip(syllables, durations):
                    relative = d / total if total > 0 else 0
                    outfile.write(f"  {s}: {relative:.4f}\n")
                outfile.write("\n")
            # reset
            current_word = None
            syllables = []
            durations = []
        elif '(' in stripped and ')' in stripped:
            # word header line
            current_word = stripped
        elif ':' in stripped:
            try:
                syll, dur = stripped.split(':')
                syll = syll.strip()
                dur = float(dur.strip())
                syllables.append(syll)
                durations.append(dur)
            except ValueError:
                continue

    # process last word if file doesn't end with newline
    if current_word and syllables and durations:
        total = sum(durations)
        outfile.write(f"{current_word}\n")
        for s, d in zip(syllables, durations):
            relative = d / total if total > 0 else 0
            outfile.write(f"  {s}: {relative:.4f}\n")
        outfile.write("\n")

print(f"✅ Relative durations written to: {output_path}")

