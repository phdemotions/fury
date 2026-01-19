# Usability Improvements — Novice-First Redesign

**Primary creator & maintainer:** Josh Gonzales (GitHub: `phdemotions`)
**Canonical source:** `/phdemotions`

---

## Critical Insight

After walking through the package **as a complete novice**, I identified major usability barriers that would cause researchers to give up within the first 5 minutes.

This document details the problems found and solutions implemented.

---

## Problems Identified (The Novice Nightmare)

### Problem #1: File Path Hell

**What novice sees in README:**
```r
my_data_file <- "C:/Users/YourName/Downloads/MySurvey.sav"
```

**What novice doesn't know:**
- Their actual file path on their computer
- Whether to use `/` or `\` (Mac vs Windows)
- That they need to replace "YourName" with their actual username
- Where their Downloads folder actually is

**Result:** "Error: file not found" → **GIVES UP**

**Solution:** Use `file.choose()` instead:
```r
my_file <- file.choose()  # Opens file picker dialog!
```

---

### Problem #2: Two-Step Dance (Spec → Run)

**What novice sees:**
```r
# Step 1: Create spec and save to file
spec <- fury_spec() %>%
  fury_source(...) %>%
  fury_to_yaml("my_spec.yaml")

# Step 2: Run fury on the file you just created
result <- fury_run("my_spec.yaml", out_dir = "...")
```

**What novice thinks:**
- "Why am I creating a file just to immediately use it?"
- "Can't I skip step 1?"
- "What if I don't want a YAML file?"

**Result:** Confusion → **GIVES UP**

**Solution:** Allow one-step execution:
```r
# Just run it directly!
result <- fury_run(
  fury_spec() %>% fury_source(file.choose(), format = "spss"),
  out_dir = "results"
)
```

---

### Problem #3: YAML Presented First

**README structure BEFORE:**
1. Shows YAML file first (complex syntax, indentation rules)
2. Mentions R code as "Advanced" later

**Why this is backwards:**
- YAML requires learning new syntax
- Requires creating a text file (where? how?)
- Indentation errors are silent killers
- Novices already know how to run R code (or can copy-paste)

**Result:** "I have to learn YAML just to try this?" → **GIVES UP**

**Solution:** Show R code FIRST, label it "Easy - Recommended"

---

### Problem #4: No "Just Works" Example

**What was missing:**
- Example that runs with ZERO customization
- Uses included test data
- Shows actual output
- Proves fury works before asking user to configure

**What novices need:**
1. Copy-paste code
2. See it work immediately
3. THEN customize for their data

**Result:** "I don't know if fury works or if I'm doing something wrong" → **GIVES UP**

**Solution:** Create 5-minute quickstart with test data

---

### Problem #5: The %>% Pipe Mystery

**What novice sees:**
```r
fury_spec() %>% fury_source(...)
```

**What novice doesn't know:**
- What `%>%` means (it's not standard R)
- That they need `magrittr` or `dplyr` loaded
- That R 4.1+ has `|>` as alternative
- Whether to type it or use autocomplete

**Result:** "Error: could not find function '%>%'" → **GIVES UP**

**Solution:**
- Mention `library(magrittr)` upfront
- Show `|>` alternative
- Include in error troubleshooting

---

### Problem #6: "Advanced" Mislabeling

**README labeled spec builder as "Advanced"**

But spec builder is actually **EASIER** than YAML because:
- No new syntax to learn
- Familiar R function calls
- Autocomplete works
- Immediate error messages

**Result:** Novices skip the easier approach thinking it's too hard for them

**Solution:** Relabel as "Recommended for Beginners"

---

## Solutions Implemented

### Solution #1: 5-Minute Quick Start Vignette

**New file:** `vignettes/absolute-beginner-5-minutes.Rmd`

**What it does:**
1. Shows test data example (works immediately, zero config)
2. Then shows `file.choose()` for user's data
3. Provides copy-paste cheat sheet
4. Troubleshoots common first-time errors

**Code example:**
```r
# Copy-paste this - it just works!
library(fury)
test_file <- system.file("extdata", "test_minimal.sav", package = "fury")
result <- fury_run(
  fury_spec() %>% fury_source(test_file, format = "spss"),
  out_dir = tempdir()
)
print(result)
```

**Why this works:**
- ✅ No file paths to customize
- ✅ No external data needed
- ✅ Shows output immediately
- ✅ Proves fury works
- ✅ Builds confidence

---

### Solution #2: README Redesign (Easy Path First)

**New README structure:**

1. **🚀 5-Minute Quick Start** (test data, copy-paste)
2. **Using YOUR data** with `file.choose()`
3. **Add screening in one line** (exclude consent, flag attention checks)
4. **For More Control** section (two options: R code OR YAML)

**Key changes:**
- R code shown FIRST (labeled "Recommended")
- YAML shown SECOND (for text file lovers)
- file.choose() featured prominently
- One-step execution emphasized

**Before (YAML first):**
```yaml
# Novice sees complex YAML syntax first
data:
  sources:
    - file: "my_qualtrics_data.sav"
      format: "spss"
