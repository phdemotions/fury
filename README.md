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

## 5-Minute Quick Start 🚀

**New to fury? Just want to see it work?** Copy-paste this:

```r
# Install
install.packages("remotes")
remotes::install_github("phdemotions/fury")
install.packages("haven")

# Run on test data (works immediately!)
library(fury)
test_file <- system.file("extdata", "test_minimal.sav", package = "fury")
result <- fury_run(
  fury_spec() %>% fury_source(test_file, format = "spss"),
  out_dir = tempdir()
)
print(result)
```

**Now use YOUR data:**

```r
library(fury)

# Let R find your file (opens file picker - no typing paths!)
my_file <- file.choose()  # Select your .sav file

# Run fury
result <- fury_run(
  fury_spec() %>% fury_source(my_file, format = "spss"),
  out_dir = "my_results"  # Creates this folder
)

# Open results
browseURL(result$artifacts$audit_dir)
```

**Want to exclude non-consenters?** Add one line:

```r
result <- fury_run(
  fury_spec() %>%
    fury_source(file.choose(), format = "spss") %>%
    fury_exclude_missing("consent"),  # ← Add this
  out_dir = "my_results"
)
```

**Want to flag attention checks?** Add this instead:

```r
result <- fury_run(
  fury_spec() %>%
    fury_source(file.choose(), format = "spss") %>%
    fury_flag_attention(
      var = "attn_check_1",   # Your variable name
      pass_values = 3,         # Correct answer
      description = "Select 3"
    ),
  out_dir = "my_results"
)
```

---

## For Beginners Who Want More Control

**You collected data in Qualtrics and need to:**
1. Exclude participants who failed attention checks
2. Separate pilot/pretest data from your main study
3. Document participant flow for your journal submission

### Two Ways to Build Your Screening Rules:

**Option A: R Code (Easier - Recommended for Beginners)**

```r
library(fury)

# Build your rules step-by-step
spec <- fury_spec() %>%
  fury_source(file.choose(), format = "spss") %>%
  fury_partition_pilot(
    date_var = "StartDate",
    start = "2024-01-01",
    end = "2024-01-15"
  ) %>%
  fury_exclude_missing("consent") %>%
  fury_flag_attention(
    var = "attn_check_1",
    pass_values = 3,
    description = "Select 3"
  )

# Run it
result <- fury_run(spec, out_dir = "my_audit")
```

**Option B: YAML File (For Text File Lovers)**

Create a file called `screening_rules.yaml`:

```yaml
data:
  sources:
    - file: "my_qualtrics_data.sav"
      format: "spss"

  screening:
    # Separate pilot data collected Jan 1-15
    partitioning:
      pilot:
        by: "date_range"
        date_var: "StartDate"
        start: "2024-01-01"
        end: "2024-01-15"

    # Exclude anyone missing consent
    eligibility:
      required_nonmissing: ["consent"]
      action: "exclude"

    # Flag (but don't remove) attention check failures
    quality_flags:
      attention_checks:
        - var: "attn_check_1"
          pass_values: [3]
          description: "Select 3"
          action: "flag"
```

Then run:

```r
library(fury)
result <- fury_run("screening_rules.yaml", out_dir = "my_audit")
```

### Step 5: Check the results

fury creates several files in `my_audit/audit/`:

- **`screening_summary.csv`** — Quick overview (read this first!)
- **`warnings.csv`** — Alerts if you forgot to declare pilots or if flagged cases are still in your data
- **`decision_registry.csv`** — Shows exactly what you declared vs. didn't declare
- **`consort_flow.csv`** — Participant flow diagram data for your Methods section

**Important:** Open `warnings.csv` first. It will tell you if something looks wrong.

---

## Advanced: Tidyverse-Style Spec Builder

**For R users who prefer pipes over YAML:**

fury provides a fluent API for building specs interactively. You write R code, then **export to YAML** for preregistration:

