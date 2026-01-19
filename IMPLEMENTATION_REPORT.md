# fury Screening Implementation Report

**Increment:** CONSORT-style partitioning + screening (simple + expert modes)
**Status:** ✓ Complete, all tests passing (259 tests, 0 failures, 0 warnings)
**Primary creator & maintainer-of-record:** Josh Gonzales (GitHub: phdemotions)

## Summary

Implemented novice-friendly CONSORT-style screening for `fury` with two input modes:
1. **SIMPLE MODE** (novice): Structured fields, zero predicates
2. **EXPERT MODE** (advanced): Restricted DSL with safety validation

## Files Added

### Core Implementation (3 new R files)
- `R/screening_compile.R` (465 lines) - Compiles simple/expert configs to rule tables
- `R/screening_engine.R` (240 lines) - Applies compiled rules to data
- `R/consort_flow.R` (380 lines) - Generates CONSORT artifacts

### Updated Files (1 modified)
- `R/fury_write_bundle.R` - Integrated screening artifact writing

### Tests (3 new test files)
- `tests/testthat/test-screening-simple-mode.R` (503 lines, 60 tests)
- `tests/testthat/test-screening-expert-mode.R` (170 lines, 21 tests)
- `tests/testthat/test-methods-language-tripwire.R` - Added screening language test

### Documentation
- `inst/doc/SCREENING_IMPLEMENTATION.md` - Detailed implementation notes
- `inst/doc/SCREENING_README.md` - User-facing guide
- `inst/examples/screening_example.R` - Complete working example

## Key Features Implemented

### 1. Simple Mode Configuration
```yaml
partitioning:
  pretest:
    by: "date_range"
    date_var: "start_time"
    start: "2024-01-01 09:00:00"  # Supports datetime
    end: "2024-01-15 23:59:59"
  pilot:
    by: "date_range"
    date_var: "start_time"
    start: "2024-01-16"  # Or just date
    end: "2024-01-31"

eligibility:
  required_nonmissing: ["age", "consent"]
  action: "exclude"

quality_flags:
  attention_checks:
    - var: "attn_check"
      pass_values: [3]
      action: "flag"
      description: "Select 3 to continue"
```

### 2. Expert Mode (Restricted DSL)
```r
screening_rules = data.frame(
  rule_id = "complex_01",
  predicate = "age >= 18 AND consent IS NOT MISSING",
  action = "exclude"
)
```

**DSL Safety:** Rejects `system()`, `eval()`, `:::`, `$`, `[[`, functions, control flow

### 3. Screening Outputs

**Data columns (non-mutating):**
- `.fury_partition`: "pretest" | "pilot" | "main"
- `.fury_excluded`: logical
- `.fury_excluded_by`: rule_id
- `.fury_flag_<rule_id>`: logical per flag rule
- `.fury_pool_main`: eligible for analysis
- `.fury_pool_note`: non-evaluative description

