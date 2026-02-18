#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $DIR

# setup error handling function
function error_exit {
    echo "$1" 1>&2
}
trap 'error_exit "Error: $0:$LINENO $BASH_COMMAND"' ERR

# check that $1 is set and is a directory
if [ -z "$1" ] || [ ! -d "$1" ]; then
    echo "Error: $1 is not a directory"
    exit 1
fi
DATA_DIR="$1"

# create the output directory if not provided as an argument or if it does not exist
if [ -z "$2" ]; then
    OUT_DIR="$DATA_DIR/tiff"
else
    OUT_DIR="$2"
fi
mkdir -p $OUT_DIR

# loop through all files (.dat.gz.tar) in the directory and untar them in a temporary directory
for FILE in $DATA_DIR/*.dat.gz.tar; do
    if [ -f "$FILE" ]; then
        echo "Processing $FILE"

        # extract date from the filename metoffice-c-band-rain-radar_uk_20040406_1km-composite.dat.gz.tar
        BASE_FILE=$(basename $FILE)
        BASE_FILE=${BASE_FILE%.dat.gz.tar}

        TEMP_DIR=$(mktemp -d)
        tar -xf $FILE -C $TEMP_DIR
        for DAT_FILE in $( ls "$TEMP_DIR" ); do
            if [ -f "$TEMP_DIR/$DAT_FILE" ]; then
                # destination filename is the same as the source filename, but with a .tiff extension and without the .dat.gz extension
                OUT_FILE=$(echo $DAT_FILE | sed 's/\.dat\.gz//').tiff

                # create the output directory if it does not exist
                mkdir -p $OUT_DIR/$BASE_FILE
                OUT_FILE_PATH="$OUT_DIR/$BASE_FILE/$OUT_FILE"

                # skip if the output file already exists
                if [ -f "$OUT_FILE_PATH" ]; then
                    echo "Skipping $DAT_FILE -> $OUT_FILE_PATH"
                    continue
                fi

                # process the file
                echo "Processing $DAT_FILE -> $OUT_FILE_PATH"
                gunzip -c $TEMP_DIR/$DAT_FILE | \
                python3 nimrod.py -x /dev/stdin /dev/stdout 2> /dev/null | \
                gdal_translate -if AAIGrid -of GTiff -ot Int16 -strict \
                                -a_srs EPSG:27700 -a_scale 0.03125 \
                                -co COMPRESS=ZSTD -co PREDICTOR=2 -co TILED=YES \
                                -mo UNSCALED_UNITS="mm/h\*32" -mo SCALED_UNITS="mm/h" -mo SCALE_FACTOR="0.03125" \
                                /vsistdin/\?buffer_limit=-1 $OUT_FILE_PATH > /dev/null 2>&1
            fi
        done
        rm -rf $TEMP_DIR
    fi
done

# example uasge:
# ./convert_data.sh /path/to/data/YEAR /path/to/output
