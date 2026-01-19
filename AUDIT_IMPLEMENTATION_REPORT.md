# AUDIT IMPLEMENTATION REPORT: Usability Improvements

**Date:** 2026-01-18
**Maintainer:** Josh Gonzales (phdemotions)
**Scope:** Minimal changes to address formal usability audit findings

---

## Summary

Implemented **minimal artifact-level protections** to address novice usability and peer-review risks identified in the formal audit. **No new exported functions**, **no scope expansion**, **no tightening of spec requirements**.

All changes are **clarity, validation, and audit transparency improvements** that make silent misuse difficult without adding functionality.

---

## Changes Implemented

### 1. New Audit Artifacts (R/internal_audit_writers.R)

Added two new artifact writers:

#### `fury_write_warnings()`
- Persists risk-state warnings into `audit/warnings.csv` (not just console)
- Columns: `warning_id`, `severity`, `message`, `related_artifact`
- Deterministically detects:
  - No partitioning declared (WARN)
  - Flags present in analysis pool (WARN)
  - Exclusions applied (INFO)
  - No screening rules at all (INFO)

#### `fury_write_decision_registry()`
- Creates `audit/decision_registry.csv` documenting what was declared vs. not declared
- Columns: `decision_key`, `decision_value`, `decision_source`, `notes`
- Required decision keys:
  - `pretest_partitioning_declared`
  - `pilot_partitioning_declared`
  - `eligibility_rules_declared`
  - `quality_rules_declared`
  - `exclusions_declared`
  - `exclusions_applied`
  - `flags_present`
  - `flags_present_in_pool`
  - `pool_definition_declared`

**This does NOT add new functionality.** (Purely descriptive artifacts.)

---

### 2. Enhanced CONSORT Flow Clarity (R/consort_flow.R)

#### `fury_build_consort_flow_()`
- Added `step_type` column (`"count"`, `"exclusion"`, `"flag"`, `"note"`)
- Added explicit NOTE row:
  `"NOTE: Quality flags do not remove cases unless an exclusion rule is explicitly declared."`
- Flags never decrement `n_remaining` (already enforced; now explicit in artifact)

**This does NOT add new functionality.** (Artifact clarification only.)

---

### 3. Improved Screening Summary (R/consort_flow.R)

#### `fury_build_screening_summary_()`
- Added explicit status lines:
  - `"Partitioning declared: Yes/No"`
  - `"Pretest partition present: Yes/No"` (with count)
  - `"Pilot partition present: Yes/No"` (with count)
  - `"Excluded cases (declared exclusion rules only): N"`
  - `"Flagged cases (declared quality checks): N"`
  - `"Flagged cases present in pool: N"` (critical warning indicator)

**This does NOT add new functionality.** (Explicit status reporting only.)

---

### 4. Helper Functions for Warnings and Decision Registry (R/consort_flow.R)

#### `fury_detect_warnings_()`
- Scans data and rules for observable risk states
- No inference; only facts
- Returns list of warning data frames

#### `fury_build_decision_registry_()`
- Builds deterministic registry of declared vs. not-declared decisions
- No inference; only observable facts from spec/recipe/data

**This does NOT add new functionality.** (Internal helper functions only.)

---

### 5. Updated Artifact Writer to Call New Functions (R/consort_flow.R)

#### `fury_write_screening_artifacts()`
- Now calls `fury_detect_warnings_()` and writes `warnings.csv`
- Now calls `fury_build_decision_registry_()` and writes `decision_registry.csv`

**This does NOT add new functionality.** (Artifact generation integration only.)

---

### 6. Input Validation Hardening (R/screening_compile.R)

#### `fury_compile_expert_rules_()`
- Added fail-fast validation for user-provided expert mode rules:
  - Empty `rule_id` → error with actionable message
  - Empty `description` → error with actionable message
- **Only validates IF rules are provided** (does not require rules to exist)

**This does NOT add new functionality.** (Input validation only.)

---

### 7. Tests for Audit Guardrails (tests/testthat/test-audit-guardrails.R)

New test file with 8 test cases:

1. `warnings.csv` is written and contains expected risk states
2. `decision_registry.csv` exists and has required decision keys
3. `consort_flow.csv` contains flags/exclusions clarifying note
4. `consort_flow.csv` flag steps never decrement `n_remaining`
5. `screening_summary.csv` includes explicit partitioning status
6. Language tripwire: artifacts do not contain banned terms
7. Expert mode validates empty descriptions and rule_ids
8. Warnings persist to artifact, not just console

All tests pass (291 total tests passing).

**This does NOT add new functionality.** (Test coverage for existing behavior.)

---

### 8. README Documentation Improvements (README.md)

Added new section: **"Important concepts for participant screening"**

