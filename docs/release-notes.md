# DBmaint Module Release Notes

_This document provides the version history of the KDB-X DBmaint Module, detailing released versions, fixes, and improvements._

## 2.0.0

**Release Date**: 2026-04-23

### Fixes and Improvements

- Flat table support.
- Compression support.
- New health check functions: `checkTabExistence`, `checkColFiles`, and `checkDotDEquality`.
- Pre-modification health check prevents partial overwrites.
- Errors are raised explicitly instead of being silently ignored.
- New table function: `copyTab`.
- Improved documentation.
- `addCol` fails if the column already exists.
- `reorderCols` also accepts a single column name.
- Improved secondary thread handling.
- fix: `addMissingCols`, `fnCol` (therefore `castCol`, `setAttr`, and `rmAttr`) preserve compression.
- fix: `addCol` and `addMissingCols` properly handle nested columns.
- fix: `copyCol`, `delCol` and `renameCol` properly handle anymap columns.
- fix: partition directories ending with `$` are ignored.
- fix: `renameTab`, `renameCol`, and `copyCol` tolerate whitespace in directory/file names.
- NUC: `addTab` API change.
- NUC: `addTab` writes input data untouched (does not apply `0#`).
- NUC: `addCol` API change — the 5th parameter is now a dictionary instead of a symbol enumeration file.

## 1.0.0

**Release Date**: 2026-02-27

### Fixes and Improvements

The DBmaint module was developed based on [dbmaint.q](https://github.com/KxSystems/kdb/blob/master/utils/dbmaint.md). Key changes include:

- Clearer function and variable names, adopting camel case for consistency.
- Support for splayed, partitioned, and segmented databases.
- Enhanced compatibility with nested column types.
- Parallel processing capabilities for large datasets.
- The `addCol` function no longer requires a symbol domain for new columns of non-symbol types.
- The `fnCol`, `castCol`, `setAttr`, `rmAttr` functions now accept an optional parameter to specify partitions to consider.
