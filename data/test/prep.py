import os
import re
import sys
import time
from concurrent.futures import ProcessPoolExecutor
from pydub.utils import mediainfo

def process_folder(folder_name, base_dir):
    """Process a single folder and return data for all files"""
    folder_path = os.path.join(base_dir, folder_name)
    
    # Skip the Manual folder
    word_to_split = re.split("_", folder_name)
    word_to_note = " ".join(word_to_split)
    if word_to_note == "Manual":
        return None
        
    if word_to_note in ["WalaLeft", "WalaZero"]:
        word_to_note = "Wala"
        
    print(f"Working on folder: {folder_path}\n with words: {word_to_note}\n")
    
    results = {
        'segments': [],
        'text': [],
        'utt2spk': [],
        'wav_scp': [],
        'reco2file': []
    }
    
    # Get all WAV files
    wav_files = [f for f in os.listdir(folder_path) if f.endswith(".wav")]
    
    # Process each WAV file
    for wav_file in wav_files:
        file_path = os.path.join(folder_path, wav_file)
        file_base = os.path.splitext(wav_file)[0]
        
        # Process the filename once
        match = re.match(r"(\D*)(\d+)([a-zA-Z-0-9]+)", file_base)
        if not match:
            print(f"Warning: Could not parse filename: {file_base}")
            continue
            
        utt_id = match.group(1)
        letter = match.group(2)
        number = match.group(3)
        utterance = f"{number}{letter}-{utt_id}"
        
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
        results['wav_scp'].append(f"{file_base} {folder_path}/{wav_file}")
        results['utt2spk'].append(f"{utterance} {number}{letter}")
        results['reco2file'].append(f"{file_base} {folder_path}/{wav_file} A")
        
    return {
        'results': results,
        'corpus': word_to_note
    }

def write_results_to_files(all_results):
    """Write all results to their respective files"""
    # Initialize files
    file_names = ['segments', 'text', 'utt2spk', 'wav.scp', 'reco2file_and_channel']
    for file_name in file_names:
        with open(file_name, 'w') as f:
            pass  # Just create/clear the file
    
    # Clear corpus file
    with open('corpus', 'w') as f:
        pass
    
    # Combine all results
    corpus_words = set()
    
    for result in all_results:
        if result is None:
            continue
            
        # Add to corpus set
        if result['corpus']:
            corpus_words.add(result['corpus'])
            with open('corpus', 'a') as f:
                f.write(f"{result['corpus']}\n")
        
        # Write each type of result to the corresponding file
        with open('segments', 'a') as f:
            f.write('\n'.join(result['results']['segments']) + '\n' if result['results']['segments'] else '')
            
        with open('text', 'a') as f:
            f.write('\n'.join(result['results']['text']) + '\n' if result['results']['text'] else '')
            
        with open('utt2spk', 'a') as f:
            f.write('\n'.join(result['results']['utt2spk']) + '\n' if result['results']['utt2spk'] else '')
            
        with open('wav.scp', 'a') as f:
            f.write('\n'.join(result['results']['wav_scp']) + '\n' if result['results']['wav_scp'] else '')
            
        with open('reco2file_and_channel', 'a') as f:
            f.write('\n'.join(result['results']['reco2file']) + '\n' if result['results']['reco2file'] else '')

def LAYITALLOUT(input_dir):
    start_time = time.time()
    
    # Make sure input_dir ends with a slash
    if not input_dir.endswith('/'):
        input_dir += '/'
    
    # Get list of folders to process
    folder_names = [f for f in os.listdir(input_dir) if os.path.isdir(os.path.join(input_dir, f))]
    
    # Use ProcessPoolExecutor for parallel processing
    max_workers = min(os.cpu_count(), len(folder_names))
    print(f"Using {max_workers} processes for parallel processing")
    
    with ProcessPoolExecutor(max_workers=max_workers) as executor:
        # Submit tasks
        futures = [executor.submit(process_folder, folder, input_dir) for folder in folder_names]
        
        # Collect results
        all_results = [future.result() for future in futures]
    
    # Write results to files
    write_results_to_files(all_results)
    
    elapsed_time = time.time() - start_time
    print(f"Processing completed in {elapsed_time:.2f} seconds")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python prep.py testDIR")
        sys.exit(1)
    
    input_file = sys.argv[1]
    LAYITALLOUT(input_file)
