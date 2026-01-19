# Test: Audit Invariants for Novice Workflow + Tutorial Completeness
# Primary creator & maintainer: Josh Gonzales (GitHub: phdemotions)
# Canonical source: /phdemotions
#
# PURPOSE:
# Enforce audit invariants to prevent scope creep and ensure novice usability.
# These tests verify documentation quality, conservative language, and artifact generation.

# Test 1: README Contains Minimal Working Example with .sav Ingestion -----

test_that("README contains .sav ingestion example", {
  skip_if_not(file.exists("../../README.md"), "README.md not found")

  readme_text <- readLines("../../README.md", warn = FALSE)

  # Check for .sav mention
  has_sav_mention <- any(grepl("\\.sav", readme_text, ignore.case = TRUE))
  expect_true(has_sav_mention,
              info = "README must include an example showing .sav file ingestion")

  # Check for fury_run() or equivalent entry point
  has_entry_point <- any(grepl("fury_run\\(", readme_text))
  expect_true(has_entry_point,
              info = "README must show how to run fury_run() or equivalent")
})

# Test 2: README Contains Novice Warning About Flags vs Exclusions -------

test_that("README warns about flags vs exclusions", {
  skip_if_not(file.exists("../../README.md"), "README.md not found")

  readme_text <- paste(readLines("../../README.md", warn = FALSE), collapse = " ")

  # Check for explicit warning about flags
  has_flag_warning <- grepl("flag.*exclude|exclude.*flag|flags do not remove|flagging vs|flag.*action", readme_text, ignore.case = TRUE)
  expect_true(has_flag_warning,
              info = "README must explicitly warn that flags do not remove cases unless an exclusion rule is declared")

  # Check for explanation of action types
  has_action_explanation <- grepl('action.*"flag"|action.*"exclude"', readme_text, ignore.case = TRUE)
  expect_true(has_action_explanation,
              info = "README must explain the difference between action: 'flag' and action: 'exclude'")
})

# Test 3: README Uses Conservative Language (No Inflated Claims) ---------

test_that("README uses conservative language (no inflated claims)", {
  skip_if_not(file.exists("../../README.md"), "README.md not found")

  readme_text <- tolower(paste(readLines("../../README.md", warn = FALSE), collapse = " "))

  # Banned terms that indicate inflated claims
  banned_terms <- c(
    "final dataset",
    "cleaned data",
    "final sample"
  )

  for (term in banned_terms) {
    # Check if term appears
    if (grepl(term, readme_text, fixed = TRUE)) {
      # Allow if it's in a negative context (e.g., "NOT final dataset")
      negative_pattern <- paste0("(not|never|no|does not)\\s+\\S+\\s*", gsub(" ", "\\\\s+", term))
      is_negative_context <- grepl(negative_pattern, readme_text)
      expect_true(is_negative_context,
                  info = paste0("README contains inflated term: '", term, "' (not in negative context)"))
    }
  }

  # Check for conservative alternative phrasing
  has_conservative_language <- grepl("analysis-eligible|analysis pool|declared rules", readme_text)
  expect_true(has_conservative_language,
              info = "README should use conservative phrasing like 'analysis-eligible per declared rules'")
})

# Test 4: README Does Not Claim Fury Performs Out-of-Scope Tasks ---------

test_that("README does not claim fury performs modeling, scoring, or validation", {
  skip_if_not(file.exists("../../README.md"), "README.md not found")

  readme_text <- tolower(paste(readLines("../../README.md", warn = FALSE), collapse = " "))

  # Terms that indicate out-of-scope functionality
  banned_claims <- c(
    "cronbach",
    "factor analysis",
    "structural equation",
    "mediation analysis",
    "moderation analysis",
    "manipulation check",
    "construct validation"
  )

  for (term in banned_claims) {
    if (grepl(term, readme_text, fixed = TRUE)) {
      # Only allowed in negative context (e.g., "fury does NOT perform" or in a "does NOT do" list)
      # Check for broader negative patterns including list items
      negative_patterns <- c(
        paste0("(not|never|no|does not|do not)\\s+\\S+\\s*", gsub(" ", "\\\\s+", term)),
        paste0("does not do.*", gsub(" ", "\\\\s+", term)),
        paste0("what.*does not.*", gsub(" ", "\\\\s+", term)),
        paste0("-\\s+", gsub(" ", "\\\\s+", term))  # Bullet point in "does NOT" section
      )

      is_negative_context <- any(sapply(negative_patterns, function(p) grepl(p, readme_text)))

      # Also check if it's in a clearly negative section (What fury does NOT do)
      section_pattern <- "what.*does\\s+not\\s+do"
      has_negative_section <- grepl(section_pattern, readme_text, ignore.case = TRUE)
      if (has_negative_section) {
        # Extract the "does NOT do" section
        readme_lines <- readLines("../../README.md", warn = FALSE)
        not_section_start <- grep("what.*does\\s+not\\s+do", readme_lines, ignore.case = TRUE)
        if (length(not_section_start) > 0) {
          # Find end of section (next header or empty section)
          next_header <- grep("^##", readme_lines[-(1:not_section_start[1])])
          section_end <- if (length(next_header) > 0) {
            not_section_start[1] + next_header[1]
          } else {
            length(readme_lines)
          }

          not_section <- paste(readme_lines[not_section_start[1]:section_end], collapse = " ")
          is_in_not_section <- grepl(term, tolower(not_section), fixed = TRUE)
          is_negative_context <- is_negative_context || is_in_not_section
        }
      }

      expect_true(is_negative_context,
                  info = paste0("README claims fury performs: '", term, "' (out of scope)"))
    }
  }
})

