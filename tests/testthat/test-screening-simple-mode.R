# Tests for Simple Mode Screening
#
# Primary creator & maintainer-of-record: Josh Gonzales (GitHub: phdemotions)
# Part of the niche R universe

test_that("fury_compile_rules_ returns empty table when no config provided", {
  data <- data.frame(x = 1:10)
  rules <- fury:::fury_compile_rules_(NULL, data)

  expect_s3_class(rules, "data.frame")
  expect_equal(nrow(rules), 0)
  expect_true(all(c("rule_id", "category", "description", "predicate", "action") %in% names(rules)))
})

test_that("simple mode partitioning by date_range compiles correctly", {
  data <- data.frame(
    response_id = 1:10,
    start_time = as.Date(c(
      "2024-01-01", "2024-01-02", "2024-01-15",
      "2024-01-16", "2024-01-17", "2024-02-01",
      "2024-02-02", "2024-02-03", "2024-02-04", "2024-02-05"
    ))
  )

  screening_config <- list(
    partitioning = list(
      pretest = list(
        by = "date_range",
        date_var = "start_time",
        start = "2024-01-01",
        end = "2024-01-15"
      ),
      pilot = list(
        by = "date_range",
        date_var = "start_time",
        start = "2024-01-16",
        end = "2024-01-31"
      )
    )
  )

  rules <- fury:::fury_compile_rules_(screening_config, data)

  expect_equal(nrow(rules), 2)
  expect_equal(rules$category, c("partition", "partition"))
  expect_equal(rules$action, c("partition", "partition"))
  expect_equal(rules$assign_value, c("pretest", "pilot"))
  expect_true(grepl("start_time", rules$predicate[1]))
})

test_that("simple mode partitioning by IDs compiles correctly", {
  data <- data.frame(
    response_id = 1:10,
    x = letters[1:10]
  )

  screening_config <- list(
    partitioning = list(
      pretest = list(
        by = "ids",
        ids = c(1, 2, 3)
      )
    )
  )

  rules <- fury:::fury_compile_rules_(screening_config, data)

  expect_equal(nrow(rules), 1)
  expect_equal(rules$action, "partition")
  expect_equal(rules$assign_value, "pretest")
  expect_true(grepl("row_number IN", rules$predicate))
  expect_true(grepl("1, 2, 3", rules$predicate))
})

test_that("simple mode eligibility required_nonmissing compiles correctly", {
  data <- data.frame(
    response_id = 1:10,
    age = c(25, NA, 30, 35, NA, 40, 45, 50, NA, 55),
    consent = c(1, 1, 1, NA, 1, 1, 1, 1, 1, 1)
  )

  screening_config <- list(
    eligibility = list(
      required_nonmissing = c("age", "consent"),
      action = "exclude"
    )
  )

  rules <- fury:::fury_compile_rules_(screening_config, data)

  expect_equal(nrow(rules), 1)
  expect_equal(rules$category, "eligibility")
  expect_equal(rules$action, "exclude")
  expect_true(grepl("age IS NOT MISSING", rules$predicate))
  expect_true(grepl("consent IS NOT MISSING", rules$predicate))
  expect_true(grepl("AND", rules$predicate))
})

test_that("simple mode quality attention_checks compile correctly", {
  data <- data.frame(
    response_id = 1:10,
    attn_check_1 = c(3, 3, 2, 3, 1, 3, 3, 2, 3, 3),
    attn_check_2 = c("correct", "correct", "wrong", "correct", "correct", "correct", "wrong", "correct", "correct", "correct")
  )

  screening_config <- list(
    quality_flags = list(
      attention_checks = list(
        list(
          var = "attn_check_1",
          pass_values = c(3),
          action = "flag",
          description = "Attention check 1: select 3"
        ),
        list(
          var = "attn_check_2",
          pass_values = c("correct"),
          action = "flag",
          description = "Attention check 2: select correct"
        )
      )
    )
  )

  rules <- fury:::fury_compile_rules_(screening_config, data)

  expect_equal(nrow(rules), 2)
  expect_equal(rules$category, c("quality", "quality"))
  expect_equal(rules$action, c("flag", "flag"))
  expect_true(grepl("attn_check_1 IN \\(3\\)", rules$predicate[1]))
  expect_true(grepl("attn_check_2 IN \\('correct'\\)", rules$predicate[2]))
})

