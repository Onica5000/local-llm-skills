---
name: audio-sox-tts
description: Use for audio editing (convert, trim, merge, normalize, effects, generate tones) with SoX, and for text-to-speech / voice cloning with XTTS-v2 (local) or edge-tts (fast online).
---

# audio-sox-tts

## SoX 14.4.2 â€” audio swiss-army knife
> Windows SoX ships only `sox.exe`. No `soxi`/`play`/`rec`. Use `sox --info` and FFmpeg/ffplay for playback.
```powershell
sox input.mp3 output.wav                       # convert format
sox input.wav -r 48000 -b 24 output.wav        # change sample rate / bit depth
sox in.wav out.wav trim 0:30 1:00              # trim: start 0:30, length 1:00
sox a.wav b.wav merged.wav                      # concatenate
sox -m a.wav b.wav mixed.wav                    # mix together
sox in.wav out.wav norm                         # normalize volume
sox in.wav out.wav gain -3                       # gain -3 dB
sox in.wav out.wav fade 3 0 3                    # 3s fade in / 3s fade out
sox in.wav out.wav reverse                       # reverse
sox -n tone.wav synth 5 sine 440                 # generate 5s 440Hz tone
sox in.wav out.wav silence 1 0.1 1% 1 0.1 1%     # split/trim on silence
sox --info input.wav                             # file info (soxi replacement)
```

## Text-to-speech

### edge-tts (fast, online, no GPU) â€” best default
```powershell
edge-tts --text "Hello there." --voice en-US-AriaNeural --write-media out.mp3
edge-tts --list-voices            # hundreds of voices, many languages
```

### XTTS-v2 (local neural TTS + voice cloning) â€” runs on CPU here
Model already downloaded (no re-download). Set TOS env var to avoid the prompt.
```powershell
$tts = "C:\Python314\Scripts\tts.exe"
$env:COQUI_TOS_AGREED = "1"
# Plain synthesis (language required)
& $tts --model_name "tts_models/multilingual/multi-dataset/xtts_v2" `
       --text "Hello, this is a test." --language_idx en --out_path out.wav
# Voice cloning from a 6-30s clean reference WAV
& $tts --model_name "tts_models/multilingual/multi-dataset/xtts_v2" `
       --text "Cloned voice speaking." --speaker_wav "reference.wav" `
       --language_idx en --out_path cloned.wav
```

## Rules
- XTTS runs on **CPU** (torch is CPU-only on this AMD box) â€” fine for short clips, slow for
  long ones. For speed or bulk, use **edge-tts** (cloud, near-instant).
- Do NOT try to GPU-accelerate XTTS via torch-directml â€” it's slower and breaks coqui-tts.
- For speech-to-TEXT (transcription) instead of TTS, see `python-ml-libs` (faster-whisper).

