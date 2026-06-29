#!/usr/bin/env python3
"""
Generate docs/demo.gif - an animated terminal demo of the websearch tool.

Self-contained (Pillow only, which ships with this repo's Python env). Re-runnable:
    python docs/make_demo_gif.py
Renders a fake-but-faithful opencode session: the /websearch command types out, real
results appear, then the model's answer. Edit TRANSCRIPT below to change the content.
"""
import os
from PIL import Image, ImageDraw, ImageFont

OUT = os.path.join(os.path.dirname(__file__), "demo.gif")
W, H = 860, 540
PAD = 22
TOPBAR = 34
LINE_H = 26
BG = (30, 30, 46)
BAR = (49, 50, 68)
DOTS = [(243, 139, 168), (249, 226, 175), (166, 227, 161)]

# colors
PROMPT = (137, 180, 250)
CMD = (205, 214, 244)
HEAD = (249, 226, 175)
TITLE = (205, 214, 244)
URL = (116, 199, 236)
ANS = (166, 227, 161)
DIM = (147, 153, 178)

# (text, color, types_out?) - one screen line. types_out animates char-by-char.
TRANSCRIPT = [
    ("~/project $ opencode", PROMPT, False),
    ("> /websearch amd rx 6600 ffmpeg hevc encoding flags", CMD, True),
    ("", CMD, False),
    ("  websearch (via duckduckgo) - 4 results", HEAD, False),
    ("", CMD, False),
    ("  1. Hardware/AMF - FFmpeg", TITLE, False),
    ("     https://trac.ffmpeg.org/wiki/Hardware/AMF", URL, False),
    ("  2. Recommended FFmpeg Encoder Settings - GitHub", TITLE, False),
    ("     https://github.com/GPUOpen-LibrariesAndSDKs/AMF/wiki/...", URL, False),
    ("  3. Encode with ffmpeg using AMD Radeon (askubuntu)", TITLE, False),
    ("     https://askubuntu.com/questions/1488443/...", URL, False),
    ("  4. GPU-Accelerated FFmpeg: NVENC, QSV, AMF Compared", TITLE, False),
    ("     https://32blog.com/en/ffmpeg/ffmpeg-gpu-encoding-nvenc-qsv", URL, False),
    ("", CMD, False),
    ("  Use -c:v hevc_amf with -rc cqp -qp_i 22 -qp_p 24 -qp_b 26", ANS, False),
    ("  -quality quality. Full GPU pipe: add -hwaccel d3d11va.", ANS, False),
    ("  (source: trac.ffmpeg.org)", DIM, False),
]


def load_font(size):
    for p in (r"C:\Windows\Fonts\consola.ttf", r"C:\Windows\Fonts\cour.ttf"):
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


FONT = load_font(16)


def frame(visible, partial_last=None, cursor=True):
    """visible = number of full lines shown; partial_last = (text,color) typing line."""
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, W, TOPBAR], fill=BAR)
    for i, c in enumerate(DOTS):
        d.ellipse([PAD + i * 22, 11, PAD + i * 22 + 12, 23], fill=c)
    d.text((PAD + 80, 9), "websearch  -  local-llm-skills", font=FONT, fill=DIM)

    y = TOPBAR + 14
    for i in range(visible):
        text, color, _ = TRANSCRIPT[i]
        d.text((PAD, y), text, font=FONT, fill=color)
        y += LINE_H
    if partial_last is not None:
        text, color = partial_last
        d.text((PAD, y), text, font=FONT, fill=color)
        if cursor:
            w = d.textlength(text, font=FONT)
            d.rectangle([PAD + w + 2, y + 2, PAD + w + 11, y + 19], fill=CMD)
    return img


def build():
    frames, durations = [], []

    def add(img, ms):
        frames.append(img)
        durations.append(ms)

    # line 0 visible, then type line 1
    typed_idx = next(i for i, t in enumerate(TRANSCRIPT) if t[2])
    base = typed_idx  # lines before the typed one are shown instantly
    text = TRANSCRIPT[typed_idx][0]
    add(frame(base, partial_last=("", CMD)), 500)
    step = 2
    for n in range(0, len(text) + 1, step):
        add(frame(base, partial_last=(text[:n], CMD)), 45)
    add(frame(base, partial_last=(text, CMD)), 650)

    # reveal the rest line by line (typed line now counts as fully visible)
    for v in range(typed_idx + 1, len(TRANSCRIPT) + 1):
        text_v = TRANSCRIPT[v - 1][0]
        # faster for blank/url lines, a beat for titles/answers
        ms = 90 if (text_v.strip() == "" or text_v.strip().startswith("http")) else 230
        add(frame(v, cursor=False), ms)

    # hold final
    add(frame(len(TRANSCRIPT), cursor=False), 2800)
    return frames, durations


def main():
    frames, durations = build()
    frames[0].save(
        OUT, save_all=True, append_images=frames[1:], duration=durations,
        loop=0, optimize=True, disposal=2,
    )
    kb = os.path.getsize(OUT) / 1024
    print(f"Wrote {OUT}  ({len(frames)} frames, {kb:.0f} KB)")


if __name__ == "__main__":
    main()
