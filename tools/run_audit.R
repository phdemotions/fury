#!/usr/bin/env Rscript
# Novice Workflow Audit + Tutorial Audit — fury Package
# Primary creator & maintainer: Josh Gonzales (GitHub: phdemotions)
# Canonical source: /phdemotions
#
# PURPOSE:
# Run a minimal end-to-end audit using ONLY in-package toy data.
# Verify that fury produces required artifacts and uses conservative language.
# Exit with non-zero status on failure.
#
# USAGE:
#   Rscript tools/run_audit.R
#
# REQUIREMENTS:
# - No network access
# - No external user data
# - Writes only to tempdir()
# - Guards Suggests dependencies (haven)

# Setup -------------------------------------------------------------------

cat("=============================================================\n")
cat("fury Package Audit: Novice Workflow + Tutorial Completeness\n")
cat("=============================================================\n\n")

# Track pass/fail status
audit_pass <- TRUE
audit_results <- list()

# Helper function to record check results
record_check <- function(check_name, passed, message = "") {
  status <- if (passed) "PASS" else "FAIL"
  cat(sprintf("[%s] %s\n", status, check_name))
  if (nchar(message) > 0) {
    cat(sprintf("       %s\n", message))
  }
  audit_results[[check_name]] <<- list(passed = passed, message = message)
  if (!passed) audit_pass <<- FALSE
  invisible(passed)
}

# Load fury package (from installed package or source)
tryCatch({
  # Try to load installed package first
  suppressPackageStartupMessages(library(fury))
  record_check("Load fury package", TRUE)
}, error = function(e) {
  # If not installed, try to load from source using devtools
  if (requireNamespace("devtools", quietly = TRUE)) {
    tryCatch({
      suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))
      record_check("Load fury package (from source)", TRUE)
    }, error = function(e2) {
      record_check("Load fury package", FALSE,
                   paste("Error loading fury:", e$message))
      quit(status = 1)
    })
  } else {
    record_check("Load fury package", FALSE,
                 paste("Error loading fury:", e$message,
                       "(devtools not available for loading from source)"))
    quit(status = 1)
  }
})

# Check for haven (Suggests dependency)
haven_available <- requireNamespace("haven", quietly = TRUE)
if (!haven_available) {
  record_check("Check haven availability", FALSE,
               "SKIPPED: haven not installed (required for .sav ingestion)")
} else {
  record_check("Check haven availability", TRUE)
}

# Section 1: Toy Fixtures -------------------------------------------------

cat("\n--- Section 1: Toy Fixtures ---\n")

# Check for .sav fixture
extdata_path <- system.file("extdata", package = "fury")
sav_files <- list.files(extdata_path, pattern = "\\.sav$", full.names = TRUE)
sav_fixture_exists <- length(sav_files) > 0

if (!sav_fixture_exists) {
  record_check("SPSS .sav fixture exists", FALSE,
               "No .sav file found in inst/extdata/")
} else {
  sav_fixture <- sav_files[1]
  sav_size <- file.size(sav_fixture)
  if (sav_size > 10240) { # 10 KB limit
    record_check("SPSS .sav fixture exists", FALSE,
                 sprintf("Fixture too large: %d bytes (max 10 KB)", sav_size))
  } else {
    record_check("SPSS .sav fixture exists", TRUE,
                 sprintf("Found: %s (%d bytes)", basename(sav_fixture), sav_size))
  }
}

# Section 2: Minimal Workflow (No .sav) ----------------------------------

cat("\n--- Section 2: Minimal Workflow (No SPSS) ---\n")

