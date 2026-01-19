# Tutorial Completeness Checklist — fury Package

**Primary creator & maintainer:** Josh Gonzales (GitHub: `phdemotions`)
**Canonical source:** `/phdemotions`

---

## Purpose

This checklist enumerates the REQUIRED tutorials and vignettes for the `fury` package. Each tutorial must be:

1. **Runnable end-to-end** (novice can copy-paste and execute)
2. **Using only in-package fixtures** (no external data dependencies)
3. **Producing verifiable artifacts** (file names and locations clearly stated)
4. **Using conservative language** (no inflated claims about "cleaned data", "validated", "final sample")
5. **Including required callout boxes** (warnings about flags, pilot declarations, scope limitations)

---

## Required Tutorials

### Tutorial 1: Ingest a Single SPSS .sav File and Generate a RAW Codebook

**Location:** Vignette, inst/examples/, or README section

**Required Sections:**

1. **Install and Load**
   - How to install `fury` (from GitHub or CRAN)
   - How to load the package: `library(fury)`
   - Note that `haven` is required for `.sav` ingestion (Suggests dependency)

2. **Locate or Create a .sav File**
   - Point to in-package fixture: `system.file("extdata", "test_minimal.sav", package = "fury")`
   - OR show how user can export their own Qualtrics data as `.sav`

3. **Create a Minimal Spec**
   - Show how to create a YAML spec with a single `.sav` source
   - Example:
     ```yaml
     data:
       sources:
         - file: "test_minimal.sav"
           format: "spss"
     ```
   - Alternatively, show spec builder API:
     ```r
     spec <- fury_spec() %>%
       fury_source("test_minimal.sav", format = "spss") %>%
       fury_to_yaml("my_spec.yaml")
     ```

4. **Run fury**
   - Execute: `result <- fury_run("my_spec.yaml", out_dir = tempdir())`
   - OR: `result <- fury_run(spec_path, out_dir = tempdir())`

5. **Locate the RAW Codebook**
   - Show where artifact is written: `file.path(result$artifacts$audit_dir, "raw_codebook.csv")`
   - Display codebook contents: `read.csv(result$artifacts$raw_codebook)`

6. **Interpret the Codebook Conservatively**
   - Explain columns: variable name, variable label (item text), value labels
   - State clearly: "This is a RAW codebook. It does NOT include computed scores, reliability estimates, or validation results."

**Required Callout Boxes:**

- ⚠️ **Scope Limitation:** "fury does NOT perform scoring, validation, or reliability analysis. The codebook shows only raw variable metadata from the source file."
- ⚠️ **Haven Dependency:** "SPSS .sav ingestion requires the `haven` package. Install with: `install.packages('haven')`"

**FAIL Criteria:**
- Tutorial is not runnable end-to-end
- Tutorial references external data not in package
- Tutorial uses inflated language ("cleaned codebook", "validated variables")
- Required callout boxes are missing

---

### Tutorial 2: Ingest Multiple Sources (Pilot + Main) and Preserve Provenance

**Location:** Vignette, inst/examples/, or README section

**Required Sections:**

1. **Install and Load**
   - Same as Tutorial 1

2. **Scenario Explanation**
   - "You collected pilot data (Jan 1–15) and main data (Jan 16–31). You want to keep them separate for reporting."

3. **Create a Spec with Partitioning**
   - Show how to declare pilot partition by date range:
     ```yaml
     data:
       sources:
         - file: "my_data.sav"
           format: "spss"
       screening:
         partitioning:
           pilot:
             by: "date_range"
             date_var: "StartDate"
             start: "2024-01-01"
             end: "2024-01-15"
     ```
   - Alternatively, show spec builder API:
     ```r
     spec <- fury_spec() %>%
       fury_source("my_data.sav", format = "spss") %>%
       fury_partition_pilot(date_var = "StartDate",
                            start = "2024-01-01",
                            end = "2024-01-15") %>%
       fury_to_yaml("my_spec.yaml")
     ```

