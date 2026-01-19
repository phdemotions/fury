# Screening Rule Compilation
#
# Compiles SIMPLE and EXPERT mode screening configurations into
# a standardized rule table for execution by the screening engine.
#
# Primary creator & maintainer-of-record: Josh Gonzales (GitHub: phdemotions)
# Part of the niche R universe

#' Compile Screening Rules from Config
#'
#' Takes a screening configuration (from spec/recipe) and compiles it into
#' a standardized rule table. Supports both SIMPLE mode (structured fields)
#' and EXPERT mode (explicit rule table).
#'
#' @param screening_config List. Screening configuration from spec$data$screening
#'   or recipe$screening. If NULL or missing, returns empty rule table.
#' @param data Data frame. The data to be screened (used for validation only).
#'
#' @return Data frame with columns:
#'   - rule_id: character, stable boring ID (e.g., "partition_pretest_01")
#'   - category: character, one of "partition", "eligibility", "quality"
#'   - description: character, novice-friendly description
#'   - fields_used: character, comma-separated variable names
#'   - predicate: character, restricted DSL expression
#'   - action: character, one of "partition", "exclude", "flag"
#'   - order: integer, execution order
#'   - assign_value: character, for partition rules (pretest/pilot/main/unassigned)
#'
#' @noRd
fury_compile_rules_ <- function(screening_config, data) {
  # If no screening config, return empty rule table
  if (is.null(screening_config) || length(screening_config) == 0) {
    return(fury_empty_rule_table_())
  }

  # Check if EXPERT mode (explicit screening_rules table provided)
  if (!is.null(screening_config$screening_rules)) {
    return(fury_compile_expert_rules_(screening_config$screening_rules, data))
  }

  # Otherwise compile SIMPLE mode
  fury_compile_simple_rules_(screening_config, data)
}

#' Create Empty Rule Table
#'
#' @return Empty data frame with standard rule table columns
#' @noRd
fury_empty_rule_table_ <- function() {
  data.frame(
    rule_id = character(0),
    category = character(0),
    description = character(0),
    fields_used = character(0),
    predicate = character(0),
    action = character(0),
    order = integer(0),
    assign_value = character(0),
    stringsAsFactors = FALSE
  )
}

#' Compile Simple Mode Rules
#'
#' @param screening_config List with partitioning, eligibility, quality_flags
#' @param data Data frame
#' @return Rule table data frame
#' @noRd
fury_compile_simple_rules_ <- function(screening_config, data) {
  rules <- list()
  order_counter <- 1L

  # 1. Partition rules (execute first)
  if (!is.null(screening_config$partitioning)) {
    part_rules <- fury_compile_partitioning_rules_(
      screening_config$partitioning,
      data,
      order_counter
    )
    rules <- c(rules, list(part_rules))
    order_counter <- order_counter + nrow(part_rules)
  }

  # 2. Eligibility rules
  if (!is.null(screening_config$eligibility)) {
    elig_rules <- fury_compile_eligibility_rules_(
      screening_config$eligibility,
      data,
      order_counter
    )
    rules <- c(rules, list(elig_rules))
    order_counter <- order_counter + nrow(elig_rules)
  }

  # 3. Quality flag rules
  if (!is.null(screening_config$quality_flags)) {
    qual_rules <- fury_compile_quality_rules_(
      screening_config$quality_flags,
      data,
      order_counter
    )
    rules <- c(rules, list(qual_rules))
  }

  # Combine all rules
  if (length(rules) == 0) {
    return(fury_empty_rule_table_())
  }

  do.call(rbind, rules)
}

#' Compile Partitioning Rules from Simple Mode
#'
#' @param partitioning List with pretest, pilot, remainder_partition
#' @param data Data frame
#' @param start_order Integer starting order
#' @return Rule table data frame
#' @noRd
fury_compile_partitioning_rules_ <- function(partitioning, data, start_order) {
  rules <- list()
  rule_counter <- 1L

  # Pretest partition
  if (!is.null(partitioning$pretest)) {
    pretest_rule <- fury_compile_partition_block_(
      block = partitioning$pretest,
      partition_name = "pretest",
      data = data,
      rule_number = rule_counter,
      order = start_order
    )
    rules <- c(rules, list(pretest_rule))
    rule_counter <- rule_counter + 1L
    start_order <- start_order + 1L
  }

  # Pilot partition
  if (!is.null(partitioning$pilot)) {
    pilot_rule <- fury_compile_partition_block_(
      block = partitioning$pilot,
      partition_name = "pilot",
      data = data,
      rule_number = rule_counter,
      order = start_order
    )
    rules <- c(rules, list(pilot_rule))
    rule_counter <- rule_counter + 1L
  }

  if (length(rules) == 0) {
    return(fury_empty_rule_table_())
  }

  do.call(rbind, rules)
}

