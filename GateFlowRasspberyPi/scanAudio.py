from speechbrain.pretrained import SpeakerRecognition
import torchaudio
import torchaudio.transforms as T
import noisereduce as nr
import torch
import numpy as np
import ffmpeg
from scipy.signal import butter, sosfilt

class scanAudio:
    @staticmethod
    def convert_to_wav(audio_path):
        """Converts an audio file to PCM WAV (16-bit, 16kHz, mono) using ffmpeg."""
        output_path = audio_path.rsplit(".", 1)[0] + "_fixed.wav"
        try:
            (
                ffmpeg.input(audio_path)
                .output(output_path, acodec="pcm_s16le", ar=16000, ac=1)
                .run(overwrite_output=True, quiet=True)
            )
            return output_path
        except Exception as e:
            print(f"Error converting {audio_path}: {e}")
            return None

    @staticmethod
    def butter_bandpass(lowcut, highcut, fs, order=5):
        """Creates a bandpass filter for the given parameters."""
        sos = butter(order, [lowcut, highcut], btype='band', fs=fs, output='sos')
        return sos

    @staticmethod
    def load_and_preprocess(audio_path):
        """Loads and preprocesses the audio for comparison."""
        wav_path = scanAudio.convert_to_wav(audio_path)
        if wav_path is None:
            return None, None

        try:
            signal, sr = torchaudio.load(wav_path)
        except Exception as e:
            print(f"Error loading {wav_path}: {e}")
            return None, None

        if sr != 16000:
            resample = T.Resample(orig_freq=sr, new_freq=16000)
            signal = resample(signal)

        signal_np = signal.numpy().squeeze()
        reduced_noise = nr.reduce_noise(y=signal_np, sr=16000)
        sos = scanAudio.butter_bandpass(300, 3400, 16000)
        filtered_signal = sosfilt(sos, reduced_noise)
        signal_torch = torch.tensor(filtered_signal).unsqueeze(0)
        signal_torch = signal_torch / torch.max(torch.abs(signal_torch) + 1e-6)

        return signal_torch, 16000

    @staticmethod
    def compare_speakers(audio_path1, audio_path2, threshold=0.6):
        """Compares two audio files and returns True if they are from the same speaker."""
        try:
            verification = SpeakerRecognition.from_hparams(
                source="speechbrain/spkrec-ecapa-voxceleb", 
                savedir="tmpdir"
            )
        except Exception as e:
            print(f"Error loading SpeakerRecognition model: {e}")
            return False

        signal1, sr1 = scanAudio.load_and_preprocess(audio_path1)
        signal2, sr2 = scanAudio.load_and_preprocess(audio_path2)

        if signal1 is None or signal2 is None:
            return False

        score, prediction = verification.verify_batch(signal1, signal2)
        similarity_score = score.item()
        print(f"Similarity Score: {similarity_score:.4f}")

        return similarity_score > threshold
