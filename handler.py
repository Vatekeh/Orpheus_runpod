import runpod
from orpheus_tts import OrpheusModel
import wave
import io
import base64
import os
import time

# --- Configuration ---
# Determine model name (can be set via environment variable or default)
MODEL_NAME = os.environ.get("MODEL_NAME", "canopylabs/orpheus-tts-0.1-finetune-prod") 
DEFAULT_VOICE = "tara" # Default voice if not specified in input

# --- Model Loading ---
# Initialize the model globally so it's loaded only once
print(f"Loading model: {MODEL_NAME}...")
start_load_time = time.time()
model = OrpheusModel(model_name=MODEL_NAME)
print(f"Model loaded in {time.time() - start_load_time:.2f} seconds.")

# --- Core Function ---
def text_to_base64_audio(text, voice=DEFAULT_VOICE):
    """Converts text to audio using the loaded Orpheus model and returns base64 encoded WAV."""
    print(f"Generating speech for text: '{text[:50]}...' with voice: '{voice}'")
    start_gen_time = time.time()
    
    # Generate speech tokens (streaming)
    syn_tokens = model.generate_speech(
        prompt=text,
        voice=voice,
    )

    audio_buffer = io.BytesIO()
    total_frames = 0
    
    # Create WAV file in memory
    with wave.open(audio_buffer, "wb") as wf:
        wf.setnchannels(1)  # mono
        wf.setsampwidth(2)  # 16-bit (2 bytes per sample)
        wf.setframerate(24000) # Orpheus sample rate

        # Write audio chunks as they arrive
        for audio_chunk in syn_tokens:
            if audio_chunk: # Ensure chunk is not empty
                wf.writeframes(audio_chunk)
                total_frames += len(audio_chunk) // (wf.getsampwidth() * wf.getnchannels())

    duration = total_frames / wf.getframerate() if wf.getframerate() > 0 else 0
    print(f"Generated {duration:.2f} seconds of audio in {time.time() - start_gen_time:.2f} seconds.")

    # Get the binary audio data and convert to base64
    audio_data = audio_buffer.getvalue()
    return base64.b64encode(audio_data).decode('utf-8')

# --- RunPod Handler ---
def handler(job):
    """
    RunPod serverless handler function.
    Takes text input and returns base64 encoded audio.
    """
    job_input = job.get("input", {})

    text = job_input.get("text")
    if not text:
        return {"error": "Missing 'text' field in input"}

    voice = job_input.get("voice", DEFAULT_VOICE)

    print(f"Processing job ID: {job.get('id')}")

    try:
        audio_base64 = text_to_base64_audio(text, voice)
        return {"audio_base64": audio_base64}
    except Exception as e:
        print(f"Error processing job {job.get('id')}: {e}")
        # Consider more specific error handling/logging here
        return {"error": f"Failed to generate audio: {str(e)}"}

# --- Server Start ---
if __name__ == "__main__":
    print("Starting RunPod serverless worker...")
    runpod.serverless.start({"handler": handler}) 