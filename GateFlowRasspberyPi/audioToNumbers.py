from pydub import AudioSegment
import speech_recognition as sr
import os

class audioToNumbers:
    def convert_m4a_to_wav(self, m4a_path, target_path):
        # Load the M4A file
        audio = AudioSegment.from_file(m4a_path, format="m4a")
        # Export as WAV after processing
        audio.export(target_path, format="wav")

    def transcribe_audio(self, audio_path):
        # Initialize the recognizer
        recognizer = sr.Recognizer()
        
        # Load the audio file
        with sr.AudioFile(audio_path) as source:
            audio_data = recognizer.record(source)
        
        # Try to recognize the speech using Google Speech Recognition
        try:
            # Recognize the speech
            text = recognizer.recognize_google(audio_data, language='eng')
            # Extract numbers only from the recognized text
            numbers = ''.join(filter(str.isdigit, text))
            return numbers
        except sr.UnknownValueError:
            return "Google Speech Recognition could not understand audio"
        except sr.RequestError as e:
            return f"Could not request results from Google Speech Recognition service; {e}"

    def main(self, m4a_path):
        wav_path = "temp_audio.wav"
        self.convert_m4a_to_wav(m4a_path, wav_path)
        transcription = self.transcribe_audio(wav_path)
        print(f"Transcription: {transcription}")
        # Delete
