#!/usr/bin/env bash
# Parallel version of convert_data.sh
# Processes multiple daily .dat.gz.tar archives concurrently
# Usage: ./convert_data_parallel.sh /path/to/data /path/to/output [WORKERS]
set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ -z "${1:-}" ] || [ ! -d "$1" ]; then
    echo "Error: $1 is not a directory"
    exit 1
fi
DATA_DIR="$1"
OUT_DIR="${2:-$DATA_DIR/tiff}"
WORKERS="${3:-$(nproc)}"

mkdir -p "$OUT_DIR"

convert_one_tar() {
    local FILE="$1"
    local OUT_DIR="$2"
    local SCRIPT_DIR="$3"

    local BASE_FILE
    BASE_FILE=$(basename "$FILE")
    BASE_FILE=${BASE_FILE%.dat.gz.tar}

    # skip if output directory already has files (idempotent)
    if [ -d "$OUT_DIR/$BASE_FILE" ] && [ "$(ls "$OUT_DIR/$BASE_FILE"/*.tiff 2>/dev/null | wc -l)" -gt 200 ]; then
        echo "SKIP: $BASE_FILE (already converted)"
        return 0
    fi

    local TEMP_DIR
    TEMP_DIR=$(mktemp -d)
    tar -xf "$FILE" -C "$TEMP_DIR"

    mkdir -p "$OUT_DIR/$BASE_FILE"

    local count=0
    for DAT_FILE in "$TEMP_DIR"/*; do
        [ -f "$DAT_FILE" ] || continue
        local FNAME
        FNAME=$(basename "$DAT_FILE")
        local OUT_FILE="${FNAME%.dat.gz}.tiff"
        local OUT_FILE_PATH="$OUT_DIR/$BASE_FILE/$OUT_FILE"

        [ -f "$OUT_FILE_PATH" ] && continue

        gunzip -c "$DAT_FILE" | \
        python3 "$SCRIPT_DIR/nimrod.py" -x /dev/stdin /dev/stdout 2>/dev/null | \
        gdal_translate -if AAIGrid -of GTiff -ot Int16 -strict \
                        -a_srs EPSG:27700 -a_scale 0.03125 \
                        -co COMPRESS=ZSTD -co PREDICTOR=2 -co TILED=YES \
                        -mo "UNSCALED_UNITS=mm/h*32" -mo "SCALED_UNITS=mm/h" -mo "SCALE_FACTOR=0.03125" \
                        /vsistdin/\?buffer_limit=-1 "$OUT_FILE_PATH" >/dev/null 2>&1
        count=$((count + 1))
    done

    rm -rf "$TEMP_DIR"
    echo "OK: $BASE_FILE ($count files)"
}
export -f convert_one_tar

echo "Converting $(ls "$DATA_DIR"/*.dat.gz.tar 2>/dev/null | wc -l) archives with $WORKERS parallel workers..."
ls "$DATA_DIR"/*.dat.gz.tar | xargs -P "$WORKERS" -I {} bash -c "convert_one_tar '{}' '$OUT_DIR' '$DIR'"
echo "Done."
