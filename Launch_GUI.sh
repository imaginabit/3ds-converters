#!/usr/bin/env bash
# 3DS Converter GUI Launcher (Linux/macOS counterpart of Launch_GUI.bat)
set -euo pipefail
cd "$(dirname "$0")"

echo
echo "╔════════════════════════════════════════════════╗"
echo "║  3DS ROM Converter Pro - GUI Launcher         ║"
echo "╚════════════════════════════════════════════════╝"
echo

if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: Python 3 is not installed or not in PATH"
    echo
    echo "Please install Python 3.9+ from https://python.org"
    echo "  Debian/Ubuntu: sudo apt install python3"
    echo "  Fedora:        sudo dnf install python3"
    echo "  Arch:          sudo pacman -S python"
    echo
    read -r -p "Press Enter to exit..."
    exit 1
fi

echo "Launching 3DS ROM Converter Pro GUI..."
echo
if ! python3 3ds_converter_gui.py; then
    echo
    echo "An error occurred. Please check the setup guide for troubleshooting."
    read -r -p "Press Enter to exit..."
fi
