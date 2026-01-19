# SPSS `.sav` Ingestion Implementation Summary

**Package:** fury v0.1.0
**Maintainer:** Josh Gonzales (@phdemotions)
**Implementation Date:** 2026-01-18

## Overview

Implemented SPSS `.sav` ingestion support with RAW documentation artifacts for APA7 Methods reporting. This increment adds **pre-analysis data ingestion only** — no scoring, analysis, or construct validation.

---

## Files Changed

### New Files Created

1. **R/ingest_sav.R**
   - Internal reader `fury_read_sav_()` for SPSS `.sav` files
   - Uses `haven::read_sav()` when available (Suggests dependency)
   - Preserves `haven_labelled` columns exactly as imported
   - Captures import warnings deterministically
   - Fails fast with clear novice message if haven unavailable

2. **R/codebook_raw.R**
   - `fury_codebook_raw()`: Generates RAW codebook from imported data
   - `fury_build_value_labels_json_()`: Creates full value-label mapping artifact
   - `fury_methods_helper_table_()`: Generates APA7 Methods helper table
   - `fury_codebook_column_dictionary_()`: Returns fixed column definitions with disclaimers
   - All helper functions for min/max label extraction, preview formatting, etc.

3. **inst/extdata/create_test_sav.R**
   - Script to generate minimal test fixture
   - Creates `test_minimal.sav` with 6 variables, 5 observations
   - Includes labelled variables (satisfaction, condition, etc.) and unlabelled variables

4. **inst/extdata/test_minimal.sav**
   - Minimal SPSS fixture (1482 bytes)
   - Non-licensed toy data for testing

5. **tests/testthat/test-ingest-sav.R**
   - Tests `.sav` ingestion with/without haven
   - Verifies `haven_labelled` preservation
   - Tests deterministic warning capture
   - Ensures no file modification during read

6. **tests/testthat/test-codebook-raw.R**
   - Tests RAW codebook structure (exact 20 columns in specified order)
   - Tests deterministic row ordering
   - Tests response_scale_type classification
   - Tests min/max label extraction
   - Tests value_labels_preview truncation
   - Tests JSON artifact structure
   - Tests methods helper table columns
   - Tests missingness computation

7. **tests/testthat/test-methods-language-tripwire.R**
   - Tripwire tests to prevent scope creep
   - Bans inflated/construct language in dictionary
   - Verifies required disclaimers present
   - Scans package R/ code for banned analysis tokens
   - Tests determinism (same inputs → same hashes)

### Modified Files

1. **DESCRIPTION**
   - Added `haven` to Suggests

2. **R/internal_audit_writers.R**
   - Updated `fury_write_raw_codebook()` to accept optional data parameter
   - When data provided, generates real codebook + all artifacts
   - When data NULL, writes empty placeholder (original behavior)
   - Writes 4 artifacts: raw_codebook.csv, raw_codebook_value_labels.json, methods_items_response_scales.csv, raw_codebook_columns.txt

---

## Artifacts Generated

When `fury_write_raw_codebook()` is called with data:

### 1. `raw_codebook.csv`
RAW codebook with **exactly 20 columns** in stable order:
- `var_name`: Variable name as in raw import
- `item_text_raw`: Verbatim item/question text (from var_label for .sav)
- `var_label`: Haven variable label if present
- `storage_class`: R class (e.g., "haven_labelled,vctrs_vctr,double")
- `is_haven_labelled`: Logical flag
- `response_scale_type`: Descriptive classification (labelled_options, free_text, numeric_unlabelled, datetime_unlabelled, unknown)
- `response_scale_n_options`: Count of value labels (NA if none)
- `response_scale_min_label`: Label at min code (NA if none)
- `response_scale_max_label`: Label at max code (NA if none)
- `value_labels_preview`: First 10 labels in "code = label" format, with "... (+N more)" if truncated
- `value_labels_ref`: Pointer to full mapping in JSON (e.g., "raw_codebook_value_labels.json#var_name")
- `user_missing`: SPSS user-missing metadata if extractable (NA otherwise)
- `n_non_missing`, `n_missing`, `pct_missing`: Missingness stats
- `distinct_values`: Count of distinct non-missing values
- `source_file`, `wave`, `module`, `language`: Provenance fields

**Row ordering:** Grouped by (source_file, wave, module, language), then alphabetical by var_name.

### 2. `raw_codebook_value_labels.json`
Full value-label mappings for variables with labels. Structure:
```json
{
  "var_name": [
    {"code": "1", "label": "Extremely dissatisfied"},
    {"code": "2", "label": "Dissatisfied"},
    ...
  ]
}
```
Codes sorted numerically (or lexicographically if non-numeric).

### 3. `methods_items_response_scales.csv`
Novice-friendly helper table for APA7 Methods reporting. Contains **only**:
- `var_name`, `item_text_raw`, `response_scale_type`, `response_scale_n_options`, `response_scale_min_label`, `response_scale_max_label`, `value_labels_ref`, `source_file`, `wave`, `module`, `language`

**NO** construct claims, reliability, scoring, or analysis columns.

