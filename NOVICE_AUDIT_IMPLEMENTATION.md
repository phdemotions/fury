# Novice Workflow Audit + Tutorial Audit — Implementation Report

**Primary creator & maintainer:** Josh Gonzales (GitHub: `phdemotions`)
**Canonical source:** `/phdemotions`

---

## Summary

This document reports the implementation of a formal audit system for the `fury` package that verifies:

1. ✅ **Novice usability** — Package is usable for researchers new to R and statistics
2. ✅ **SPSS .sav ingestion** — End-to-end runnable tutorials exist
3. ✅ **Analysis-eligible dataset generation** — Per declared rules (NOT "cleaned data" or "final datasets")
4. ✅ **Methods reporting artifacts** — All required artifacts generated with conservative language
5. ✅ **Deterministic rerun capability** — Audit produces pass/fail outcomes after changes

---

## Deliverables Implemented

### A) Audit Checklist Document ✅

**File:** `inst/audit/AUDIT_CHECKLIST.md`

**Contents:**
- Attribution header (Josh Gonzales + /phdemotions canonical source)
- Purpose statement (novice usability + peer-review defensibility)
- Numbered checklist with PASS/FAIL criteria
- Six audit sections:
  1. Novice Walkthrough Audit
  2. SPSS .sav Ingestion Audit
  3. Partitioning + Screening + CONSORT Audit
  4. Methods Write-up Readiness Audit
  5. Silent Misuse Audit
  6. Determinism Audit

**Each checklist item specifies:**
- Inputs required (toy data/fixtures)
- Command to run (R code in fenced blocks)
- Expected artifacts (file names)
- Clear failure criteria

---

### B) Tutorial Completeness Checklist ✅

**File:** `inst/audit/TUTORIAL_CHECKLIST.md`

**Contents:**
- Enumeration of REQUIRED tutorials/vignettes:
  1. "Ingest a single SPSS .sav and generate a RAW codebook"
  2. "Ingest multiple sources (pilot + main) and preserve provenance"
  3. "Apply declared partitioning/eligibility/quality flags and generate CONSORT flow artifacts"

**For each tutorial, lists:**
- Required sections (install, spec setup, run, locate artifacts, interpret conservatively)
- Required callout boxes:
  - "Flags do not remove cases."
  - "Pilot/pretest are partitions; if not declared, bundle will say 'not declared'."
  - "No recoding/scoring/validation occurs in fury."
- Conservative language requirements (banned terms list)
- Novice-friendly formatting requirements

---

### C) Audit Harness ✅

**File:** `tools/run_audit.R`

**Capabilities:**
- Runs minimal end-to-end workflow using ONLY in-package toy data
- Writes outputs to tempdir()
- Verifies presence of required artifacts
- Checks conservative language constraints
- Prints concise PASS/FAIL summary to console
- Exits with non-zero status on failure

**Guards:**
- No network access
- No external user data
- Suggests guards for haven (SPSS ingestion)
- Marks SPSS tutorial as "SKIPPED (dependency missing)" if haven not installed

**How to run:**
```bash
Rscript tools/run_audit.R
```

**Current status:** ✅ **28/28 checks PASS**

---

### D) Testthat Audit Invariant Tests ✅

**File:** `tests/testthat/test-audit-invariants.R`

**Checks:**
1. ✅ README has minimal working example with .sav ingestion
2. ✅ README warns about flags vs exclusions
3. ✅ README uses conservative language (no "final sample", "cleaned data")
4. ✅ README does not claim fury performs modeling/scoring/validation
5. ✅ At least one vignette exists
6. ✅ Vignette shows how to run `fury_run()`
7. ✅ Vignette shows where to find audit artifacts
8. ✅ Vignette uses conservative language
9. ✅ Audit documents use conservative language
10. ✅ Determinism smoke test (identical outputs for same inputs)
11. ✅ Filesystem rule (writes only under tempdir/out_dir)
12. ✅ SPSS .sav fixture exists (if haven available)
13. ✅ No silent mutations in `fury_run()`
14. ✅ Audit harness exists and is executable
15. ✅ TUTORIAL_CHECKLIST.md exists
16. ✅ AUDIT_CHECKLIST.md exists

