---
name: documents-pandoc
description: Use for converting documents between formats â€” Markdown, DOCX, PDF, HTML, EPUB, MOBI, ODT, etc. Pandoc for general docs, md2pdf for quick Markdown-to-PDF, Calibre for eBooks.
---

# documents-pandoc

## Pandoc 3.10 â€” universal document converter
```powershell
pandoc input.md -o output.docx
pandoc input.md -o output.pdf            # needs a PDF engine; if it fails, use md2pdf below
pandoc input.docx -o output.md
pandoc input.md -o output.html
pandoc input.html -o output.md
pandoc input.md -o output.epub
pandoc input.md --toc -o output.pdf      # with table of contents
```

## md2pdf â€” fast, offline Markdown -> PDF (no LaTeX needed)
A custom tool on PATH (ReportLab-based). Use it when pandoc's PDF engine isn't set up.
```powershell
md2pdf input.md                  # -> input.pdf
md2pdf input.md output.pdf
```

## Calibre 9.9 â€” eBooks
```powershell
ebook-convert input.epub output.mobi      # convert between eBook formats
ebook-convert input.pdf output.epub
calibredb add book.epub                    # add to library
calibredb export --all                     # export library
```

## Other doc tools on this machine
- `foxidermist/ai-to-pdf-docx-odt-epub` LM Studio plugin also converts to pdf/docx/odt/epub.

## Rules
- Markdown -> PDF: try `md2pdf` first (offline, reliable); use pandoc for everything else.
- DOCX <-> Markdown round-trips well with pandoc; complex formatting may need manual cleanup.
- For PDFs you need to READ/extract text from, that's a different job â€” extract with pandoc or
  a Python lib (`python-ml-libs`), don't try to "convert" a scanned PDF.

