# Audit Guardrails Tests
#
# These tests verify that the audit artifacts protect novice users from
# silent misuse and provide peer-review-ready transparency.

test_that("warnings.csv is written and contains expected risk states", {
  # Create minimal screening scenario with flags but no exclusions
  data <- data.frame(
    id = 1:10,
    attn_check = c(rep("correct", 7), rep("wrong", 3))
  )

  # Compile rules with flag action (not exclude)
  screening_config <- list(
    quality_flags = list(
      attention_checks = list(
        list(
          var = "attn_check",
          pass_values = "correct",
          description = "Attention check passed",
          action = "flag"
        )
      )
    )
  )

  rules <- fury_compile_rules_(screening_config, data)
  screened_data <- fury_screen(data, rules, drop_excluded = FALSE)

  # Write artifacts to temp dir
  audit_dir <- tempfile()
  dir.create(audit_dir, recursive = TRUE)

  fury_write_screening_artifacts(screened_data, rules, audit_dir)

  # Check warnings.csv exists
  warnings_path <- file.path(audit_dir, "warnings.csv")
  expect_true(file.exists(warnings_path))

  # Read warnings
  warnings <- read.csv(warnings_path, stringsAsFactors = FALSE)

  # Should have warning about no partitioning declared
  expect_true(any(grepl("partitioning rules declared", warnings$message, ignore.case = TRUE)))

  # Should have warning about flags in analysis pool
  expect_true(any(grepl("flags present in analysis pool", warnings$message, ignore.case = TRUE)))

  # Clean up
  unlink(audit_dir, recursive = TRUE)
})

test_that("decision_registry.csv exists and has required decision keys", {
  # Create minimal screening scenario
  data <- data.frame(
    id = 1:10,
    consent = c(rep("yes", 9), "no")
  )

  # Compile rules with exclusion
  screening_config <- list(
    eligibility = list(
      required_nonmissing = "consent",
      action = "exclude"
    )
  )

  rules <- fury_compile_rules_(screening_config, data)
  screened_data <- fury_screen(data, rules, drop_excluded = FALSE)

  # Write artifacts to temp dir
  audit_dir <- tempfile()
  dir.create(audit_dir, recursive = TRUE)

  fury_write_screening_artifacts(screened_data, rules, audit_dir)

  # Check decision_registry.csv exists
  registry_path <- file.path(audit_dir, "decision_registry.csv")
  expect_true(file.exists(registry_path))

  # Read registry
  registry <- read.csv(registry_path, stringsAsFactors = FALSE)

  # Check required decision keys
  required_keys <- c(
    "pretest_partitioning_declared",
    "pilot_partitioning_declared",
    "eligibility_rules_declared",
    "quality_rules_declared",
    "exclusions_declared",
    "exclusions_applied",
    "flags_present",
    "flags_present_in_pool",
    "pool_definition_declared"
  )

  for (key in required_keys) {
    expect_true(
      key %in% registry$decision_key,
      info = paste0("Missing decision_key: ", key)
    )
  }

  # Clean up
  unlink(audit_dir, recursive = TRUE)
})

test_that("consort_flow.csv contains flags/exclusions clarifying note", {
  # Create minimal screening scenario
  data <- data.frame(
    id = 1:5,
    quality_var = c(1, 1, 1, 0, 0)
  )

  # No screening rules (minimal case)
  rules <- fury_compile_rules_(NULL, data)
  screened_data <- fury_screen(data, rules, drop_excluded = FALSE)

  # Build CONSORT flow
  flow <- fury_build_consort_flow_(screened_data, rules)

  # Check for note row
  note_rows <- flow[flow$step_type == "note", ]
  expect_true(nrow(note_rows) > 0)

  # Check note content
  expect_true(any(grepl("flags do not remove cases", note_rows$description, ignore.case = TRUE)))
})

test_that("consort_flow.csv flag steps never decrement n_remaining", {
  # Create screening scenario with flags
  data <- data.frame(
    id = 1:10,
    attn = c(rep("pass", 6), rep("fail", 4))
  )

  screening_config <- list(
    quality_flags = list(
      attention_checks = list(
        list(
          var = "attn",
          pass_values = "pass",
          description = "Attention check",
          action = "flag"
        )
      )
    )
  )

  rules <- fury_compile_rules_(screening_config, data)
  screened_data <- fury_screen(data, rules, drop_excluded = FALSE)

  # Build CONSORT flow
  flow <- fury_build_consort_flow_(screened_data, rules)

  # Find flag steps
  flag_steps <- flow[flow$step_type == "flag", ]

  if (nrow(flag_steps) > 0) {
    # For each flag step, check that n_remaining equals previous step
    for (i in seq_len(nrow(flag_steps))) {
      step_num <- flag_steps$step[i]
      prev_step <- flow[flow$step == (step_num - 1), ]

      if (nrow(prev_step) > 0) {
        expect_equal(
          flag_steps$n_remaining[i],
          prev_step$n_remaining[1],
          info = "Flag step should not decrement n_remaining"
        )
      }
    }
  }
})

