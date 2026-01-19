# Spec Builder Tests
#
# Tests for the tidyverse-style spec builder API

test_that("fury_spec creates a valid builder object", {
  builder <- fury_spec()

  expect_s3_class(builder, "fury_spec_builder")
  expect_true(is.list(builder))
  expect_true("data" %in% names(builder))
})

test_that("fury_spec can initialize with data source", {
  builder <- fury_spec("test.sav", format = "spss")

  expect_length(builder$data$sources, 1)
  expect_equal(builder$data$sources[[1]]$file, "test.sav")
  expect_equal(builder$data$sources[[1]]$format, "spss")
})

test_that("fury_source adds data source to builder", {
  builder <- fury_spec() %>%
    fury_source("my_data.sav", format = "spss")

  expect_length(builder$data$sources, 1)
  expect_equal(builder$data$sources[[1]]$file, "my_data.sav")
  expect_equal(builder$data$sources[[1]]$format, "spss")
})

test_that("fury_partition_pilot adds pilot partition", {
  builder <- fury_spec() %>%
    fury_partition_pilot(
      date_var = "StartDate",
      start = "2024-01-01",
      end = "2024-01-15"
    )

  expect_equal(builder$data$screening$partitioning$pilot$by, "date_range")
  expect_equal(builder$data$screening$partitioning$pilot$date_var, "StartDate")
  expect_equal(builder$data$screening$partitioning$pilot$start, "2024-01-01")
  expect_equal(builder$data$screening$partitioning$pilot$end, "2024-01-15")
})

test_that("fury_partition_pretest adds pretest partition", {
  builder <- fury_spec() %>%
    fury_partition_pretest(
      date_var = "StartDate",
      start = "2024-01-01 09:00:00",
      end = "2024-01-01 12:00:00"
    )

  expect_equal(builder$data$screening$partitioning$pretest$by, "date_range")
  expect_equal(builder$data$screening$partitioning$pretest$date_var, "StartDate")
  expect_equal(builder$data$screening$partitioning$pretest$start, "2024-01-01 09:00:00")
  expect_equal(builder$data$screening$partitioning$pretest$end, "2024-01-01 12:00:00")
})

test_that("fury_exclude_missing sets up exclusion rule", {
  builder <- fury_spec() %>%
    fury_exclude_missing(c("consent", "age"))

  expect_equal(
    builder$data$screening$eligibility$required_nonmissing,
    c("consent", "age")
  )
  expect_equal(builder$data$screening$eligibility$action, "exclude")
})

test_that("fury_flag_missing sets up flag rule", {
  builder <- fury_spec() %>%
    fury_flag_missing(c("consent", "age"))

  expect_equal(
    builder$data$screening$eligibility$required_nonmissing,
    c("consent", "age")
  )
  expect_equal(builder$data$screening$eligibility$action, "flag")
})

test_that("fury_flag_attention adds attention check", {
  builder <- fury_spec() %>%
    fury_flag_attention(
      var = "attn_1",
      pass_values = 3,
      description = "Select 3"
    )

  expect_length(builder$data$screening$quality_flags$attention_checks, 1)

  check <- builder$data$screening$quality_flags$attention_checks[[1]]
  expect_equal(check$var, "attn_1")
  expect_equal(check$pass_values, 3)
  expect_equal(check$description, "Select 3")
  expect_equal(check$action, "flag")
})

test_that("fury_flag_attention can exclude instead of flag", {
  builder <- fury_spec() %>%
    fury_flag_attention(
      var = "attn_1",
      pass_values = 3,
      description = "Select 3",
      action = "exclude"
    )

  check <- builder$data$screening$quality_flags$attention_checks[[1]]
  expect_equal(check$action, "exclude")
})

