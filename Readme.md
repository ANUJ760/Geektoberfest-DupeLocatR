# DupeLocatR

> Fast, menu-driven duplicate file finder for Windows — type `dlr` from anywhere to scan.

---

## Install

### via winget *(pending review)*

```powershell
winget install varadisthedev.DupeLocatR
```

### via Scoop *(available immediately)*

```powershell
scoop bucket add varad https://github.com/varadisthedev/scoop-bucket
scoop install dupelocatr
```

After either install, open **any** terminal and type:

```
dlr
```

DupeLocatR scans the current directory for duplicates.

---

## Manual install (no package manager)

```powershell
# Clone or download the repo, then:
powershell -ExecutionPolicy Bypass -File DupeLocatr.ps1
# Or scan a specific folder:
powershell -ExecutionPolicy Bypass -File DupeLocatr.ps1 -Path "D:\Photos"
# Or double-click:
Run_DupeLocatr.bat
```

---

## How it works

DupeLocatR uses a **3-stage tiered hashing pipeline** to avoid wasting I/O on large files:

| Stage | What happens | Cost |
| ------- | ------------- | ------ |
| **1 — Size grouping** | Files with unique sizes are eliminated instantly | Zero disk reads |
| **2 — Tiered sampling** | Files are fingerprinted based on their size tier (see below) | Minimal reads |
| **3 — Full hash** | Only confirmed candidates are fully hashed (MD5 or SHA256) | Targeted |

### Sampling tiers (Stage 2)

| File size | Sample strategy |
| ----------- | ---------------- |
| **< 10 MB** | Skip sampling → direct full hash |
| **10 MB – 500 MB** | First 64 KB + Last 64 KB |
| **> 500 MB** | First + Middle + Last + 2 deterministic-random 64 KB windows |

This means a folder full of large videos is scanned **fast** — most never get fully read.

Excluded folders (`.git`, `node_modules`, `.vs`, etc.) are skipped **during** the folder walk itself, so they're never enumerated in the first place — not scanned then thrown away. Stages 2 and 3 run across multiple threads in parallel for large scans (configurable in Settings, default auto-detected from CPU core count).

---

## Features

- Finds duplicates across **all file types**: images, videos, music, documents, archives, etc.
- Category filter: scan only Images, Videos, Music, etc.
- **Keep strategy**: keep the alphabetically first / oldest / newest / shortest-path copy
- **Parallel hashing**: sampling and full-hash confirmation run across multiple threads (auto-tuned to CPU cores, configurable)
- **Safe actions**: Move duplicates to a staging folder (undoable) or send to Recycle Bin (recoverable)
- Exports a CSV report
- Colored console + progress bars
- Never modifies anything without explicit confirmation

---

## Uninstall

```powershell
winget uninstall varadisthedev.DupeLocatR
# or
scoop uninstall dupelocatr
```

---

## License

MIT

test 4
