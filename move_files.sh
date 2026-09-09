#!/bin/bash

# =========================
# VARIABLES
# =========================

SOURCE_DIR="files"
DEST_DIR="json_and_CSV"

# =========================
# SETUP
# =========================

mkdir -p "$DEST_DIR"

echo "Starting file move..."

# =========================
# MOVE CSV AND JSON FILES
# =========================

for file in "$SOURCE_DIR"/*.csv "$SOURCE_DIR"/*.json; do
    if [ -f "$file" ]; then
        mv "$file" "$DEST_DIR"/
        echo "Moved: $file"
    fi
done

echo "File move completed."