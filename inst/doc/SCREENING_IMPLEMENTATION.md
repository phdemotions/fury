# fury Screening Implementation Summary

**Primary creator & maintainer-of-record:** Josh Gonzales (GitHub: phdemotions)
**Canonical source:** `/phdemotions/fury`

## Implementation Overview

This increment implements novice-friendly CONSORT-style partitioning + screening for `fury` that is reviewer-proof and spec-driven.

## Key Features

### Two Input Modes

1. **SIMPLE MODE** (novice default): Structured fields with zero predicates
   - `partitioning`: Define pretest/pilot by date ranges or IDs
   - `eligibility`: Declare required non-missing variables
   - `quality_flags`: Define attention checks with pass values

2. **EXPERT MODE** (optional): Explicit rule table with restricted DSL
   - Direct specification of predicates using safe DSL operators
   - Validation prevents arbitrary R code injection

### Screening Outputs

All screening operations add `.fury_*` metadata columns without mutating original data:

- `.fury_partition`: "pretest" | "pilot" | "main" | "unassigned"
- `.fury_excluded`: logical
- `.fury_excluded_by`: rule_id or NA
- `.fury_flag_<rule_id>`: logical (one per flag rule)
- `.fury_pool_main`: logical (eligible for main analysis)
- `.fury_pool_note`: character (non-evaluative)

### CONSORT Artifacts

Generated artifacts (all CSV except where noted):

1. `screening_log.csv` - Rule table with counts
2. `screening_overlap.csv` - Pairwise overlaps for exclude/flag rules
3. `consort_flow.csv` - Sequential flow with n_remaining
4. `consort_by_reason.csv` - Exclusions by rule
5. `screening_summary.csv` - Novice-friendly summary (one-liner per category)

## Governance Compliance

### Language Requirements (ENFORCED)
- ✓ Conservative, non-evaluative language throughout
- ✓ "Analysis-eligible pool (declared)" instead of "final sample"
- ✓ "Declared partition/eligibility/quality checks" acknowledging rules are specified, not validated
- ✓ No claims about data quality, reliability, or validity

### Banned Terms (TESTED)
The following terms are prohibited and tested in `test-methods-language-tripwire.R`:
- "final sample", "cleaned data", "validated"
- "reliability", "Cronbach", "mediator", "manipulation check"
- "quality data", "high quality", "valid responses", "reliable"
- "passed screening", "good data"

### Scope Boundaries
- NO analysis, scoring, construct claims, manipulation checks, or recommendations
- Quality checks default to FLAG, not EXCLUDE
- Never implies "final sample"; always "analysis-eligible per declared rules"

## Files Added

### Core Implementation
- `R/screening_compile.R` - Compiles simple/expert mode configs to rule tables
- `R/screening_engine.R` - Applies compiled rules to data
- `R/consort_flow.R` - Generates CONSORT artifacts

### Updated Files
- `R/fury_write_bundle.R` - Integrated screening artifact writing

### Tests
- `tests/testthat/test-screening-simple-mode.R` - 55 tests for simple mode
- `tests/testthat/test-screening-expert-mode.R` - 21 tests for expert mode
- `tests/testthat/test-methods-language-tripwire.R` - Updated with screening language tests

### Examples
- `inst/examples/screening_example.R` - Complete working example with simple mode

## Test Results

All 259 tests pass (0 failures, 0 warnings, 1 skip):
```
devtools::test()
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 259 ]
```

### Test Coverage

**Simple Mode (60 tests)**
- Empty config handling
- Date range partitioning (supports YYYY-MM-DD)
- Datetime partitioning (supports YYYY-MM-DD HH:MM:SS for same-day pretest/pilot)
- ID-based partitioning
- Required non-missing eligibility
- Attention check quality flags
- Partition defaults (pretest pool_main = FALSE, pilot explicitly noted)
- Exclusion vs. flag behavior
- Row dropping (default FALSE, optional TRUE)
- Determinism checks
- CONSORT artifact generation
- Conservative language validation

