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

awk '
# split a CSV line into fields, respecting "quoted, commas"
function split_csv(line,    n, i, ch, field, in_quotes, count) {
    field = ""
    in_quotes = 0
    count = 0
    n = length(line)
    for (i = 1; i <= n; i++) {
        ch = substr(line, i, 1)
        if (ch == "\"") {
            in_quotes = !in_quotes
        } else if (ch == "," && !in_quotes) {
            count++
            columns[count] = field
            field = ""
        } else {
            field = field ch
        }
    }
    count++
    columns[count] = field
    return count
}
 
# header row: find which column number each field we need is in
NR == 1 {
    total = split_csv($0)
    for (i = 1; i <= total; i++) {
        col_name = columns[i]
        if (col_name == "Variable_code") col_name = "variable_code"
        position[tolower(col_name)] = i
    }
    print "year,Value,Units,variable_code"
    next
}
 
# every other row: pull out just the 4 columns we want, in order
{
    split_csv($0)
    print columns[position["year"]] "," columns[position["value"]] "," columns[position["units"]] "," columns[position["variable_code"]]
}
' "$RAW_FILE" > "$TRANSFORMED_FILE"

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