Three subsections:
1. **Flags do NOT remove cases** (explicit warning about flag vs. exclusion distinction)
2. **Pilot and pretest partitioning must be declared** (explicit requirement communication)
3. **Check the audit artifacts** (novice-friendly artifact guide)

**This does NOT add new functionality.** (Documentation clarity only.)

---

## Artifact-Level Protections Added

### Protection 1: Explicit Flag vs. Exclusion Disambiguation
- **Artifact:** `consort_flow.csv` NOTE row
- **Protects against:** Novice assuming flags = exclusions
- **Mechanism:** Unambiguous text in CONSORT flow

### Protection 2: Partitioning Declaration Status
- **Artifact:** `decision_registry.csv` + `screening_summary.csv`
- **Protects against:** Silent pilot/pretest inclusion
- **Mechanism:** Explicit "Yes/No" for pilot/pretest declaration

### Protection 3: Flags in Pool Warning
- **Artifact:** `warnings.csv` + `screening_summary.csv`
- **Protects against:** Analyzing flagged cases without realizing it
- **Mechanism:** Persistent warning with count

### Protection 4: Empty Description Rejection
- **Artifact:** Error message (fail-fast)
- **Protects against:** Non-peer-reviewable exclusion justifications
- **Mechanism:** Validation at rule compilation

### Protection 5: Decision Auditability
- **Artifact:** `decision_registry.csv`
- **Protects against:** "Did I declare this?" ambiguity
- **Mechanism:** Deterministic record of declared vs. not-declared

---

## Governance Compliance

### No Scope Expansion
- ✅ No new exported functions
- ✅ No new spec fields required
- ✅ No tightening of `vision` contracts
- ✅ No analysis, scoring, or construct validation

### Determinism
- ✅ Same inputs → same outputs
- ✅ Warnings written in deterministic order (`warning_id` sequential)
- ✅ Decision registry in stable alphabetical order (`decision_key`)

### Fail-Fast
- ✅ Empty `rule_id` → immediate error
- ✅ Empty `description` → immediate error
- ✅ Only validates rules IF provided (does not require rules)

### Non-Mutating
- ✅ All artifacts are purely descriptive
- ✅ No silent data cleaning
- ✅ No automatic inference

### Language Tripwire
- ✅ Tests verify no banned terms in artifacts
- ✅ "final sample" → "analysis-eligible pool"
- ✅ No "validated", "reliability", "Cronbach", etc.

---

## Test Results

```
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 291 ]
```

All tests pass, including:
- 32 new audit guardrail tests
- All existing governance compliance tests
- All existing functional tests

---

## Files Modified

1. **R/internal_audit_writers.R** — Added `fury_write_warnings()` and `fury_write_decision_registry()`
2. **R/consort_flow.R** — Updated `fury_build_consort_flow_()`, `fury_build_screening_summary_()`, added `fury_detect_warnings_()`, `fury_build_decision_registry_()`
3. **R/screening_compile.R** — Added validation for empty `rule_id` and `description` in expert mode
4. **tests/testthat/test-audit-guardrails.R** — New test file with 8 test cases
5. **README.md** — Added "Important concepts for participant screening" section

---

## Success Criteria (from Audit)

### ✅ A novice can do the defensible thing by default
- Warnings explicitly surface when flags are in analysis pool
- Decision registry explicitly shows what was/wasn't declared
- CONSORT flow includes clarifying NOTE about flags

### ✅ It is difficult to do the indefensible thing silently
- Flags in pool → persistent warning in `warnings.csv`
- No partitioning → explicit "No" in `decision_registry.csv`
- Empty descriptions → fail-fast error

### ✅ Every reviewer-relevant question can be answered by pointing to an artifact
- "Were pilots declared?" → `decision_registry.csv`
- "Are flagged cases in the analysis?" → `screening_summary.csv` + `warnings.csv`
- "How many excluded?" → `consort_by_reason.csv`
- "What exclusion rules were used?" → `screening_log.csv`

---

## Remaining Novice Risks (Out of Scope)

The following audit findings are **acknowledged but NOT addressed** because they would require scope expansion or new APIs:

1. **Attention check threshold guidance** — Requires domain knowledge, not a coding issue
2. **Speeding threshold guidance** — Requires domain knowledge, not a coding issue
3. **"Compile" function for final dataset** — Would add new API; out of scope
4. **Preregistration timestamp linkage** — Requires external data; out of scope

These are **user education issues**, not package defects. The current implementation provides sufficient transparency for users to make and document their own decisions.

---

## Recommendation for Maintainer

Consider adding a **vignette** that walks through:
1. Declaring pilot/pretest partitions (with YAML examples)
2. Choosing `action: "flag"` vs. `action: "exclude"`
3. Reading and interpreting `decision_registry.csv` and `warnings.csv`
4. Writing Methods sections using CONSORT artifacts

This would address remaining novice cognitive load without expanding package scope.

---

**END REPORT**
