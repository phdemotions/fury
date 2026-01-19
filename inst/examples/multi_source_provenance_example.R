# Example: Ingest Multiple Sources (Pilot + Main) and Preserve Provenance
# Primary creator & maintainer: Josh Gonzales (GitHub: phdemotions)
# Canonical source: /phdemotions
#
# PURPOSE:
# Demonstrate how to partition pilot/pretest data from main study data
# and track provenance via decision_registry.csv and source_manifest.csv
#
# SCENARIO:
# You collected pilot data (Jan 1-15) and main study data (Jan 16-31).
# You want to keep them separate for reporting in your Methods section.

# Install and Load --------------------------------------------------------

library(fury)

# Locate Toy Data ---------------------------------------------------------

# For this example, we'll use the minimal CSV fixture
# (In practice, you'd use your own .sav file from Qualtrics)
csv_file <- system.file("extdata", "toy_data_minimal.csv", package = "fury")

if (!file.exists(csv_file)) {
  stop("Test fixture not found. Ensure fury is installed correctly.")
}

cat("Using fixture:", csv_file, "\n\n")

# Preview the data
cat("--- Preview of data (first few rows) ---\n")
toy_data <- read.csv(csv_file, stringsAsFactors = FALSE)
print(head(toy_data))
cat("\n")
cat("Note: This dataset has a 'StartDate' column showing when each participant responded.\n")
cat("We'll use this to separate pilot (Jan 1-15) from main study (Jan 16-31).\n\n")

# Create a Spec with Pilot Partitioning ----------------------------------

cat("=============================================================\n")
cat("Step 1: Declare Pilot Partition\n")
cat("=============================================================\n\n")

cat("We'll tell fury that data collected between Jan 1-15 is pilot data.\n")
cat("fury will label these participants as 'pilot' without removing them.\n\n")

# Option 1: Using spec builder API
spec <- fury_spec() %>%
  fury_source(csv_file, format = "csv") %>%
  fury_partition_pilot(
    date_var = "StartDate",
    start = "2024-01-01",
    end = "2024-01-15"
  )

# Export to YAML
spec_path <- tempfile(fileext = ".yaml")
fury_to_yaml(spec, spec_path)

cat("Spec written to:", spec_path, "\n")
cat("--- Spec contents ---\n")
cat(readLines(spec_path), sep = "\n")
cat("\n\n")

# Option 2: Manual YAML (for researchers who prefer text files)
# You can create a file like this:
#
# data:
#   sources:
#     - file: "my_qualtrics_data.sav"
#       format: "spss"
#   screening:
#     partitioning:
#       pilot:
#         by: "date_range"
#         date_var: "StartDate"
#         start: "2024-01-01"
#         end: "2024-01-15"

# Run fury ----------------------------------------------------------------

cat("=============================================================\n")
cat("Step 2: Run fury Workflow\n")
cat("=============================================================\n\n")

out_dir <- tempdir()
result <- fury_run(spec_path, out_dir = out_dir)

cat("✅ fury execution complete\n\n")

# Locate Provenance Artifacts ---------------------------------------------

cat("=============================================================\n")
cat("Step 3: Review Provenance Artifacts\n")
cat("=============================================================\n\n")

# 1. Source Manifest
manifest_path <- file.path(result$artifacts$audit_dir, "source_manifest.csv")
cat("--- Source Manifest (tracks which files were ingested) ---\n")
cat("Location:", manifest_path, "\n\n")
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE)
print(manifest)
cat("\n")

# 2. Decision Registry
registry_path <- file.path(result$artifacts$audit_dir, "decision_registry.csv")
cat("--- Decision Registry (shows what you declared vs didn't declare) ---\n")
cat("Location:", registry_path, "\n\n")
registry <- read.csv(registry_path, stringsAsFactors = FALSE)
print(registry)
cat("\n")

cat("👀 Look for: 'Pilot partition present: Yes'\n")
cat("   This confirms that you declared a pilot partition.\n\n")

