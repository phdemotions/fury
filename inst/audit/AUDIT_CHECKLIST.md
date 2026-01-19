# Novice Workflow Audit + Tutorial Audit — fury Package

**Primary creator & maintainer:** Josh Gonzales (GitHub: `phdemotions`)
**Canonical source:** `/phdemotions`

---

## Purpose

This audit checklist verifies that the `fury` package is:

1. **Usable for novice researchers** who are new to R and to statistics
2. **Capable of ingesting SPSS (.sav) files** with end-to-end runnable tutorials
3. **Producing analysis-eligible datasets per declared rules** (NOT "cleaned data" or "final datasets")
4. **Generating all artifacts required for Methods section reporting** with conservative language
5. **Rerunnable with deterministic pass/fail outcomes** after code changes

This audit does NOT verify modeling, scoring, construct validation, or APA rendering (out of scope for `fury`).

---

## How to Use This Checklist

- Each item has a **PASS/FAIL** outcome
- **PASS** means the specified artifact exists, contains the required content, and uses conservative language
- **FAIL** means the artifact is missing, incomplete, or uses inflated language (e.g., "final sample", "cleaned data", "validated", "reliability")
- Run the audit harness: `Rscript tools/run_audit.R` to automate most checks
- Manual review is required for language checks and tutorial completeness

---

## Section 1: Novice Walkthrough Audit (Fresh Session)

**Purpose:** Verify that a researcher with no R experience can follow the README and run a minimal workflow.

### 1.1 README Contains Minimal Working Example with .sav Ingestion

**Required:**
- README has a "Quick Start for Beginners" section
- Section includes an example showing how to ingest a `.sav` file
- Example is wrapped in `\dontrun{}` or similar if it references external data
- Example shows how to run `fury_run()` or equivalent entry point

**Command:**
```r
# Read README.md and verify presence of .sav ingestion example
readme_text <- readLines("README.md")
grep("\\.sav", readme_text, value = TRUE)
```

**Expected artifact:**
- At least one line in `README.md` mentioning `.sav` file format

**FAIL if:**
- No `.sav` example exists
- Example is incomplete (no `fury_run()` call)

---

### 1.2 README Contains Novice Warning: Flags vs Exclusions

**Required:**
- README explicitly warns that `action: "flag"` does NOT remove cases
- README uses clear language: "Flags do not remove cases unless an exclusion rule is declared"
- README distinguishes between `"flag"` and `"exclude"` actions

**Command:**
```r
# Check for flag/exclude warning in README
readme_text <- readLines("README.md")
any(grepl("flag.*exclude|exclude.*flag", readme_text, ignore.case = TRUE))
```

**Expected artifact:**
- Section in README explaining the difference between flagging and excluding

**FAIL if:**
- No warning exists
- Warning uses ambiguous language like "flags usually remove cases" or "flags may affect your data"

---

### 1.3 README Uses Conservative Language (No Inflated Claims)

**Required:**
- README says "analysis-eligible per declared rules" or similar conservative phrasing
- README does NOT say: "final dataset", "cleaned data", "validated data", "final sample"
- README does NOT claim `fury` performs: reliability analysis, validation, mediation, manipulation checks

**Command:**
```r
# Scan README for banned inflated language
banned_terms <- c("final dataset", "cleaned data", "final sample",
                  "validated", "reliability", "Cronbach", "mediator",
                  "manipulation check")
readme_text <- tolower(paste(readLines("README.md"), collapse = " "))
any(sapply(banned_terms, function(x) grepl(x, readme_text, fixed = TRUE)))
```

**Expected artifact:**
- `README.md` passes language tripwire (no banned terms)

**FAIL if:**
- Any banned term is found (except in negative statements like "fury does NOT perform validation")

---

## Section 2: SPSS .sav Ingestion Audit

**Purpose:** Verify that `.sav` files can be ingested and that tutorials exist for this workflow.

### 2.1 Toy .sav Fixture Exists in inst/extdata

**Required:**
- At least one `.sav` file exists in `inst/extdata/`
- File is minimal (< 5 KB), non-licensed, synthetic
- File contains labelled variables with value labels and variable labels

**Command:**
```r
# Check for .sav fixture
sav_files <- list.files("inst/extdata", pattern = "\\.sav$", full.names = TRUE)
length(sav_files) > 0
```

**Expected artifact:**
- `inst/extdata/test_minimal.sav` (or similar)

**FAIL if:**
- No `.sav` file exists
- File is too large (> 10 KB) or contains real participant data

---

### 2.2 .sav Ingestion Function Exists and Is Documented

**Required:**
- Function exists to ingest `.sav` files (e.g., `ingest_sav()` or internal equivalent)
- Function is documented with roxygen2
- Documentation mentions that `haven` is required (Suggests dependency)