test_that("fury_screen applies partition rules correctly", {
  data <- data.frame(
    response_id = 1:10,
    start_time = as.Date(c(
      "2024-01-01", "2024-01-02", "2024-01-15",
      "2024-01-16", "2024-01-17", "2024-02-01",
      "2024-02-02", "2024-02-03", "2024-02-04", "2024-02-05"
    ))
  )

  screening_config <- list(
    partitioning = list(
      pretest = list(
        by = "date_range",
        date_var = "start_time",
        start = "2024-01-01",
        end = "2024-01-15"
      )
    )
  )

  rules <- fury:::fury_compile_rules_(screening_config, data)
  screened <- fury:::fury_screen(data, rules)

  expect_true(".fury_partition" %in% names(screened))
  expect_equal(sum(screened$.fury_partition == "pretest"), 3)
  expect_equal(sum(screened$.fury_partition == "main"), 7)
})

test_that("fury_screen pretest defaults to pool_main = FALSE", {
  data <- data.frame(
    response_id = 1:5,
    start_time = as.Date(c(
      "2024-01-01", "2024-01-02", "2024-02-01", "2024-02-02", "2024-02-03"
    ))
  )

  screening_config <- list(
    partitioning = list(
      pretest = list(
        by = "date_range",
        date_var = "start_time",
        start = "2024-01-01",
        end = "2024-01-15"
      )
    )
  )

  rules <- fury:::fury_compile_rules_(screening_config, data)
  screened <- fury:::fury_screen(data, rules)

  pretest_rows <- screened$.fury_partition == "pretest"
  expect_true(all(!screened$.fury_pool_main[pretest_rows]))
})

test_that("fury_screen pilot is explicitly partitioned", {
  data <- data.frame(
    response_id = 1:10,
    start_time = as.Date(c(
      "2024-01-01", "2024-01-02", "2024-01-15",
      "2024-01-16", "2024-01-17", "2024-02-01",
      "2024-02-02", "2024-02-03", "2024-02-04", "2024-02-05"
    ))
  )

  screening_config <- list(
    partitioning = list(
      pilot = list(
        by = "date_range",
        date_var = "start_time",
        start = "2024-01-16",
        end = "2024-01-31"
      )
    )
  )

  rules <- fury:::fury_compile_rules_(screening_config, data)
  screened <- fury:::fury_screen(data, rules)

  expect_equal(sum(screened$.fury_partition == "pilot"), 2)
  pilot_rows <- screened$.fury_partition == "pilot"
  expect_true(all(grepl("pilot", screened$.fury_pool_note[pilot_rows], ignore.case = TRUE)))
})

test_that("fury_screen applies exclusion rules correctly", {
  data <- data.frame(
    response_id = 1:10,
    age = c(25, NA, 30, 35, NA, 40, 45, 50, NA, 55),
    consent = c(1, 1, 1, NA, 1, 1, 1, 1, 1, 1)
  )

  screening_config <- list(
    eligibility = list(
      required_nonmissing = c("age", "consent"),
      action = "exclude"
    )
  )

  rules <- fury:::fury_compile_rules_(screening_config, data)
  screened <- fury:::fury_screen(data, rules)

  expect_true(".fury_excluded" %in% names(screened))
  expect_true(".fury_excluded_by" %in% names(screened))

  # Should exclude 4 rows (3 with missing age, 1 with missing consent)
  expect_equal(sum(screened$.fury_excluded), 4)
  expect_equal(sum(!is.na(screened$.fury_excluded_by)), 4)
})