```

**After (R code first):**
```r
# Novice sees familiar R function calls first
library(fury)
result <- fury_run(
  fury_spec() %>% fury_source(file.choose(), format = "spss"),
  out_dir = "results"
)
```

---

### Solution #3: Website Navigation Redesign

**Old navigation:**
- Get Started → Complete Beginner's Guide (long, comprehensive)

**New navigation:**
- Get Started → **5-Minute Quick Start** (short, copy-paste)
- Tutorials dropdown:
  - 🚀 **5-Minute Quick Start** (featured at top)
  - Complete Beginner's Guide (below)

**Why this works:**
- Novices see quickstart FIRST
- Quick win builds confidence
- Then they explore full guide

---

### Solution #4: Cheat Sheet in Quick Start

**What novices want:** "Just tell me what to type!"

**Provided:**

```r
# The absolute minimum (just import)
library(fury)
result <- fury_run(
  fury_spec() %>% fury_source(file.choose(), format = "spss"),
  out_dir = "results"
)

# Exclude missing consent (one extra line)
result <- fury_run(
  fury_spec() %>%
    fury_source(file.choose(), format = "spss") %>%
    fury_exclude_missing("consent"),
  out_dir = "results"
)

# Flag attention checks (add this instead)
result <- fury_run(
  fury_spec() %>%
    fury_source(file.choose(), format = "spss") %>%
    fury_flag_attention(var = "attn_check_1", pass_values = 3, description = "Select 3"),
  out_dir = "results"
)
```

**Copy-paste ready. No customization needed except variable names.**

---

### Solution #5: Common Problems Section

**Added to 5-minute quickstart:**

**Problem:** "Error: could not find function '%>%'"
**Solution:** `library(magrittr)` or use `|>` instead

**Problem:** "Error: haven package not found"
**Solution:** `install.packages("haven")`

**Problem:** "Error: file not found"
**Solution:** Use `file.choose()` instead of typing path

**Why this works:** Novices hit these errors FIRST, not later

---

### Solution #6: browseURL() to Open Results

**Added:**
```r
# Open results folder automatically
browseURL(result$artifacts$audit_dir)
```

**Why this helps:**
- Novices don't know where tempdir() is
- Don't have to hunt for output folder
- Immediate visual feedback

---

## Usability Testing Checklist

### Can a novice with zero R experience:

✅ **Install fury without errors?**
- Clear instructions
- haven dependency mentioned upfront

✅ **Run fury on test data in < 5 minutes?**
- Copy-paste example provided
- No customization needed

✅ **Run fury on THEIR data without typing file paths?**
- file.choose() featured prominently
- No "C:/Users/YourName/..." confusion

✅ **See output without hunting for folders?**
- browseURL() opens results automatically

✅ **Add basic screening (consent, attention checks)?**
- One-line additions shown
- Cheat sheet provided

✅ **Understand what they need to customize?**
- REPLACE THIS comments in code
- Clear variable name placeholders

✅ **Recover from common first-time errors?**
- Troubleshooting section in quickstart
- Error messages → solutions

---

## Before/After Comparison

### Before: Novice Journey (FAILED)

1. Reads README
2. Sees YAML syntax (unfamiliar)
3. Doesn't know how to create .yaml file
4. Tries typing file path, gets it wrong
5. "Error: file not found"
6. **GIVES UP** (Time: 3 minutes)

### After: Novice Journey (SUCCESS)

1. Reads README
2. Clicks "5-Minute Quick Start"
3. Copy-pastes test data example
4. Sees it work immediately! (confidence boost)
5. Copy-pastes "use YOUR data" example
6. Uses file.choose() (no typing paths)
7. Sees output open automatically
8. **SUCCESS!** (Time: 5 minutes)

---

## Metrics of Success

**Package is usable if:**

✅ Novice can run fury on test data in ONE copy-paste
✅ Novice can run fury on their data in TWO copy-pastes
✅ Novice sees output without hunting for folders
✅ Novice recovers from %>% error in < 1 minute
✅ Novice knows what to customize (variable names only)

**All metrics now achievable.**

---

## Files Modified

### New Files Created

1. **`vignettes/absolute-beginner-5-minutes.Rmd`**
   - 5-minute quickstart with test data
   - file.choose() examples
   - Cheat sheet
   - Troubleshooting

### Files Updated

2. **`README.md`**
   - Redesigned to show R code FIRST
   - Added 5-minute quickstart section at top
   - file.choose() featured prominently
   - Moved YAML to "Option B"

3. **`_pkgdown.yml`**
   - "Get Started" now points to quickstart (not full guide)
   - Quickstart featured at top of Tutorials dropdown
   - Website navigation redesigned

---

## What This Does NOT Change

✅ **No new functions added** (scope discipline maintained)

✅ **No changes to fury's behavior** (just documentation)

✅ **No changes to API** (same functions, same arguments)

✅ **Conservative language preserved** (all guidelines still followed)

✅ **Governance compliance maintained** (ecosystem contracts obeyed)

**This is purely a documentation/usability improvement.**

---

## Key Insight: Novices Need Wins, Not Walls

**Walls (what we had before):**
- YAML syntax
- File path typing
- Two-step process
- No working example

**Wins (what we have now):**
- Copy-paste code that works immediately
- file.choose() removes file path barrier
- One-step execution
- Test data proves it works

**First impression determines if novice continues or gives up.**

**fury now gives novices a win in < 5 minutes.**

---

## Validation

**Test this yourself as a novice:**

1. Pretend you've never used fury
2. Go to the 5-minute quickstart
3. Copy-paste the test data example
4. Did it work? (Should show output)
5. Copy-paste the "YOUR data" example
6. Click to select file in dialog
7. Did it work? (Should show output)

**If both work → SUCCESS**

**If either fails → More usability work needed**

---

## Future Usability Improvements (Not Implemented Yet)

### Potential Enhancements

1. **Interactive tutorial** (learnr package)
   - Runs in RStudio
   - Validates each step
   - Provides hints

2. **Video walkthrough** (5 minutes)
   - Screen recording
   - Shows file.choose() in action
   - Embed in quickstart vignette

3. **fury_start() helper function**
   - Opens file picker
   - Runs minimal workflow
   - Opens results automatically
   ```r
   fury_start()  # Does everything interactively
   ```

4. **RStudio addin**
   - Point-and-click interface
   - No code needed
   - Generates R code for reproducibility

**None implemented yet (out of scope for current task)**

---

## Summary

**Before:** fury was technically correct but practically unusable for novices

**After:** fury has a 5-minute path to success for complete beginners

**Key changes:**
- ✅ R code shown before YAML
- ✅ file.choose() removes file path barrier
- ✅ One-step execution emphasized
- ✅ Test data example proves it works
- ✅ 5-minute quickstart featured prominently
- ✅ Cheat sheet for common tasks
- ✅ Troubleshooting for first-time errors

**Result:** Novices can now succeed instead of giving up.

---

**Last updated:** 2026-01-19
**Usability version:** 2.0.0 (novice-first redesign)