**Command:**
```r
# Check for documented .sav ingestion function
exists("ingest_sav", where = asNamespace("fury"), mode = "function")
# Or check R/*.R files for haven::read_sav usage
```

**Expected artifact:**
- Function definition in `R/ingest_sav.R` or equivalent
- Roxygen2 documentation with `@param`, `@return`

**FAIL if:**
- No `.sav` ingestion capability exists
- Function is undocumented

---

### 2.3 .sav Ingestion Produces RAW Codebook

**Required:**
- Ingesting a `.sav` file produces a `raw_codebook.csv` artifact
- Codebook includes: variable name, variable label (item text), value labels
- Codebook does NOT include computed scores, reliability estimates, or factor loadings

**Command:**
```r
# Run minimal .sav ingestion workflow
library(fury)
spec_path <- system.file("extdata", "test_spec.yaml", package = "fury") # if exists
result <- fury_run(spec_path, out_dir = tempdir())
codebook_path <- file.path(result$artifacts$audit_dir, "raw_codebook.csv")
file.exists(codebook_path)
```

**Expected artifact:**
- `audit/raw_codebook.csv` with columns: variable, label, value_labels (or similar)

**FAIL if:**
- No codebook is produced
- Codebook contains scoring/validation columns

---

## Section 3: Partitioning + Screening + CONSORT Audit

**Purpose:** Verify that pilot/pretest partitioning, screening rules, and CONSORT flow artifacts are generated.

### 3.1 Pilot/Pretest Partitioning Is Declared and Tracked

**Required:**
- Spec allows declaration of pilot/pretest partitions (by date range or ID list)
- If no partition is declared, `decision_registry.csv` says "Pilot partition present: No"
- If partition is declared, `screening_summary.csv` shows pilot counts

**Command:**
```r
# Run workflow with no pilot declaration
result <- fury_run("spec_no_pilot.yaml", out_dir = tempdir())
decision_registry <- read.csv(file.path(result$artifacts$audit_dir, "decision_registry.csv"))
any(grepl("Pilot partition present: No", decision_registry$value, ignore.case = TRUE))
```

**Expected artifact:**
- `audit/decision_registry.csv` with explicit "Yes/No" for pilot partition presence

**FAIL if:**
- Decision registry does not track pilot declaration
- Undeclared pilots are silently merged into main sample without warning

---

### 3.2 Screening Rules Generate CONSORT Flow Artifacts

**Required:**
- Eligibility rules (e.g., `required_nonmissing`) produce exclusion counts
- Quality flags (e.g., attention checks) produce flagged-but-retained counts
- CONSORT flow artifact shows: N enrolled → N after exclusions → N flagged → N analysis-eligible
- Artifact uses conservative language: "analysis-eligible per declared rules" (NOT "final sample")

**Command:**
```r
# Run workflow with screening rules
result <- fury_run("spec_with_screening.yaml", out_dir = tempdir())
consort_path <- file.path(result$artifacts$audit_dir, "consort_flow.csv")
consort_data <- read.csv(consort_path)
all(c("stage", "n", "description") %in% colnames(consort_data))
```

**Expected artifact:**
- `audit/consort_flow.csv` with columns: stage, n, description

**FAIL if:**
- No CONSORT artifact is produced
- Artifact uses inflated language ("final sample", "validated participants")

---

### 3.3 Flags Do Not Remove Cases (Traceability Preserved)

**Required:**
- Cases with `action: "flag"` are marked in the dataset but NOT removed
- Flagged cases appear in a flag summary artifact (e.g., `screening_summary.csv`)
- Warnings artifact alerts user if flagged cases remain in analysis pool

**Command:**
```r
# Run workflow with flag rule
result <- fury_run("spec_with_flags.yaml", out_dir = tempdir())
warnings_path <- file.path(result$artifacts$audit_dir, "warnings.csv")
warnings_data <- read.csv(warnings_path)
any(grepl("flagged cases", warnings_data$message, ignore.case = TRUE))
```

**Expected artifact:**
- `audit/warnings.csv` with message about flagged cases if they remain in data

**FAIL if:**
- Flagged cases are silently removed
- No warning is issued

---

## Section 4: Methods Write-Up Readiness Audit (Artifact-Only)

**Purpose:** Verify that all artifacts required for APA 7 Methods section reporting are generated.

### 4.1 Decision Registry Documents What Was/Wasn't Declared

**Required:**
- `decision_registry.csv` exists
- Registry lists: pilot declared (Yes/No), pretest declared (Yes/No), exclusion rules declared (Yes/No), quality flags declared (Yes/No)
- Registry is human-readable (can be opened in Excel)

