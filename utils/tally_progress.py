import os
import json
import csv
import sys

def categorize_value(value):
    if '2' in value:
        return '2'
    elif '3' in value:
        return '3'
    else:
        return '1'

def process_json_files(folder_path):
    tally = {}

    for filename in os.listdir(folder_path):
        if filename.endswith(".json"):
            filepath = os.path.join(folder_path, filename)
            with open(filepath, 'r') as file:
                data = json.load(file)
                progress = data.get("progress", {})
                for keyword, value in progress.items():
                    category = categorize_value(value)
                    if keyword not in tally:
                        tally[keyword] = {'1': 0, '2': 0, '3': 0}
                    tally[keyword][category] += 1

    return tally

def write_to_csv(tally, output_file='output.csv'):
    with open(output_file, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(['Keyword', 'Count_1s', 'Count_2s', 'Count_3s'])
        for keyword, counts in sorted(tally.items()):
            writer.writerow([keyword, counts['1'], counts['2'], counts['3']])

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py /path/to/folder")
        sys.exit(1)

    folder_path = sys.argv[1]
    tally = process_json_files(folder_path)
    write_to_csv(tally)
    print("CSV output written to 'output.csv'")

