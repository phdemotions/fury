# Functional Tests for fury Public API
#
# These tests verify that the exported functions work as expected
# and enforce determinism and contract compliance.

test_that("fury_scope returns character string", {
  scope <- fury_scope()
  expect_type(scope, "character")
  expect_length(scope, 1)
  expect_true(nchar(scope) > 0)
})

test_that("fury_run requires valid spec_path", {
  expect_error(
    fury_run(spec_path = 123),
    class = "niche_validation_error"
  )

  expect_error(
    fury_run(spec_path = "nonexistent_file.yaml"),
    class = "niche_validation_error"
  )
})

test_that("fury_execute_recipe requires niche_recipe input", {
  not_a_recipe <- list(foo = "bar")

  expect_error(
    fury_execute_recipe(not_a_recipe),
    "niche_recipe"
  )
})

test_that("fury_execute_recipe creates audit directory and artifacts", {
  skip_if_not_installed("vision")
  skip_if_not_installed("nicheCore")

  # Create a minimal spec
  temp_spec <- tempfile(fileext = ".yaml")
  on.exit(unlink(temp_spec), add = TRUE)

  vision::write_spec_template(temp_spec)

  # Read and build recipe
  spec <- vision::read_spec(temp_spec)
  recipe <- vision::build_recipe(spec)

  # Execute in temp directory
  temp_out <- tempfile()
  on.exit(unlink(temp_out, recursive = TRUE), add = TRUE)

  result <- fury_execute_recipe(recipe, out_dir = temp_out)

  # Check result structure (required fields per nicheCore contract)
  expect_true(nicheCore::is_niche_result(result))
  expect_true("recipe" %in% names(result))
  expect_true("outputs" %in% names(result))
  expect_true("artifacts" %in% names(result))
  expect_true("session_info" %in% names(result))
  expect_true("warnings" %in% names(result))
  expect_true("created" %in% names(result))

  # Check audit directory exists
  expect_true(dir.exists(result$artifacts$audit_dir))

  # Check expected files exist
  expected_files <- c(
    "recipe.json",
    "source_manifest.csv",
    "import_log.csv",
    "raw_codebook.csv",
    "session_info.txt"
  )

  for (fname in expected_files) {
    fpath <- fs::path(result$artifacts$audit_dir, fname)
    expect_true(
      file.exists(fpath),
      label = paste("Expected file:", fname)
    )
  }
})

test_that("fury_run produces deterministic artifacts (structure)", {
  skip_if_not_installed("vision")
  skip_if_not_installed("nicheCore")

  # Create a minimal spec
  temp_spec <- tempfile(fileext = ".yaml")
  on.exit(unlink(temp_spec), add = TRUE)

  vision::write_spec_template(temp_spec)

  # Run twice with same spec
  temp_out1 <- tempfile()
  temp_out2 <- tempfile()
  on.exit(unlink(c(temp_out1, temp_out2), recursive = TRUE), add = TRUE)

  result1 <- fury_run(temp_spec, out_dir = temp_out1)
  result2 <- fury_run(temp_spec, out_dir = temp_out2)

  # Check that artifact files are structurally identical
  # (we exclude timestamp from comparison)

  # Compare source_manifest.csv
  manifest1 <- read.csv(result1$artifacts$source_manifest)
  manifest2 <- read.csv(result2$artifacts$source_manifest)
  expect_identical(names(manifest1), names(manifest2))
  expect_identical(nrow(manifest1), nrow(manifest2))

  # Compare import_log.csv
  log1 <- read.csv(result1$artifacts$import_log)
  log2 <- read.csv(result2$artifacts$import_log)
  expect_identical(names(log1), names(log2))
  expect_identical(nrow(log1), nrow(log2))

  # Compare raw_codebook.csv
  codebook1 <- read.csv(result1$artifacts$raw_codebook)
  codebook2 <- read.csv(result2$artifacts$raw_codebook)
  expect_identical(names(codebook1), names(codebook2))
  expect_identical(nrow(codebook1), nrow(codebook2))
})

test_that("fury_write_bundle works with valid result", {
  skip_if_not_installed("vision")
  skip_if_not_installed("nicheCore")

  # Create a minimal spec and run fury
  temp_spec <- tempfile(fileext = ".yaml")
  on.exit(unlink(temp_spec), add = TRUE)

  vision::write_spec_template(temp_spec)

  temp_out <- tempfile()
  on.exit(unlink(temp_out, recursive = TRUE), add = TRUE)

  result <- fury_run(temp_spec, out_dir = temp_out)

  # Call fury_write_bundle
  bundle_path <- fury_write_bundle(result)

  expect_true(dir.exists(bundle_path))
})

test_that("fury_write_bundle requires niche_result", {
  not_a_result <- list(foo = "bar")

  expect_error(
    fury_write_bundle(not_a_result),
    "niche_result"
  )
})
