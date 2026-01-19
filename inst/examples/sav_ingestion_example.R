# Example: Ingest a Single SPSS .sav File and Generate a RAW Codebook
# Primary creator & maintainer: Josh Gonzales (GitHub: phdemotions)
# Canonical source: /phdemotions
#
# PURPOSE:
# Demonstrate how to ingest an SPSS .sav file and produce a raw codebook artifact.
# This example uses the minimal toy fixture included in the package.
#
# REQUIREMENTS:
# - haven package (for reading .sav files)

# Install and Load --------------------------------------------------------

# Install fury from GitHub (if not already installed)
# remotes::install_github("phdemotions/fury")

library(fury)

# Check that haven is available (required for .sav ingestion)
if (!requireNamespace("haven", quietly = TRUE)) {
  stop("This example requires the 'haven' package. Install with: install.packages('haven')")
}

# Locate the .sav Fixture -------------------------------------------------

# fury includes a minimal toy .sav file for testing
sav_file <- system.file("extdata", "test_minimal.sav", package = "fury")

if (!file.exists(sav_file)) {
  stop("Test fixture not found. Ensure fury is installed correctly.")
}

cat("Using fixture:", sav_file, "\n\n")

# Preview the .sav file using haven
cat("--- Preview of .sav file contents ---\n")
test_data <- haven::read_sav(sav_file)
print(head(test_data, 3))
cat("\n")

# Create a Minimal Spec ---------------------------------------------------

# Option 1: Using spec builder API (tidyverse-style)
spec <- fury_spec() %>%
  fury_source(sav_file, format = "spss")

# Export to YAML for reproducibility
spec_path <- tempfile(fileext = ".yaml")
fury_to_yaml(spec, spec_path)

cat("Spec written to:", spec_path, "\n")
cat("--- Spec contents ---\n")
cat(readLines(spec_path), sep = "\n")
cat("\n")

# Option 2: Create YAML manually (for researchers who prefer text files)
# You can create a file like this:
#
# data:
#   sources:
#     - file: "my_qualtrics_data.sav"
#       format: "spss"

# Run fury ----------------------------------------------------------------

cat("--- Running fury workflow ---\n")
out_dir <- tempdir()
result <- fury_run(spec_path, out_dir = out_dir)

cat("\n✅ fury execution complete\n\n")

# Locate the RAW Codebook -------------------------------------------------

codebook_path <- file.path(result$artifacts$audit_dir, "raw_codebook.csv")

if (!file.exists(codebook_path)) {
  stop("Codebook not found at expected location: ", codebook_path)
}

cat("RAW codebook written to:", codebook_path, "\n\n")

# Display Codebook Contents -----------------------------------------------

cat("--- RAW Codebook (first few rows) ---\n")
codebook <- read.csv(codebook_path, stringsAsFactors = FALSE)
print(head(codebook))
cat("\n")

# Interpret the Codebook Conservatively -----------------------------------

cat("=============================================================\n")
cat("IMPORTANT: What This Codebook Shows\n")
cat("=============================================================\n\n")

cat("This is a RAW codebook. It shows:\n")
cat("  - Variable names from the .sav file\n")
cat("  - Variable labels (item text from Qualtrics/SPSS)\n")
cat("  - Value labels (response option text)\n\n")

cat("This codebook does NOT include:\n")
cat("  - Computed scores or scale totals\n")
cat("  - Reliability estimates (e.g., Cronbach's alpha)\n")
cat("  - Factor loadings or validation results\n\n")

cat("⚠️  fury does NOT perform scoring, validation, or reliability analysis.\n")
cat("    It only shows you what variables exist in your raw data.\n\n")

# Where to Find Other Artifacts -------------------------------------------

cat("=============================================================\n")
cat("Other Audit Artifacts\n")
cat("=============================================================\n\n")

cat("fury created several files in:", result$artifacts$audit_dir, "\n\n")

cat("Files you should review:\n")
cat("  1. source_manifest.csv — Tracks which files were ingested\n")
cat("  2. raw_codebook.csv    — Variable and value labels (this file)\n")
cat("  3. import_log.csv      — Details of data ingestion process\n")
cat("  4. session_info.txt    — R version and loaded packages\n\n")

cat("You can open these CSV files in Excel for easier viewing.\n\n")

# Cleanup -----------------------------------------------------------------

cat("--- Cleanup ---\n")
cat("Temporary files created in:", out_dir, "\n")
cat("You can delete this directory when you're done reviewing the artifacts.\n")

# Summary -----------------------------------------------------------------

cat("\n=============================================================\n")
cat("Summary\n")
cat("=============================================================\n\n")

cat("✅ Ingested .sav file:", basename(sav_file), "\n")
cat("✅ Generated raw codebook with", nrow(codebook), "variables\n")
cat("✅ All audit artifacts written to:", result$artifacts$audit_dir, "\n\n")

cat("Next steps:\n")
cat("  - Review the raw codebook to understand your variables\n")
cat("  - If you need to exclude participants or flag attention checks,\n")
cat("    see the screening example: inst/examples/screening_example.R\n\n")

cat("⚠️  Remember: fury produces an 'analysis-eligible dataset per declared rules',\n")
cat("    NOT a 'final' or 'cleaned' dataset. Downstream decisions are YOUR responsibility.\n\n")