#' Compile Single Partition Block
#'
#' @param block List with by, date_var, start, end, or ids
#' @param partition_name Character, e.g., "pretest" or "pilot"
#' @param data Data frame
#' @param rule_number Integer
#' @param order Integer execution order
#' @return Single-row rule table
#' @noRd
fury_compile_partition_block_ <- function(block, partition_name, data,
                                          rule_number, order) {
  # Validate block
  if (is.null(block$by)) {
    nicheCore::niche_abort(
      paste0("partitioning$", partition_name, "$by is required")
    )
  }

  if (!block$by %in% c("date_range", "ids")) {
    nicheCore::niche_abort(
      paste0("partitioning$", partition_name, "$by must be 'date_range' or 'ids'")
    )
  }

  # Build predicate based on method
  if (block$by == "date_range") {
    predicate <- fury_build_date_range_predicate_(
      date_var = block$date_var,
      start = block$start,
      end = block$end,
      data = data
    )
    fields_used <- block$date_var
    description <- paste0(
      "Partition: ", partition_name, " (date range ",
      block$start, " to ", block$end, ")"
    )
  } else {
    # by == "ids"
    predicate <- fury_build_ids_predicate_(
      ids = block$ids,
      data = data
    )
    fields_used <- "row_id"
    description <- paste0(
      "Partition: ", partition_name, " (", length(block$ids), " specified IDs)"
    )
  }

  # Create rule
  data.frame(
    rule_id = sprintf("partition_%s_%02d", partition_name, rule_number),
    category = "partition",
    description = description,
    fields_used = fields_used,
    predicate = predicate,
    action = "partition",
    order = as.integer(order),
    assign_value = partition_name,
    stringsAsFactors = FALSE
  )
}

#' Build Date Range Predicate
#'
#' Supports both date (YYYY-MM-DD) and datetime (YYYY-MM-DD HH:MM:SS) formats.
#' This is critical because pilots and pretests may occur on the same day.
#'
#' @param date_var Character, variable name
#' @param start Character, YYYY-MM-DD or YYYY-MM-DD HH:MM:SS
#' @param end Character, YYYY-MM-DD or YYYY-MM-DD HH:MM:SS
#' @param data Data frame
#' @return Character predicate in restricted DSL
#' @noRd
fury_build_date_range_predicate_ <- function(date_var, start, end, data) {
  # Validate date_var exists
  if (!date_var %in% names(data)) {
    nicheCore::niche_abort(
      paste0("date_var '", date_var, "' not found in data")
    )
  }

  # Validate format: YYYY-MM-DD or YYYY-MM-DD HH:MM:SS
  datetime_pattern <- "^\\d{4}-\\d{2}-\\d{2}( \\d{2}:\\d{2}:\\d{2})?$"

  if (!grepl(datetime_pattern, start)) {
    nicheCore::niche_abort(
      paste0(
        "start must be YYYY-MM-DD or YYYY-MM-DD HH:MM:SS format, got: ",
        start
      )
    )
  }
  if (!grepl(datetime_pattern, end)) {
    nicheCore::niche_abort(
      paste0(
        "end must be YYYY-MM-DD or YYYY-MM-DD HH:MM:SS format, got: ",
        end
      )
    )
  }

  # Build predicate: date_var >= start AND date_var <= end
  paste0(
    date_var, " >= '", start, "' AND ",
    date_var, " <= '", end, "'"
  )
}