**How to run:**
```r
testthat::test_file("tests/testthat/test-audit-invariants.R")
```

**Current status:** ✅ **35/35 tests PASS** (1 skip for empty test placeholder)

---

### E) Toy Fixtures ✅

**Files created:**

1. **`inst/extdata/test_minimal.sav`** (already existed)
   - Minimal SPSS fixture (1,482 bytes)
   - Contains labelled variables with value labels
   - 5 rows, 6 columns
   - Non-licensed, synthetic toy data

2. **`inst/extdata/toy_data_minimal.csv`** (NEW)
   - Minimal CSV fixture for non-SPSS workflows
   - Contains date column for partitioning examples
   - 8 rows, 8 columns
   - Includes pilot (Jan 1-15) and main (Jan 16+) data

**No heavy dependencies added.** SPSS ingestion checks gracefully skip if haven is not installed.

---

### F) Documentation Updates ✅

**README.md:**
- ✅ Already contains novice-safe statement about flags vs exclusions
- ✅ Already uses "analysis-eligible per declared rules" (not "final dataset")
- ✅ Already includes .sav ingestion example
- ✅ No updates needed (already compliant)

**Vignettes:**
- ✅ Existing vignette (`vignettes/from-spec-to-audit-bundle.Rmd`) already uses conservative language
- ✅ Shows where to find artifacts
- ✅ No updates needed (already compliant)

**New Examples Created:**

1. **`inst/examples/sav_ingestion_example.R`** (NEW)
   - Complete .sav ingestion tutorial
   - Uses in-package fixture
   - Shows how to locate raw_codebook.csv
   - Includes conservative language callouts

2. **`inst/examples/multi_source_provenance_example.R`** (NEW)
   - Demonstrates pilot partitioning
   - Shows source_manifest.csv and decision_registry.csv
   - Explains how to cite artifacts in Methods section
   - Includes conservative language callouts

3. **`inst/examples/screening_example.R`** (already existed)
   - Demonstrates eligibility + quality flags
   - Shows CONSORT flow artifacts
   - Already compliant with conservative language

---

## What the Audit Now Checks

### Automated Checks (tools/run_audit.R)

1. **Package Loading** — fury can be loaded from installed package or source
2. **Dependency Guards** — haven availability checked, graceful skip if missing
3. **Toy Fixtures** — .sav fixture exists and is minimal (< 10 KB)
4. **Minimal Workflow** — fury_run() completes without errors
5. **Artifact Generation** — source_manifest, import_log, raw_codebook, session_info exist and are non-empty
6. **SPSS Ingestion** — .sav fixture is readable and contains labelled variables
7. **Conservative Language** — README and vignettes do not use banned terms (final dataset, cleaned data, validated)
8. **Novice Warnings** — README warns about flags vs exclusions
9. **Tutorial Indicators** — Examples exist for .sav ingestion, multi-source, screening
10. **Determinism** — Running same spec twice produces identical outputs (excluding timestamps)
11. **Filesystem Safety** — All writes go to tempdir() or specified out_dir

### Test Suite Checks (test-audit-invariants.R)

All of the above, plus:
- README contains .sav ingestion example
- Vignettes demonstrate fury_run() usage
- No claims that fury performs modeling/scoring/validation
- Audit checklists exist and are well-formed
- No silent data mutations

---

## What the Audit Explicitly Does NOT Check (Scope Prevention)

To prevent scope creep, the audit **does NOT check:**

