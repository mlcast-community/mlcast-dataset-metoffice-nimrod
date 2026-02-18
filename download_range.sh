#!/usr/bin/env bash
# Download UK NIMROD radar archives from CEDA for a specific date range.
#
# Usage: ./download_range.sh START_DATE END_DATE OUTPUT_DIR [PARALLEL]
#   e.g.: ./download_range.sh 2024-07-30 2025-12-31 /disks/fast/uk-raw 4
#
# Requires: API_KEY env var or access_token file in the same directory.

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ $# -lt 3 ]; then
    echo "Usage: $0 START_DATE END_DATE OUTPUT_DIR [PARALLEL]"
    echo "  e.g.: $0 2024-07-30 2025-12-31 /disks/fast/uk-raw 4"
    exit 1
fi

START_DATE="$1"
END_DATE="$2"
OUT_DIR="$3"
PARALLEL="${4:-4}"
mkdir -p "$OUT_DIR"

# Load API key from env or file
if [ -z "${API_KEY:-}" ]; then
    if [ -f "$DIR/access_token" ]; then
        API_KEY=$(cat "$DIR/access_token")
    else
        echo "Error: API_KEY not set and no access_token file found"
        exit 1
    fi
fi
export API_KEY

BASE_URL="https://dap.ceda.ac.uk/badc/ukmo-nimrod/data/composite/uk-1km"

# Build list of URLs to download
url_list=$(mktemp)
current="$START_DATE"
while [[ "$current" < "$END_DATE" ]] || [[ "$current" == "$END_DATE" ]]; do
    year=$(date -d "$current" +%Y)
    ymd=$(date -d "$current" +%Y%m%d)
    filename="metoffice-c-band-rain-radar_uk_${ymd}_1km-composite.dat.gz.tar"
    outpath="${OUT_DIR}/${filename}"

    if [ -f "$outpath" ] && [ -s "$outpath" ]; then
        : # skip existing non-empty files
    else
        echo "${BASE_URL}/${year}/${filename} ${outpath}" >> "$url_list"
    fi
    current=$(date -d "$current + 1 day" +%Y-%m-%d)
done

total=$(wc -l < "$url_list")
echo "Downloading $total files with $PARALLEL parallel workers..."

# Download function for xargs
download_one() {
    url="$1"
    outpath="$2"
    filename=$(basename "$outpath")
    wget -q --timeout=120 --tries=3 --header "Authorization: Bearer $API_KEY" \
        -O "$outpath" "$url" 2>/dev/null && \
        echo "OK: $filename" || {
            echo "FAIL: $filename"
            rm -f "$outpath"
        }
}
export -f download_one

# Run parallel downloads
cat "$url_list" | xargs -P "$PARALLEL" -L 1 bash -c 'download_one "$1" "$2"' _

rm -f "$url_list"
echo "Done. Files saved to $OUT_DIR"
