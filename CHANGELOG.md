# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased](https://github.com/mlcast-community/mlcast-dataset-metoffice-nimrod)

## [v0.1.0](https://github.com/mlcast-community/mlcast-dataset-metoffice-nimrod/releases/tag/v0.1.0) - 2026-02-18

### Added

- `download_range.sh`: parallel date-range downloader for CEDA NIMROD archives (reads Bearer token from `API_KEY` env var or `access_token` file)
- `download_data.sh`: simple recursive wget mirror of the full CEDA archive
- `convert_data_parallel.sh`: parallel converter — unpacks daily `.dat.gz.tar` archives and converts each NIMROD file to GeoTIFF via `nimrod.py` + `gdal_translate` (int16, EPSG:27700, ZSTD, scale 0.03125)
- `convert_data.sh`: serial version of the converter
- `nimrod.py`: NIMROD format parser by Richard Thomas (Artistic License 2.0), sourced from <https://github.com/richard-thomas/MetOffice_NIMROD>
- Dual license: Apache-2.0 OR BSD-3-Clause (own scripts only; `nimrod.py` retains Artistic License 2.0)
- pre-commit configuration (trailing-whitespace, end-of-file-fixer, isort, black, flake8; `nimrod.py` excluded from formatting)
