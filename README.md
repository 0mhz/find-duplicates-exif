Current issues: --extensions doesn't capture the full list of arguments passed to it

Usage: ./process_unique_exifs_xargs_call.sh [--remove-source] [--dry-run] --output-dir OUTPUT_DIR --extensions EXT1 [EXT2 ...]
Options:
  --remove-source      Remove source files after copying (default: false)
  --dry-run            Perform a trial run with no changes made (default: false)
  --check-exports	     Look for images with no camera-related data and treat them differently (default: false)
  --output-dir         Specify the output directory (required)
  --extensions         Specify photo extensions to process (e.g., jpg, dng, cr2)
  --help               Show this help message
