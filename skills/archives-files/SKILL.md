---
name: archives-files
description: Use for compressing/extracting archives (7z, zip, tar, gz, rar) and for robust file copying, mirroring, and bulk file operations with 7-Zip, tar, robocopy, and xcopy.
---

# archives-files

## 7-Zip (`7z`) â€” compress/extract almost anything
```powershell
7z l archive.7z                       # list contents
7z x archive.7z                       # extract (keeps full paths)
7z x archive.zip -o"C:\dest"          # extract to a folder
7z a out.7z folder\                   # create 7z archive
7z a -tzip out.zip folder\            # create a ZIP
7z a -p out.7z folder\                # password-protect (prompts)
7z x archive.rar                      # extract RAR (read-only support)
```
Handles 7z, zip, tar, gz, bz2, xz, rar, iso, and more.

## tar (built-in)
```powershell
tar -czf out.tar.gz folder\           # create gzip tarball
tar -xzf out.tar.gz                    # extract
tar -tzf out.tar.gz                    # list
```

## robocopy â€” robust copy / mirror (built-in, resilient)
```powershell
robocopy C:\src D:\dst /E             # copy incl. empty subdirs
robocopy C:\src D:\dst /MIR           # MIRROR (deletes extras in dst â€” be careful)
robocopy C:\src D:\dst /E /Z /R:3 /W:5   # resumable, retry 3x, wait 5s
```
> `/MIR` deletes files in the destination that aren't in the source. Confirm before using it.

## xcopy (legacy, simple)
```powershell
xcopy C:\src D:\dst /E /I /Y
```

## Rules
- Prefer `7z` for compression (best ratios, most formats) and `robocopy` for big/resilient copies.
- `robocopy /MIR` and password flags are destructive/sensitive â€” confirm intent first.