# Create minimal spec using vision
tryCatch({
  suppressPackageStartupMessages(library(vision))

  # Create temp spec file
  spec_path <- tempfile(fileext = ".yaml")
  vision::write_spec_template(spec_path)
  record_check("Create minimal spec via vision", TRUE,
               paste("Spec written to:", spec_path))

  # Run fury workflow
  out_dir <- tempfile(pattern = "fury_audit_")
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

  result <- fury_run(spec_path, out_dir = out_dir)
  record_check("Execute fury_run() on minimal spec", TRUE)

  # Check that result is niche_result
  is_niche_result <- inherits(result, "niche_result")
  record_check("Result is niche_result object", is_niche_result,
               if (!is_niche_result) paste("Got class:", class(result)[1]) else "")

  # Check for required artifacts
  audit_dir <- result$artifacts$audit_dir
  required_artifacts <- c(
    "source_manifest.csv",
    "import_log.csv",
    "raw_codebook.csv",
    "session_info.txt"
  )

  for (artifact in required_artifacts) {
    artifact_path <- file.path(audit_dir, artifact)
    artifact_exists <- file.exists(artifact_path)
    record_check(paste("Artifact exists:", artifact), artifact_exists,
                 if (!artifact_exists) paste("Not found:", artifact_path) else "")
  }

  # Verify artifacts are non-empty
  for (artifact in required_artifacts) {
    artifact_path <- file.path(audit_dir, artifact)
    if (file.exists(artifact_path)) {
      artifact_size <- file.size(artifact_path)
      artifact_nonempty <- artifact_size > 0
      record_check(paste("Artifact non-empty:", artifact), artifact_nonempty,
                   if (!artifact_nonempty) "File is empty" else "")
    }
  }

  # Clean up
  unlink(spec_path)

}, error = function(e) {
  record_check("Execute fury_run() on minimal spec", FALSE,
               paste("Error:", e$message))
})

# Section 3: SPSS .sav Ingestion Workflow ---------------------------------

cat("\n--- Section 3: SPSS .sav Ingestion Workflow ---\n")

if (!haven_available) {
  record_check("SPSS ingestion workflow", FALSE,
               "SKIPPED: haven package not installed")
} else if (!sav_fixture_exists) {
  record_check("SPSS ingestion workflow", FALSE,
               "SKIPPED: No .sav fixture available")
} else {
  tryCatch({
    # Create spec that references .sav fixture
    # For now, we'll just verify the fixture can be read
    # (Full ingestion workflow depends on fury implementation)

    test_data <- haven::read_sav(sav_fixture)
    sav_readable <- is.data.frame(test_data) && nrow(test_data) > 0
    record_check("SPSS .sav fixture is readable", sav_readable,
                 if (sav_readable) sprintf("%d rows, %d cols", nrow(test_data), ncol(test_data)) else "")

    # Check for labelled variables
    has_labels <- any(sapply(test_data, function(x) inherits(x, "haven_labelled")))
    record_check("SPSS fixture contains labelled variables", has_labels,
                 if (!has_labels) "No labelled variables found (expected for SPSS)" else "")

  }, error = function(e) {
    record_check("SPSS ingestion workflow", FALSE,
                 paste("Error reading .sav fixture:", e$message))
  })
}

# Section 4: Conservative Language Tripwire -------------------------------

cat("\n--- Section 4: Conservative Language Tripwire ---\n")

# Banned terms that indicate inflated claims
banned_terms <- c(
  "final dataset",
  "cleaned data",
  "final sample",
  "validated data",
  "validated participants"
)

# Check README.md
readme_path <- "README.md"
if (file.exists(readme_path)) {
  readme_text <- tolower(paste(readLines(readme_path, warn = FALSE), collapse = " "))

  # Check for banned terms (excluding negative contexts like "does NOT")
  violations <- character(0)
  for (term in banned_terms) {
    if (grepl(term, readme_text, fixed = TRUE)) {
      # Check if it's in a negative context
      context_pattern <- paste0("(not|never|no)\\s+\\w+\\s+", gsub(" ", "\\\\s+", term))
      if (!grepl(context_pattern, readme_text)) {
        violations <- c(violations, term)
      }
    }
  }

  if (length(violations) > 0) {
    record_check("README uses conservative language", FALSE,
                 paste("Found banned terms:", paste(violations, collapse = ", ")))
  } else {
    record_check("README uses conservative language", TRUE)
  }

  # Check for flag/exclude warning
  has_flag_warning <- grepl("flag.*exclude|exclude.*flag", readme_text)
  record_check("README contains flag vs exclude warning", has_flag_warning,
               if (!has_flag_warning) "No warning about flags vs exclusions found" else "")

  # Check for .sav mention
  has_sav_mention <- grepl("\\.sav", readme_text)
  record_check("README mentions .sav ingestion", has_sav_mention,
               if (!has_sav_mention) "No .sav ingestion example found" else "")

} else {
  record_check("README exists", FALSE, "README.md not found")
}

