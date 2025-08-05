import os
import shutil
import random
from collections import defaultdict
import math

def split_wav_files(source_dir, num_splits=4):
    """
    Split wav files from keyword folders in the source directory into 
    multiple sample directories, distributing files equally and randomly.
    
    Args:
        source_dir: Path to the source directory containing keyword folders
        num_splits: Number of target directories to create
    """
    # Create target directories
    target_dirs = []
    for i in range(1, num_splits + 1):
        target_dir = os.path.join(os.path.dirname(source_dir), f"{os.path.basename(source_dir)}{i}")
        if not os.path.exists(target_dir):
            os.makedirs(target_dir)
        target_dirs.append(target_dir)
    
    # Get all keyword folders
    keyword_folders = [f for f in os.listdir(source_dir) 
                       if os.path.isdir(os.path.join(source_dir, f))]
    
    print(f"Found {len(keyword_folders)} keyword folders in {source_dir}")
    
    # Process each keyword folder
    for keyword in keyword_folders:
        keyword_path = os.path.join(source_dir, keyword)
        wav_files = [f for f in os.listdir(keyword_path) 
                    if f.endswith('.wav') and os.path.isfile(os.path.join(keyword_path, f))]
        
        # Calculate how many files should go to each target directory
        total_files = len(wav_files)
        files_per_target = math.ceil(total_files / num_splits)
        
        print(f"Keyword: {keyword}, Found {total_files} wav files")
        
        # Shuffle wav files for random distribution
        random.shuffle(wav_files)
        
        # Distribute files across target directories
        file_distribution = defaultdict(list)
        for i, wav_file in enumerate(wav_files):
            target_index = i % num_splits
            file_distribution[target_index].append(wav_file)
        
        # Create keyword folders in target directories and copy files
        for target_idx, target_dir in enumerate(target_dirs):
            # Create keyword folder in the target directory
            target_keyword_dir = os.path.join(target_dir, keyword)
            if not os.path.exists(target_keyword_dir):
                os.makedirs(target_keyword_dir)
            
            # Copy files assigned to this target
            for wav_file in file_distribution[target_idx]:
                src_file = os.path.join(keyword_path, wav_file)
                dst_file = os.path.join(target_keyword_dir, wav_file)
                shutil.copy2(src_file, dst_file)
            
            print(f"  Copied {len(file_distribution[target_idx])} files to {target_keyword_dir}")

if __name__ == "__main__":
    # Path to the samples directory - adjust this to your actual path
    samples_dir = "samples"  # Change this to your actual path
    
    # Run the function to split files
    split_wav_files(samples_dir, 10)
    
    print("File splitting completed successfully!")
