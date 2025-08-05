import os
import re
import sys
import time
from concurrent.futures import ProcessPoolExecutor
from pydub.utils import mediainfo

def process_folder(folder_path, exemption):
    """Process a single folder and return data for all files"""
    if folder_path == exemption:
        return None
    
    results = {
        'segments': [],
        'text': [],
        'utt2spk': [],
        'wav_scp': [],
        'reco2file': []
    }
    
    # Get all subdirectories in the folder
    for file in os.listdir(folder_path):
        subfolder_path = os.path.join(folder_path, file)
        if not os.path.isdir(subfolder_path):
            continue
            
        word_to_split = re.split("_", file)
        word_to_note = " ".join(word_to_split)
        if word_to_note in ["WalaLeft", "WalaZero"]:
            word_to_note = "Wala"
            
        print(f"Working on folder: {subfolder_path}\n with words: {word_to_note}\n")
        
        # Get all WAV files
        wav_files = [f for f in os.listdir(subfolder_path) if f.endswith(".wav")]
        
        corpus_words = [word_to_note]
        
        for wav_file in wav_files:
            file_path = os.path.join(subfolder_path, wav_file)
            file_base = os.path.splitext(wav_file)[0]
            
            # Process the filename once
            match = re.match(r"(\D*)(\d+)([a-zA-Z-0-9]+)", file_base)
            if match:
                utt_id = match.group(1)
                letter = match.group(2)
                number = match.group(3)
                utterance = f"{number}{letter}-{utt_id}"
            else:
                print(f"Warning: Could not parse filename: {file_base}")
                continue
                
            # Get duration
            try:
                info = mediainfo(file_path)
                duration = float(info["duration"])  # Duration in seconds
            except Exception as e:
                print(f"Error getting duration for {file_path}: {e}")
                continue
                
            # Prepare data for files
            results['text'].append(f"{utterance} {word_to_note}")
            results['segments'].append(f"{utterance} {file_base} 0.0 {duration:.4f}")
            results['wav_scp'].append(f"{file_base} {subfolder_path}/{wav_file}")
            results['utt2spk'].append(f"{utterance} {number}{letter}")
            results['reco2file'].append(f"{file_base} {subfolder_path}/{wav_file} A")
            
    return {
        'results': results,
        'corpus': set(corpus_words)
    }

def write_results_to_files(all_results):
    """Write all results to their respective files"""
    # Initialize files
    file_names = ['segments', 'text', 'utt2spk', 'wav.scp', 'reco2file_and_channel', 'corpus']
    for file_name in file_names:
        with open(file_name, 'w') as f:
            pass  # Just create/clear the file
    
    # Combine all results
    combined_corpus = set()
    
    for result in all_results:
        if result is None:
            continue
            
        # Add to corpus set
        combined_corpus.update(result['corpus'])
        
        # Write each type of result to the corresponding file
        with open('segments', 'a') as f:
            f.write('\n'.join(result['results']['segments']) + '\n')
            
        with open('text', 'a') as f:
            f.write('\n'.join(result['results']['text']) + '\n')
            
        with open('utt2spk', 'a') as f:
            f.write('\n'.join(result['results']['utt2spk']) + '\n')
            
        with open('wav.scp', 'a') as f:
            f.write('\n'.join(result['results']['wav_scp']) + '\n')
            
        with open('reco2file_and_channel', 'a') as f:
            f.write('\n'.join(result['results']['reco2file']) + '\n')
    
    # Write corpus file
    with open('corpus', 'w') as f:
        f.write('\n'.join(sorted(combined_corpus)) + '\n')

def LAYITALLOUT(exemption):
    start_time = time.time()
    
    all_folders = [
        "/mnt/KINGSTON/Kaldi/kaldi/egs/phoneTest/samples1/",
        "/mnt/KINGSTON/Kaldi/kaldi/egs/phoneTest/samples2/",
        "/mnt/KINGSTON/Kaldi/kaldi/egs/phoneTest/samples3/",
        "/mnt/KINGSTON/Kaldi/kaldi/egs/phoneTest/samples4/",
        "/mnt/KINGSTON/Kaldi/kaldi/egs/phoneTest/samples5/",
        "/mnt/KINGSTON/Kaldi/kaldi/egs/phoneTest/samples6/",
        "/mnt/KINGSTON/Kaldi/kaldi/egs/phoneTest/samples7/",
        "/mnt/KINGSTON/Kaldi/kaldi/egs/phoneTest/samples8/",
        "/mnt/KINGSTON/Kaldi/kaldi/egs/phoneTest/samples9/",
        "/mnt/KINGSTON/Kaldi/kaldi/egs/phoneTest/samples10/"
    ]
    
    # Use ProcessPoolExecutor for parallel processing
    max_workers = min(os.cpu_count(), len(all_folders))
    print(f"Using {max_workers} processes for parallel processing")
    
    with ProcessPoolExecutor(max_workers=max_workers) as executor:
        # Submit tasks
        futures = [executor.submit(process_folder, folder, exemption) for folder in all_folders]
        
        # Collect results
        all_results = [future.result() for future in futures]
    
    # Write results to files
    write_results_to_files(all_results)
    
    elapsed_time = time.time() - start_time
    print(f"Processing completed in {elapsed_time:.2f} seconds")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python prep.py exemptionDIR")
        sys.exit(1)
    
    input_file = sys.argv[1]
    LAYITALLOUT(input_file)
