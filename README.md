# mlcast-dataset-metoffice-nimrod

<!-- SPDX-License-Identifier: Apache-2.0 OR BSD-3-Clause -->

Scripts to download UK Met Office NIMROD composite rain radar archives from
[CEDA](https://catalogue.ceda.ac.uk/uuid/27dd6ffba67f667a18c62de5c3456350/)
and convert them to mlcast-compliant GeoTIFFs, ready for ingestion by
[mlcast-dataset-tiff2zarr](https://github.com/mlcast-community/mlcast-dataset-tiff2zarr).

## Dataset

**UK Met Office C-band rain radar 1 km composite** — NIMROD format, 5-minute
timestep, EPSG:27700 (British National Grid), ~1725×2175 pixels, int16 stored
as mm/h×32 (scale factor 0.03125). Archived as daily `.dat.gz.tar` bundles at
[CEDA](https://data.ceda.ac.uk/badc/ukmo-nimrod/data/composite/uk-1km).

> **Access required.** You need a CEDA account and must have been granted
> access to the `ukmo_wx` group. Authenticate via a Bearer token (see
> [CEDA documentation](https://help.ceda.ac.uk/article/5096)).

## Pipeline

```
CEDA (dat.gz.tar)
   └─ download_range.sh      ← parallel date-range downloader
        └─ convert_data_parallel.sh   ← unpack + NIMROD→GeoTIFF (gdal_translate)
             └─ mlcast-dataset-tiff2zarr   ← GeoTIFF→Zarr v3
```

## Scripts

| Script | Description |
|--------|-------------|
| `download_range.sh` | Download daily archives for a date range with parallel workers |
| `download_data.sh` | Simple recursive wget mirror of the full archive |
| `convert_data_parallel.sh` | Unpack `.dat.gz.tar` → GeoTIFF in parallel |
| `convert_data.sh` | Serial version of the converter |

## Usage

### 1. Authenticate

Set your CEDA Bearer token as an environment variable:

```bash
export API_KEY="<your-ceda-bearer-token>"
```

Or place it in an `access_token` file in the same directory (never commit this file).

### 2. Download

```bash
# Download a date range with 4 parallel workers
./download_range.sh 2024-01-01 2024-12-31 /disks/fast/uk-raw 4
```

### 3. Convert to GeoTIFF

Requires `gdal_translate` and `python3` on `PATH`.

```bash
# Parallel conversion (uses all CPU cores by default)
./convert_data_parallel.sh /disks/fast/uk-raw /disks/fast/uk-tiff 16
```

Output: one subdirectory per day, each containing 288 `.tiff` files (5-min, int16, ZSTD-compressed, EPSG:27700, scale 0.03125).

### 4. Convert to Zarr v3

Use [mlcast-dataset-tiff2zarr](https://github.com/mlcast-community/mlcast-dataset-tiff2zarr)
with the bundled `convert_uk_metoffice.sh` script.

## Dependencies

| Tool | Purpose |
|------|---------|
| `wget` | Downloading from CEDA |
| `gdal_translate` (GDAL) | NIMROD ASC → GeoTIFF |
| `python3` | Running `nimrod.py` parser |
| `tar`, `gunzip` | Unpacking daily archives |

## Third-party code

`nimrod.py` is authored by **Richard Thomas** and licensed under the
[Artistic License 2.0](http://opensource.org/licenses/Artistic-2.0).
Source: <https://github.com/richard-thomas/MetOffice_NIMROD>

## Contributing

Please run pre-commit before submitting:

```bash
uv run pre-commit install
uv run pre-commit run --all-files
```

## License

The scripts in this project (excluding `nimrod.py`) are dual-licensed under either:

* Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
* BSD 3-Clause License ([LICENSE-BSD](LICENSE-BSD) or https://opensource.org/licenses/BSD-3-Clause)

at your option. See [LICENSE](LICENSE) for more details.

`nimrod.py` retains its original [Artistic License 2.0](http://opensource.org/licenses/Artistic-2.0).
