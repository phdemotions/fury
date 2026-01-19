# Screening Engine
#
# Applies compiled screening rules to data and adds .fury_* columns.
# Does not mutate original data columns; only adds screening metadata.
#
# Primary creator & maintainer-of-record: Josh Gonzales (GitHub: phdemotions)
# Part of the niche R universe

#' Apply Screening Rules to Data
#'
#' Takes compiled screening rules and applies them to data, adding
#' .fury_* metadata columns. Does not drop rows by default.
#'
#' @param data Data frame to screen
#' @param rules Rule table from fury_compile_rules_()
#' @param drop_excluded Logical. If TRUE, removes excluded rows.
#'   Default FALSE (keeps all rows, marks exclusions).
#'
#' @return Data frame with added columns:
#'   - .fury_partition: character (pretest/pilot/main/unassigned)
#'   - .fury_excluded: logical
#'   - .fury_excluded_by: character (rule_id or NA)
#'   - .fury_flag_<rule_id>: logical (one per flag rule)
#'   - .fury_pool_main: logical (eligible for main analysis)
#'   - .fury_pool_note: character (non-evaluative notes)
#'
#' @noRd
fury_screen <- function(data, rules, drop_excluded = FALSE) {
  if (!is.data.frame(data)) {
    nicheCore::niche_abort("data must be a data.frame")
  }
  if (!is.data.frame(rules)) {
    nicheCore::niche_abort("rules must be a data.frame")
  }

  if (nrow(data) == 0) {
    nicheCore::niche_abort("Cannot screen empty data frame")
  }

  # Initialize .fury_* columns
  data$.fury_partition <- "unassigned"
  data$.fury_excluded <- FALSE
  data$.fury_excluded_by <- NA_character_
  data$.fury_pool_main <- TRUE
  data$.fury_pool_note <- NA_character_

  # If no rules, return data with initialized columns
  if (nrow(rules) == 0) {
    data$.fury_partition <- "main"
    data$.fury_pool_note <- "No screening rules applied"
    return(data)
  }

  # Add row_number for ID-based partitioning
  data$.fury_row_number <- seq_len(nrow(data))

  # Sort rules by order
  rules <- rules[order(rules$order), ]

  # Apply each rule
  for (i in seq_len(nrow(rules))) {
    rule <- rules[i, ]
    data <- fury_apply_rule_(data, rule)
  }

  # Remove temporary row_number
  data$.fury_row_number <- NULL

  # Apply partition defaults
  data <- fury_apply_partition_defaults_(data)

  # Drop excluded rows if requested
  if (drop_excluded) {
    n_excluded <- sum(data$.fury_excluded)
    if (n_excluded > 0) {
      cli::cli_alert_info("Dropping {n_excluded} excluded row{?s}")
      data <- data[!data$.fury_excluded, ]
    }
  }

  data
}

#' Apply Single Rule to Data
#'
#' @param data Data frame with .fury_* columns initialized
#' @param rule Single-row rule data frame
#' @return Data frame with rule applied
#' @noRd
fury_apply_rule_ <- function(data, rule) {
  # Evaluate predicate to get logical vector
  match_vector <- fury_eval_predicate_(rule$predicate, data)

  # Apply action
  if (rule$action == "partition") {
    # Assign partition value to matching rows (only if still unassigned)
    unassigned_mask <- data$.fury_partition == "unassigned"
    assign_mask <- match_vector & unassigned_mask
    data$.fury_partition[assign_mask] <- rule$assign_value

  } else if (rule$action == "exclude") {
    # Mark non-matching rows as excluded (only if not already excluded)
    not_excluded_mask <- !data$.fury_excluded
    exclude_mask <- !match_vector & not_excluded_mask
    data$.fury_excluded[exclude_mask] <- TRUE
    data$.fury_excluded_by[exclude_mask] <- rule$rule_id

  } else if (rule$action == "flag") {
    # Add flag column for non-matching rows
    flag_col_name <- paste0(".fury_flag_", rule$rule_id)
    data[[flag_col_name]] <- !match_vector

  } else {
    nicheCore::niche_abort(
      paste0("Unknown action: ", rule$action)
    )
  }

  data
}