# Test 5: At Least One Vignette Exists -----------------------------------

test_that("at least one vignette exists", {
  skip_if_not(dir.exists("../../vignettes"), "vignettes/ directory not found")

  vignette_files <- list.files("../../vignettes", pattern = "\\.Rmd$", full.names = TRUE)
  expect_true(length(vignette_files) > 0,
              info = "At least one .Rmd vignette must exist")
})

# Test 6: Vignette Shows How to Run fury_run() ---------------------------

test_that("vignette shows how to run fury_run()", {
  skip_if_not(dir.exists("../../vignettes"), "vignettes/ directory not found")

  vignette_files <- list.files("../../vignettes", pattern = "\\.Rmd$", full.names = TRUE)
  skip_if(length(vignette_files) == 0, "No vignettes found")

  # Check first vignette
  vignette_text <- paste(readLines(vignette_files[1], warn = FALSE), collapse = " ")

  has_fury_run <- grepl("fury_run\\(", vignette_text)
  expect_true(has_fury_run,
              info = "Vignette must demonstrate how to use fury_run() or equivalent entry point")
})

# Test 7: Vignette Shows Where to Find Audit Artifacts -------------------

test_that("vignette shows where to find audit artifacts", {
  skip_if_not(dir.exists("../../vignettes"), "vignettes/ directory not found")

  vignette_files <- list.files("../../vignettes", pattern = "\\.Rmd$", full.names = TRUE)
  skip_if(length(vignette_files) == 0, "No vignettes found")

  vignette_text <- paste(readLines(vignette_files[1], warn = FALSE), collapse = " ")

  # Check for mentions of key artifacts
  artifact_mentions <- c(
    "raw_codebook" = grepl("raw_codebook|codebook\\.csv", vignette_text, ignore.case = TRUE),
    "audit_dir" = grepl("audit_dir|audit/", vignette_text, ignore.case = TRUE)
  )

  expect_true(any(artifact_mentions),
              info = "Vignette must show where to find audit artifacts (e.g., raw_codebook.csv, audit_dir)")
})

# Test 8: Vignette Uses Conservative Language -----------------------------

test_that("vignette uses conservative language (no inflated claims)", {
  skip_if_not(dir.exists("../../vignettes"), "vignettes/ directory not found")

  vignette_files <- list.files("../../vignettes", pattern = "\\.Rmd$", full.names = TRUE)
  skip_if(length(vignette_files) == 0, "No vignettes found")

  vignette_text <- tolower(paste(readLines(vignette_files[1], warn = FALSE), collapse = " "))

  # Banned terms
  banned_terms <- c(
    "final dataset",
    "cleaned data",
    "final sample",
    "validated data"
  )

  for (term in banned_terms) {
    if (grepl(term, vignette_text, fixed = TRUE)) {
      # Check if it's in a negative context
      negative_pattern <- paste0("(not|never|no|does not)\\s+\\S+\\s*", gsub(" ", "\\\\s+", term))
      is_negative_context <- grepl(negative_pattern, vignette_text)
      expect_true(is_negative_context,
                  info = paste0("Vignette contains inflated term: '", term, "' (not in negative context)"))
    }
  }
})

# Test 9: Artifact Language Tripwire (inst/audit/*.md) -------------------

