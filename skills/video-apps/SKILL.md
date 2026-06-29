---
name: video-apps
description: Use to drive the big GUI media apps headlessly from the shell â€” VLC (play/transcode/stream/snapshot), Blender (3D render, video sequencer), OBS (screen capture/record), DaVinci Resolve (pro edit/color), GIMP/Audacity. Reach here for things the CLI tools can't do (3D, compositing, screen capture, color grading).
---

# video-apps

Full GUI programs that can be scripted/launched from the shell. For plain convert/encode,
prefer `media-ffmpeg` â€” use these for capabilities FFmpeg lacks.

## VLC 3.0.23 â€” fully scriptable headless
`D:\Program Files\VideoLAN\VLC\vlc.exe`
```powershell
$vlc = "D:\Program Files\VideoLAN\VLC\vlc.exe"
# Transcode to MP4 and quit
& $vlc -I dummy "in.avi" --sout "#transcode{vcodec=h264,acodec=mp3}:std{access=file,mux=mp4,dst=out.mp4}" vlc://quit
# Snapshot/thumbnail near 10s
& $vlc -I dummy "in.mp4" --start-time=10 --stop-time=11 --video-filter=scene --scene-path="C:\temp" vlc://quit
# Stream over HTTP :8080
& $vlc -I dummy "in.mp4" --sout "#standard{access=http,mux=ts,dst=:8080}"
```

## Blender 5.1 â€” headless render / Python (bpy)
`D:\Program Files\Blender Foundation\Blender 5.1\blender.exe`
```powershell
$blender = "D:\Program Files\Blender Foundation\Blender 5.1\blender.exe"
& $blender -b "scene.blend" -o "C:\temp\render_" -f 1          # render frame 1
& $blender -b "scene.blend" -o "C:\temp\anim_" -s 1 -e 250 -a  # render range
& $blender -b --python "script.py"                              # run bpy script
```

## OBS Studio 32 â€” screen/video capture (launch flags only)
Must start from its own bin dir.
```powershell
$obs = "D:\Program Files\obs-studio\bin\64bit\obs64.exe"
Start-Process -FilePath $obs -WorkingDirectory "D:\Program Files\obs-studio\bin\64bit" -ArgumentList "--startrecording","--minimize-to-tray"
# also: --startstreaming, --startvirtualcam, --scene "Name", --profile "Name"
```

## DaVinci Resolve 21 â€” Python/Lua scripting API
Resolve must be RUNNING; scripts connect via `DaVinciResolveScript` (set `RESOLVE_SCRIPT_API`/
`RESOLVE_SCRIPT_LIB`). API at `C:\ProgramData\Blackmagic Design\DaVinci Resolve\Support\Developer\Scripting`.
No one-shot CLI â€” it's in-app automation (import, timeline build, render queue, color).

## Also available
- **GIMP** batch image editing â†’ see `images-magick-gimp`.
- **Audacity 3.7** (GUI, pipe-only) â€” for scripted audio prefer SoX/FFmpeg (`audio-sox-tts`).

