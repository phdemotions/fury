# Novice Walkthrough — Complete Beginner's Guide to fury

**Primary creator & maintainer:** Josh Gonzales (GitHub: `phdemotions`)
**Canonical source:** `/phdemotions`

---

## What Was Created

A **comprehensive, jargon-free vignette** for researchers who are completely new to R and statistics.

**File:** `vignettes/novice-walkthrough.Rmd`

---

## What Makes This Walkthrough Novice-Friendly

### 1. Zero Jargon (Or Jargon Explained Immediately)

**Every technical term is explained in plain English:**

| Technical Term | Plain English Explanation |
|----------------|---------------------------|
| "Spec" | A recipe file that tells fury what to do |
| "YAML" | A simple text file format (human-readable) |
| "GitHub" | A website where programmers share code |
| "SPSS" | A statistics program; Qualtrics exports this format |
| "Partition" | Label (e.g., "pilot" vs. "main") without removing |
| "Analysis-eligible" | Ready for you to analyze (not a "final" dataset) |
| "CONSORT" | A flowchart format journals require |
| "Codebook" | A list of your variables (questions) and answer options |

**No term is used without explanation.**

---

### 2. Crystal-Clear Explanations of Confusing Concepts

#### 🔑 Flagging vs. Excluding (The #1 Mistake)

The walkthrough dedicates an **entire section** with:

- ✅ Visual table showing when to flag vs. exclude
- ✅ Concrete examples ("Participant 42 is STILL in your data")
- ✅ Golden rule: "When in doubt, flag (you can always exclude later)"

**Example from the vignette:**

> ### Flagging = Marking (Participants Stay In Your Data)
>
> When you **flag** someone, you're putting a note on their data that says "hey, this person failed an attention check" BUT **they are still in your dataset**.
>
> **Example:**
> ```
> Participant 42 failed the attention check
> → fury adds a column: attn_check_failed = TRUE
> → Participant 42 is STILL in your data
> → You decide later whether to remove them
> ```

#### 🔑 Pilot vs. Main Study

Explains:

- ✅ Why it matters (reviewers want to know)
- ✅ What happens if you DON'T declare a pilot (fury documents "No")
- ✅ That partitioning = labeling (not removing)

#### 🔑 Analysis-Eligible Dataset (Not "Final")

Explains:

- ✅ What "analysis-eligible per declared rules" means
- ✅ Why we don't call it "final" (you still have work to do)
- ✅ What decisions YOU still need to make (outliers, missing data, etc.)

---

### 3. Four Complete Tutorials (Copy-Paste Ready)

Each tutorial includes:

1. **Clear scenario** ("You just want to import your Qualtrics data")
2. **Step-by-step instructions** with numbered steps
3. **Two options:** R code (beginner-friendly) OR YAML (text file)
4. **"What just happened?" explanations** after each code block
5. **Expected output** ("You'll see these files...")

#### Tutorial 1: Import One SPSS File (No Exclusions)

- Shows how to export from Qualtrics
- Creates minimal spec
- Runs fury
- Explains each output file

#### Tutorial 2: Exclude People Who Didn't Consent

- Finds the consent variable in the codebook
- Adds an exclusion rule
- Checks screening_summary.csv and consort_flow.csv

#### Tutorial 3: Flag (But Don't Remove) Failed Attention Checks

- Adds a flag rule (not exclude)
- Explains warnings.csv
- Lists options (keep, exclude, or run analysis twice)

#### Tutorial 4: Separate Pilot Data from Main Study

- Declares pilot partition by date range
- Checks decision_registry.csv
- Explains why this matters for reviewers

---

### 4. Visual "Big Picture" Diagram

The walkthrough includes a **flowchart** showing where fury fits in the research workflow:

```
Step 1: Collect Data in Qualtrics
         ↓
Step 2: Export as SPSS (.sav file)
         ↓
Step 3: Use fury to import and screen data    ← YOU ARE HERE
         ↓
Step 4: Review fury's output files
         ↓
Step 5: Make final decisions about flagged participants
         ↓
Step 6: Compute scale scores (separate R script)
         ↓
Step 7: Run your statistical analyses
         ↓
Step 8: Create APA tables and figures
         ↓
Step 9: Write your manuscript
         ↓
Step 10: Share fury output files as supplementary materials
```

**Message:** "fury handles Steps 3-4. You handle the rest!"

---

### 5. Troubleshooting Section

Addresses common beginner mistakes:

| Problem | Solution |
|---------|----------|
| "Error: haven package not found" | `install.packages("haven")` |
| "Error: file not found" | Check file path (use forward slashes `/`) |
| "I don't understand the output files" | Start with warnings.csv, then screening_summary.csv |