#' Build IDs Predicate
#'
#' @param ids Vector of IDs
#' @param data Data frame
#' @return Character predicate in restricted DSL
#' @noRd
fury_build_ids_predicate_ <- function(ids, data) {
  if (is.null(ids) || length(ids) == 0) {
    nicheCore::niche_abort("ids vector cannot be empty for partition by IDs")
  }

  # Check if data has a row_id or similar identifier
  # For now, assume row numbers (1-indexed)
  # Predicate: row_number IN (id1, id2, ...)
  ids_collapsed <- paste(ids, collapse = ", ")
  paste0("row_number IN (", ids_collapsed, ")")
}

#' Compile Eligibility Rules from Simple Mode
#'
#' @param eligibility List with required_nonmissing, action
#' @param data Data frame
#' @param start_order Integer starting order
#' @return Rule table data frame
#' @noRd
fury_compile_eligibility_rules_ <- function(eligibility, data, start_order) {
  rules <- list()

  # required_nonmissing
  if (!is.null(eligibility$required_nonmissing)) {
    vars <- eligibility$required_nonmissing

    # Validate all variables exist
    missing_vars <- setdiff(vars, names(data))
    if (length(missing_vars) > 0) {
      nicheCore::niche_abort(
        paste0(
          "required_nonmissing variables not found in data: ",
          paste(missing_vars, collapse = ", ")
        )
      )
    }

    # Determine action (default "exclude" for eligibility)
    action <- if (!is.null(eligibility$action)) {
      eligibility$action
    } else {
      "exclude"
    }

    if (!action %in% c("exclude", "flag")) {
      nicheCore::niche_abort("eligibility$action must be 'exclude' or 'flag'")
    }

    # Build predicate: all variables are NOT missing
    # DSL: var1 IS NOT MISSING AND var2 IS NOT MISSING ...
    predicates <- paste0(vars, " IS NOT MISSING")
    predicate <- paste(predicates, collapse = " AND ")

    rule <- data.frame(
      rule_id = "eligibility_required_nonmissing_01",
      category = "eligibility",
      description = paste0(
        "Required non-missing: ",
        paste(vars, collapse = ", ")
      ),
      fields_used = paste(vars, collapse = ", "),
      predicate = predicate,
      action = action,
      order = as.integer(start_order),
      assign_value = NA_character_,
      stringsAsFactors = FALSE
    )

    rules <- c(rules, list(rule))
  }

  if (length(rules) == 0) {
    return(fury_empty_rule_table_())
  }

  do.call(rbind, rules)
}

#' Compile Quality Flag Rules from Simple Mode
#'
#' @param quality_flags List with attention_checks, default_action
#' @param data Data frame
#' @param start_order Integer starting order
#' @return Rule table data frame
#' @noRd
fury_compile_quality_rules_ <- function(quality_flags, data, start_order) {
  rules <- list()

  # Default action for quality flags is "flag"
  default_action <- if (!is.null(quality_flags$default_action)) {
    quality_flags$default_action
  } else {
    "flag"
  }

  # Attention checks
  if (!is.null(quality_flags$attention_checks)) {
    checks <- quality_flags$attention_checks

    for (i in seq_along(checks)) {
      check <- checks[[i]]

      # Validate required fields
      if (is.null(check$var)) {
        nicheCore::niche_abort(
          paste0("attention_checks[", i, "]$var is required")
        )
      }
      if (is.null(check$pass_values)) {
        nicheCore::niche_abort(
          paste0("attention_checks[", i, "]$pass_values is required")
        )
      }
      if (is.null(check$description)) {
        nicheCore::niche_abort(
          paste0("attention_checks[", i, "]$description is required")
        )
      }

      # Validate var exists
      if (!check$var %in% names(data)) {
        nicheCore::niche_abort(
          paste0("attention_checks var '", check$var, "' not found in data")
        )
      }

      # Determine action
      action <- if (!is.null(check$action)) {
        check$action
      } else {
        default_action
      }

      if (!action %in% c("exclude", "flag")) {
        nicheCore::niche_abort(
          paste0("attention_checks[", i, "]$action must be 'exclude' or 'flag'")
        )
      }

      # Build predicate: var IN (pass_value1, pass_value2, ...)
      pass_values_quoted <- vapply(
        check$pass_values,
        function(x) {
          if (is.character(x)) {
            paste0("'", x, "'")
          } else {
            as.character(x)
          }
        },
        character(1)
      )
      pass_values_collapsed <- paste(pass_values_quoted, collapse = ", ")
      predicate <- paste0(check$var, " IN (", pass_values_collapsed, ")")

      rule <- data.frame(
        rule_id = sprintf("quality_attentioncheck_%s_%02d", check$var, i),
        category = "quality",
        description = check$description,
        fields_used = check$var,
        predicate = predicate,
        action = action,
        order = as.integer(start_order + i - 1L),
        assign_value = NA_character_,
        stringsAsFactors = FALSE
      )

      rules <- c(rules, list(rule))
    }
  }

  if (length(rules) == 0) {
    return(fury_empty_rule_table_())
  }

  do.call(rbind, rules)
}