**CONSORT artifacts (5 CSV files):**
1. `screening_log.csv` - Rule table + counts
2. `screening_overlap.csv` - Pairwise overlaps
3. `consort_flow.csv` - Sequential n_remaining (flags don't decrement)
4. `consort_by_reason.csv` - Exclusions by rule
5. `screening_summary.csv` - Novice-friendly one-liners

## Governance Compliance

### Language Requirements (ENFORCED)
✓ Conservative, non-evaluative terminology
✓ "Analysis-eligible pool (declared)" not "final sample"
✓ "Declared partition/eligibility" not "validated"
✓ No quality/reliability claims

### Tested Banned Terms
- "final sample", "cleaned data", "validated"
- "reliability", "Cronbach", "mediator", "manipulation check"
- "quality data", "valid responses", "passed screening"

### Scope Boundaries
✓ No analysis, scoring, construct validation
✓ Quality checks default to FLAG (not EXCLUDE)
✓ No silent mutations or recommendations

## Datetime Support

**Critical enhancement:** Partitioning supports both date and datetime formats:
- `YYYY-MM-DD` for day-level partitions
- `YYYY-MM-DD HH:MM:SS` for hour-level partitions

**Why this matters:** Pilots and pretests often occur on the same day (morning pretest, afternoon pilot). Datetime support enables precise partitioning.

## Test Results

```
R CMD check: 0 errors ✓ | 0 warnings ✓ | 1 note (non-standard top-level files)
devtools::test(): [ FAIL 0 | WARN 0 | SKIP 1 | PASS 259 ]
```

### Test Breakdown
- **Simple mode:** 60 tests (date/datetime partitioning, eligibility, flags, CONSORT artifacts)
- **Expert mode:** 21 tests (DSL safety, rule execution, equivalence to simple mode)
- **Language tripwire:** 1 test (conservative terminology enforcement)
- **Existing tests:** 177 tests (all still passing)

## Design Decisions

### 1. Two Modes (Why?)
- **Simple mode** removes DSL barrier for novices
- Both compile to same engine → same transparency
- **Expert mode** provides escape hatch while maintaining safety

### 2. Restricted DSL (Why?)
- Prevents arbitrary R code injection from specs
- Limits to safe operators: AND, OR, NOT, IN, IS MISSING, comparisons
- Critical for CRAN/JOSS acceptance

### 3. Default to FLAG Not EXCLUDE (Why?)
- Quality checks are researcher-declared, not validated
- Flags preserve transparency without pre-judging
- Exclusions limited to design-defined eligibility

### 4. Pretest pool_main = FALSE (Why?)
- Pretest data for instrument development, not hypothesis testing
- Prevents accidental pooling in main analysis
- Still in data with clear `.fury_partition` label

### 5. Pilot Explicitly Noted but Pooled (Why?)
- Pilot responses often valid for analysis
- Explicit `.fury_partition` marking enables researcher choice
- `.fury_pool_note` provides transparency

## Behavior Changes

**No breaking changes.** All new functionality is:
- Opt-in (screening config optional)
- Additive (only adds `.fury_*` columns)
- Internal (functions are `@noRd`)

If no screening config provided:
- Returns data with `.fury_partition = "main"` and `.fury_pool_note = "No screening rules applied"`

## CRAN/JOSS Readiness

✓ Deterministic (same inputs → same outputs)
✓ Tempdir-only writes in tests
✓ No network access
✓ Suggests packages guarded
✓ No ::: to other packages
✓ Fully qualified calls

## Dependencies

**No new dependencies added.** Uses existing infrastructure:
- `nicheCore` - validation, error handling, audit writers
- `fs` - path operations
- `cli` - user messaging

## Integration Points

**Where configs live (optional fields):**
- `spec$data$screening` (from vision specs)
- `recipe$screening` (in niche_recipe)

**Bundle integration:**
- `fury_write_bundle()` checks for `result$fury_metadata$screened_data` and `screening_rules`
- If present, writes all artifacts to audit directory

## What's Intentionally NOT Implemented

Per scope requirements:
- ✗ Analysis or modeling
- ✗ Automatic data cleaning beyond declared rules
- ✗ Construct validation or psychometric assessment
- ✗ Manipulation check evaluation
- ✗ Scoring or composite creation
- ✗ Statistical inference about data quality

## Usage Example

```r
# Define config
screening_config <- list(
  partitioning = list(
    pretest = list(
      by = "date_range",
      date_var = "start_time",
      start = "2024-01-15 09:00:00",
      end = "2024-01-15 12:00:00"
    )
  ),
  eligibility = list(
    required_nonmissing = c("age", "consent"),
    action = "exclude"
  ),
  quality_flags = list(
    attention_checks = list(
      list(
        var = "attn_check",
        pass_values = c(3),
        action = "flag",
        description = "Select 3"
      )
    )
  )
)

# Compile and apply
rules <- fury:::fury_compile_rules_(screening_config, data)
screened <- fury:::fury_screen(data, rules)

# Generate CONSORT artifacts
fury:::fury_write_screening_artifacts(screened, rules, audit_dir)
```

## Running Tests

```bash
cd /path/to/fury

# All tests
R -e "devtools::load_all(); devtools::test()"

# Specific suites
R -e "devtools::test(filter = 'screening-simple')"   # 60 tests
R -e "devtools::test(filter = 'screening-expert')"   # 21 tests
R -e "devtools::test(filter = 'methods-language')"   # Language tripwires

# Check
R -e "devtools::check()"
```

## Next Steps (Not in This Increment)

Potential future enhancements (if requested):
- Public API exports (currently all internal)
- Additional DSL operators (BETWEEN, LIKE, etc.)
- Integration with fury_run() workflow
- CONSORT diagram generation (graphical)
- Speed/duration-based quality flags

## Notes for Maintainer

- All functions are internal (`@noRd`) to allow iteration
- Rule IDs are stable and deterministic (partition_pretest_01, etc.)
- Datetime regex supports YYYY-MM-DD HH:MM:SS (not fractional seconds)
- POSIXct used for datetime comparisons (assumes UTC if no timezone)
- Flag columns use `.fury_flag_<rule_id>` naming convention
- CONSORT flow step counter includes flags but doesn't decrement n_remaining

## Changelog Entry

```
fury 0.1.0 (unreleased)

NEW FEATURES
* Added CONSORT-style screening with simple mode (novice-friendly)
  and expert mode (restricted DSL)
* Partitioning supports both date (YYYY-MM-DD) and datetime
  (YYYY-MM-DD HH:MM:SS) formats for same-day pretest/pilot
* Screening generates 5 CONSORT artifacts: log, overlap, flow,
  by_reason, and novice-friendly summary
* Conservative language enforced: "analysis-eligible pool (declared)"
  not "final sample"
* Quality checks default to FLAG (not EXCLUDE) for transparency
* Pretest automatically excluded from analysis pool
* Pilot explicitly noted but included in pool by default
* All screening non-destructive: adds .fury_* columns only
```

---

**Implementation complete.** All tests passing. Ready for review.