# 3. Screening Summary
summary_path <- file.path(result$artifacts$audit_dir, "screening_summary.csv")
if (file.exists(summary_path)) {
  cat("--- Screening Summary (shows pilot vs main counts) ---\n")
  cat("Location:", summary_path, "\n\n")
  summary_data <- read.csv(summary_path, stringsAsFactors = FALSE)
  print(summary_data)
  cat("\n")
}

# Interpret Conservatively ------------------------------------------------

cat("=============================================================\n")
cat("IMPORTANT: What Happens to Pilot Data?\n")
cat("=============================================================\n\n")

cat("⚠️  Pilot data are PARTITIONED, not EXCLUDED.\n\n")

cat("This means:\n")
cat("  - Pilot participants remain in your dataset\n")
cat("  - They are labeled as 'pilot' in a partition column\n")
cat("  - You can analyze them separately or exclude them later\n\n")

cat("If you did NOT declare a pilot partition:\n")
cat("  - fury assumes all data are from the main study\n")
cat("  - The decision registry will show 'Pilot partition present: No'\n\n")

cat("Why does this matter for peer review?\n")
cat("  - Reviewers want to know if you ran a pilot/pretest\n")
cat("  - The decision registry provides a clear audit trail\n")
cat("  - You can cite this file in your Methods section\n\n")

# Where to Cite in Methods Section ----------------------------------------

cat("=============================================================\n")
cat("How to Use These Artifacts in Your Methods Section\n")
cat("=============================================================\n\n")

cat("Example Methods text:\n\n")

cat('  "Data were collected in two phases. A pilot study (N = [X]) was\n')
cat('   conducted between [start date] and [end date], followed by the\n')
cat('   main study (N = [Y]) conducted between [start date] and [end date].\n')
cat('   Pilot and main study data were ingested using the fury R package\n')
cat('   (Gonzales, 2026), which generated provenance artifacts documenting\n')
cat('   the partitioning decision (see source_manifest.csv and\n')
cat('   decision_registry.csv in supplementary materials)."\n\n')

cat("Artifacts to include as supplementary materials:\n")
cat("  - source_manifest.csv (data provenance)\n")
cat("  - decision_registry.csv (declared vs undeclared decisions)\n")
cat("  - screening_summary.csv (participant counts)\n\n")

# What If You Have Multiple Sources? --------------------------------------

cat("=============================================================\n")
cat("What If You Have Multiple .sav Files?\n")
cat("=============================================================\n\n")

cat("If you collected data from multiple Qualtrics surveys:\n\n")

cat("Option 1: Merge files before ingestion (recommended)\n")
cat("  - Combine your .sav files into one file\n")
cat("  - Use date ranges or ID lists to partition pilot/main\n\n")

cat("Option 2: Declare multiple sources in your spec (advanced)\n")
cat("  data:\n")
cat("    sources:\n")
cat("      - file: 'pilot_survey.sav'\n")
cat("        format: 'spss'\n")
cat("      - file: 'main_survey.sav'\n")
cat("        format: 'spss'\n\n")

cat("  fury will track each source separately in source_manifest.csv\n\n")

# Summary -----------------------------------------------------------------

cat("=============================================================\n")
cat("Summary\n")
cat("=============================================================\n\n")

cat("✅ Declared pilot partition (Jan 1-15)\n")
cat("✅ Provenance artifacts generated:\n")
cat("     - source_manifest.csv\n")
cat("     - decision_registry.csv\n")
cat("     - screening_summary.csv\n\n")

cat("Next steps:\n")
cat("  - Review decision_registry.csv to confirm pilot declaration\n")
cat("  - Use screening_summary.csv for participant counts in Methods\n")
cat("  - Include these artifacts as supplementary materials\n\n")

cat("⚠️  Remember: Partitions are labels, not exclusions.\n")
cat("    If you want to exclude pilot data from analysis, you'll need to\n")
cat("    do that in downstream analysis (not in fury).\n\n")

cat("--- Cleanup ---\n")
cat("Temporary files created in:", out_dir, "\n")
cat("You can delete this directory when you're done reviewing the artifacts.\n")