#' Compile Expert Mode Rules
#'
#' Validates and normalizes an explicit rule table with restricted DSL predicates.
#'
#' @param screening_rules Data frame with explicit rules
#' @param data Data frame
#' @return Standardized rule table
#' @noRd
fury_compile_expert_rules_ <- function(screening_rules, data) {
  # Validate required columns
  required_cols <- c("rule_id", "category", "description", "predicate", "action")
  missing_cols <- setdiff(required_cols, names(screening_rules))

  if (length(missing_cols) > 0) {
    nicheCore::niche_abort(
      paste0(
        "screening_rules missing required columns: ",
        paste(missing_cols, collapse = ", ")
      )
    )
  }

  # Validate each rule (fail-fast for user-provided rules)
  for (i in seq_len(nrow(screening_rules))) {
    rule_id <- screening_rules$rule_id[i]
    description <- screening_rules$description[i]
    predicate <- screening_rules$predicate[i]

    # Validate rule_id is not empty
    if (is.na(rule_id) || trimws(rule_id) == "") {
      nicheCore::niche_abort(
        paste0("screening_rules row ", i, ": rule_id cannot be empty")
      )
    }

    # Validate description is not empty
    if (is.na(description) || trimws(description) == "") {
      nicheCore::niche_abort(
        paste0(
          "screening_rules row ", i, " (rule_id: ", rule_id, "): ",
          "description cannot be empty"
        )
      )
    }

    # Validate predicate against restricted DSL
    fury_validate_dsl_predicate_(predicate, data)
  }

  # Ensure all required columns exist with defaults
  if (!"fields_used" %in% names(screening_rules)) {
    screening_rules$fields_used <- NA_character_
  }
  if (!"order" %in% names(screening_rules)) {
    screening_rules$order <- seq_len(nrow(screening_rules))
  }
  if (!"assign_value" %in% names(screening_rules)) {
    screening_rules$assign_value <- NA_character_
  }

  # Return standardized table
  screening_rules[, c(
    "rule_id", "category", "description", "fields_used",
    "predicate", "action", "order", "assign_value"
  )]
}

#' Validate DSL Predicate (Restricted)
#'
#' Ensures predicate uses only allowed operators and does not contain
#' arbitrary R code.
#'
#' @param predicate Character, DSL expression
#' @param data Data frame
#' @return NULL (throws error if invalid)
#' @noRd
fury_validate_dsl_predicate_ <- function(predicate, data) {
  # Allowed operators: AND, OR, NOT, IN, IS MISSING, IS NOT MISSING
  # Comparison: ==, !=, <, >, <=, >=
  # Literals: numbers, 'strings', variable names

  # Ban dangerous patterns
  banned_patterns <- c(
    "\\bsystem\\b", "\\beval\\b", "\\bparse\\b",
    "\\bsource\\b", "\\bload\\b", "\\bsave\\b",
    "\\blibrary\\b", "\\brequire\\b", "\\b:::\\b",
    "\\breturn\\b", "\\bfunction\\b", "\\bfor\\b",
    "\\bwhile\\b", "\\brepeat\\b", "\\bif\\b",
    "\\{", "\\}", "\\[\\[", "\\$"
  )

  for (pattern in banned_patterns) {
    if (grepl(pattern, predicate, ignore.case = TRUE)) {
      nicheCore::niche_abort(
        paste0(
          "Predicate contains disallowed pattern '", pattern, "': ", predicate
        )
      )
    }
  }

  invisible(NULL)
}