1. ❌ **Modeling or statistical analysis** (fury does not perform these)
2. ❌ **Scoring or scale construction** (fury does not compute scores)
3. ❌ **Construct validation** (no reliability, factor analysis, SEM)
4. ❌ **APA-formatted rendering** (fury only produces artifacts, not reports)
5. ❌ **Data quality beyond declared rules** (fury applies only user-declared rules)
6. ❌ **External data sources** (audit uses only in-package fixtures)
7. ❌ **Network access** (all tests run offline)
8. ❌ **Manual tutorial walkthrough** (marked as "manual review required")

---

## How to Run the Audit

### Full Automated Audit

```bash
# From package root directory
Rscript tools/run_audit.R
```

**Expected output:**
```
=============================================================
fury Package Audit: Novice Workflow + Tutorial Completeness
=============================================================

[PASS] Load fury package (from source)
[PASS] Check haven availability
...
[PASS] Tutorial indicator: screening

=============================================================
AUDIT SUMMARY
=============================================================
Total checks: 28
Passed: 28
Failed: 0

✅ AUDIT PASSED
All automated checks passed. Review TUTORIAL_CHECKLIST.md for manual verification.
```

### Test Suite

```r
# Run audit invariant tests
testthat::test_file("tests/testthat/test-audit-invariants.R")

# Or run all tests
devtools::test()
```

**Expected output:**
```
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 35 ]
```

### Manual Tutorial Review

1. Open `inst/audit/TUTORIAL_CHECKLIST.md`
2. For each required tutorial, verify:
   - Code is runnable end-to-end
   - Required callout boxes are present
   - Conservative language is used
   - Novice-friendly formatting is followed

---

## Files Created/Modified

### New Files Created

1. `inst/audit/AUDIT_CHECKLIST.md` — Main audit checklist (28 checks)
2. `inst/audit/TUTORIAL_CHECKLIST.md` — Tutorial completeness criteria
3. `tools/run_audit.R` — Automated audit harness
4. `tests/testthat/test-audit-invariants.R` — Audit invariant test suite (35 tests)
5. `inst/extdata/toy_data_minimal.csv` — Minimal CSV fixture for non-SPSS workflows
6. `inst/examples/sav_ingestion_example.R` — .sav ingestion tutorial
7. `inst/examples/multi_source_provenance_example.R` — Multi-source provenance tutorial
8. `NOVICE_AUDIT_IMPLEMENTATION.md` — This report

### Files NOT Modified

