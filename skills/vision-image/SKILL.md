---
name: vision-image
description: Use to understand or read an IMAGE — identify electronic components from a photo, read/transcribe a schematic or label, OCR text, or describe a screenshot. Routes image work to the local vision model (qwen2.5-vl).
---

# vision-image

Plain text models on this machine cannot see images. For anything that needs to *look at* a
picture, use the vision model **`qwen/qwen2.5-vl-7b`** instead.

## Option A — scripted (works from any model, no manual model switch)
A helper sends the image to the vision model via the local LM Studio API and returns text.
LM Studio JIT-loads the vision model automatically.
```powershell
python "{{SKILLS_DIR}}\vision-image\scripts\describe_image.py" "C:\path\img.jpg" "your question"
```
Examples (tuned for this user's hardware/electronics work):
```powershell
# identify a component from a photo
python ...\describe_image.py board.jpg "identify this component and its markings"
# read a resistor / cap value
python ...\describe_image.py part.jpg "what is the value from the color bands or printing?"
# transcribe a schematic's labels
python ...\describe_image.py schematic.png "list every component label and value you can read"
# OCR
python ...\describe_image.py note.png "transcribe all text exactly"
```
Requires the LM Studio server running (`lms server status`; start with `lms server start`).

## Option B — in the LM Studio chat UI
Load **qwen2.5-vl-7b** as the chat model and attach the image directly in the message. Best for
back-and-forth about one image.

## In opencode
opencode can route image tasks to the vision model with the `vision` agent:
`opencode --agent vision`. Or just call the script above via the shell.

## Rules
- Pick the right question: ask for exactly what you need (a value, a transcription, a yes/no),
  not just "describe" — vision models are more accurate when the task is specific.
- Vision output is a best-effort read; for critical values (component ratings) say it's from an
  image and suggest confirming.
- For image *editing/conversion* (resize, format, crop) you do NOT need vision — use the
  `images-magick-gimp` skill instead.
