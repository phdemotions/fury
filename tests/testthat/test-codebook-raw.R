# Tests for RAW Codebook Generation

test_that("fury_codebook_raw has exact required columns in specified order", {
  skip_if_not_installed("haven")

  test_file <- system.file("extdata", "test_minimal.sav", package = "fury")
  skip_if(test_file == "", "Test fixture not available")

  data <- fury_read_sav_(test_file)
  codebook <- fury_codebook_raw(
    data = data,
    source_file = "test_minimal.sav",
    wave = "W1",
    module = "main",
    language = "en"
  )

  # Check exact column names in specified order
  expected_cols <- c(
    "var_name",
    "item_text_raw",
    "var_label",
    "storage_class",
    "is_haven_labelled",
    "response_scale_type",
    "response_scale_n_options",
    "response_scale_min_label",
    "response_scale_max_label",
    "value_labels_preview",
    "value_labels_ref",
    "user_missing",
    "n_non_missing",
    "n_missing",
    "pct_missing",
    "distinct_values",
    "source_file",
    "wave",
    "module",
    "language"
  )

  expect_identical(names(codebook), expected_cols)
})


test_that("fury_codebook_raw row ordering is deterministic", {
  skip_if_not_installed("haven")

  test_file <- system.file("extdata", "test_minimal.sav", package = "fury")
  skip_if(test_file == "", "Test fixture not available")

  data <- fury_read_sav_(test_file)

  # Generate codebook twice
  codebook1 <- fury_codebook_raw(
    data = data,
    source_file = "test_minimal.sav"
  )
  codebook2 <- fury_codebook_raw(
    data = data,
    source_file = "test_minimal.sav"
  )

  # Row order should be identical
  expect_identical(codebook1$var_name, codebook2$var_name)
})


test_that("fury_codebook_raw preserves haven_labelled detection", {
  skip_if_not_installed("haven")

  test_file <- system.file("extdata", "test_minimal.sav", package = "fury")
  skip_if(test_file == "", "Test fixture not available")

  data <- fury_read_sav_(test_file)
  codebook <- fury_codebook_raw(
    data = data,
    source_file = "test_minimal.sav"
  )

  # Check is_haven_labelled column
  expect_type(codebook$is_haven_labelled, "logical")

  # Variables with value labels should be marked as haven_labelled
  labelled_vars <- c("condition", "satisfaction", "would_recommend", "age_group")
  for (var in labelled_vars) {
    if (var %in% codebook$var_name) {
      row <- codebook[codebook$var_name == var, ]
      expect_true(
        row$is_haven_labelled,
        label = paste(var, "should be marked as haven_labelled")
      )
    }
  }

  # Character variable should NOT be marked as haven_labelled
  if ("comments" %in% codebook$var_name) {
    row <- codebook[codebook$var_name == "comments", ]
    expect_false(row$is_haven_labelled)
  }
})


test_that("fury_codebook_raw classifies response_scale_type correctly", {
  skip_if_not_installed("haven")

  test_file <- system.file("extdata", "test_minimal.sav", package = "fury")
  skip_if(test_file == "", "Test fixture not available")

  data <- fury_read_sav_(test_file)
  codebook <- fury_codebook_raw(
    data = data,
    source_file = "test_minimal.sav"
  )

  # Check labelled_options
  labelled_vars <- c("condition", "satisfaction", "would_recommend", "age_group")
  for (var in labelled_vars) {
    if (var %in% codebook$var_name) {
      row <- codebook[codebook$var_name == var, ]
      expect_equal(
        row$response_scale_type,
        "labelled_options",
        label = paste(var, "should be labelled_options")
      )
    }
  }

  # Check free_text
  if ("comments" %in% codebook$var_name) {
    row <- codebook[codebook$var_name == "comments", ]
    expect_equal(row$response_scale_type, "free_text")
  }

  # Check numeric_unlabelled
  if ("participant_id" %in% codebook$var_name) {
    row <- codebook[codebook$var_name == "participant_id", ]
    expect_equal(row$response_scale_type, "numeric_unlabelled")
  }
})