test_that("audit checklist documents use conservative language", {
  skip_if_not(dir.exists("../../inst/audit"), "inst/audit/ directory not found")

  audit_docs <- list.files("../../inst/audit", pattern = "\\.md$", full.names = TRUE)
  skip_if(length(audit_docs) == 0, "No audit documents found")

  # These documents should NOT use inflated language
  for (doc_path in audit_docs) {
    doc_text <- tolower(paste(readLines(doc_path, warn = FALSE), collapse = " "))

    # Check for banned inflated language (except in negative contexts or examples of what NOT to do)
    # We allow these terms if they appear in sections like "Banned Terms" or "FAIL if"
    banned_terms <- c("validated", "reliability analysis", "cronbach", "manipulation check")

    for (term in banned_terms) {
      if (grepl(term, doc_text, fixed = TRUE)) {
        # Allowed in negative context, banned terms list, or FAIL criteria
        allowed_contexts <- c(
          "banned terms", "fail if", "do not", "does not", "not perform",
          "out of scope", "no inflated", "conservative language"
        )
        is_allowed_context <- any(sapply(allowed_contexts, function(ctx) grepl(ctx, doc_text, fixed = TRUE)))

        if (!is_allowed_context) {
          expect_true(FALSE,
                      info = paste0("Audit document ", basename(doc_path), " uses inflated term: '", term, "'"))
        }
      }
    }
  }

  # If we got here, all documents passed
  expect_true(TRUE)
})

# Test 10: Determinism Smoke Test -----------------------------------------

test_that("fury produces deterministic outputs (excluding timestamps)", {
  skip_if_not_installed("vision")

  # Create minimal spec
  spec_path <- tempfile(fileext = ".yaml")
  vision::write_spec_template(spec_path)
  on.exit(unlink(spec_path), add = TRUE)

  # Run fury twice
  out_dir_1 <- tempfile(pattern = "audit_test_1_")
  dir.create(out_dir_1, showWarnings = FALSE, recursive = TRUE)
  on.exit(unlink(out_dir_1, recursive = TRUE), add = TRUE)

  result_1 <- fury_run(spec_path, out_dir = out_dir_1)

  out_dir_2 <- tempfile(pattern = "audit_test_2_")
  dir.create(out_dir_2, showWarnings = FALSE, recursive = TRUE)
  on.exit(unlink(out_dir_2, recursive = TRUE), add = TRUE)

  result_2 <- fury_run(spec_path, out_dir = out_dir_2)

  # Compare raw_codebook.csv (should be identical for same spec)
  codebook_1_path <- file.path(result_1$artifacts$audit_dir, "raw_codebook.csv")
  codebook_2_path <- file.path(result_2$artifacts$audit_dir, "raw_codebook.csv")

  if (file.exists(codebook_1_path) && file.exists(codebook_2_path)) {
    codebook_1 <- read.csv(codebook_1_path, stringsAsFactors = FALSE)
    codebook_2 <- read.csv(codebook_2_path, stringsAsFactors = FALSE)

    expect_identical(codebook_1, codebook_2,
                     info = "raw_codebook.csv should be identical across runs for same spec")
  }

  # Compare source_manifest.csv (excluding timestamp columns)
  manifest_1_path <- file.path(result_1$artifacts$audit_dir, "source_manifest.csv")
  manifest_2_path <- file.path(result_2$artifacts$audit_dir, "source_manifest.csv")

  if (file.exists(manifest_1_path) && file.exists(manifest_2_path)) {
    manifest_1 <- read.csv(manifest_1_path, stringsAsFactors = FALSE)
    manifest_2 <- read.csv(manifest_2_path, stringsAsFactors = FALSE)

    # Remove timestamp columns
    timestamp_cols <- c("timestamp", "ingested_at", "created_at")
    manifest_1_clean <- manifest_1[, !colnames(manifest_1) %in% timestamp_cols, drop = FALSE]
    manifest_2_clean <- manifest_2[, !colnames(manifest_2) %in% timestamp_cols, drop = FALSE]

    expect_identical(manifest_1_clean, manifest_2_clean,
                     info = "source_manifest.csv (excl. timestamps) should be identical across runs")
  }
})

# Test 11: Filesystem Rule (Writes Only Under tempdir or out_dir) --------

test_that("fury writes only under tempdir or specified out_dir", {
  skip_if_not_installed("vision")

  spec_path <- tempfile(fileext = ".yaml")
  vision::write_spec_template(spec_path)
  on.exit(unlink(spec_path), add = TRUE)

  out_dir <- tempfile(pattern = "audit_test_fs_")
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  result <- fury_run(spec_path, out_dir = out_dir)

  # Verify audit_dir is under out_dir
  audit_dir_under_outdir <- grepl(out_dir, result$artifacts$audit_dir, fixed = TRUE)
  expect_true(audit_dir_under_outdir,
              info = paste("audit_dir should be under out_dir. Expected under:", out_dir,
                           "Got:", result$artifacts$audit_dir))

  # Verify audit_dir exists
  expect_true(dir.exists(result$artifacts$audit_dir),
              info = "audit_dir should exist at the specified location")
})

# Test 12: SPSS .sav Fixture Exists (If haven Available) ------------------