#' Evaluate DSL Predicate
#'
#' Safely evaluates a restricted DSL predicate against data.
#'
#' @param predicate Character DSL expression
#' @param data Data frame
#' @return Logical vector
#' @noRd
fury_eval_predicate_ <- function(predicate, data) {
  # Parse and evaluate restricted DSL
  # For now, implement basic operators

  # Replace DSL tokens with R equivalents
  predicate_r <- predicate

  # IS NOT MISSING -> !is.na(var)
  predicate_r <- gsub(
    "([a-zA-Z_][a-zA-Z0-9_]*) IS NOT MISSING",
    "!is.na(\\1)",
    predicate_r,
    perl = TRUE
  )

  # IS MISSING -> is.na(var)
  predicate_r <- gsub(
    "([a-zA-Z_][a-zA-Z0-9_]*) IS MISSING",
    "is.na(\\1)",
    predicate_r,
    perl = TRUE
  )

  # var IN (...) -> var %in% c(...)
  predicate_r <- gsub(
    " IN \\(",
    " %in% c(",
    predicate_r,
    perl = TRUE
  )

  # row_number IN (...) -> .fury_row_number %in% c(...)
  predicate_r <- gsub(
    "row_number",
    ".fury_row_number",
    predicate_r,
    perl = TRUE
  )

  # AND -> &
  predicate_r <- gsub(" AND ", " & ", predicate_r, perl = TRUE)

  # OR -> |
  predicate_r <- gsub(" OR ", " | ", predicate_r, perl = TRUE)

  # NOT -> !
  predicate_r <- gsub(" NOT ", " !", predicate_r, perl = TRUE)

  # Date/datetime comparisons: handle both YYYY-MM-DD and YYYY-MM-DD HH:MM:SS
  # First, check for datetime (has time component)
  # Pattern: var >= 'YYYY-MM-DD HH:MM:SS'
  predicate_r <- gsub(
    "([a-zA-Z_][a-zA-Z0-9_]*) ([><=!]+) '(\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2})'",
    "as.POSIXct(\\1) \\2 as.POSIXct('\\3')",
    predicate_r,
    perl = TRUE
  )

  # Then handle date-only (YYYY-MM-DD) for cases without time
  # Pattern: var >= 'YYYY-MM-DD' (but not if already converted to POSIXct)
  if (!grepl("as\\.POSIXct", predicate_r)) {
    predicate_r <- gsub(
      "([a-zA-Z_][a-zA-Z0-9_]*) ([><=!]+) '(\\d{4}-\\d{2}-\\d{2})'",
      "as.Date(\\1) \\2 as.Date('\\3')",
      predicate_r,
      perl = TRUE
    )
  }

  # Evaluate in data environment (safe because we validated predicate)
  tryCatch(
    {
      with(data, eval(parse(text = predicate_r)))
    },
    error = function(e) {
      nicheCore::niche_abort(
        paste0("Failed to evaluate predicate: ", predicate, "\nError: ", e$message)
      )
    }
  )
}

#' Apply Partition Defaults
#'
#' Sets .fury_pool_main and .fury_pool_note based on partition assignments.
#'
#' @param data Data frame with .fury_partition assigned
#' @return Data frame with defaults applied
#' @noRd
fury_apply_partition_defaults_ <- function(data) {
  # Assign unassigned -> main
  unassigned_mask <- data$.fury_partition == "unassigned"
  data$.fury_partition[unassigned_mask] <- "main"

  # Pretest: default pool_main = FALSE
  pretest_mask <- data$.fury_partition == "pretest"
  data$.fury_pool_main[pretest_mask] <- FALSE
  data$.fury_pool_note[pretest_mask] <- "Declared partition: pretest"

  # Pilot: default pool_main = TRUE but explicitly noted
  pilot_mask <- data$.fury_partition == "pilot"
  data$.fury_pool_note[pilot_mask] <- "Declared partition: pilot"

  # Main: no special note (default)
  main_mask <- data$.fury_partition == "main" & is.na(data$.fury_pool_note)
  data$.fury_pool_note[main_mask] <- "Declared partition: main"

  # Excluded: pool_main = FALSE
  excluded_mask <- data$.fury_excluded
  data$.fury_pool_main[excluded_mask] <- FALSE
  data$.fury_pool_note[excluded_mask] <- paste0(
    "Excluded by: ", data$.fury_excluded_by[excluded_mask]
  )

  data
}
