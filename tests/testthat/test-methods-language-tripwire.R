# Methods Language Tripwire Tests
#
# These tests prevent scope creep and ensure reviewer-proof terminology.

test_that("raw_codebook_columns.txt does not contain banned inflated language", {
  dict_lines <- fury_codebook_column_dictionary_()
  dict_text <- paste(dict_lines, collapse = "\n")

  # Banned phrases that imply analysis or construct validation
  banned_phrases <- c(
    "final sample",
    "cleaned data",
    "validated",
    "reliability",
    "Cronbach",
    "mediator",
    "manipulation check"
  )

  for (phrase in banned_phrases) {
    expect_false(
      grepl(phrase, dict_text, ignore.case = TRUE),
      label = paste("Dictionary must not contain banned phrase:", phrase)
    )
  }
})


test_that("raw_codebook_columns.txt includes required disclaimers", {
  dict_lines <- fury_codebook_column_dictionary_()
  dict_text <- paste(dict_lines, collapse = "\n")

  # Required disclaimers
  expect_true(
    grepl("No recoding, scoring, validation, exclusions, or construct claims", dict_text),
    label = "Dictionary must include disclaimer about no recoding/scoring/validation"
  )

  # Terminology note
  expect_true(
    grepl("response scale.*refers only to response-option format", dict_text, ignore.case = TRUE),
    label = "Dictionary must clarify 'response scale' terminology"
  )

  expect_true(
    grepl("does not imply.*psychometric scale", dict_text, ignore.case = TRUE),
    label = "Dictionary must disclaim psychometric implications"
  )
})


test_that("methods_items_response_scales.csv contains no construct language", {
  skip_if_not_installed("haven")

  test_file <- system.file("extdata", "test_minimal.sav", package = "fury")
  skip_if(test_file == "", "Test fixture not available")

  data <- fury_read_sav_(test_file)
  codebook <- fury_codebook_raw(
    data = data,
    source_file = "test_minimal.sav"
  )

  methods_table <- fury_methods_helper_table_(codebook)

  # Check column names for banned terms
  col_names <- paste(names(methods_table), collapse = " ")

  banned_terms <- c(
    "score",
    "composite",
    "construct",
    "reliability",
    "alpha",
    "validity",
    "dimension",
    "factor"
  )

  for (term in banned_terms) {
    expect_false(
      grepl(term, col_names, ignore.case = TRUE),
      label = paste("Methods table columns must not contain:", term)
    )
  }
})


test_that("fury package R/ code does not contain banned analysis tokens", {
  # Scan all R files for banned statistical/modeling tokens
  r_files <- list.files(
    path = "../../R",
    pattern = "\\.R$",
    full.names = TRUE,
    recursive = TRUE
  )

  all_code <- character(0)
  for (f in r_files) {
    all_code <- c(all_code, readLines(f, warn = FALSE))
  }

  code_text <- paste(all_code, collapse = "\n")

  # Banned tokens indicating analysis (from governance test)
  banned_patterns <- c(
    "\\blm\\(",
    "\\bglm\\(",
    "\\baov\\(",
    "\\bt\\.test\\(",
    "\\bcor\\.test\\(",
    "\\bchisq\\.test\\(",
    "\\bpsych::alpha",
    "\\blavaan::",
    "\\bbrms::",
    "\\brstanarm::",
    "\\blme4::",
    "\\bnlme::",
    "\\bsem\\(",
    "\\bcfa\\("
  )

  for (pattern in banned_patterns) {
    expect_false(
      grepl(pattern, code_text, perl = TRUE),
      label = paste("Banned analysis token found:", pattern)
    )
  }
})


test_that("all bundle writes occur only under temp directories", {
  # Filesystem safety test
  r_files <- list.files(
    path = "../../R",
    pattern = "\\.R$",
    full.names = TRUE,
    recursive = TRUE
  )

  all_code <- character(0)
  for (f in r_files) {
    all_code <- c(all_code, readLines(f, warn = FALSE))
  }

  code_text <- paste(all_code, collapse = "\n")

  # No hardcoded writes to package source
  expect_false(
    grepl('writeLines\\([^,]+, "R/', code_text, perl = TRUE),
    label = "Must not write to package R/ directory"
  )

  expect_false(
    grepl('writeLines\\([^,]+, "tests/', code_text, perl = TRUE),
    label = "Must not write to package tests/ directory"
  )
})


test_that("fury_write_raw_codebook determinism (same inputs = same hashes)", {
  skip_if_not_installed("haven")

  test_file <- system.file("extdata", "test_minimal.sav", package = "fury")
  skip_if(test_file == "", "Test fixture not available")

  data <- fury_read_sav_(test_file)

  # Run 1
  temp_dir1 <- tempfile()
  dir.create(temp_dir1)
  on.exit(unlink(temp_dir1, recursive = TRUE), add = TRUE)

  fury_write_raw_codebook(
    audit_dir = temp_dir1,
    data = data,
    source_file = "test_minimal.sav"
  )

  # Run 2
  temp_dir2 <- tempfile()
  dir.create(temp_dir2)
  on.exit(unlink(temp_dir2, recursive = TRUE), add = TRUE)

  fury_write_raw_codebook(
    audit_dir = temp_dir2,
    data = data,
    source_file = "test_minimal.sav"
  )

  # Compare file hashes
  files_to_check <- c(
    "raw_codebook.csv",
    "raw_codebook_value_labels.json",
    "methods_items_response_scales.csv",
    "raw_codebook_columns.txt"
  )

  for (fname in files_to_check) {
    file1 <- fs::path(temp_dir1, fname)
    file2 <- fs::path(temp_dir2, fname)

    # Read and compare content (identical content = deterministic)
    content1 <- readLines(file1, warn = FALSE)
    content2 <- readLines(file2, warn = FALSE)

    expect_identical(
      content1,
      content2,
      label = paste("Artifact must be deterministic:", fname)
    )
  }
})