test_that("fury_screen applies flag rules correctly and does not exclude", {
  data <- data.frame(
    response_id = 1:10,
    attn_check = c(3, 3, 2, 3, 1, 3, 3, 2, 3, 3)
  )

  screening_config <- list(
    quality_flags = list(
      attention_checks = list(
        list(
          var = "attn_check",
          pass_values = c(3),
          action = "flag",
          description = "Attention check: select 3"
        )
      )
    )
  )

  rules <- fury:::fury_compile_rules_(screening_config, data)
  screened <- fury:::fury_screen(data, rules)

  flag_col <- ".fury_flag_quality_attentioncheck_attn_check_01"
  expect_true(flag_col %in% names(screened))

  # Should flag 3 rows (values 2, 2, 1)
  expect_equal(sum(screened[[flag_col]]), 3)

  # Flags should NOT exclude
  expect_equal(sum(screened$.fury_excluded), 0)
})

test_that("fury_screen keeps all rows by default (drop_excluded = FALSE)", {
  data <- data.frame(
    response_id = 1:10,
    age = c(25, NA, 30, 35, NA, 40, 45, 50, NA, 55)
  )

  screening_config <- list(
    eligibility = list(
      required_nonmissing = c("age"),
      action = "exclude"
    )
  )

  rules <- fury:::fury_compile_rules_(screening_config, data)
  screened <- fury:::fury_screen(data, rules, drop_excluded = FALSE)

  expect_equal(nrow(screened), 10)
  expect_true(".fury_excluded" %in% names(screened))
})

test_that("fury_screen drops excluded rows when drop_excluded = TRUE", {
  data <- data.frame(
    response_id = 1:10,
    age = c(25, NA, 30, 35, NA, 40, 45, 50, NA, 55)
  )

  screening_config <- list(
    eligibility = list(
      required_nonmissing = c("age"),
      action = "exclude"
    )
  )

  rules <- fury:::fury_compile_rules_(screening_config, data)
  screened <- fury:::fury_screen(data, rules, drop_excluded = TRUE)

  expect_equal(nrow(screened), 7)
  expect_true(all(!screened$.fury_excluded))
})

test_that("screening artifacts are deterministic (same inputs = same outputs)", {
  data <- data.frame(
    response_id = 1:10,
    age = c(25, NA, 30, 35, NA, 40, 45, 50, NA, 55),
    attn_check = c(3, 3, 2, 3, 1, 3, 3, 2, 3, 3)
  )

  screening_config <- list(
    eligibility = list(
      required_nonmissing = c("age"),
      action = "exclude"
    ),
    quality_flags = list(
      attention_checks = list(
        list(
          var = "attn_check",
          pass_values = c(3),
          action = "flag",
          description = "Attention check"
        )
      )
    )
  )

  rules_1 <- fury:::fury_compile_rules_(screening_config, data)
  rules_2 <- fury:::fury_compile_rules_(screening_config, data)

  expect_identical(rules_1, rules_2)

  screened_1 <- fury:::fury_screen(data, rules_1)
  screened_2 <- fury:::fury_screen(data, rules_2)

  expect_identical(screened_1, screened_2)
})

test_that("consort flow artifacts write to tempdir successfully", {
  skip_if_not_installed("fs")

  data <- data.frame(
    response_id = 1:10,
    age = c(25, NA, 30, 35, NA, 40, 45, 50, NA, 55)
  )

  screening_config <- list(
    eligibility = list(
      required_nonmissing = c("age"),
      action = "exclude"
    )
  )

  rules <- fury:::fury_compile_rules_(screening_config, data)
  screened <- fury:::fury_screen(data, rules)

  temp_audit <- tempdir()
  artifacts <- fury:::fury_write_screening_artifacts(screened, rules, temp_audit)

  expect_true(fs::file_exists(artifacts$screening_log))
  expect_true(fs::file_exists(artifacts$screening_overlap))
  expect_true(fs::file_exists(artifacts$consort_flow))
  expect_true(fs::file_exists(artifacts$consort_by_reason))
  expect_true(fs::file_exists(artifacts$screening_summary))
})

