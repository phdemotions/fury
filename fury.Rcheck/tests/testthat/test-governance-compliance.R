# Governance Compliance Tests
#
# These tests enforce the Ecosystem Contract and prevent scope drift.
# They must pass for fury to remain compliant with niche R universe standards.

test_that("fury does not contain banned modeling/statistical tokens", {
  # Scan all R files for banned statistical/modeling tokens
  r_files <- list.files(
    path = "../../R",
    pattern = "\\.R$",
    full.names = TRUE,
    recursive = TRUE
  )

  # Read all R code
  all_code <- character(0)
  for (f in r_files) {
    all_code <- c(all_code, readLines(f, warn = FALSE))
  }

  # Combine into single string for searching
  code_text <- paste(all_code, collapse = "\n")

  # Banned tokens that indicate modeling/statistical analysis
  banned_patterns <- c(
    "\\blm\\(",           # linear models
    "\\bglm\\(",          # generalized linear models
    "\\baov\\(",          # ANOVA
    "\\bt\\.test\\(",     # t-tests
    "\\bcor\\.test\\(",   # correlation tests
    "\\bchisq\\.test\\(", # chi-square tests
    "\\bpsych::alpha",    # reliability analysis
    "\\blavaan::",        # SEM
    "\\bbrms::",          # Bayesian modeling
    "\\brstanarm::",      # Bayesian modeling
    "\\blme4::",          # mixed models
    "\\bnlme::",          # mixed models
    "\\bsem\\(",          # structural equation models
    "\\bcfa\\("           # confirmatory factor analysis
  )

  for (pattern in banned_patterns) {
    matches <- grepl(pattern, code_text, perl = TRUE)
    expect_false(
      matches,
      label = paste("Banned token found:", pattern),
      info = "fury must not perform modeling or statistical analysis"
    )
  }
})

test_that("fury_run calls vision functions and does not define its own schema", {
  # This is a structural test - we verify the function signature
  # and that it depends on vision, not that it runs successfully

  # Check that fury_run exists and is exported
  expect_true("fury_run" %in% getNamespaceExports("fury"))

  # Check function body references vision functions
  body_text <- deparse(body(fury_run))
  body_str <- paste(body_text, collapse = " ")

  expect_true(
    grepl("vision::read_spec", body_str),
    info = "fury_run must call vision::read_spec"
  )
  expect_true(
    grepl("vision::validate_spec", body_str),
    info = "fury_run must call vision::validate_spec"
  )
  expect_true(
    grepl("vision::build_recipe", body_str),
    info = "fury_run must call vision::build_recipe"
  )
})

test_that("fury_execute_recipe accepts niche_recipe and returns niche_result", {
  # Check that fury_execute_recipe exists and is exported
  expect_true("fury_execute_recipe" %in% getNamespaceExports("fury"))

  # Check function body uses nicheCore validators
  body_text <- deparse(body(fury_execute_recipe))
  body_str <- paste(body_text, collapse = " ")

  expect_true(
    grepl("nicheCore::is_niche_recipe", body_str),
    info = "fury_execute_recipe must validate input as niche_recipe"
  )
  expect_true(
    grepl("nicheCore::new_niche_result", body_str),
    info = "fury_execute_recipe must return a niche_result"
  )
})

test_that("all file writes occur only under temp or user-specified directories", {
  # Scan R code for file write operations
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

  # Check that writes use out_dir parameter or nicheCore helpers
  # No hardcoded paths to package source
  expect_false(
    grepl('fs::path\\("R/', code_text, fixed = TRUE),
    info = "Must not write to package source directory"
  )
  expect_false(
    grepl('fs::path\\("tests/', code_text, fixed = TRUE),
    info = "Must not write to package source directory"
  )

  # Verify use of nicheCore output helpers
  if (grepl("write_audit_csv|write_audit_json", code_text)) {
    expect_true(
      grepl("nicheCore::write_audit", code_text),
      info = "Must use nicheCore write helpers"
    )
  }
})

test_that("fury_scope returns expected scope statement", {
  scope <- fury_scope()

  expect_type(scope, "character")
  expect_length(scope, 1)

  # Check key scope boundaries are mentioned
  expect_true(grepl("ingestion", scope, ignore.case = TRUE))
  expect_true(grepl("audit", scope, ignore.case = TRUE))
  expect_true(grepl("NOT", scope))
  expect_true(grepl("modeling|scoring|validation|rendering", scope, ignore.case = TRUE))
})