4. **Run fury**
   - Execute: `result <- fury_run("my_spec.yaml", out_dir = tempdir())`

5. **Locate Provenance Artifacts**
   - Show `source_manifest.csv`: tracks which files were ingested and when
   - Show `decision_registry.csv`: shows "Pilot partition present: Yes"
   - Show `screening_summary.csv`: shows pilot vs. main counts

6. **Interpret Conservatively**
   - "Pilot data are PARTITIONED, not excluded. They remain in the dataset with a partition label."
   - "If you did NOT declare a pilot partition, the decision registry will say 'Pilot partition present: No'."

**Required Callout Boxes:**

- ⚠️ **Pilot Declaration Matters:** "If you ran a pilot or pretest, you MUST declare it in the spec. Otherwise, fury assumes all data are from the main study."
- ⚠️ **Partitions Are Not Exclusions:** "fury does not remove pilot data. It labels them as 'pilot' so you can analyze them separately."

**FAIL Criteria:**
- Tutorial does not show multi-source or partitioning workflow
- Tutorial does not explain provenance tracking
- Tutorial claims pilot data are "removed" or "cleaned out"
- Required callout boxes are missing

---

### Tutorial 3: Apply Declared Partitioning/Eligibility/Quality Flags and Generate CONSORT Flow Artifacts

**Location:** Vignette, inst/examples/, or README section

**Required Sections:**

1. **Install and Load**
   - Same as Tutorial 1

2. **Scenario Explanation**
   - "You want to exclude participants who did not consent, and flag (but not remove) those who failed attention checks."

3. **Create a Spec with Screening Rules**
   - Show how to declare eligibility exclusions and quality flags:
     ```yaml
     data:
       sources:
         - file: "my_data.sav"
           format: "spss"
       screening:
         eligibility:
           required_nonmissing: ["consent"]
           action: "exclude"
         quality_flags:
           attention_checks:
             - var: "attn_check_1"
               pass_values: [3]
               description: "Instructions said select 3"
               action: "flag"
     ```
   - Alternatively, show spec builder API:
     ```r
     spec <- fury_spec() %>%
       fury_source("my_data.sav", format = "spss") %>%
       fury_exclude_missing("consent") %>%
       fury_flag_attention(var = "attn_check_1",
                           pass_values = 3,
                           description = "Instructions said select 3") %>%
       fury_to_yaml("my_spec.yaml")
     ```

4. **Run fury**
   - Execute: `result <- fury_run("my_spec.yaml", out_dir = tempdir())`

5. **Locate CONSORT Flow Artifact**
   - Show `consort_flow.csv`: lists stages (enrolled → excluded → flagged → analysis-eligible)
   - Display contents: `read.csv(file.path(result$artifacts$audit_dir, "consort_flow.csv"))`

6. **Locate Warnings Artifact**
   - Show `warnings.csv`: alerts if flagged cases remain in analysis pool
   - Explain: "If you see a warning about flagged cases, decide whether to exclude them or keep them for sensitivity analysis."

7. **Interpret Conservatively**
   - "CONSORT flow shows 'analysis-eligible per declared rules', NOT 'final sample' or 'cleaned data'."
   - "Flagged cases are MARKED, not REMOVED. Check warnings.csv to see if action is needed."

**Required Callout Boxes:**

- ⚠️ **Flags Do Not Remove Cases:** "Setting `action: 'flag'` marks cases but DOES NOT remove them. Use `action: 'exclude'` if you want to remove cases."
- ⚠️ **Analysis-Eligible ≠ Final Sample:** "fury produces an 'analysis-eligible dataset per declared rules'. It does NOT produce a 'final' or 'cleaned' dataset. Downstream decisions (e.g., outlier removal, imputation) are YOUR responsibility."
- ⚠️ **No Recoding/Scoring/Validation:** "fury does NOT recode variables, compute scores, or validate constructs. It only applies the rules YOU declare."

