# fury

<!-- badges: start -->
<!-- badges: end -->

## Primary creator & maintainer

**Josh Gonzales** (GitHub: `phdemotions`)
Canonical source: `/phdemotions`

---

## Scope

`fury` is a pre-analysis data ingestion and audit layer for consumer psychology research. It consumes validated `niche_spec` and `niche_recipe` objects (produced by `vision`), orchestrates data ingestion, and produces audit artifacts bundled in a `niche_result` object.

`fury` is part of the **niche R universe**, an ecosystem of R packages designed for peer-review-ready, audit-ready, APA 7–aligned research outputs.

---

## What fury does NOT do

`fury` **does not** perform:

- Modeling or statistical analysis (no `lm()`, `t.test()`, `aov()`, etc.)
- Scoring or scale construction
- Construct validation (reliability, factor analysis, SEM)
- APA-formatted rendering or report generation

These tasks belong to downstream packages in the niche R universe.

---

## Installation

```r
# Install from GitHub (when available)
# remotes::install_github("phdemotions/fury")

# For development
devtools::load_all()
```

---

## Minimal example

```r
library(fury)
library(vision)

# Create a minimal spec template
spec_path <- tempfile(fileext = ".yaml")
vision::write_spec_template(spec_path)

# Run the complete fury workflow
result <- fury_run(spec_path, out_dir = tempdir())

# Examine result
print(result)

# Check audit artifacts
list.files(result$artifacts$audit_dir)
```

Expected output:

```
[1] "recipe.json"          "source_manifest.csv"
[3] "import_log.csv"       "raw_codebook.csv"
[5] "session_info.txt"
```

---

## Workflow

1. **`vision`** reads and validates a spec file (YAML/JSON) and builds a `niche_recipe`.
2. **`fury`** consumes the `niche_recipe`, ingests data, and produces audit artifacts.
3. **Downstream packages** consume the `niche_result` for modeling, scoring, and rendering.

---

## Important concepts for participant screening

### Flags do NOT remove cases

**CRITICAL:** When you "flag" cases for quality issues (e.g., attention check failures, speeding), those cases are **marked** but **NOT removed** from your data.

- **Flagging** identifies cases that may have quality issues
- **Exclusion** removes cases from the analysis pool
- If you want flagged cases removed, you must explicitly use an exclusion rule (set `action: "exclude"`)

The audit artifacts will warn you if flagged cases are present in your analysis pool.

### Pilot and pretest partitioning must be declared

If you collected pilot or pretest data:

- You **must** declare `partitioning` rules in your spec/recipe
- If you omit partitioning rules, the audit bundle will explicitly state "No partitioning declared"
- Pilots and pretests that are not declared may be silently included in your main analysis pool

The `decision_registry.csv` artifact explicitly documents whether pilot/pretest partitions were declared.

### Check the audit artifacts

After running `fury`, examine these novice-friendly artifacts in the `audit/` directory:

- **`screening_summary.csv`**: High-level overview of partitions, exclusions, and flags
- **`decision_registry.csv`**: Explicit record of what was declared vs. not declared
- **`warnings.csv`**: Risk states detected (e.g., flags in analysis pool, no partitioning declared)
- **`consort_flow.csv`**: Sequential participant flow with clarifying notes

---

## Exported functions

- `fury_run(spec_path, out_dir)`: Novice-friendly entry point. Reads spec, builds recipe, executes ingestion.
- `fury_execute_recipe(recipe, out_dir)`: Core execution function. Takes a `niche_recipe`, produces `niche_result`.
- `fury_write_bundle(result, out_dir)`: Writes/verifies audit bundle from `niche_result`.
- `fury_scope()`: Returns scope statement (used in docs/tests to prevent drift).

---

## Governance

`fury` obeys the **Ecosystem Contract** and **Package Standard** for the niche R universe:

- Object authority: Only `nicheCore` defines `niche_spec`, `niche_recipe`, `niche_result` structure.
- Validation: fail-fast, structural, non-mutating.
- Determinism: same inputs → same outputs.
- Filesystem: all writes under `tempdir()` or user-specified `out_dir`.
- Dependencies: one-way only (`fury` imports `nicheCore` and `vision`, never the reverse).

---

## License

MIT + file LICENSE

---

## Citation

If you use `fury` in published research, please cite:

> Gonzales, J. (2026). *fury: Pre-Analysis Data Ingestion and Audit Layer for Consumer Psychology Research*. R package version 0.1.0. https://github.com/phdemotions/fury
