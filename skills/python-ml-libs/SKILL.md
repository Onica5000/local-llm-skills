---
name: python-ml-libs
description: Use when a task needs Python for media or machine-learning work that CLI tools can't do easily â€” frame-accurate video, audio analysis, speech-to-text transcription, image generation, running Hugging Face models. Lists the libraries already installed (no pip needed).
---

# python-ml-libs

Python 3.14 at `C:\Python314`. These libraries are ALREADY installed â€” write Python that
imports them directly. No `pip install` needed.

| Import | Library | Use for |
|---|---|---|
| `import av` | PyAV 17 | Frame-accurate read/write of video & audio (FFmpeg bindings) |
| `import torchaudio` | torchaudio 2.11 | Load/save audio as tensors, resample, transforms |
| `from torchcodec.decoders import *` | torchcodec | Fast video/audio decode to tensors |
| `import librosa` | librosa 0.11 | Audio analysis: spectrograms, MFCC, beat/tempo, pitch |
| `import soundfile` | soundfile | Read/write WAV/FLAC/OGG |
| `from PIL import Image` | Pillow 12 | Image read/write/edit/convert |
| `import cairo` | pycairo | 2D vector drawing |
| `from svglib.svglib import svg2rlg` | svglib | Render/convert SVG (to PDF/PNG) |
| `import matplotlib` | matplotlib 3.11 | Plots/charts to PNG/SVG/PDF |
| `from transformers import pipeline` | transformers 4.57 | Run Hugging Face vision/audio/LLM models |
| `from faster_whisper import WhisperModel` | faster-whisper | Speech-to-text transcription |
| `import numpy` / `scipy` | numpy/scipy | Numerical + signal processing |

## Speech-to-text (transcription) with faster-whisper
```python
from faster_whisper import WhisperModel
# torch is CPU-only on this AMD box -> use device="cpu", compute_type="int8"
model = WhisperModel("base", device="cpu", compute_type="int8")
segments, info = model.transcribe("audio.mp3")
for s in segments:
    print(f"[{s.start:.1f}-{s.end:.1f}] {s.text}")
```
A GPU path exists via `onnxruntime-directml` (`providers=["DmlExecutionProvider"]`).

## Important
- **`torch` is CPU-only** (`+cpu`) â€” `torch.cuda.is_available()` is False. transformers/XTTS/
  whisper run on CPU. Don't install `torch-directml` (stale, breaks things).
- For simple audio/video/image jobs prefer the CLI skills (`media-ffmpeg`, `audio-sox-tts`,
  `images-magick-gimp`) â€” only drop to Python for frame-level or ML work.
- Run scripts with `python script.py` (or `uv run script.py`).