test_that("consort flow flags do NOT decrement n_remaining", {
  data <- data.frame(
    response_id = 1:10,
    attn_check = c(3, 3, 2, 3, 1, 3, 3, 2, 3, 3)
  )

  screening_config <- list(
    quality_flags = list(
      attention_checks = list(
        list(
          var = "attn_check",
          pass_values = c(3),
          action = "flag",
          description = "Attention check"
        )
      )
    )
  )

  rules <- fury:::fury_compile_rules_(screening_config, data)
  screened <- fury:::fury_screen(data, rules)

  consort_flow <- fury:::fury_build_consort_flow_(screened, rules)

  # n_remaining should not change for flag rules
  expect_true(all(consort_flow$n_remaining[1] == consort_flow$n_remaining[2]))
})

test_that("consort flow exclusions decrement n_remaining", {
  data <- data.frame(
    response_id = 1:10,
    age = c(25, NA, 30, 35, NA, 40, 45, 50, NA, 55)
  )

  screening_config <- list(
    eligibility = list(
      required_nonmissing = c("age"),
      action = "exclude"
    )
  )

  rules <- fury:::fury_compile_rules_(screening_config, data)
  screened <- fury:::fury_screen(data, rules)

  consort_flow <- fury:::fury_build_consort_flow_(screened, rules)

  # Starting: 10
  expect_equal(consort_flow$n_remaining[1], 10)

  # After exclusion: 7
  expect_equal(consort_flow$n_remaining[2], 7)
})

test_that("screening_summary uses conservative language", {
  data <- data.frame(
    response_id = 1:10,
    age = c(25, NA, 30, 35, NA, 40, 45, 50, NA, 55)
  )

  screening_config <- list(
    eligibility = list(
      required_nonmissing = c("age"),
      action = "exclude"
    )
  )

  rules <- fury:::fury_compile_rules_(screening_config, data)
  screened <- fury:::fury_screen(data, rules)

  summary <- fury:::fury_build_screening_summary_(screened, rules)

  # Check for conservative language
  all_text <- paste(summary$line_text, collapse = " ")
  expect_true(grepl("Analysis-eligible pool \\(declared\\)", all_text))
  expect_false(grepl("final sample", all_text, ignore.case = TRUE))
  expect_false(grepl("cleaned", all_text, ignore.case = TRUE))
  expect_false(grepl("validated", all_text, ignore.case = TRUE))
})

test_that("partitioning supports datetime (same-day pretest and pilot)", {
  # Critical: pilots and pretests may occur on the same day
  data <- data.frame(
    response_id = 1:10,
    start_time = as.POSIXct(c(
      # Pretest: morning
      "2024-01-15 09:00:00", "2024-01-15 09:30:00", "2024-01-15 10:00:00",
      # Pilot: afternoon same day
      "2024-01-15 14:00:00", "2024-01-15 14:30:00",
      # Main: next day
      "2024-01-16 09:00:00", "2024-01-16 10:00:00",
      "2024-01-16 11:00:00", "2024-01-16 12:00:00", "2024-01-16 13:00:00"
    ))
  )

  screening_config <- list(
    partitioning = list(
      pretest = list(
        by = "date_range",
        date_var = "start_time",
        start = "2024-01-15 09:00:00",
        end = "2024-01-15 12:00:00"
      ),
      pilot = list(
        by = "date_range",
        date_var = "start_time",
        start = "2024-01-15 14:00:00",
        end = "2024-01-15 23:59:59"
      )
    )
  )

  rules <- fury:::fury_compile_rules_(screening_config, data)
  screened <- fury:::fury_screen(data, rules)

  # Verify partitions
  expect_equal(sum(screened$.fury_partition == "pretest"), 3)
  expect_equal(sum(screened$.fury_partition == "pilot"), 2)
  expect_equal(sum(screened$.fury_partition == "main"), 5)

  # Pretest excluded from pool
  expect_true(all(!screened$.fury_pool_main[screened$.fury_partition == "pretest"]))

  # Pilot included in pool but noted
  pilot_notes <- screened$.fury_pool_note[screened$.fury_partition == "pilot"]
  expect_true(all(grepl("pilot", pilot_notes, ignore.case = TRUE)))
})