### 4. `raw_codebook_columns.txt`
Fixed text artifact defining all RAW codebook columns. Includes:
- Required disclaimer: "No recoding, scoring, validation, exclusions, or construct claims are performed by fury."
- Terminology note: "'response scale' refers only to response-option format/anchors ... does not imply a psychometric scale or construct measurement."
- Plain-language definition of each column

---

## Behavior Details

### Ingestion (`fury_read_sav_()`)
- **Input validation:** Checks file exists, path is scalar character
- **Haven availability:** Errors cleanly if haven not installed: "Reading SPSS .sav files requires the 'haven' package. Install it with install.packages('haven') and re-run."
- **Preservation:** `haven_labelled` columns remain `haven_labelled` (no conversion to factor/character)
- **Warning capture:** Collects warnings during import as structured log rows (attached as attribute)
- **No side effects:** Does not modify raw file, does not write anything during read

### Codebook Generation (`fury_codebook_raw()`)
- **Determinism:** Same inputs → same outputs; stable column order; stable row order
- **No inference:** No silent data cleaning, no "good/bad quality" judgments
- **Terminology guardrail:** "response scale" means response-option format ONLY (not psychometric scale)
- **Haven label structure:** Correctly handles haven's format (names = labels, values = codes)
- **Missingness:** Based on base R `is.na()` as observed at import (does NOT treat user-missing codes as NA)

### Artifact Writing
- **Filesystem safety:** All writes occur under user-specified `audit_dir` (never package source dir)
- **Deterministic hashing:** Artifacts are deterministic (same content = same hash across runs)
- **No timestamps in hashed content:** Ensures reproducibility

---

## Tests

**Total tests:** 163 (162 pass, 1 skip)
**Coverage:** All required behaviors tested

### Test Modes
1. **Mode 1: haven NOT installed**
   - `.sav` ingestion errors cleanly with install message
   - Test skipped when haven installed (cannot test error path)

2. **Mode 2: haven installed**
   - `haven_labelled` columns preserved
   - RAW codebook has exact 20 columns in specified order
   - Row ordering deterministic
   - Value labels extracted correctly (min/max labels, preview, JSON)
   - Methods helper table contains only specified columns
   - Dictionary includes required disclaimers
   - Determinism verified (same inputs → identical artifacts)

### Tripwire Tests (Scope Creep Prevention)
- Bans: "final sample", "cleaned data", "validated", "reliability", "Cronbach", "mediator", "manipulation check"
- Scans R/ code for banned analysis tokens: `lm(`, `glm(`, `aov(`, `t.test(`, `psych::alpha`, `lavaan::`, etc.
- Verifies all writes occur under temp directories only

### R CMD check
```
Status: OK
0 errors ✔ | 0 warnings ✔ | 0 notes ✔
```

---

## What Was Intentionally NOT Implemented

Per governance (NO SCOPE CREEP):
- ❌ No modeling, scoring, recoding, reverse-coding
- ❌ No imputation, composites, construct validation
- ❌ No manipulation checks, recommendations
- ❌ No conversion of `haven_labelled` to factor/character
- ❌ No interpretation of missingness (no "good/bad" labels)
- ❌ No exported functions (all internal)
- ❌ No .sav writing (read-only ingestion)

---

## How to Run Tests Locally

```r
# Install dependencies
install.packages(c("devtools", "testthat", "haven"))

# Run all tests
devtools::test()

# Run specific test file
devtools::test(filter = "ingest-sav")
devtools::test(filter = "codebook-raw")
devtools::test(filter = "methods-language-tripwire")

# Run R CMD check
devtools::check()
```

---

## Integration Example

```r
library(fury)

# Read .sav file
data <- fury_read_sav_("path/to/data.sav")

# Generate RAW codebook artifacts
temp_dir <- tempfile()
dir.create(temp_dir)

fury_write_raw_codebook(
  audit_dir = temp_dir,
  data = data,
  source_file = "data.sav",
  wave = "W1",
  module = "main",
  language = "en"
)

# Artifacts created:
#   - raw_codebook.csv
#   - raw_codebook_value_labels.json
#   - methods_items_response_scales.csv
#   - raw_codebook_columns.txt

# Read artifacts
codebook <- read.csv(file.path(temp_dir, "raw_codebook.csv"))
methods <- read.csv(file.path(temp_dir, "methods_items_response_scales.csv"))
```

---

## Governance Compliance

✅ **Object authority:** Does not redefine `niche_spec`, `niche_recipe`, `niche_result`
✅ **Validation:** Fail-fast, structural, non-mutating
✅ **Determinism:** Same inputs → same outputs; stable ordering; no time/OS-dependent behavior
✅ **Filesystem:** All writes under `tempdir()`; never writes to package source
✅ **Dependency discipline:** haven in Suggests (guarded); no `:::` usage
✅ **Package standard:** Roxygen docs, testthat tests, README coherent
✅ **Scope:** Pre-analysis ingestion + audit only (no analysis/scoring/validation)
✅ **Terminology:** "response scale" = response-option format (not psychometric scale)

---

## Next Steps (NOT in this increment)

Future increments may add:
- CSV ingestion dispatcher
- Excel ingestion dispatcher
- Multi-file merging logic
- Data quality flags (inventory-only, no exclusions)

**This increment is complete and ready for review.**
