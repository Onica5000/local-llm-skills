---
name: media-ffmpeg
description: Use for any video or audio conversion, encoding, transcoding, trimming, extracting, streaming, or inspecting media files. Covers FFmpeg/ffprobe/ffplay including GPU hardware encoding (NVIDIA/AMD/Intel).
---

# media-ffmpeg

FFmpeg, `ffprobe`, and `ffplay` handle nearly all video/audio jobs. Confirm install with
`ffmpeg -version`; if missing, load `install-tools` (`winget install Gyan.FFmpeg`).

## Inspect a file (always do this first)
```powershell
ffprobe -v quiet -show_streams -show_format -of json "file.mkv"
```

## GPU hardware encoding — pick the flag matching YOUR GPU
| GPU vendor | H.264 | H.265/HEVC | AV1 |
|---|---|---|---|
| **NVIDIA** | `-c:v h264_nvenc` | `-c:v hevc_nvenc` | `-c:v av1_nvenc` (RTX 40+) |
| **AMD** | `-c:v h264_amf` | `-c:v hevc_amf` | `-c:v av1_amf` (RX 7000+) |
| **Intel** | `-c:v h264_qsv` | `-c:v hevc_qsv` | `-c:v av1_qsv` (Arc) |

List what your build supports: `ffmpeg -encoders | findstr "nvenc amf qsv"`.
GPU decode: add `-hwaccel d3d11va` before `-i` (Windows; auto-falls back to CPU).

**Example (AMD HEVC, full GPU pipeline):**
```powershell
ffmpeg -hwaccel d3d11va -i input.avi -c:v hevc_amf -rc cqp -qp_i 22 -qp_p 24 -qp_b 26 -quality quality -c:a aac -b:a 384k -sn output.mkv
```
Swap `hevc_amf` for `hevc_nvenc`/`hevc_qsv` on NVIDIA/Intel. For CPU-quality encodes use
`-c:v libx264`/`libx265` with `-crf 18..23`.

## Common operations
```powershell
ffmpeg -i input.avi output.mp4                                   # simple convert
ffmpeg -i video.mp4 -vn -c:a copy audio.m4a                      # extract audio
ffmpeg -ss 00:01:30 -i input.mp4 -t 00:00:45 -c copy clip.mp4    # trim, no re-encode
ffmpeg -ss 10 -i input.mp4 -frames:v 1 frame.png                 # grab a frame at 10s
ffmpeg -i input.mp4 -vf "scale=1280:-2" out.mp4                  # resize
ffmpeg -i input.mp4 -vf "fps=12,scale=480:-1" out.gif           # make a GIF
ffmpeg -f concat -safe 0 -i list.txt -c copy joined.mp4         # concat (same codec)
```

## Rules
- `-c copy` = no re-encode (instant, lossless) — use it whenever just cutting/remuxing.
- For frame-accurate or programmatic work, see `python-ml-libs` (PyAV).
- Audio-only jobs are often simpler with the `audio-sox-tts` skill.