**Command:**
```r
# Check decision registry structure
result <- fury_run("minimal_spec.yaml", out_dir = tempdir())
registry_path <- file.path(result$artifacts$audit_dir, "decision_registry.csv")
registry_data <- read.csv(registry_path)
all(c("decision_type", "value") %in% colnames(registry_data))
```

**Expected artifact:**
- `audit/decision_registry.csv` with decision_type and value columns

**FAIL if:**
- Decision registry is missing
- Registry format is not CSV or is not human-readable

---

### 4.2 Source Manifest Tracks Data Provenance

**Required:**
- `source_manifest.csv` exists
- Manifest lists all data sources (file paths, formats, ingestion timestamps)
- Manifest is suitable for citation in Methods section (e.g., "Data were ingested from [file] on [date]")

**Command:**
```r
# Check source manifest
result <- fury_run("minimal_spec.yaml", out_dir = tempdir())
manifest_path <- file.path(result$artifacts$audit_dir, "source_manifest.csv")
manifest_data <- read.csv(manifest_path)
all(c("source_id", "file", "format") %in% colnames(manifest_data))
```

**Expected artifact:**
- `audit/source_manifest.csv` with source_id, file, format, timestamp columns

**FAIL if:**
- Source manifest is missing
- Manifest does not include file paths or formats

---

### 4.3 Screening Summary Is Concise and Conservative

**Required:**
- `screening_summary.csv` exists
- Summary includes: N enrolled, N excluded (with reasons), N flagged, N analysis-eligible
- Summary uses conservative language (no "final sample", "cleaned data")

**Command:**
```r
# Check screening summary
result <- fury_run("spec_with_screening.yaml", out_dir = tempdir())
summary_path <- file.path(result$artifacts$audit_dir, "screening_summary.csv")
summary_data <- read.csv(summary_path)
any(grepl("analysis-eligible|analysis pool", tolower(paste(summary_data, collapse = " "))))
```

**Expected artifact:**
- `audit/screening_summary.csv` with conservative phrasing

**FAIL if:**
- Summary uses inflated language
- Summary claims "data cleaning" or "validation" occurred

---

## Section 5: Silent Misuse Audit

**Purpose:** Verify that `fury` detects and warns about common novice mistakes.

### 5.1 Warning Issued If Pilot Not Declared

**Required:**
- If spec contains no pilot/pretest partition, `warnings.csv` or `decision_registry.csv` clearly states "Pilot partition present: No"
- No silent assumption that all data are main study data

**Command:**
```r
# Run workflow with no pilot declaration
result <- fury_run("spec_no_pilot.yaml", out_dir = tempdir())
decision_registry <- read.csv(file.path(result$artifacts$audit_dir, "decision_registry.csv"))
any(grepl("Pilot.*No", decision_registry$value, ignore.case = TRUE))
```

**Expected artifact:**
- `audit/decision_registry.csv` explicitly shows "Pilot partition present: No"

**FAIL if:**
- No statement about pilot declaration status

---

### 5.2 Warning Issued If Flagged Cases Remain in Analysis Pool

**Required:**
- If `action: "flag"` is used and flagged cases are not excluded, `warnings.csv` contains a message
- Message warns user to review flagged cases before analysis

**Command:**
```r
# Run workflow with flags but no exclusions
result <- fury_run("spec_flags_only.yaml", out_dir = tempdir())
warnings_path <- file.path(result$artifacts$audit_dir, "warnings.csv")
if (file.exists(warnings_path)) {
  warnings_data <- read.csv(warnings_path)
  any(grepl("flagged", warnings_data$message, ignore.case = TRUE))
}
```

**Expected artifact:**
- `audit/warnings.csv` with flagged case warning (if applicable)

**FAIL if:**
- No warning when flagged cases remain

---

### 5.3 No Silent Data Mutations

**Required:**
- `fury` does NOT recode variables, compute scores, impute missing values, or transform data
- All ingested data is preserved in original form
- Any derived variables (e.g., flag columns) are clearly marked as added by `fury`

**Command:**
```r
# Verify no silent mutations by comparing ingested data to source
# This is a conceptual check; implementation depends on fury internals
# Audit harness should verify raw data == source data (except for added flag columns)
```

**Expected artifact:**
- No silent mutations (verified in audit harness)

**FAIL if:**
- Variables are recoded or transformed without explicit documentation

---

## Section 6: Determinism Audit

**Purpose:** Verify that running the same spec twice produces identical outputs (except timestamps).

### 6.1 Identical Inputs → Identical Outputs

**Required:**
- Run the same spec file twice with the same input data
- All CSV artifacts (excluding explicit timestamp columns) are identical
- Bundle hash index (if implemented) is identical

**Command:**
```r
# Run audit harness twice
source("tools/run_audit.R")
# Harness should verify determinism internally
```

**Expected artifact:**
- Audit harness reports "PASS: Determinism check"

