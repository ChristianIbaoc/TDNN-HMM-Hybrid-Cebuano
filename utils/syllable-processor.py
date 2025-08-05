#!/usr/bin/env python3
import os
import sys
import math
from collections import defaultdict

if len(sys.argv) != 3:
    print("Usage: python3 analyze_ctm_debug.py /path/to/input.ctm /path/to/referenceW2Syll.txt")
    sys.exit(1)

ctm_path = sys.argv[1]
wordref_path = sys.argv[2]
output_path = os.path.join(os.path.dirname(ctm_path), "Output.txt")

# === Special-case mapping ===
special_cases = {
    "WalaLeft": "Wala",
    "WalaZero": "Wala"
}

# === Load word-to-syllable mapping with disambiguated duplicates ===
def disambiguate_syllables(syllables):
    count = defaultdict(int)
    result = []
    for s in syllables:
        count[s] += 1
        if count[s] == 1:
            result.append(s)
        else:
            result.append(f"{s}_{count[s]}")
    return result

word_to_syllables = {}
with open(wordref_path, 'r') as f:
    for line in f:
        parts = line.strip().split()
        if len(parts) >= 2:
            word = parts[0]
            syllables = disambiguate_syllables(parts[1:])
            word_to_syllables[word] = syllables

# Manually copy reference syllables for special-case words
for special, real in special_cases.items():
    if real in word_to_syllables:
        word_to_syllables[special] = word_to_syllables[real]

# === Data structures ===
# data[word][syllable] = list of durations
data = defaultdict(lambda: defaultdict(list))
word_syllable_count = {}  # Tracks number of syllables per word
matched_sylls = []
# === Helper function to flush buffered syllables ===
def flush_word_data(word_id, sylls, durs):
    word_parts = word_id.split('_')
    syll_index = 0
    ref_index=0
    for word in word_parts:
        if word not in word_to_syllables:
            print(f"[WARN] Word not in reference: {word}")
            continue
        ref_sylls = word_to_syllables[word]
        word_syllable_count[word] = len(ref_sylls)
        print(f"\n[INFO] Processing word: {word}")
        print(f"       Reference syllables: {ref_sylls}")
        print(f"\n       User syllables: {sylls}")
        matched_sylls = []
        s=0;
        while s < len(ref_sylls):
            if syll_index >= len(durs):
                print(f"[WARN] Not enough syllables in CTM for {word}")
                break
            
            if ref_sylls[s] == sylls[syll_index]:
                dur = durs[syll_index]
                data[word][s].append(dur)
                matched_sylls.append((sylls[syll_index], dur))
                syll_index += 1
                s+=1
            else:
                syll_index+=1
        data[word]['count'].append(1)  # Append 1 for counting samples
        print(f"       Matched durations: {matched_sylls}")

# === Parse CTM ===
current_word_id = None
syllable_buffer = []
duration_buffer = []

with open(ctm_path, 'r') as f:
    for line in f:
        parts = line.strip().split()
        if len(parts) < 5:
            continue

        path, _, start, duration, syllable = parts
        duration = float(duration)

        try:
            word_id = path.split('/')[3]
        except IndexError:
            continue

        if current_word_id and word_id != current_word_id:
            flush_word_data(current_word_id, syllable_buffer, duration_buffer)
            syllable_buffer = []
            duration_buffer = []

        current_word_id = word_id
        syllable_buffer.append(syllable)
        duration_buffer.append(duration)

# Flush last word
if current_word_id and syllable_buffer:
    flush_word_data(current_word_id, syllable_buffer, duration_buffer)

# === Output with standard deviation ===
with open(output_path, 'w') as out:
    for word in sorted(data):
        syll_count = word_syllable_count.get(word, 1)
        count = sum(data[word].pop('count', [1]))
        divisor = count / syll_count
        print(f"{word} (samples: {count}, syllables: {syll_count}, divisor: {divisor:.2f}):\n")
        out.write(f"{word} (samples: {count}, syllables: {syll_count}, divisor: {divisor:.2f}):\n")
        n=0
        for syll in word_to_syllables.get(word, []):
            durations = data[word][n]
            print(durations)
            if durations:
                mean = sum(durations)
                #stddev = math.sqrt(sum((d - mean) ** 2 for d in durations) / len(durations)) if len(durations) > 1 else 0.0
                print(f"  {syll}: {mean:.4f}\n")
                out.write(f"  {syll}: {mean:.4f}\n")
            n+=1
        out.write("\n")

print(f"\n✅ Output written to: {output_path}")

