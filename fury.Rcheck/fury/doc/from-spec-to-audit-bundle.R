## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----setup--------------------------------------------------------------------
library(fury)
library(vision)

## ----create-spec--------------------------------------------------------------
# Create temp spec file
spec_path <- tempfile(fileext = ".yaml")
vision::write_spec_template(spec_path)

# Inspect the spec (first few lines)
readLines(spec_path, n = 20)

## ----run-fury-----------------------------------------------------------------
# Create temp output directory
out_dir <- tempdir()

# Run fury
result <- fury_run(spec_path, out_dir = out_dir)

# Examine result
print(result)

## ----inspect-artifacts--------------------------------------------------------
# List artifact files
list.files(result$artifacts$audit_dir)

## ----source-manifest----------------------------------------------------------
manifest <- read.csv(result$artifacts$source_manifest)
print(manifest)

## ----import-log---------------------------------------------------------------
import_log <- read.csv(result$artifacts$import_log)
print(import_log)

## ----raw-codebook-------------------------------------------------------------
codebook <- read.csv(result$artifacts$raw_codebook)
print(codebook)

## ----session-info-------------------------------------------------------------
session_lines <- readLines(result$artifacts$session_info)
cat(session_lines[1:10], sep = "\n")

## ----write-bundle-------------------------------------------------------------
bundle_path <- fury_write_bundle(result, out_dir = out_dir)
print(bundle_path)

## ----scope--------------------------------------------------------------------
fury_scope()

## ----cleanup, include=FALSE---------------------------------------------------
# Clean up temp files
unlink(spec_path)
unlink(out_dir, recursive = TRUE)