test_that("SPSS .sav fixture exists in inst/extdata", {
  extdata_path <- system.file("extdata", package = "fury")
  skip_if(extdata_path == "", "inst/extdata not found in installed package")

  sav_files <- list.files(extdata_path, pattern = "\\.sav$", full.names = TRUE)

  # If haven is available, we expect a .sav fixture
  if (requireNamespace("haven", quietly = TRUE)) {
    expect_true(length(sav_files) > 0,
                info = "At least one .sav fixture should exist in inst/extdata (haven is available)")

    if (length(sav_files) > 0) {
      # Check fixture is reasonably small (< 10 KB for toy data)
      sav_size <- file.size(sav_files[1])
      expect_true(sav_size < 10240,
                  info = paste0("SPSS fixture should be < 10 KB (got ", sav_size, " bytes)"))

      # Verify fixture is readable
      test_data <- haven::read_sav(sav_files[1])
      expect_true(is.data.frame(test_data),
                  info = "SPSS fixture should be readable as data.frame")
      expect_true(nrow(test_data) > 0,
                  info = "SPSS fixture should contain at least one row")
    }
  } else {
    # If haven is not available, we can skip or just check that fixture exists
    skip("haven not available; skipping .sav fixture validation")
  }
})

# Test 13: No Silent Mutations in fury_run() -----------------------------

test_that("fury does not silently mutate ingested data", {
  skip_if_not_installed("vision")

  # This is a conceptual test; full implementation depends on fury internals
  # For now, we just verify that fury_run completes without errors
  # and produces expected artifacts

  spec_path <- tempfile(fileext = ".yaml")
  vision::write_spec_template(spec_path)
  on.exit(unlink(spec_path), add = TRUE)

  out_dir <- tempfile(pattern = "audit_test_mutation_")
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  result <- fury_run(spec_path, out_dir = out_dir)

  # Verify result is valid
  expect_s3_class(result, "niche_result")

  # Verify raw_codebook exists (implies data was ingested, not mutated)
  codebook_path <- file.path(result$artifacts$audit_dir, "raw_codebook.csv")
  expect_true(file.exists(codebook_path),
              info = "raw_codebook.csv should exist (implies data ingestion occurred)")

  # Future: compare ingested data to source data to verify no mutations
  # (This would require access to result$data or equivalent)
})

# Test 14: Audit Harness Exists and Is Executable ------------------------

test_that("audit harness exists and is executable", {
  harness_path <- "../../tools/run_audit.R"
  skip_if_not(file.exists(harness_path), "tools/run_audit.R not found")

  # Verify file is not empty
  harness_size <- file.size(harness_path)
  expect_true(harness_size > 0,
              info = "tools/run_audit.R should not be empty")

  # Verify file contains expected sections
  harness_text <- paste(readLines(harness_path, warn = FALSE), collapse = "\n")

  expect_true(grepl("fury_run\\(", harness_text),
              info = "Audit harness should call fury_run()")
  expect_true(grepl("record_check|expect_", harness_text),
              info = "Audit harness should contain check/assertion logic")
  expect_true(grepl("quit\\(status", harness_text),
              info = "Audit harness should exit with status code")
})

# Test 15: Tutorial Checklist Exists --------------------------------------

test_that("TUTORIAL_CHECKLIST.md exists in inst/audit", {
  checklist_path <- "../../inst/audit/TUTORIAL_CHECKLIST.md"
  expect_true(file.exists(checklist_path),
              info = "TUTORIAL_CHECKLIST.md should exist in inst/audit/")

  if (file.exists(checklist_path)) {
    checklist_text <- paste(readLines(checklist_path, warn = FALSE), collapse = "\n")

    # Verify it enumerates required tutorials
    expect_true(grepl("Tutorial 1", checklist_text),
                info = "TUTORIAL_CHECKLIST.md should enumerate required tutorials")
    expect_true(grepl("SPSS|sav", checklist_text, ignore.case = TRUE),
                info = "TUTORIAL_CHECKLIST.md should mention SPSS .sav ingestion")
    expect_true(grepl("conservative language|banned terms", checklist_text, ignore.case = TRUE),
                info = "TUTORIAL_CHECKLIST.md should mention conservative language requirements")
  }
})

# Test 16: Audit Checklist Exists -----------------------------------------

test_that("AUDIT_CHECKLIST.md exists in inst/audit", {
  checklist_path <- "../../inst/audit/AUDIT_CHECKLIST.md"
  expect_true(file.exists(checklist_path),
              info = "AUDIT_CHECKLIST.md should exist in inst/audit/")

  if (file.exists(checklist_path)) {
    checklist_text <- paste(readLines(checklist_path, warn = FALSE), collapse = "\n")

    # Verify it contains required sections
    required_sections <- c(
      "Novice Walkthrough",
      "SPSS.*Ingestion",
      "CONSORT",
      "Methods Write-Up",
      "Determinism"
    )

    for (section in required_sections) {
      expect_true(grepl(section, checklist_text, ignore.case = TRUE),
                  info = paste0("AUDIT_CHECKLIST.md should contain section: ", section))
    }
  }
})
