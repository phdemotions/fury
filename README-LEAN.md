# fury

<!-- badges: start -->
<!-- badges: end -->

**Pre-analysis data ingestion and audit layer for consumer psychology research.**

Import Qualtrics data, apply screening rules, generate audit artifacts for peer review.

---

## Primary creator & maintainer

**Josh Gonzales** (GitHub: `phdemotions`)
Canonical source: `/phdemotions`

---

## Installation

```r
install.packages("remotes")
remotes::install_github("phdemotions/fury")
install.packages("haven")  # For SPSS files
```

---

## 5-Minute Quick Start 🚀

**Copy-paste this to see it work:**

```r
library(fury)

# Test with included data (works immediately!)
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

# Opens file picker - no typing paths!
my_file <- file.choose()

# Import only
result <- fury_run(
  fury_spec() %>% fury_source(my_file, format = "spss"),
  out_dir = "results"
)

# Exclude missing consent
result <- fury_run(
  fury_spec() %>%
    fury_source(my_file, format = "spss") %>%
    fury_exclude_missing("consent"),
  out_dir = "results"
)

# Flag attention checks
result <- fury_run(
  fury_spec() %>%
    fury_source(my_file, format = "spss") %>%
    fury_flag_attention(var = "attn_check_1", pass_values = 3, description = "Select 3"),
  out_dir = "results"
)
```

---

## What fury Does

✅ Imports SPSS (.sav) files from Qualtrics
✅ Applies screening rules (exclude/flag participants)
✅ Tracks pilot vs. main study data
✅ Generates audit artifacts for Methods section
✅ Creates CONSORT flow diagrams

---

## What fury Does NOT Do

❌ Does NOT run statistical tests (t-tests, ANOVA, regression)
❌ Does NOT compute scale scores or reverse-code items
❌ Does NOT check reliability (Cronbach's alpha, factor analysis)
❌ Does NOT create APA tables or figures

**fury prepares data. You analyze it.**

---

## Learn More

📖 **[5-Minute Tutorial](https://phdemotions.github.io/fury/articles/absolute-beginner-5-minutes.html)** — Copy-paste examples

📖 **[Complete Guide](https://phdemotions.github.io/fury/articles/novice-walkthrough.html)** — Full walkthrough for beginners

📖 **[Function Reference](https://phdemotions.github.io/fury/reference/index.html)** — All functions documented

📖 **[Output Files Guide](https://phdemotions.github.io/fury/articles/output-files-guide.html)** — What fury creates

📖 **[Methods Section Guide](https://phdemotions.github.io/fury/articles/methods-section-guide.html)** — Templates for your paper

---

## Key Concept: Flagging vs. Excluding ⚠️

**The #1 mistake beginners make:**

- **`action: "flag"`** → Marks participants but KEEPS them in data
- **`action: "exclude"`** → Removes participants from data

**When in doubt, use "flag"** (you can exclude later in your analysis).

See the [complete guide](https://phdemotions.github.io/fury/articles/novice-walkthrough.html#flagging-vs-excluding) for details.

---

## Common First-Time Errors

**Error:** `could not find function '%>%'`
**Fix:** `library(magrittr)` or use `|>` instead

**Error:** `haven package not found`
**Fix:** `install.packages("haven")`

**Error:** `file not found`
**Fix:** Use `file.choose()` instead of typing the path

---

## Governance

fury obeys the **Ecosystem Contract** and **Package Standard** for the niche R universe:

- Only `nicheCore` defines core objects (`niche_spec`, `niche_recipe`, `niche_result`)
- Validation is fail-fast, structural, non-mutating
- Deterministic (same inputs → same outputs)
- No network access in tests
- One-way dependencies

See [governance docs](https://phdemotions.github.io/fury/articles/scope-and-governance.html) for details.

---

## Citation

If you use fury in published research:

> Gonzales, J. (2026). *fury: Pre-Analysis Data Ingestion and Audit Layer for Consumer Psychology Research*. R package version 0.1.0. https://github.com/phdemotions/fury

---

## License

MIT + file LICENSE