**FAIL Criteria:**
- Tutorial does not show both exclusions and flags
- Tutorial does not explain the difference between `"flag"` and `"exclude"`
- Tutorial uses inflated language ("final sample", "cleaned data", "validated participants")
- Required callout boxes are missing

---

## Tutorial Formatting Requirements

All tutorials MUST include:

1. **Code blocks** with `r` syntax highlighting (in Rmarkdown) or plain text fences (in Markdown)
2. **File paths** for all expected artifacts (e.g., `audit/raw_codebook.csv`)
3. **Sample output** showing what the artifact looks like (first few rows of CSV)
4. **Conservative language** (see banned terms list below)

**Banned Terms in Tutorials:**
- "final dataset"
- "cleaned data"
- "final sample"
- "validated data"
- "validated participants"
- "reliability analysis" (unless preceded by "fury does NOT perform")
- "Cronbach's alpha" (unless preceded by "fury does NOT compute")
- "factor analysis" (unless preceded by "fury does NOT perform")
- "mediation" (unless preceded by "fury does NOT test")
- "manipulation check" (unless preceded by "fury does NOT conduct")

**Conservative Alternatives:**
- Use: "analysis-eligible per declared rules"
- Use: "dataset with declared exclusions applied"
- Use: "participants meeting eligibility criteria"
- Use: "raw codebook" (not "validated codebook")

---

## Tutorial Testing

Each tutorial MUST be verified to run without errors:

1. **Manual Test:** Copy-paste code into fresh R session and execute
2. **Vignette Build:** If tutorial is a vignette, ensure it builds with `R CMD build`
3. **Fixture Availability:** Verify all referenced fixtures exist in `inst/extdata/`
4. **Determinism:** Running tutorial twice should produce identical artifacts (excluding timestamps)

---

## Tutorial Accessibility (Novice-Friendly Requirements)

Tutorials must be accessible to researchers who:
- Are new to R
- Are new to statistics
- Have never used tidyverse or pipes
- Have never written YAML
- Are unfamiliar with package installation

**Required novice accommodations:**

1. **Explicit install instructions:**
   ```r
   # Install fury from GitHub
   install.packages("remotes")
   remotes::install_github("phdemotions/fury")
   ```

2. **Explicit library loading:**
   ```r
   library(fury)
   ```

3. **Avoid jargon:**
   - Say "delete participants" not "filter observations"
   - Say "attention check" not "validity screener"
   - Say "mark but don't delete" not "flag for downstream sensitivity analysis"

4. **Show expected output:**
   - Include screenshots or plain-text renderings of CSVs
   - Show what `print(result)` looks like
   - Show what `list.files(result$artifacts$audit_dir)` returns

5. **Explain file paths:**
   - "The codebook is saved in the `audit` folder inside your output directory."
   - "You can open this file in Excel to view it."

---

## Summary: Tutorial Pass Criteria

**To pass this checklist, ALL of the following must be true:**

1. Tutorial 1 exists and is runnable end-to-end (`.sav` ingestion + RAW codebook)
2. Tutorial 2 exists and is runnable end-to-end (multi-source + provenance)
3. Tutorial 3 exists and is runnable end-to-end (screening + CONSORT flow)
4. All tutorials use only in-package fixtures
5. All tutorials include required callout boxes
6. All tutorials use conservative language (no banned terms)
7. All tutorials are novice-friendly (explicit install/load, no jargon)
8. All tutorials show expected artifacts (file paths, sample output)

**If any tutorial is missing or fails criteria, the checklist FAILS.**

---

## Cross-Reference with AUDIT_CHECKLIST.md

This checklist (TUTORIAL_CHECKLIST.md) verifies **tutorial completeness**.

The main AUDIT_CHECKLIST.md verifies:
- Novice usability of the package itself
- Correctness of artifact generation
- Conservative language in documentation
- Determinism and governance compliance

Both checklists must pass for fury to be considered audit-ready.

---

**Last updated:** 2026-01-19
**Checklist version:** 1.0.0
