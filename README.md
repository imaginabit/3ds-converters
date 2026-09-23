You might also be interested in [Hotcorners for windows](https://github.com/rohithvishaal/hotcorners-for-windows) (triggers actions you set when your mouse cursor reaches the corners of your screen)

# 3DS ROM Converter Pro - Modern Edition

A modern GUI-based tool for converting 3DS ROM files between CIA and CCI formats and for decrypting them for use with Citra.

**Runs on Windows and Linux** (Linux uses native tools, no wine/cmd needed).

![UI](screenshots/GUI.png)

## What this tool does

The current GUI workflow is implemented in [3ds_converter_gui.py](3ds_converter_gui.py). It provides a desktop interface for:

- CCI to CIA conversion
- CIA to CCI conversion
- CCI/3DS decryption
- CIA to decrypted CCI conversion

For the CCI-to-CIA and CIA-to-CCI flows, the script will first try the normal conversion and, if that fails, it will attempt a decrypt-first retry before trying again.

## Recent changes

- **Linux support**: on non-Windows, decryption runs through native `ctrdecrypt`/`ctrtool`/`makerom` binaries instead of the Windows batch script (no wine required).
- **Cross-platform tool resolution**: tools are looked up as `bin/<name>` on Linux and `bin/<name>.exe` on Windows, with a clear error if missing; executable bits are set automatically on Linux.
- **`.3ds` support in CCI decrypt**: folder CCI decryption now also picks up `.3ds` files, not only `.cci`.
- **Auto conversion type**: selecting a single `.cia`/`.cci` file in the GUI pre-selects the matching conversion type so Start Conversion works without manual dropdown changes.
- **seeddb handling**: `seeddb.bin` is temporarily placed next to the ROMs so `ctrdecrypt` can find it, then cleaned up.
- **Native binaries added**: `bin/ctrdecrypt`, `bin/ctrtool`, `bin/makerom` (Linux x86-64) committed alongside the existing `.exe` tools.
- **Shell script counterparts**: `Launch_GUI.sh`, `3DS_Converter.sh` and `Batch CIA 3DS Decryptor Redux.sh` mirror the `.bat` scripts for Linux (native tools, no wine).
- **.gitignore**: ignore `ROMs/` and `__pycache__/` so local ROMs and caches are never committed.

## Features

- Modern Tkinter-based GUI window
- Single ROM mode or full-folder batch mode
- Output folder selection
- Real-time log window
- Status bar and progress indicator
- Automatic detection of available CCI, 3DS and CIA files in a selected folder
- Batch processing for multiple files and conversion types

## Requirements

- Python 3.9 or higher
- Windows or Linux (x86-64)
- Helper files in the `bin` folder:
  - **Windows:** `makerom.exe`, `ctrtool.exe`, `decrypt.exe`
  - **Linux:** `makerom`, `ctrtool`, `ctrdecrypt`
  - `seeddb.bin` (both platforms)
  - Decryptor script: [Batch CIA 3DS Decryptor Redux.bat](Batch%20CIA%203DS%20Decryptor%20Redux.bat) (Windows) or [Batch CIA 3DS Decryptor Redux.sh](Batch%20CIA%203DS%20Decryptor%20Redux.sh) (Linux)

## Installation

### 1. Install Python
Download and install Python from python.org and make sure Python is added to PATH.

### 2. Verify Python is available
Windows (PowerShell):

```powershell
python --version
```

Linux/macOS:

```bash
python3 --version
```

### 3. Place the required files in the project folder
The GUI expects the batch script and tools to be available so it can launch them when needed.

## Running the GUI

From the project folder:

```bash
# Windows
python 3ds_converter_gui.py
# or
Launch_GUI.bat

# Linux/macOS
python3 3ds_converter_gui.py
# or
./Launch_GUI.sh
```

## Using the GUI

### Input selection
Choose one of two modes:

- Single ROM File: convert one selected ROM file
- Entire Folder: process all compatible ROMs in a chosen folder

### Single ROM mode
1. Click Browse ROM File and select a .cia or .cci ROM.
2. Enter or confirm the ROM name.
3. Choose a conversion type from the dropdown.
4. Choose an output folder.
5. Click Start Conversion.

### Folder batch mode
1. Click Browse Folder and select a directory containing ROM files.
2. The GUI will show how many .cci and .cia files it found.
3. Enable one or more conversion options:
   - CCI → CIA
   - CIA → CCI
   - CCI Decrypt
   - CIA → Decrypted CCI
4. Choose an output folder.
5. Click Start Conversion.

### Output behavior
By default, converted files are written to the ROMs folder. You can choose another output location in the GUI.

## File layout

```text
3ds-converters/
├── 3ds_converter_gui.py
├── Batch CIA 3DS Decryptor Redux.bat / .sh
├── Launch_GUI.bat / .sh
├── 3DS_Converter.bat / .sh
├── bin/
│   ├── makerom / makerom.exe
│   ├── ctrtool / ctrtool.exe
│   ├── ctrdecrypt / decrypt.exe
│   └── seeddb.bin
├── ROMs/            (local, git-ignored)
└── screenshots/
```

## Fallback option if the GUI fails

If the GUI script does not complete successfully, you can fall back to the decryptor script directly.

1. Place the ROM files in the same folder as the decryptor script.
2. Run it:

```powershell
# Windows
./Batch CIA 3DS Decryptor Redux.bat
```

```bash
# Linux/macOS
./Batch\ CIA\ 3DS\ Decryptor\ Redux.sh
```

3. Follow the prompts in the console window.

This is useful when you want a simpler, script-driven approach for decryption and conversion.

## Troubleshooting

### Python is not recognized
Install Python and make sure it is added to PATH.

### makerom / ctrtool not found
Make sure the tools exist in the `bin` folder (`bin/makerom` + `bin/ctrtool` on Linux, `bin/makerom.exe` + `bin/ctrtool.exe` on Windows).

### ROM not found
Check that the ROM file is present in the selected source folder or that the correct file extension is being used (.cia or .cci).

### Conversion seems slow
Some conversions can take several minutes. The GUI remains responsive while work is running.

### The decryptor script is easier to use in some cases
If the GUI fails repeatedly, try the decryptor script fallback described above and keep the ROMs in the same folder as the script.

## Credits

Original credits for the underlying tools and workflow:

- 54634564 - decrypt.exe
- profi200 / jakcron - original makerom and ctrtool
- matif - Batch CIA 3DS Decryptor batch flow
- @xxmichibxx - Batch CIA 3DS Decryptor Redux
- @rohithvishaal - original automation script

Fork: [imaginabit/3ds-converters](https://github.com/imaginabit/3ds-converters)

### Bundled tools

| Tool | Upstream | License |
|------|----------|---------|
| `ctrtool` | [3DSGuy/Project_CTR](https://github.com/3DSGuy/Project_CTR) | MIT |
| `makerom` | [3DSGuy/Project_CTR](https://github.com/3DSGuy/Project_CTR) | MIT |
| `ctrdecrypt` | [shijimasoft/ctrdecrypt](https://github.com/shijimasoft/ctrdecrypt) | GPL-3.0 |
| `decrypt.exe` | 54634564 | (see original credits) |

`ctrdecrypt` is distributed under GPL-3.0: source is available at the upstream repository above.