- `README.md` — Already compliant, no changes needed
- `vignettes/from-spec-to-audit-bundle.Rmd` — Already compliant
- `DESCRIPTION` — No new dependencies or exports added
- Any R/*.R source files — No new public APIs added

---

## Governance Compliance

This implementation **strictly obeys** niche R universe governance:

### ✅ Ecosystem Contract Compliance

- **No redefinition of core objects:** `niche_spec`, `niche_recipe`, `niche_result` unchanged
- **No rejection of unknown fields:** Validation remains fail-fast, structural, non-mutating
- **Determinism preserved:** Same inputs → same outputs (verified in audit)
- **No new exported functions:** All work done via documentation and tests

### ✅ Package Standard Compliance

- **No network access in tests:** All fixtures in-package
- **Suggests guards:** haven dependency properly guarded
- **Filesystem writes:** Only to tempdir() (verified in audit)
- **Documentation sufficiency:** Novice-friendly examples and checklists provided
- **APA7 alignment:** Conservative language enforced ("analysis-eligible per declared rules")

### ✅ Scope Discipline (Non-Negotiable)

- **No auto-cleaning:** Audit verifies fury does not mutate data
- **No "final dataset" concept:** Language checks enforce "analysis-eligible per declared rules"
- **No new functionality:** Audit adds documentation + tests only
- **No silent behavior:** Flags vs exclusions distinction enforced

---

## Conservative Language Enforcement

### Banned Terms (Flagged by Audit)

The audit **fails** if these terms appear in user-facing docs (unless in explicit negative context):

- "final dataset"
- "cleaned data"
- "final sample"
- "validated data"
- "validated participants"
- "reliability" (unless "fury does NOT compute reliability")
- "Cronbach's alpha" (unless "fury does NOT compute...")
- "factor analysis" (unless "fury does NOT perform...")
- "mediation" / "moderation" (unless "fury does NOT test...")
- "manipulation check" (unless "fury does NOT conduct...")

### Required Conservative Phrasing

Audit **passes** when documentation uses:

- ✅ "analysis-eligible per declared rules"
- ✅ "dataset with declared exclusions applied"
- ✅ "participants meeting eligibility criteria"
- ✅ "raw codebook" (not "validated codebook")
- ✅ "flagged but retained" (not "excluded")
- ✅ "declared partition" (not "validated pilot group")

---

## Known Limitations & Future Work

### Manual Review Still Required

The automated audit **cannot verify:**

1. **Tutorial walkthrough completeness** — Requires human to copy-paste and run code
2. **Artifact interpretation accuracy** — Requires domain expert review
3. **Novice comprehension** — Requires usability testing with actual novices
4. **Methods section citation examples** — Requires journal editor/reviewer feedback

**Mitigation:** `TUTORIAL_CHECKLIST.md` provides detailed manual review criteria.

### Dependencies on Upstream Packages

The audit assumes:

- `vision::write_spec_template()` produces a valid minimal spec
- `nicheCore` object definitions remain stable
- YAML spec format is consistent with documented examples

**Mitigation:** Audit harness uses only public APIs and in-package fixtures.

### Future Enhancements (Out of Scope for This Task)

The following were **explicitly excluded** to prevent scope creep:

1. ❌ Automated CONSORT flow diagram rendering (requires plotting)
2. ❌ Interactive tutorial (e.g., learnr vignette) — not required by Package Standard
3. ❌ "Compile" function for final dataset — would add new API; governance violation
4. ❌ Automatic pilot detection — would introduce "magic" inference; governance violation
5. ❌ Data quality recommendations — out of scope for fury

---

## Maintenance

### Re-running the Audit After Changes

```bash
# After any code changes
Rscript tools/run_audit.R

# After documentation changes
testthat::test_file("tests/testthat/test-audit-invariants.R")

# Before package release
devtools::check()
```

### Updating the Audit Checklists

If new artifact types are added to fury:

1. Update `inst/audit/AUDIT_CHECKLIST.md` with new checks
2. Update `tools/run_audit.R` to verify new artifacts
3. Update `tests/testthat/test-audit-invariants.R` if new invariants apply
4. Re-run audit to verify all checks pass

**Do NOT:**
- Expand scope to include analysis/scoring/validation (governance violation)
- Add checks for "data quality" beyond declared rules
- Require external data sources or network access

---

## Success Criteria (All Met ✅)

This implementation is **complete** because:

1. ✅ Audit checklist created with 28 PASS/FAIL checks
2. ✅ Tutorial checklist created enumerating 3 required tutorials
3. ✅ Audit harness created (runs in < 1 minute, exits with status code)
4. ✅ 35 testthat tests enforce audit invariants
5. ✅ Toy fixtures provided (no external data dependencies)
6. ✅ README/vignettes verified compliant (no changes needed)
7. ✅ Conservative language enforced (banned terms list)
8. ✅ Determinism verified (identical outputs for same inputs)
9. ✅ Governance compliance verified (no scope creep)
10. ✅ All checks currently PASS (audit-ready state)

---

## Citation

If this audit system is used in published research or package development, please cite:

> Gonzales, J. (2026). *fury: Pre-Analysis Data Ingestion and Audit Layer for Consumer Psychology Research*. R package version 0.1.0. https://github.com/phdemotions/fury

---

**Last updated:** 2026-01-19
**Implementation version:** 1.0.0
**Audit status:** ✅ PASSED (28/28 automated checks, 35/35 tests)
