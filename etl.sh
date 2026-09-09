#!/bin/bash

# =========================
# LOCATE SCRIPT DIRECTORY (CRON JOBS REQUIRE THIS)
# ========================= 

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# =========================
# VARIABLES
# =========================

NAME="$USER"
export URL="https://www.stats.govt.nz/assets/Uploads/Annual-enterprise-survey/Annual-enterprise-survey-2023-financial-year-provisional/Download-data/annual-enterprise-survey-2023-financial-year-provisional.csv"

RAW_DIR="raw"
TRANSFORMED_DIR="transformed"
GOLD_DIR="gold"

RAW_FILE="$RAW_DIR/data.csv"
TRANSFORMED_FILE="$TRANSFORMED_DIR/2023_year_finance.csv"
GOLD_FILE="$GOLD_DIR/2023_year_finance.csv"

# =========================
# SETUP
# =========================

echo " ETL pipeline started at $(date)"

mkdir -p "$RAW_DIR" "$TRANSFORMED_DIR" "$GOLD_DIR"

echo "Pipeline directories are ready."

# =========================
# EXTRACT
# =========================

echo "Starting extract step..."
echo "Downloading data from $URL"

curl -o "$RAW_FILE" "$URL"

if [ -f "$RAW_FILE" ]; then
    echo "Extract Completed: Data downloaded successfully to $RAW_FILE"
else
    echo "Failed to download data from $URL"
    exit 1
fi

# =========================
# TRANSFORM
# =========================

echo "Starting transform step..."

awk -F',' 'NR == 1 {print "year,Value,Units,variable_code"} NR > 1 {print $1","$9","$5","$6}' "$RAW_FILE" > "$TRANSFORMED_FILE"

if [ -f "$TRANSFORMED_FILE" ]; then
    echo "Transform Completed: Data transformed successfully to $TRANSFORMED_FILE"
else
    echo "Failed to transform data."
    exit 1
fi


# =========================
# LOAD
# =========================

echo "Starting load step..."

cp "$TRANSFORMED_FILE" "$GOLD_FILE"

if [ -f "$GOLD_FILE" ]; then
    echo "Load Completed: Data loaded successfully to $GOLD_FILE"
else
    echo "Failed to load data."
    exit 1
fi