**Expert Mode (21 tests)**
- Explicit rule table acceptance
- Required column validation
- DSL safety (rejects system(), eval(), :::, $, [[, function(), etc.)
- Safe predicate acceptance
- Equivalence to simple mode
- Complex predicates (AND/OR)
- IN operator for categorical values
- Execution order maintenance
- Optional column defaults

**Language Tripwire (new test)**
- Screening artifacts use only conservative language
- No banned evaluative terms
- Required use of "analysis-eligible" and "declared"

## Usage Example (Simple Mode)

```r
# Define screening config
screening_config <- list(
  partitioning = list(
    pretest = list(
      by = "date_range",
      date_var = "start_time",
      start = "2024-01-01",
      end = "2024-01-15"
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

# Generate artifacts
fury:::fury_write_screening_artifacts(screened, rules, audit_dir)
```

## Intentionally NOT Implemented

Per scope requirements:
- Analysis or modeling functions
- Automatic data cleaning beyond declared rules
- Construct validation or psychometric assessment
- Manipulation check evaluation
- Scoring or composite creation
- Statistical inference about data quality

## Integration with fury Workflow

Screening config lives in optional fields:
- `spec$data$screening` (from vision specs)
- `recipe$screening` (in niche_recipe)

If absent, fury returns "no rules applied" with clean pass-through.

Bundle integration via `fury_write_bundle()` checks for:
- `result$fury_metadata$screened_data`
- `result$fury_metadata$screening_rules`

If present, writes all screening artifacts to audit directory.

## How to Run Tests

```bash
# All tests
cd /path/to/fury
R -e "devtools::load_all(); devtools::test()"

# Specific test files
R -e "devtools::load_all(); devtools::test(filter = 'screening-simple')"
R -e "devtools::load_all(); devtools::test(filter = 'screening-expert')"
R -e "devtools::load_all(); devtools::test(filter = 'methods-language')"
```

## Design Decisions

### Why Two Modes?
- **Simple mode** removes DSL barrier for novices; structured fields compile to same engine
- **Expert mode** provides escape hatch for complex predicates while maintaining safety

### Why Restricted DSL?
- Prevents arbitrary R code execution from untrusted specs
- Limits to safe operators: AND, OR, NOT, IN, IS MISSING, comparisons
- Rejects: system(), eval(), :::, $, [[, function definitions, control flow

### Why Default to FLAG Not EXCLUDE?
- Quality checks are researcher-declared, not validated
- Flags preserve transparency without pre-judging responses
- Exclusions limited to design-defined eligibility criteria

### Why "Analysis-Eligible Pool" Not "Final Sample"?
- "Final" implies completeness and validation fury doesn't provide
- "Declared rules" acknowledges these are researcher-specified, not objective quality assessments
- Maintains scope boundary between ingestion/audit (fury) and analysis (downstream)

### Why Pretest pool_main = FALSE by Default?
- Pretest data typically used for instrument development, not hypothesis testing
- Explicit exclusion prevents accidental inclusion in main analysis
- Still available in data with clear `.fury_partition` label

### Why Pilot Explicitly Noted but Pooled?
- Pilot responses often valid for analysis (unlike pretest)
- Explicit `.fury_partition` marking enables researcher choice
- `.fury_pool_note` provides transparency without forced exclusion

## CRAN Readiness

Implementation follows CRAN/JOSS standards:
- ✓ Deterministic outputs (same inputs → same results)
- ✓ Tempdir-only writes in tests
- ✓ No network access
- ✓ Suggests packages guarded with skip_if_not_installed()
- ✓ No ::: access to other packages
- ✓ Fully qualified function calls (dplyr::mutate, etc.)

## Dependencies

No new hard dependencies added. Uses existing fury/nicheCore infrastructure:
- `nicheCore` for validation, error handling, stable_order, write_audit_csv
- `fs` for path operations
- `cli` for user messaging

All screening functions are internal (`@noRd`) to minimize API surface and allow iteration.
