#!/usr/bin/env python3
import pyaudio
import wave
import threading
import time
import os
import sys
import numpy as np
import shutil
import subprocess
import re

wordTitle = "bananaboi"
word = "changeToWord1m"
duration = 0
silenced_path =""
def record_audio(wordTitle):
    save_directory = f"/mnt/KINGSTON/Kaldi/kaldi/egs/phoneTest/demo/"
    wordToSplit = re.split("_",wordTitle)
    space = ""
    wordFile=space.join(wordToSplit)
    wordFile=wordFile.lower()
    # Create the main save directory if it doesn't exist
    os.makedirs(save_directory, exist_ok=True)
    
    print(f"Recordings will be saved to: {save_directory}")
    
    # Audio recording parameters
    FORMAT = pyaudio.paInt16
    CHANNELS = 1
    RATE = 48000  # 48kHz sample rate
    CHUNK = 1024
    
    print("Recording script ready!")
    print("Commands:")
    print("  'r'  - Start recording")
    print("  's'  - Stop recording and save")
    print("  'q'  - Quit the program")
    print("  'test' - Test audio levels")
    
    audio = pyaudio.PyAudio()
    recording = False
    frames = []
    recording_thread = None
    
    # Find the right input device
    device_index = 1
    for i in range(audio.get_device_count()):
        info = audio.get_device_info_by_index(i)
        if info["maxInputChannels"] > 0:
            print(f"Input Device {i}: {info['name']}")
            if device_index is None:
                device_index = i  # Default to first found device
    if device_index is None:
        print("No input devices found. Please check your microphone connection.")
        return
    
    print(f"Using device: {audio.get_device_info_by_index(device_index)['name']}")
    
    def test_audio_levels():
        """Test microphone input levels"""
        try:
            stream = audio.open(format=FORMAT, channels=CHANNELS, rate=RATE,
                                input=True, input_device_index=device_index, frames_per_buffer=CHUNK)
            
            print("Testing audio levels for 5 seconds...")
            for _ in range(50):  # 50 * 0.1s = 5 seconds
                data = stream.read(CHUNK, exception_on_overflow=False)
                audio_data = np.frombuffer(data, dtype=np.int16)
                max_level = np.max(np.abs(audio_data)) / 32768.0
                print(f"Level: {'|' * int(max_level * 50)} {max_level:.3f}", end='\r')
                time.sleep(0.1)
            
            print("\nAudio test complete.")
            stream.stop_stream()
            stream.close()
        except Exception as e:
            print(f"Error testing audio: {e}")

    def record_thread():
        nonlocal frames
        try:
            stream = audio.open(format=FORMAT, channels=CHANNELS, rate=RATE,
                                input=True, input_device_index=device_index, frames_per_buffer=CHUNK)
            time.sleep(0.5)  # Allow stabilization
            print("Recording started...")
            while recording:
                data = stream.read(CHUNK, exception_on_overflow=False)
                frames.append(data)
            
            stream.stop_stream()
            stream.close()
            print("Recording stopped.")
        except Exception as e:
            print(f"Error in recording thread: {e}")

    def save_recording():
        global duration 
        global silenced_path
        # timestamp = time.strftime("%Y-%m-%d_%H-%M-%S")
        original_filename = f"{wordFile}.wav"
        silenced_filename = f"{wordFile}.wav"
        
        original_path = os.path.join(save_directory, original_filename)
        silenced_dir = os.path.join(save_directory, wordTitle[:-3])
        os.makedirs(silenced_dir, exist_ok=True)  # Ensure silenced folder exists
        silenced_path = os.path.join(silenced_dir, silenced_filename)

        if frames:
            try:
                print("Saving original recording...")
                wf = wave.open(original_path, 'wb')
                wf.setnchannels(CHANNELS)
                wf.setsampwidth(audio.get_sample_size(FORMAT))
                wf.setframerate(RATE)
                wf.writeframes(b''.join(frames))
                wf.close()
                
                num_frames = len(b''.join(frames)) // audio.get_sample_size(FORMAT)
                duration = num_frames / RATE
                print(f"Original file saved: {original_path} (Duration: {duration:.2f} seconds)")

                # Try adding silence using SoX
                if shutil.which("sox"):
                    try:
                        subprocess.run(["sox", original_path, silenced_path, "pad", "1", "1"], check=True)
                        duration = duration + 2
                        print(f"Silenced file saved: {silenced_path}")
                    except subprocess.SubprocessError as e:
                        print(f"Error adding silence: {e}. Keeping original recording only.")
                else:
                    print("SoX not found. Skipping silence padding.")

            except Exception as e:
                print(f"Error saving recording: {e}")
        else:
            print("No audio data to save")

    try:
        global duration
        global silenced_path
        while True:
            command = input("> ").strip().lower()
            
            if command == 'r' and not recording:
                recording = True
                frames = []
                recording_thread = threading.Thread(target=record_thread)
                recording_thread.start()
                
            elif command == 's' and recording:
                recording = False
                if recording_thread:
                    recording_thread.join()
                save_recording()
                
            elif command == 'test':
                test_audio_levels()
                
            elif command == 'q':
                if recording:
                    recording = False
                    if recording_thread:
                        recording_thread.join()
                    save_recording()
                break
                
            else:
                print("Unknown command. Use 'r' to record, 's' to stop, 'q' to quit, 'test' to check audio levels.")
        match = re.match(r"(\D*)(\d+)([a-zA-Z-0-9]+)", wordTitle)
        word = match.group(1)      
        wordToSplit = re.split("_",word)
        space = " "
        word=space.join(wordToSplit)
        folders = ["segments","text","utt2spk","wav.scp","reco2file_and_channel"]
        print(f"Working on folder: {silenced_path}\n with words: {word}\n")
        # Get all WAV filenames
        with open("corpus","a") as f:
            f.write(f"{word}\n")

        # Write to a text file
        output_text = "text"
        with open(output_text,"a") as f:
            file_base = os.path.splitext(wordFile)[0]
            match = re.match(r"(\D*)(\d+)([a-zA-Z-0-9]+)", file_base)
            if match:
                utt_id = match.group(1)
                letter = match.group(2)
                number = match.group(3)
            else:
                print(f"{file_base}")
            f.write(f"{number}{letter}-{utt_id} {word}\n")
        print(f"Text Saved to {output_text}")

        output_file = "segments"
        with open(output_file, "a") as f:
            file_base = os.path.splitext(wordFile)[0]
            match = re.match(r"(\D*)(\d+)([a-zA-Z-0-9]+)", file_base)
            utt_id = match.group(1)
            letter = match.group(2)
            number = match.group(3)
            f.write(f"{number}{letter}-{utt_id} {file_base} 0.0 {duration:.4f}\n")
        print(f"Segments saved to {output_file}")

        output_wavs = "wav.scp"
        with open(output_wavs,"a") as f:
            file_base = os.path.splitext(wordFile)[0]
            f.write(f"{file_base} {silenced_path}\n")
        print(f"WAVscps saved to {output_wavs}")

        output_spks = "utt2spk"
        with open(output_spks,"a") as f:
            file_base = os.path.splitext(wordFile)[0]
            match = re.match(r"(\D*)(\d+)([a-zA-Z-0-9]+)", file_base)
            utt_id = match.group(1)
            letter = match.group(2)
            number = match.group(3)
            f.write(f"{number}{letter}-{utt_id} {number}{letter}\n")
        print(f"UTT2SPKs saved to {output_spks}")
        
        output_reco= "reco2file_and_channel"
        with open(output_reco,"a") as f:
            file_base = os.path.splitext(wordFile)[0]
            f.write(f"{file_base} {silenced_path} A\n")
        
    except KeyboardInterrupt:
        print("\nInterrupted by user")
    finally:
        if recording:
            recording = False
            if recording_thread and recording_thread.is_alive():
                recording_thread.join()
        audio.terminate()
        print("Recording program terminated.")
    

if __name__ == "__main__":
    # Check if SoX is installed
    if not shutil.which("sox"):
        print("Warning: SoX not found. Install with: sudo apt-get install sox")

    if len(sys.argv) != 2:
        print("Usage: python script.py word")
        sys.exit(1)
    
    word = sys.argv[1]
    record_audio(word)

