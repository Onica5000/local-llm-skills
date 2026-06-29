#!/usr/bin/env python3
"""
describe_image.py - analyze an image with a local vision model via the LM Studio API.

Lets ANY model (or you) get an image understood by qwen2.5-vl without leaving the shell.
LM Studio JIT-loads the vision model on request (if JIT is enabled), so you don't have to
load it by hand. Zero dependencies (Python stdlib only).

USAGE
  python describe_image.py <image> "your question about the image"
  python describe_image.py photo.jpg "what is the resistor color-code value?"
  python describe_image.py schematic.png "transcribe all component labels" --max 800
  python describe_image.py img.png "describe it" --model qwen/qwen2.5-vl-7b

Requires LM Studio's local server running (lms server start) with a vision model available.
"""
import sys
import os
import json
import base64
import argparse
import urllib.request
import urllib.error

for _s in (sys.stdout, sys.stderr):
    try:
        _s.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

MIME = {".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".png": "image/png",
        ".gif": "image/gif", ".webp": "image/webp", ".bmp": "image/bmp"}


def main():
    ap = argparse.ArgumentParser(description="Analyze an image with a local vision model.")
    ap.add_argument("image", help="path to the image file")
    ap.add_argument("prompt", nargs="?", default="Describe this image in detail.",
                    help="question/instruction about the image")
    ap.add_argument("--model", default="qwen/qwen2.5-vl-7b", help="vision model id loaded in LM Studio")
    ap.add_argument("--api", default="http://127.0.0.1:1234/v1", help="LM Studio API base URL")
    ap.add_argument("--max", type=int, default=600, help="max tokens in the answer")
    args = ap.parse_args()

    if not os.path.isfile(args.image):
        sys.exit(f"Image not found: {args.image}")
    ext = os.path.splitext(args.image)[1].lower()
    mime = MIME.get(ext, "image/png")
    with open(args.image, "rb") as f:
        b64 = base64.b64encode(f.read()).decode("ascii")

    payload = {
        "model": args.model,
        "messages": [{
            "role": "user",
            "content": [
                {"type": "text", "text": args.prompt},
                {"type": "image_url", "image_url": {"url": f"data:{mime};base64,{b64}"}},
            ],
        }],
        "max_tokens": args.max,
        "temperature": 0.2,
    }
    req = urllib.request.Request(
        args.api.rstrip("/") + "/chat/completions",
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=180) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        print(data["choices"][0]["message"]["content"].strip())
    except urllib.error.URLError as e:
        sys.exit(f"Could not reach LM Studio at {args.api} ({e}). "
                 f"Start it: 'lms server start', and make sure a vision model like "
                 f"'{args.model}' is available (LM Studio will JIT-load it).")
    except (KeyError, IndexError, json.JSONDecodeError) as e:
        sys.exit(f"Unexpected API response: {e}")


if __name__ == "__main__":
    main()