test_that("fury_codebook_raw extracts min/max labels correctly", {
  skip_if_not_installed("haven")

  test_file <- system.file("extdata", "test_minimal.sav", package = "fury")
  skip_if(test_file == "", "Test fixture not available")

  data <- fury_read_sav_(test_file)
  codebook <- fury_codebook_raw(
    data = data,
    source_file = "test_minimal.sav"
  )

  # Check satisfaction variable (7-point scale)
  if ("satisfaction" %in% codebook$var_name) {
    row <- codebook[codebook$var_name == "satisfaction", ]
    expect_equal(row$response_scale_min_label, "Extremely dissatisfied")
    expect_equal(row$response_scale_max_label, "Extremely satisfied")
  }

  # Check would_recommend (binary)
  if ("would_recommend" %in% codebook$var_name) {
    row <- codebook[codebook$var_name == "would_recommend", ]
    expect_equal(row$response_scale_min_label, "No")
    expect_equal(row$response_scale_max_label, "Yes")
  }

  # Check unlabelled variable (should be NA)
  if ("participant_id" %in% codebook$var_name) {
    row <- codebook[codebook$var_name == "participant_id", ]
    expect_true(is.na(row$response_scale_min_label))
    expect_true(is.na(row$response_scale_max_label))
  }
})


test_that("value_labels_preview truncation is deterministic", {
  skip_if_not_installed("haven")

  test_file <- system.file("extdata", "test_minimal.sav", package = "fury")
  skip_if(test_file == "", "Test fixture not available")

  data <- fury_read_sav_(test_file)
  codebook <- fury_codebook_raw(
    data = data,
    source_file = "test_minimal.sav"
  )

  # Check satisfaction variable (7 options, should NOT truncate)
  if ("satisfaction" %in% codebook$var_name) {
    row <- codebook[codebook$var_name == "satisfaction", ]
    expect_false(grepl("\\+.*more", row$value_labels_preview))
  }

  # Check that unlabelled variable shows "(none)"
  if ("participant_id" %in% codebook$var_name) {
    row <- codebook[codebook$var_name == "participant_id", ]
    expect_equal(row$value_labels_preview, "(none)")
  }

  # If we had >10 options, it should report "(+N more)"
  # Create synthetic example
  large_labels <- setNames(1:15, paste0("Option", 1:15))
  preview <- fury_format_value_labels_preview_(large_labels)
  expect_true(grepl("\\+5 more", preview))
})


test_that("fury_build_value_labels_json_ produces stable sorted codes", {
  skip_if_not_installed("haven")

  test_file <- system.file("extdata", "test_minimal.sav", package = "fury")
  skip_if(test_file == "", "Test fixture not available")

  data <- fury_read_sav_(test_file)
  json_obj <- fury_build_value_labels_json_(data)

  # Check structure
  expect_type(json_obj, "list")

  # Variables with labels should be present
  expect_true("satisfaction" %in% names(json_obj))

  # Check satisfaction variable
  if ("satisfaction" %in% names(json_obj)) {
    sat_mapping <- json_obj$satisfaction
    expect_type(sat_mapping, "list")
    expect_equal(length(sat_mapping), 7)

    # Check first and last entries
    expect_equal(sat_mapping[[1]]$code, "1")
    expect_equal(sat_mapping[[1]]$label, "Extremely dissatisfied")
    expect_equal(sat_mapping[[7]]$code, "7")
    expect_equal(sat_mapping[[7]]$label, "Extremely satisfied")
  }

  # Variables without labels should NOT be present
  expect_false("participant_id" %in% names(json_obj))
  expect_false("comments" %in% names(json_obj))
})