# Check vignettes
vignette_dir <- "vignettes"
if (dir.exists(vignette_dir)) {
  vignette_files <- list.files(vignette_dir, pattern = "\\.Rmd$", full.names = TRUE)

  if (length(vignette_files) > 0) {
    record_check("Vignettes exist", TRUE,
                 sprintf("Found %d vignette(s)", length(vignette_files)))

    # Check first vignette for conservative language
    vignette_text <- tolower(paste(readLines(vignette_files[1], warn = FALSE), collapse = " "))

    violations <- character(0)
    for (term in banned_terms) {
      if (grepl(term, vignette_text, fixed = TRUE)) {
        violations <- c(violations, term)
      }
    }

    if (length(violations) > 0) {
      record_check("Vignettes use conservative language", FALSE,
                   paste("Found banned terms:", paste(violations, collapse = ", ")))
    } else {
      record_check("Vignettes use conservative language", TRUE)
    }

  } else {
    record_check("Vignettes exist", FALSE, "No .Rmd files found in vignettes/")
  }
} else {
  record_check("Vignettes exist", FALSE, "vignettes/ directory not found")
}

# Section 5: Determinism Check --------------------------------------------

cat("\n--- Section 5: Determinism Check ---\n")

# Run the same spec twice and compare outputs
tryCatch({
  suppressPackageStartupMessages(library(vision))

  spec_path <- tempfile(fileext = ".yaml")
  vision::write_spec_template(spec_path)

  # First run
  out_dir_1 <- tempfile(pattern = "fury_audit_run1_")
  dir.create(out_dir_1, showWarnings = FALSE, recursive = TRUE)
  result_1 <- fury_run(spec_path, out_dir = out_dir_1)

  # Second run (same spec)
  out_dir_2 <- tempfile(pattern = "fury_audit_run2_")
  dir.create(out_dir_2, showWarnings = FALSE, recursive = TRUE)
  result_2 <- fury_run(spec_path, out_dir = out_dir_2)

  # Compare source_manifest.csv (excluding timestamp columns if they exist)
  manifest_1_path <- file.path(result_1$artifacts$audit_dir, "source_manifest.csv")
  manifest_2_path <- file.path(result_2$artifacts$audit_dir, "source_manifest.csv")

  if (file.exists(manifest_1_path) && file.exists(manifest_2_path)) {
    manifest_1 <- read.csv(manifest_1_path, stringsAsFactors = FALSE)
    manifest_2 <- read.csv(manifest_2_path, stringsAsFactors = FALSE)

    # Remove timestamp columns for comparison
    timestamp_cols <- c("timestamp", "ingested_at", "created_at")
    manifest_1_clean <- manifest_1[, !colnames(manifest_1) %in% timestamp_cols, drop = FALSE]
    manifest_2_clean <- manifest_2[, !colnames(manifest_2) %in% timestamp_cols, drop = FALSE]

    manifests_identical <- identical(manifest_1_clean, manifest_2_clean)
    record_check("Determinism: source_manifest identical (excl. timestamps)", manifests_identical,
                 if (!manifests_identical) "Manifests differ between runs" else "")
  }

  # Compare codebook.csv
  codebook_1_path <- file.path(result_1$artifacts$audit_dir, "raw_codebook.csv")
  codebook_2_path <- file.path(result_2$artifacts$audit_dir, "raw_codebook.csv")

  if (file.exists(codebook_1_path) && file.exists(codebook_2_path)) {
    codebook_1 <- read.csv(codebook_1_path, stringsAsFactors = FALSE)
    codebook_2 <- read.csv(codebook_2_path, stringsAsFactors = FALSE)

    codebooks_identical <- identical(codebook_1, codebook_2)
    record_check("Determinism: raw_codebook identical", codebooks_identical,
                 if (!codebooks_identical) "Codebooks differ between runs" else "")
  }

  # Clean up
  unlink(spec_path)
  unlink(out_dir_1, recursive = TRUE)
  unlink(out_dir_2, recursive = TRUE)

}, error = function(e) {
  record_check("Determinism check", FALSE,
               paste("Error:", e$message))
})

