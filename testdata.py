import os
import shutil
from pathlib import Path

# Get the current directory where script is located
script_dir = Path(__file__).parent

# Get all subfolders in samples directory
samples_dir = script_dir / 'samples'
testings_dir = script_dir / 'testings'

# Loop through each subfolder in samples
for folder in samples_dir.iterdir():
    if folder.is_dir():
        folder_name = folder.name
        
        # Create matching folder in testings
        new_folder = testings_dir / folder_name
        new_folder.mkdir(parents=True, exist_ok=True)
        
        # Get all WAV files in current folder
        wav_files = list(folder.glob('*.wav'))
        
        # Move first 2 WAV files (modify number as needed)
        for wav_file in wav_files[:2]:
            destination = new_folder / wav_file.name
            shutil.move(str(wav_file), str(destination))
            print(f"Moved: {wav_file} -> {destination}")