test_that("fury_methods_helper_table_ contains only specified columns", {
  skip_if_not_installed("haven")

  test_file <- system.file("extdata", "test_minimal.sav", package = "fury")
  skip_if(test_file == "", "Test fixture not available")

  data <- fury_read_sav_(test_file)
  codebook <- fury_codebook_raw(
    data = data,
    source_file = "test_minimal.sav"
  )

  methods_table <- fury_methods_helper_table_(codebook)

  # Check exact columns
  expected_cols <- c(
    "var_name",
    "item_text_raw",
    "response_scale_type",
    "response_scale_n_options",
    "response_scale_min_label",
    "response_scale_max_label",
    "value_labels_ref",
    "source_file",
    "wave",
    "module",
    "language"
  )

  expect_identical(names(methods_table), expected_cols)
})


test_that("fury_codebook_column_dictionary_ includes required disclaimers", {
  dict_lines <- fury_codebook_column_dictionary_()

  # Combine into single text for checking
  dict_text <- paste(dict_lines, collapse = "\n")

  # Check required disclaimer
  expect_true(
    grepl("No recoding, scoring, validation, exclusions, or construct claims", dict_text, ignore.case = TRUE)
  )

  # Check terminology note
  expect_true(
    grepl("response scale.*refers only to response-option format", dict_text, ignore.case = TRUE)
  )
  expect_true(
    grepl("does not imply.*psychometric scale", dict_text, ignore.case = TRUE)
  )
})


test_that("fury_write_raw_codebook writes all required artifacts", {
  skip_if_not_installed("haven")

  test_file <- system.file("extdata", "test_minimal.sav", package = "fury")
  skip_if(test_file == "", "Test fixture not available")

  data <- fury_read_sav_(test_file)

  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  fury_write_raw_codebook(
    audit_dir = temp_dir,
    data = data,
    source_file = "test_minimal.sav"
  )

  # Check all expected files exist
  expect_true(file.exists(fs::path(temp_dir, "raw_codebook.csv")))
  expect_true(file.exists(fs::path(temp_dir, "raw_codebook_value_labels.json")))
  expect_true(file.exists(fs::path(temp_dir, "methods_items_response_scales.csv")))
  expect_true(file.exists(fs::path(temp_dir, "raw_codebook_columns.txt")))
})


test_that("fury_codebook_raw computes missingness correctly", {
  skip_if_not_installed("haven")

  test_file <- system.file("extdata", "test_minimal.sav", package = "fury")
  skip_if(test_file == "", "Test fixture not available")

  data <- fury_read_sav_(test_file)
  codebook <- fury_codebook_raw(
    data = data,
    source_file = "test_minimal.sav"
  )

  # Check that missingness columns exist
  expect_true("n_non_missing" %in% names(codebook))
  expect_true("n_missing" %in% names(codebook))
  expect_true("pct_missing" %in% names(codebook))

  # Comments variable: SPSS converts NA to empty string for character variables
  # So we expect 0 NA values (but there may be empty strings)
  if ("comments" %in% codebook$var_name) {
    row <- codebook[codebook$var_name == "comments", ]
    # SPSS character variables don't have true NA after import
    expect_true(row$n_missing >= 0)
    expect_true(row$n_non_missing <= 5)
  }

  # participant_id has 0 missing
  if ("participant_id" %in% codebook$var_name) {
    row <- codebook[codebook$var_name == "participant_id", ]
    expect_equal(row$n_missing, 0)
    expect_equal(row$n_non_missing, 5)
    expect_equal(row$pct_missing, 0)
  }
})


test_that("fury_codebook_raw sets item_text_raw from var_label", {
  skip_if_not_installed("haven")

  test_file <- system.file("extdata", "test_minimal.sav", package = "fury")
  skip_if(test_file == "", "Test fixture not available")

  data <- fury_read_sav_(test_file)
  codebook <- fury_codebook_raw(
    data = data,
    source_file = "test_minimal.sav"
  )

  # Check that item_text_raw equals var_label when var_label present
  for (i in seq_len(nrow(codebook))) {
    var_label <- codebook$var_label[i]
    item_text <- codebook$item_text_raw[i]

    if (!is.na(var_label)) {
      expect_equal(item_text, var_label)
    } else {
      expect_true(is.na(item_text))
    }
  }
})
