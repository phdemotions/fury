# fury Screening: Novice-Friendly CONSORT-Style Partitioning + Screening

**Primary creator & maintainer-of-record:** Josh Gonzales (GitHub: phdemotions)

## Quick Start

### Simple Mode (Recommended for Beginners)

No predicates required. Just declare your screening criteria using structured fields:

```r
screening_config <- list(
  # Partition by date ranges or IDs
  partitioning = list(
    pretest = list(
      by = "date_range",
      date_var = "start_time",
      start = "2024-01-01",
      end = "2024-01-15"
    )
  ),

  # Eligibility criteria
  eligibility = list(
    required_nonmissing = c("age", "consent"),
    action = "exclude"
  ),

  # Attention checks (default: flag, not exclude)
  quality_flags = list(
    attention_checks = list(
      list(
        var = "attn_check",
        pass_values = c(3),
        action = "flag",
        description = "Select 3 to continue"
      )
    )
  )
)

# Compile rules
rules <- fury:::fury_compile_rules_(screening_config, data)

# Apply screening
screened <- fury:::fury_screen(data, rules)

# Write CONSORT artifacts
fury:::fury_write_screening_artifacts(screened, rules, audit_dir)
```

## What Gets Generated

### Data Columns (Non-Destructive)

Original data untouched. New `.fury_*` columns added:

- `.fury_partition`: "pretest" | "pilot" | "main" | "unassigned"
- `.fury_excluded`: TRUE if excluded by eligibility rules
- `.fury_excluded_by`: Rule ID that triggered exclusion
- `.fury_flag_<rule_id>`: TRUE if flagged by quality check
- `.fury_pool_main`: TRUE if eligible for main analysis
- `.fury_pool_note`: Human-readable note (non-evaluative)

### CONSORT Artifacts (CSV files in audit/)

1. **screening_log.csv** - Rule execution summary with counts
2. **screening_overlap.csv** - Which exclusions/flags overlap
3. **consort_flow.csv** - Sequential flow (n_remaining after each step)
4. **consort_by_reason.csv** - Exclusions broken down by rule
5. **screening_summary.csv** - One-line summary (novice-friendly)

## Partitioning Rules

### Pretest
- Automatically excluded from `.fury_pool_main`
- Use for instrument development, not hypothesis testing
- Still in dataset with clear `.fury_partition = "pretest"` label

### Pilot
- Included in `.fury_pool_main` by default
- Explicitly noted via `.fury_pool_note`
- Researcher can choose to use or exclude in downstream analysis

### Main
- Default for unassigned cases
- Included in `.fury_pool_main` (unless excluded by eligibility)

## Eligibility vs. Quality Flags

### Eligibility (Design-Defined)
- **Default action: EXCLUDE**
- Example: Missing consent, age out of range
- Decrements n_remaining in CONSORT flow

### Quality Flags (Researcher-Declared)
- **Default action: FLAG**
- Example: Failed attention checks, speeding
- Does NOT exclude; does NOT decrement n_remaining
- Preserves transparency; researcher decides downstream

## Conservative Language (Enforced)

fury uses reviewer-proof terminology:

✓ "Analysis-eligible pool (declared rules)"
✗ "Final sample"

✓ "Declared partition"
✗ "Validated partition"

✓ "Flagged for attention"
✗ "Failed quality check"

No claims about:
- Data quality or reliability
- Construct validity
- Manipulation check success
- Response legitimacy

## Expert Mode (Optional)

For complex predicates, use explicit rule tables with restricted DSL:

```r
screening_config <- list(
  screening_rules = data.frame(
    rule_id = "complex_01",
    category = "eligibility",
    description = "Age 18+ AND consent provided",
    predicate = "age >= 18 AND consent IS NOT MISSING",
    action = "exclude",
    stringsAsFactors = FALSE
  )
)
```

### Restricted DSL Operators (Safe)

**Allowed:**
- Comparisons: `>=`, `<=`, `>`, `<`, `==`, `!=`
- Logical: `AND`, `OR`, `NOT`
- Missing checks: `IS MISSING`, `IS NOT MISSING`
- Set membership: `IN (value1, value2, ...)`
- Variable names, numbers, quoted strings

**Rejected (Security):**
- `system()`, `eval()`, `parse()`, `source()`
- `:::`, `$`, `[[` (accessor injection)
- `function()`, `for()`, `while()`, `if()` (control flow)
- Any arbitrary R code

## Integration with fury Workflow

Screening config lives in optional spec/recipe fields:
- `spec$data$screening` (vision specs)
- `recipe$screening` (niche_recipe)

If absent, fury passes through with "no rules applied" log.

Bundle integration:
```r
result <- fury_execute_recipe(recipe)
# If recipe contains screening, artifacts auto-generated
```

## Example Output: screening_summary.csv

```
line_order,line_text,n
1,Pretest cases (declared partition):,3
2,Pilot cases (declared partition):,2
3,Excluded (declared eligibility):,4
4,Flagged (declared quality checks):,6
5,Analysis-eligible pool (declared):,13
```

## Design Philosophy

### What fury Does
- Ingests data
- Applies declared screening rules
- Generates transparent audit trail
- Preserves all data (exclusions marked, not dropped)

### What fury Does NOT Do
- Judge data quality
- Validate constructs
- Recommend exclusions
- Make statistical claims
- Score or compute composites

### Why This Matters
- Peer review requires transparency, not black-box "cleaning"
- Researchers remain responsible for screening decisions
- Audit trail enables reproducibility
- Conservative language prevents scope creep

## Running the Example

```bash
cd /path/to/fury
Rscript inst/examples/screening_example.R
```

## Questions?

This is a pre-release implementation. Functions are internal (`fury:::`) to allow iteration.

For issues or feature requests, contact maintainer Josh Gonzales or file issue at canonical repo.