**Includes `file.choose()` tip** for users who don't know their file paths.

---

### 6. Methods Section Writing Help

Provides a **ready-to-use template** for the Methods section:

> "Data were screened using the fury R package (Gonzales, 2026). Participants were excluded if they did not provide consent (n = 5). Participants who failed the attention check were flagged but retained for sensitivity analysis (n = 7). All screening rules were preregistered and are available in the supplementary materials (my_screening_rules.yaml). A complete audit trail, including a participant flow diagram (CONSORT format), is also available in the supplementary materials."

**Lists which files to share as supplementary materials:**

1. ✅ my_screening_rules.yaml
2. ✅ decision_registry.csv
3. ✅ screening_summary.csv
4. ✅ consort_flow.csv
5. ✅ source_manifest.csv
6. ✅ session_info.txt

---

### 7. Conservative Language Throughout

**Banned terms are NOT used:**

- ❌ "final dataset"
- ❌ "cleaned data"
- ❌ "validated data"

**Conservative alternatives used:**

- ✅ "analysis-eligible dataset per declared rules"
- ✅ "fury prepares your data. YOU finish it."
- ✅ "raw codebook" (not "validated codebook")

**Explicit scope statements:**

> **What fury does NOT do:**
> - ❌ Does NOT run statistical tests
> - ❌ Does NOT compute scale scores
> - ❌ Does NOT check reliability
> - ❌ Does NOT create APA-formatted tables

---

### 8. Beginner-Friendly Formatting

- ✅ **Short paragraphs** (3-4 sentences max)
- ✅ **Bullet points** for lists
- ✅ **Tables** for comparisons
- ✅ **Code blocks** with syntax highlighting
- ✅ **Emoji indicators** (🔑 for key concepts, ⚠️ for warnings, ✅ for checkmarks)
- ✅ **"What just happened?" boxes** after code
- ✅ **Bold and italic** for emphasis

---

## What This Walkthrough Covers

### Installation ✅

- How to install fury from GitHub
- How to install haven for SPSS files
- How to load fury in each R session

### Key Concepts ✅

- Flagging vs. excluding (with decision table)
- Pilot vs. main study partitioning
- "Analysis-eligible" vs. "final" dataset

### Four Complete Tutorials ✅

1. Import one SPSS file (no exclusions)
2. Exclude non-consenters
3. Flag failed attention checks
4. Separate pilot from main study

### Output Files Explained ✅

- raw_codebook.csv (what variables do I have?)
- screening_summary.csv (how many excluded?)
- consort_flow.csv (for Methods section diagram)
- warnings.csv (anything wrong?)
- decision_registry.csv (what did I declare?)
- source_manifest.csv (which files imported?)
- session_info.txt (reproducibility)

### Writing Your Methods Section ✅

- Template text to copy-paste
- Which files to share as supplementary materials
- How to cite fury

### Troubleshooting ✅

- Common error messages and solutions
- File path mistakes (backslashes vs. forward slashes)
- Using file.choose() to find file paths

---

## What This Walkthrough Does NOT Cover (Intentionally)

To prevent scope creep and confusion:

- ❌ **Statistical analysis** (fury doesn't do this)
- ❌ **Computing scale scores** (out of scope)
- ❌ **Reverse-coding items** (out of scope)
- ❌ **Checking reliability** (out of scope)
- ❌ **Creating APA tables** (out of scope)
- ❌ **Advanced R programming** (not needed for fury)

**Each of these is explicitly stated as "fury does NOT do this"** to set correct expectations.

---

## Audit Compliance

### Novice-Friendly Requirements ✅

From `TUTORIAL_CHECKLIST.md`:

1. ✅ **Explicit install instructions** — Shown with `install.packages()` and `remotes::install_github()`
2. ✅ **Explicit library loading** — Every tutorial starts with `library(fury)`
3. ✅ **Avoid jargon** — All technical terms explained in plain English
4. ✅ **Show expected output** — Every tutorial says "you'll see these files..."
5. ✅ **Explain file paths** — Includes `file.choose()` tip and forward-slash advice

### Conservative Language ✅

- ✅ Uses "analysis-eligible per declared rules"
- ✅ Never uses "final dataset" or "cleaned data"
- ✅ Includes all required callout boxes:
  - "Flags do not remove cases"
  - "Pilot/pretest are partitions, not exclusions"
  - "No recoding/scoring/validation occurs in fury"

### Tutorial Completeness ✅

All 3 required tutorials are present:

1. ✅ "Ingest a single SPSS .sav and generate a RAW codebook" (Tutorial 1)
2. ✅ "Ingest multiple sources (pilot + main) and preserve provenance" (Tutorial 4)
3. ✅ "Apply screening rules and generate CONSORT flow artifacts" (Tutorials 2 & 3)

---

## How Novices Will Use This

### Typical Workflow

1. **Researcher collects Qualtrics data** (never used R before)
2. **Researcher Googles "R package for Qualtrics screening"** → finds fury
3. **Researcher opens `novice-walkthrough.Rmd`** in RStudio
4. **Researcher reads "Welcome! This Guide is For You If..."** → feels seen
5. **Researcher reads "Key Concepts"** → understands flagging vs. excluding
6. **Researcher follows Tutorial 1** → successfully imports data
7. **Researcher sees raw_codebook.csv** → understands their variables
8. **Researcher follows Tutorial 2** → excludes non-consenters
9. **Researcher checks screening_summary.csv** → sees exclusion count
10. **Researcher uses Methods section template** → writes paper

**No R expertise required. No statistics background assumed.**

---

## Comparison to Typical R Vignettes

### Typical R Vignette (Expert-Focused)

```r
# Load package
library(pkg)

# Run analysis
result <- analyze(data, method = "parametric")

# Extract results
summary(result)
```

**Problems for novices:**

- ❌ Assumes you know how to install packages
- ❌ Assumes you know where `data` came from
- ❌ Doesn't explain what "parametric" means
- ❌ Doesn't show what the output looks like

### fury Novice Walkthrough (Beginner-Focused)

```r
# Install fury from GitHub (if not already installed)
remotes::install_github("phdemotions/fury")

# Load fury (do this every time you start R)
library(fury)

# Tell fury where your SPSS file is
# REPLACE THIS with your actual file path!
my_data_file <- "C:/Users/YourName/Downloads/MySurvey.sav"

# Create the spec (recipe)
spec <- fury_spec() %>%
  fury_source(my_data_file, format = "spss")

# Save the spec to a file
fury_to_yaml(spec, "my_screening_rules.yaml")

# Run fury
result <- fury_run("my_screening_rules.yaml", out_dir = "my_audit")

# Look at your output files
# Open the folder my_audit/audit/ on your computer
# You'll see: raw_codebook.csv, screening_summary.csv, warnings.csv...
```

**What just happened?**

- `fury_spec()` starts creating your recipe
- `fury_source()` tells fury where your data file is
- `fury_to_yaml()` saves your recipe to a text file
- `fury_run()` imports your data and creates output files

**Advantages for novices:**

- ✅ Shows installation step
- ✅ Explains what to replace ("REPLACE THIS with your actual file path!")
- ✅ Uses plain English labels ("spec" = "recipe")
- ✅ Explains what each line does
- ✅ Shows where to find output files
- ✅ "What just happened?" box summarizes

---

## Success Metrics

This walkthrough is successful if a novice researcher can:

1. ✅ **Install fury** without getting stuck
2. ✅ **Import their Qualtrics data** on the first try
3. ✅ **Understand the difference between flagging and excluding** before making mistakes
4. ✅ **Find and interpret output files** (especially warnings.csv and screening_summary.csv)
5. ✅ **Write their Methods section** using the provided template
6. ✅ **Share the right files** as supplementary materials
7. ✅ **Know what fury does NOT do** (so they don't expect it to run their t-tests)

**Target audience:** Someone who has:

- Never used R before (or only used it once in a class)
- Never heard of GitHub
- Never written YAML
- Collected data in Qualtrics and exported an SPSS file
- No statistics training beyond undergraduate basics

**If this person can successfully use fury after reading this walkthrough, it's a success.**

---

## Maintenance

### When to Update This Walkthrough

- If fury's API changes (e.g., function names change)
- If new required tutorials are added to `TUTORIAL_CHECKLIST.md`
- If user feedback indicates confusion about a specific concept
- If journals change their Methods section requirements

### What NOT to Add

To prevent scope creep:

- ❌ Advanced R programming techniques
- ❌ Statistical analysis tutorials
- ❌ Scale construction or scoring
- ❌ APA table formatting
- ❌ Power analysis or sample size calculation

**These belong in other packages or guides.**

---

## Citation

If this walkthrough is referenced in teaching or documentation, please cite:

> Gonzales, J. (2026). *fury: Pre-Analysis Data Ingestion and Audit Layer for Consumer Psychology Research*. R package version 0.1.0. https://github.com/phdemotions/fury

---

**Last updated:** 2026-01-19
**Walkthrough version:** 1.0.0
**Target audience:** Researchers with zero R experience
