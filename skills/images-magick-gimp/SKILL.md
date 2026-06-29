---
name: images-magick-gimp
description: Use for image conversion, resizing, cropping, format changes, and batch image processing. ImageMagick for quick CLI jobs (GPU-accelerated), GIMP for advanced/scripted edits beyond ImageMagick.
---

# images-magick-gimp

## ImageMagick 7 â€” use `magick` (NOT `convert`)
> In PowerShell `convert` is a Windows disk tool. Always use `magick`.
> OpenCL GPU acceleration is ON (`MAGICK_OCL_DEVICE=ON`) for blur/resize/sharpen.
```powershell
magick input.png output.jpg                       # convert format
magick input.jpg -resize 1920x1080 output.jpg      # resize (keeps aspect)
magick input.jpg -resize 50% output.jpg            # resize by percent
magick input.png -crop 800x600+100+50 out.png      # crop WxH+X+Y
magick input.jpg -quality 85 output.jpg            # set JPEG quality
magick input.png -blur 0x8 output.png              # GPU blur
magick input.png -sharpen 0x2 output.png           # GPU sharpen
magick *.png montage.jpg                            # combine to montage
magick input.gif -coalesce frame_%03d.png          # split GIF to frames
magick input.heic output.png                        # HEIC -> PNG
# Batch resize a folder (PowerShell loop)
Get-ChildItem *.jpg | ForEach-Object { magick $_.FullName -resize 1280x $("small_" + $_.Name) }
```

## GIMP 3 â€” for what ImageMagick can't do (layers, advanced filters, Script-Fu/Python)
Console binary: `D:\Program Files\GIMP 3\bin\gimp-console-3.exe`
```powershell
$gimp = "D:\Program Files\GIMP 3\bin\gimp-console-3.exe"
# Batch flatten + export via Script-Fu, then quit
& $gimp -i -b '(let* ((img (car (gimp-file-load RUN-NONINTERACTIVE \"in.xcf\" \"in.xcf\"))) (d (car (gimp-image-flatten img)))) (file-png-save RUN-NONINTERACTIVE img d \"out.png\" \"out\" 0 9 1 1 1 1 1))' -b '(gimp-quit 0)'
```
GIMP also bundles Python at `D:\Program Files\GIMP 3\bin\python.exe` (Python-Fu), and a
standalone GEGL CLI at `...\bin\gegl.exe` for graph-based ops.

## Rules
- Reach for `magick` first â€” it handles 95% of image jobs in one line.
- Use GIMP only for layered/interactive-style edits or filters ImageMagick lacks.
- For SVG rendering or programmatic drawing in Python, see `python-ml-libs` (pycairo, svglib, Pillow).

