#!/usr/bin/env bash
# 3DS Converter (Linux counterpart of 3DS_Converter.bat)
# NOTE: the .bat references 3ds.py which no longer exists; this launches the current GUI.
set -euo pipefail
cd "$(dirname "$0")"
python3 3ds_converter_gui.py