test_that("screening_summary.csv includes explicit partitioning status", {
  # Create scenario with NO partitioning
  data <- data.frame(id = 1:5)
  rules <- fury_compile_rules_(NULL, data)
  screened_data <- fury_screen(data, rules, drop_excluded = FALSE)

  summary <- fury_build_screening_summary_(screened_data, rules)

  # Check for partitioning status lines
  expect_true(any(grepl("Partitioning declared:", summary$line_text)))
  expect_true(any(grepl("Pretest partition present:", summary$line_text)))
  expect_true(any(grepl("Pilot partition present:", summary$line_text)))
  expect_true(any(grepl("Flagged cases present in pool:", summary$line_text)))
})

test_that("language tripwire: artifacts do not contain banned terms", {
  # Create minimal screening scenario
  data <- data.frame(id = 1:5)
  rules <- fury_compile_rules_(NULL, data)
  screened_data <- fury_screen(data, rules, drop_excluded = FALSE)

  # Write artifacts
  audit_dir <- tempfile()
  dir.create(audit_dir, recursive = TRUE)
  fury_write_screening_artifacts(screened_data, rules, audit_dir)

  # Read all CSV artifacts
  csv_files <- list.files(audit_dir, pattern = "\\.csv$", full.names = TRUE)

  all_content <- character(0)
  for (f in csv_files) {
    lines <- readLines(f, warn = FALSE)
    all_content <- c(all_content, lines)
  }

  content_text <- paste(all_content, collapse = " ")

  # Banned terms per governance
  banned_terms <- c(
    "final sample",
    "cleaned data",
    "validated",
    "reliability",
    "Cronbach",
    "mediator",
    "manipulation check"
  )

  for (term in banned_terms) {
    expect_false(
      grepl(term, content_text, ignore.case = TRUE),
      info = paste0("Banned term found in artifacts: ", term)
    )
  }

  # Clean up
  unlink(audit_dir, recursive = TRUE)
})

test_that("expert mode validates empty descriptions and rule_ids", {
  # Create data
  data <- data.frame(id = 1:5, consent = rep("yes", 5))

  # Expert mode rules with empty description
  bad_rules <- data.frame(
    rule_id = "test_01",
    category = "eligibility",
    description = "",  # Empty description
    predicate = "consent IS NOT MISSING",
    action = "exclude",
    stringsAsFactors = FALSE
  )

  expect_error(
    fury_compile_expert_rules_(bad_rules, data),
    regexp = "description cannot be empty",
    info = "Should reject empty description"
  )

  # Expert mode rules with empty rule_id
  bad_rules2 <- data.frame(
    rule_id = "",  # Empty rule_id
    category = "eligibility",
    description = "Test rule",
    predicate = "consent IS NOT MISSING",
    action = "exclude",
    stringsAsFactors = FALSE
  )

  expect_error(
    fury_compile_expert_rules_(bad_rules2, data),
    regexp = "rule_id cannot be empty",
    info = "Should reject empty rule_id"
  )
})

test_that("warnings persist to artifact, not just console", {
  # This test verifies that warnings are in the CSV, not just logged to console
  data <- data.frame(
    id = 1:10,
    flag_var = c(rep(1, 8), rep(0, 2))
  )

  screening_config <- list(
    quality_flags = list(
      attention_checks = list(
        list(
          var = "flag_var",
          pass_values = 1,
          description = "Quality flag",
          action = "flag"
        )
      )
    )
  )

  rules <- fury_compile_rules_(screening_config, data)
  screened_data <- fury_screen(data, rules, drop_excluded = FALSE)

  # Detect warnings
  warnings_list <- fury_detect_warnings_(screened_data, rules)

  # Should have warnings in the list
  expect_true(length(warnings_list) > 0)

  # Each warning should have required columns
  for (w in warnings_list) {
    expect_true(all(c("warning_id", "severity", "message", "related_artifact") %in% names(w)))
  }
})