**FAIL if:**
- Any differences in output artifacts (excluding timestamps)
- Non-deterministic sorting, random sampling, or time-dependent logic

---

### 6.2 Filesystem Writes Only Under tempdir() or User-Specified out_dir

**Required:**
- `fury` never writes to working directory unless `out_dir` is explicitly set
- All tests use `tempdir()`
- No network access during tests

**Command:**
```r
# Run tests with filesystem monitoring
# testthat tests should verify no writes outside tempdir()
```

**Expected artifact:**
- All tests pass `R CMD check --as-cran`

**FAIL if:**
- Writes occur outside `tempdir()` or `out_dir`
- Tests require network access

---

## Section 7: Tutorial Completeness Cross-Check

**Purpose:** Verify that required tutorials exist and meet minimum standards (see `TUTORIAL_CHECKLIST.md`).

### 7.1 Tutorial 1 Exists: "Ingest a Single SPSS .sav and Generate RAW Codebook"

**Required:**
- Tutorial exists (vignette, inst/examples/, or README section)
- Tutorial shows: install, load package, run `fury_run()` on `.sav` file, locate `raw_codebook.csv`
- Tutorial includes conservative language callout box

**Command:**
```r
# Check for vignette or example file
vignette_files <- list.files("vignettes", pattern = "\\.Rmd$", full.names = TRUE)
any(grepl("sav|spss|codebook", tolower(vignette_files)))
```

**Expected artifact:**
- Vignette or example demonstrating `.sav` ingestion

**FAIL if:**
- No tutorial exists

---

### 7.2 Tutorial 2 Exists: "Ingest Multiple Sources and Preserve Provenance"

**Required:**
- Tutorial shows how to ingest pilot + main data from separate files
- Tutorial demonstrates `source_manifest.csv` artifact
- Tutorial explains how provenance is tracked

**Command:**
```r
# Check for multi-source example in vignettes or inst/examples/
grep -r "pilot.*main|multiple.*source" vignettes/ inst/examples/
```

**Expected artifact:**
- Tutorial or example showing multi-source ingestion

**FAIL if:**
- No multi-source tutorial exists

---

### 7.3 Tutorial 3 Exists: "Apply Screening Rules and Generate CONSORT Flow"

**Required:**
- Tutorial shows how to declare eligibility rules and quality flags
- Tutorial demonstrates `consort_flow.csv` artifact
- Tutorial includes flags vs. exclusions callout box

**Command:**
```r
# Check for screening example in vignettes or inst/examples/
grep -r "screening|consort|eligibility" vignettes/ inst/examples/
```

**Expected artifact:**
- Tutorial or example showing screening workflow

**FAIL if:**
- No screening tutorial exists

---

## Summary: Audit Pass Criteria

**To pass the full audit, ALL of the following must be true:**

1. README contains `.sav` ingestion example and novice warnings
2. README uses conservative language (no inflated claims)
3. At least one `.sav` fixture exists in `inst/extdata/`
4. `.sav` ingestion produces a RAW codebook
5. Pilot/pretest partitions are tracked in `decision_registry.csv`
6. CONSORT flow artifact is generated with conservative language
7. Flags do not remove cases (warnings are issued)
8. All Methods artifacts exist: decision registry, source manifest, screening summary
9. Warnings are issued for common novice mistakes (missing pilot declaration, flagged cases)
10. Determinism: same inputs → same outputs (excluding timestamps)
11. Filesystem writes only under `tempdir()` or `out_dir`
12. Required tutorials exist and meet minimum standards (see `TUTORIAL_CHECKLIST.md`)

**If any item FAILS, the audit FAILS.**

---

## Running the Audit

**Automated:**
```bash
Rscript tools/run_audit.R
```

**Manual:**
1. Open this checklist
2. Run each command in a fresh R session
3. Verify expected artifacts
4. Mark each item as PASS/FAIL

**Test suite:**
```r
# Run testthat tests that enforce audit invariants
testthat::test_file("tests/testthat/test-audit-invariants.R")
```

---

## What This Audit Does NOT Check (Out of Scope)

- **Modeling or statistical analysis** (fury does not perform these)
- **Scoring or scale construction** (fury does not compute scores)
- **Construct validation** (no reliability, factor analysis, SEM)
- **APA-formatted rendering** (fury only produces artifacts, not reports)
- **Data quality beyond declared rules** (fury applies only user-declared rules, not inferred ones)
- **External data sources** (audit uses only in-package fixtures)

---

## Maintenance

- Re-run this audit after any changes to `fury` APIs, documentation, or artifact generation logic
- Update this checklist if new artifact types are added
- Do NOT expand scope to include analysis, scoring, or validation (governance violation)

---

**Last updated:** 2026-01-19
**Audit version:** 1.0.0
