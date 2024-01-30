#!/bin/bash

EXIF_TOOL="/usr/local/bin/exiftool"
DEBUG_MODE=1
REMOVE_SOURCE=false
DRY_RUN=false
EXPORT_MODE=false
OUTPUT_DIR=""
PHOTO_EXTENSIONS=()

function show_help() {
    echo "Usage: $0 [--remove-source] [--dry-run] --output-dir OUTPUT_DIR --extensions EXT1 [EXT2 ...]"
    echo "Options:"
    echo "  --remove-source      Remove source files after copying (default: false)"
    echo "  --dry-run            Perform a trial run with no changes made (default: false)"
    echo "  --check-exports	 Look for images with no camera-related data and treat them differently (default: false)"
    echo "  --output-dir         Specify the output directory (required)"
    echo "  --extensions         Specify photo extensions to process (e.g., jpg, dng, cr2)"
    echo "  --help               Show this help message"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --remove-source)
            REMOVE_SOURCE=true
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
	--check-exports)
	    EXPORT_MODE=true
	    ;;
        --output-dir)
            OUTPUT_DIR="$2"
	    shift
            ;;
        --extensions)
            shift
            PHOTO_EXTENSIONS=("$@")
            break
            ;;
        --help)
            show_help
            ;;
        *)
            show_help
            ;;
    esac
    shift
done

[ -n "$OUTPUT_DIR" ] || { echo "Error: --output-dir is required."; show_help; exit 1; }
[ -d "$OUTPUT_DIR" ] || mkdir -p "$OUTPUT_DIR"

export EXIF_TOOL DEBUG_MODE REMOVE_SOURCE DRY_RUN EXPORT_MODE OUTPUT_DIR PHOTO_EXTENSIONS