test_that("multiple attention checks can be added", {
  builder <- fury_spec() %>%
    fury_flag_attention(var = "attn_1", pass_values = 3, description = "Check 1") %>%
    fury_flag_attention(var = "attn_2", pass_values = 5, description = "Check 2")

  expect_length(builder$data$screening$quality_flags$attention_checks, 2)
  expect_equal(builder$data$screening$quality_flags$attention_checks[[1]]$var, "attn_1")
  expect_equal(builder$data$screening$quality_flags$attention_checks[[2]]$var, "attn_2")
})

test_that("complete spec can be built with piped syntax", {
  builder <- fury_spec() %>%
    fury_source("my_data.sav") %>%
    fury_partition_pilot("StartDate", "2024-01-01", "2024-01-15") %>%
    fury_exclude_missing(c("consent")) %>%
    fury_flag_attention("attn_1", 3, "Select 3")

  # Verify all components
  expect_equal(builder$data$sources[[1]]$file, "my_data.sav")
  expect_equal(builder$data$screening$partitioning$pilot$start, "2024-01-01")
  expect_equal(builder$data$screening$eligibility$required_nonmissing, c("consent"))
  expect_length(builder$data$screening$quality_flags$attention_checks, 1)
})

test_that("fury_to_yaml writes YAML file", {
  skip_if_not_installed("yaml")

  builder <- fury_spec() %>%
    fury_source("test.sav") %>%
    fury_exclude_missing("consent")

  yaml_path <- tempfile(fileext = ".yaml")

  result <- fury_to_yaml(builder, yaml_path)

  expect_true(file.exists(yaml_path))

  # Read back and verify structure
  content <- yaml::read_yaml(yaml_path)
  expect_equal(content$data$sources[[1]]$file, "test.sav")
  # YAML converts single-element vectors to scalars, not lists
  expect_equal(content$data$screening$eligibility$required_nonmissing, "consent")

  # Clean up
  unlink(yaml_path)
})

test_that("fury_to_yaml refuses to overwrite by default", {
  skip_if_not_installed("yaml")

  builder <- fury_spec() %>%
    fury_source("test.sav")

  yaml_path <- tempfile(fileext = ".yaml")
  writeLines("existing content", yaml_path)

  expect_error(
    fury_to_yaml(builder, yaml_path),
    regexp = "already exists"
  )

  # Clean up
  unlink(yaml_path)
})

test_that("fury_to_yaml can overwrite with flag", {
  skip_if_not_installed("yaml")

  builder <- fury_spec() %>%
    fury_source("test.sav")

  yaml_path <- tempfile(fileext = ".yaml")
  writeLines("existing content", yaml_path)

  # Should succeed with overwrite = TRUE
  fury_to_yaml(builder, yaml_path, overwrite = TRUE)

  content <- yaml::read_yaml(yaml_path)
  expect_equal(content$data$sources[[1]]$file, "test.sav")

  # Clean up
  unlink(yaml_path)
})

test_that("print.fury_spec_builder doesn't error", {
  builder <- fury_spec() %>%
    fury_source("test.sav") %>%
    fury_partition_pilot("StartDate", "2024-01-01", "2024-01-15") %>%
    fury_exclude_missing("consent") %>%
    fury_flag_attention("attn_1", 3, "Check 1")

  # Just verify it doesn't error (cli output won't be captured by expect_output)
  expect_no_error(print(builder))
})

test_that("spec builder functions validate input types", {
  # Non-builder object
  expect_error(
    fury_source(list(), "file.sav"),
    regexp = "must be a fury_spec_builder"
  )

  expect_error(
    fury_partition_pilot(list(), "date", "2024-01-01", "2024-01-15"),
    regexp = "must be a fury_spec_builder"
  )

  expect_error(
    fury_exclude_missing(list(), "var"),
    regexp = "must be a fury_spec_builder"
  )
})

test_that("fury_flag_attention validates action parameter", {
  builder <- fury_spec()

  expect_error(
    fury_flag_attention(builder, "var", 1, "desc", action = "invalid"),
    regexp = "must be 'flag' or 'exclude'"
  )
})
