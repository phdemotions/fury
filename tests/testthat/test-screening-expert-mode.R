# Tests for Expert Mode Screening (Restricted DSL)
#
# Primary creator & maintainer-of-record: Josh Gonzales (GitHub: phdemotions)
# Part of the niche R universe

test_that("expert mode accepts explicit rule table", {
  data <- data.frame(
    response_id = 1:10,
    age = c(25, NA, 30, 35, NA, 40, 45, 50, NA, 55)
  )

  screening_config <- list(
    screening_rules = data.frame(
      rule_id = "custom_exclusion_01",
      category = "eligibility",
      description = "Exclude missing age",
      predicate = "age IS NOT MISSING",
      action = "exclude",
      stringsAsFactors = FALSE
    )
  )

  rules <- fury:::fury_compile_rules_(screening_config, data)

  expect_equal(nrow(rules), 1)
  expect_equal(rules$rule_id, "custom_exclusion_01")
  expect_equal(rules$action, "exclude")
})

test_that("expert mode validates required columns", {
  data <- data.frame(x = 1:10)

  screening_config <- list(
    screening_rules = data.frame(
      rule_id = "test",
      # Missing required columns: category, description, predicate, action
      stringsAsFactors = FALSE
    )
  )

  expect_error(
    fury:::fury_compile_rules_(screening_config, data),
    "missing required columns"
  )
})

test_that("DSL validation rejects arbitrary R code patterns", {
  data <- data.frame(x = 1:10)

  # Test system() injection
  expect_error(
    fury:::fury_validate_dsl_predicate_("system('rm -rf /')", data),
    "disallowed pattern"
  )

  # Test eval() injection
  expect_error(
    fury:::fury_validate_dsl_predicate_("eval(parse(text='malicious'))", data),
    "disallowed pattern"
  )

  # Test function definition
  expect_error(
    fury:::fury_validate_dsl_predicate_("function() { x }", data),
    "disallowed pattern"
  )

  # Test ::: (accessing internals)
  expect_error(
    fury:::fury_validate_dsl_predicate_("pkg:::secret_function()", data),
    "disallowed pattern"
  )

  # Test $ accessor
  expect_error(
    fury:::fury_validate_dsl_predicate_("data$x", data),
    "disallowed pattern"
  )

  # Test [[ accessor
  expect_error(
    fury:::fury_validate_dsl_predicate_("data[[1]]", data),
    "disallowed pattern"
  )
})

test_that("DSL validation accepts safe predicates", {
  data <- data.frame(
    age = c(25, 30, 35),
    consent = c(1, 1, NA)
  )

  # Should NOT error on safe predicates
  expect_silent(
    fury:::fury_validate_dsl_predicate_("age IS NOT MISSING", data)
  )

  expect_silent(
    fury:::fury_validate_dsl_predicate_("age >= 18 AND consent IS NOT MISSING", data)
  )

  expect_silent(
    fury:::fury_validate_dsl_predicate_("age IN (25, 30, 35)", data)
  )
})

test_that("expert mode rule execution matches simple mode for equivalent rules", {
  data <- data.frame(
    response_id = 1:10,
    age = c(25, NA, 30, 35, NA, 40, 45, 50, NA, 55)
  )

  # Simple mode
  simple_config <- list(
    eligibility = list(
      required_nonmissing = c("age"),
      action = "exclude"
    )
  )

  # Expert mode equivalent
  expert_config <- list(
    screening_rules = data.frame(
      rule_id = "eligibility_required_nonmissing_01",
      category = "eligibility",
      description = "Required non-missing: age",
      predicate = "age IS NOT MISSING",
      action = "exclude",
      stringsAsFactors = FALSE
    )
  )

  simple_rules <- fury:::fury_compile_rules_(simple_config, data)
  expert_rules <- fury:::fury_compile_rules_(expert_config, data)

  simple_screened <- fury:::fury_screen(data, simple_rules)
  expert_screened <- fury:::fury_screen(data, expert_rules)

  # Both should exclude the same rows
  expect_equal(
    simple_screened$.fury_excluded,
    expert_screened$.fury_excluded
  )
})

test_that("expert mode supports complex predicates with AND/OR", {
  data <- data.frame(
    response_id = 1:10,
    age = c(18, 17, 25, 30, 16, 40, 19, 50, 15, 55),
    consent = c(1, 1, 1, NA, 1, 1, NA, 1, 1, 1)
  )

  screening_config <- list(
    screening_rules = data.frame(
      rule_id = "complex_eligibility_01",
      category = "eligibility",
      description = "Age >= 18 AND consent provided",
      predicate = "age >= 18 AND consent IS NOT MISSING",
      action = "exclude",
      stringsAsFactors = FALSE
    )
  )

  rules <- fury:::fury_compile_rules_(screening_config, data)
  screened <- fury:::fury_screen(data, rules)

  # Should exclude rows that fail: age < 18 OR consent missing
  # Rows 2 (age 17), 4 (consent NA), 5 (age 16), 7 (consent NA), 9 (age 15)
  expect_equal(sum(screened$.fury_excluded), 5)
})

test_that("expert mode supports IN operator for categorical values", {
  data <- data.frame(
    response_id = 1:10,
    status = c("complete", "partial", "complete", "complete", "disqualified",
               "complete", "partial", "complete", "complete", "complete")
  )

  screening_config <- list(
    screening_rules = data.frame(
      rule_id = "status_filter_01",
      category = "eligibility",
      description = "Status must be complete",
      predicate = "status IN ('complete')",
      action = "exclude",
      stringsAsFactors = FALSE
    )
  )

  rules <- fury:::fury_compile_rules_(screening_config, data)
  screened <- fury:::fury_screen(data, rules)

  # Should exclude non-complete (2 partial, 1 disqualified)
  expect_equal(sum(screened$.fury_excluded), 3)
})

test_that("expert mode rules maintain execution order", {
  data <- data.frame(
    response_id = 1:10,
    age = c(25, NA, 30, 35, NA, 40, 45, 50, NA, 55),
    consent = c(1, 1, 1, NA, 1, 1, 1, 1, 1, 1)
  )

  screening_config <- list(
    screening_rules = data.frame(
      rule_id = c("rule_01", "rule_02"),
      category = c("eligibility", "eligibility"),
      description = c("Age provided", "Consent provided"),
      predicate = c("age IS NOT MISSING", "consent IS NOT MISSING"),
      action = c("exclude", "exclude"),
      order = c(1L, 2L),
      stringsAsFactors = FALSE
    )
  )

  rules <- fury:::fury_compile_rules_(screening_config, data)

  # Rules should be in order
  expect_equal(rules$order, c(1L, 2L))
  expect_equal(rules$rule_id, c("rule_01", "rule_02"))
})

test_that("expert mode adds defaults for optional columns", {
  data <- data.frame(x = 1:10)

  screening_config <- list(
    screening_rules = data.frame(
      rule_id = "test_01",
      category = "eligibility",
      description = "Test rule",
      predicate = "x >= 5",
      action = "exclude",
      stringsAsFactors = FALSE
      # Missing: fields_used, order, assign_value
    )
  )

  rules <- fury:::fury_compile_rules_(screening_config, data)

  expect_true("fields_used" %in% names(rules))
  expect_true("order" %in% names(rules))
  expect_true("assign_value" %in% names(rules))
})