# Section 6: Filesystem Safety --------------------------------------------

cat("\n--- Section 6: Filesystem Safety ---\n")

# Verify that all writes went to tempdir() or specified out_dir
# This is enforced by design (out_dir parameter), so we just verify the contract

tryCatch({
  # Run fury and verify output is in specified location
  suppressPackageStartupMessages(library(vision))

  spec_path <- tempfile(fileext = ".yaml")
  vision::write_spec_template(spec_path)

  out_dir <- tempfile(pattern = "fury_audit_fs_")
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

  result <- fury_run(spec_path, out_dir = out_dir)

  # Verify audit_dir is under out_dir
  audit_dir_under_outdir <- grepl(out_dir, result$artifacts$audit_dir, fixed = TRUE)
  record_check("Filesystem: audit_dir is under out_dir", audit_dir_under_outdir,
               if (!audit_dir_under_outdir) {
                 paste("Expected under:", out_dir, "Got:", result$artifacts$audit_dir)
               } else "")

  # Verify audit artifacts exist
  audit_dir_exists <- dir.exists(result$artifacts$audit_dir)
  record_check("Filesystem: audit_dir exists at expected location", audit_dir_exists,
               if (!audit_dir_exists) result$artifacts$audit_dir else "")

  # Clean up
  unlink(spec_path)
  unlink(out_dir, recursive = TRUE)

}, error = function(e) {
  record_check("Filesystem safety check", FALSE,
               paste("Error:", e$message))
})

# Section 7: Tutorial Completeness (Cross-Reference) ---------------------

cat("\n--- Section 7: Tutorial Completeness (Manual Review Required) ---\n")

cat("NOTE: Full tutorial completeness audit requires manual review.\n")
cat("      See inst/audit/TUTORIAL_CHECKLIST.md for detailed criteria.\n\n")

# Automated checks for tutorial existence
vignette_files <- if (dir.exists("vignettes")) list.files("vignettes", pattern = "\\.Rmd$") else character(0)
example_files <- if (dir.exists("inst/examples")) list.files("inst/examples", pattern = "\\.R$", recursive = TRUE) else character(0)

tutorial_indicators <- c(
  "sav ingestion" = any(grepl("sav|spss", tolower(c(vignette_files, example_files)))),
  "multi-source" = any(grepl("pilot|multiple|source", tolower(example_files))),
  "screening" = any(grepl("screening|consort|eligibility", tolower(example_files)))
)

for (tutorial_name in names(tutorial_indicators)) {
  has_tutorial <- tutorial_indicators[[tutorial_name]]
  record_check(paste("Tutorial indicator:", tutorial_name), has_tutorial,
               if (!has_tutorial) "No tutorial/example found (manual review required)" else "")
}

# Final Summary -----------------------------------------------------------

cat("\n=============================================================\n")
cat("AUDIT SUMMARY\n")
cat("=============================================================\n")

total_checks <- length(audit_results)
passed_checks <- sum(sapply(audit_results, function(x) x$passed))
failed_checks <- total_checks - passed_checks

cat(sprintf("Total checks: %d\n", total_checks))
cat(sprintf("Passed: %d\n", passed_checks))
cat(sprintf("Failed: %d\n", failed_checks))

if (audit_pass) {
  cat("\n✅ AUDIT PASSED\n")
  cat("All automated checks passed. Review TUTORIAL_CHECKLIST.md for manual verification.\n")
  quit(status = 0)
} else {
  cat("\n❌ AUDIT FAILED\n")
  cat("One or more checks failed. Review output above for details.\n\n")
  cat("Failed checks:\n")
  for (check_name in names(audit_results)) {
    if (!audit_results[[check_name]]$passed) {
      cat(sprintf("  - %s\n", check_name))
      if (nchar(audit_results[[check_name]]$message) > 0) {
        cat(sprintf("    %s\n", audit_results[[check_name]]$message))
      }
    }
  }
  quit(status = 1)
}