```r
library(fury)

# Build spec using tidyverse-style pipes
spec <- fury_spec() %>%
  fury_source("my_qualtrics_data.sav", format = "spss") %>%
  fury_partition_pilot(
    date_var = "StartDate",
    start = "2024-01-01",
    end = "2024-01-15"
  ) %>%
  fury_exclude_missing(c("consent", "age")) %>%
  fury_flag_attention(
    var = "attn_check_1",
    pass_values = 3,
    description = "Instructions said select 3"
  ) %>%
  fury_to_yaml("my_screening_spec.yaml")  # Export for preregistration

# Preview the spec
print(spec)

# Then use the YAML for reproducible execution
result <- fury_run("my_screening_spec.yaml")
```

**Why this approach?**
- ✅ Write in familiar R syntax
- ✅ Export to YAML for preregistration/version control
- ✅ YAML becomes the "source of truth" for reproducibility
- ✅ Best of both worlds: R convenience + YAML auditability

---

## Advanced example (ecosystem integration)

For researchers already familiar with the niche R universe:

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

---

## Workflow

1. **`vision`** reads and validates a spec file (YAML/JSON) and builds a `niche_recipe`.
2. **`fury`** consumes the `niche_recipe`, ingests data, and produces audit artifacts.
3. **Downstream packages** consume the `niche_result` for modeling, scoring, and rendering.

---

## Important concepts (read this before using fury!)

### 🚨 Flagging vs. Excluding — THEY ARE DIFFERENT

**The #1 mistake beginners make:**

When you set `action: "flag"` for an attention check, those participants are **marked** but **STILL IN YOUR DATA**.

- ✅ `action: "flag"` → Marks bad responses, keeps them in your data (for sensitivity analysis)
- ✅ `action: "exclude"` → Removes bad responses from your data

**Which should you use?**

- Use `"exclude"` for **eligibility criteria** (e.g., must have consent, must be 18+)
- Use `"flag"` for **quality checks** (e.g., attention checks, speeders) — then decide later whether to exclude

fury will **warn you** if flagged cases are still in your analysis pool.

### 📅 Pilot and pretest data must be declared

If you ran a pilot study or pretest **before** your main data collection:

- You **must** tell fury the dates or IDs of those participants
- If you don't, fury assumes they're part of your main study
- Use the `partitioning:` section in your YAML file (see example above)

fury will show "Pilot partition present: No" in `screening_summary.csv` if you forgot.

### 📊 Always check these files after running fury

Open these files (they're just CSVs you can open in Excel):

1. **`warnings.csv`** — START HERE. Tells you if something looks wrong.
2. **`screening_summary.csv`** — Quick overview of what happened.
3. **`decision_registry.csv`** — Did you declare pilots? Exclusions? (Yes/No for each)
4. **`consort_flow.csv`** — Participant counts for your Methods section.

**If `warnings.csv` is empty, you're probably good to go.**

---

## Exported functions

### Core Functions
- `fury_run(spec_path, out_dir)`: Novice-friendly entry point. Reads spec, builds recipe, executes ingestion.
- `fury_execute_recipe(recipe, out_dir)`: Core execution function. Takes a `niche_recipe`, produces `niche_result`.
- `fury_write_bundle(result, out_dir)`: Writes/verifies audit bundle from `niche_result`.
- `fury_scope()`: Returns scope statement (used in docs/tests to prevent drift).

### Tidyverse-Style Spec Builders (NEW!)
- `fury_spec()`: Start building a screening spec interactively
- `fury_source(builder, file, format)`: Add data source
- `fury_partition_pilot(builder, date_var, start, end)`: Declare pilot partition
- `fury_partition_pretest(builder, date_var, start, end)`: Declare pretest partition
- `fury_exclude_missing(builder, vars)`: Exclude cases with missing values
- `fury_flag_missing(builder, vars)`: Flag (don't exclude) missing values
- `fury_flag_attention(builder, var, pass_values, description, action)`: Add attention check
- `fury_to_yaml(builder, path)`: Export spec to YAML file for preregistration

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
