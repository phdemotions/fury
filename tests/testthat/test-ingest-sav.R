# Tests for SPSS .sav Ingestion
#
# Mode 1: haven NOT installed - ingestion errors cleanly
# Mode 2: haven installed - ingestion preserves haven_labelled

test_that("fury_read_sav_ errors cleanly when haven not available", {
  # This test verifies the error message structure
  # When haven is installed, we skip this test
  if (requireNamespace("haven", quietly = TRUE)) {
    skip("haven is installed; cannot test error message")
  }

  test_file <- system.file("extdata", "test_minimal.sav", package = "fury")
  skip_if(test_file == "", "Test fixture not available")

  expect_error(
    fury_read_sav_(test_file),
    "haven.*package.*install"
  )
})


test_that("fury_read_sav_ requires valid file path", {
  skip_if_not_installed("haven")

  expect_error(
    fury_read_sav_("nonexistent_file.sav"),
    class = "niche_validation_error"
  )
})


test_that("fury_read_sav_ preserves haven_labelled columns", {
  skip_if_not_installed("haven")

  test_file <- system.file("extdata", "test_minimal.sav", package = "fury")
  skip_if(test_file == "", "Test fixture not available")

  data <- fury_read_sav_(test_file)

  # Check that haven_labelled columns remain haven_labelled
  expect_s3_class(data, "data.frame")

  # Variables with value labels should be haven_labelled
  labelled_vars <- c("condition", "satisfaction", "would_recommend", "age_group")

  for (var in labelled_vars) {
    if (var %in% names(data)) {
      expect_true(
        inherits(data[[var]], "haven_labelled"),
        label = paste(var, "should be haven_labelled")
      )
    }
  }

  # Character variable should remain character
  if ("comments" %in% names(data)) {
    expect_type(data$comments, "character")
  }

  # Numeric unlabelled variable should remain numeric
  if ("participant_id" %in% names(data)) {
    expect_type(data$participant_id, "double")
  }
})


test_that("fury_read_sav_ captures import warnings deterministically", {
  skip_if_not_installed("haven")

  test_file <- system.file("extdata", "test_minimal.sav", package = "fury")
  skip_if(test_file == "", "Test fixture not available")

  data <- fury_read_sav_(test_file)

  # Warnings attribute should exist (even if empty)
  expect_true("import_warnings" %in% names(attributes(data)))
  expect_type(attr(data, "import_warnings"), "character")
})


test_that("fury_read_sav_ does not modify raw file", {
  skip_if_not_installed("haven")

  test_file <- system.file("extdata", "test_minimal.sav", package = "fury")
  skip_if(test_file == "", "Test fixture not available")

  # Record file modification time before read
  mtime_before <- file.mtime(test_file)

  data <- fury_read_sav_(test_file)

  # Check modification time unchanged
  mtime_after <- file.mtime(test_file)
  expect_identical(mtime_before, mtime_after)
})


test_that("fury_read_sav_ does not write anything during read", {
  skip_if_not_installed("haven")

  test_file <- system.file("extdata", "test_minimal.sav", package = "fury")
  skip_if(test_file == "", "Test fixture not available")

  # Read into temp directory
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  # Count files before
  files_before <- list.files(temp_dir, recursive = TRUE)

  # Change to temp directory, read file, then restore
  old_wd <- getwd()
  on.exit(setwd(old_wd), add = TRUE)
  setwd(temp_dir)

  data <- fury_read_sav_(test_file)

  # Count files after
  files_after <- list.files(temp_dir, recursive = TRUE)

  # No new files should be created
  expect_identical(files_before, files_after)
})
