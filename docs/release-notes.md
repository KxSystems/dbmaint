# DBmaint Module Release Notes

_This document provides the version history of the KDB-X DBmaint Module, detailing released versions, fixes, and improvements._

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
