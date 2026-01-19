# CONSORT Flow and Screening Artifacts
#
# Generates CONSORT-style flow tables and screening logs.
# Language is conservative and non-evaluative per fury governance.
#
# Primary creator & maintainer-of-record: Josh Gonzales (GitHub: phdemotions)
# Part of the niche R universe

#' Generate Screening Log and CONSORT Artifacts
#'
#' Creates screening_log.csv, screening_overlap.csv, consort_flow.csv,
#' consort_by_reason.csv, screening_summary.csv, warnings.csv, and decision_registry.csv.
#'
#' @param data Data frame with .fury_* columns from fury_screen()
#' @param rules Rule table from fury_compile_rules_()
#' @param audit_dir Path to audit directory
#'
#' @return List with paths to created artifacts (invisibly)
#' @noRd
fury_write_screening_artifacts <- function(data, rules, audit_dir) {
  if (!fs::dir_exists(audit_dir)) {
    nicheCore::niche_abort(
      paste0("audit_dir does not exist: ", audit_dir)
    )
  }

  artifacts <- list()

  # 1. Screening log (rule table + counts)
  screening_log <- fury_build_screening_log_(data, rules)
  log_path <- fs::path(audit_dir, "screening_log.csv")
  nicheCore::write_audit_csv(screening_log, log_path)
  artifacts$screening_log <- log_path

  # 2. Screening overlap (pairwise overlaps)
  screening_overlap <- fury_build_screening_overlap_(data, rules)
  overlap_path <- fs::path(audit_dir, "screening_overlap.csv")
  nicheCore::write_audit_csv(screening_overlap, overlap_path)
  artifacts$screening_overlap <- overlap_path

  # 3. CONSORT flow (sequential n_remaining)
  consort_flow <- fury_build_consort_flow_(data, rules)
  flow_path <- fs::path(audit_dir, "consort_flow.csv")
  nicheCore::write_audit_csv(consort_flow, flow_path)
  artifacts$consort_flow <- flow_path

  # 4. CONSORT by reason (exclusions by rule)
  consort_by_reason <- fury_build_consort_by_reason_(data, rules)
  reason_path <- fs::path(audit_dir, "consort_by_reason.csv")
  nicheCore::write_audit_csv(consort_by_reason, reason_path)
  artifacts$consort_by_reason <- reason_path

  # 5. Screening summary (novice-friendly)
  screening_summary <- fury_build_screening_summary_(data, rules)
  summary_path <- fs::path(audit_dir, "screening_summary.csv")
  nicheCore::write_audit_csv(screening_summary, summary_path)
  artifacts$screening_summary <- summary_path

  # 6. Warnings (risk states detected)
  warnings_list <- fury_detect_warnings_(data, rules)
  fury_write_warnings(warnings_list, audit_dir)
  artifacts$warnings <- fs::path(audit_dir, "warnings.csv")

  # 7. Decision registry (declared vs not declared)
  decision_registry <- fury_build_decision_registry_(data, rules)
  fury_write_decision_registry(decision_registry, audit_dir)
  artifacts$decision_registry <- fs::path(audit_dir, "decision_registry.csv")

  invisible(artifacts)
}

#' Build Screening Log
#'
#' @param data Data frame with .fury_* columns
#' @param rules Rule table
#' @return Data frame with rule details and counts
#' @noRd
fury_build_screening_log_ <- function(data, rules) {
  if (nrow(rules) == 0) {
    # Empty log
    return(data.frame(
      rule_id = character(0),
      category = character(0),
      description = character(0),
      action = character(0),
      n_match = integer(0),
      n_no_match = integer(0),
      stringsAsFactors = FALSE
    ))
  }

  # Add counts to each rule
  log <- rules[, c("rule_id", "category", "description", "action", "order")]

  log$n_match <- NA_integer_
  log$n_no_match <- NA_integer_

  for (i in seq_len(nrow(log))) {
    rule <- rules[i, ]

    if (rule$action == "partition") {
      # Count rows assigned to this partition
      n_match <- sum(data$.fury_partition == rule$assign_value, na.rm = TRUE)
      n_no_match <- nrow(data) - n_match

    } else if (rule$action == "exclude") {
      # Count rows excluded by this rule
      n_match <- sum(
        data$.fury_excluded_by == rule$rule_id,
        na.rm = TRUE
      )
      n_no_match <- nrow(data) - n_match

    } else if (rule$action == "flag") {
      # Count rows flagged by this rule
      flag_col <- paste0(".fury_flag_", rule$rule_id)
      if (flag_col %in% names(data)) {
        n_match <- sum(data[[flag_col]], na.rm = TRUE)
        n_no_match <- sum(!data[[flag_col]], na.rm = TRUE)
      }
    }

    log$n_match[i] <- n_match
    log$n_no_match[i] <- n_no_match
  }

  nicheCore::stable_order(log, cols = "order")
}

#' Build Screening Overlap Matrix
#'
#' @param data Data frame with .fury_* columns
#' @param rules Rule table
#' @return Data frame with pairwise overlaps
#' @noRd
fury_build_screening_overlap_ <- function(data, rules) {
  # Filter to exclude and flag rules only
  action_rules <- rules[rules$action %in% c("exclude", "flag"), ]

  if (nrow(action_rules) == 0) {
    return(data.frame(
      rule_id_1 = character(0),
      rule_id_2 = character(0),
      n_overlap = integer(0),
      stringsAsFactors = FALSE
    ))
  }

  overlaps <- list()

  for (i in seq_len(nrow(action_rules))) {
    for (j in seq_len(nrow(action_rules))) {
      if (i >= j) next  # Skip diagonal and duplicates

      rule_1 <- action_rules[i, ]
      rule_2 <- action_rules[j, ]

      # Get affected rows for each rule
      affected_1 <- fury_get_affected_rows_(data, rule_1)
      affected_2 <- fury_get_affected_rows_(data, rule_2)

      n_overlap <- sum(affected_1 & affected_2)

      overlaps[[length(overlaps) + 1]] <- data.frame(
        rule_id_1 = rule_1$rule_id,
        rule_id_2 = rule_2$rule_id,
        n_overlap = n_overlap,
        stringsAsFactors = FALSE
      )
    }
  }

  if (length(overlaps) == 0) {
    return(data.frame(
      rule_id_1 = character(0),
      rule_id_2 = character(0),
      n_overlap = integer(0),
      stringsAsFactors = FALSE
    ))
  }

  do.call(rbind, overlaps)
}

#' Get Affected Rows for a Rule
#'
#' @param data Data frame with .fury_* columns
#' @param rule Single-row rule data frame
#' @return Logical vector
#' @noRd
fury_get_affected_rows_ <- function(data, rule) {
  if (rule$action == "exclude") {
    data$.fury_excluded_by == rule$rule_id
  } else if (rule$action == "flag") {
    flag_col <- paste0(".fury_flag_", rule$rule_id)
    if (flag_col %in% names(data)) {
      data[[flag_col]]
    } else {
      rep(FALSE, nrow(data))
    }
  } else {
    rep(FALSE, nrow(data))
  }
}

#' Build CONSORT Flow Table
#'
#' Sequential flow showing n_remaining after each exclusion.
#' Flags do NOT decrement n_remaining.
#'
#' @param data Data frame with .fury_* columns
#' @param rules Rule table
#' @return Data frame with step, description, n_affected, n_remaining, step_type
#' @noRd
fury_build_consort_flow_ <- function(data, rules) {
  n_start <- nrow(data)
  n_remaining <- n_start

  flow <- data.frame(
    step = integer(0),
    step_type = character(0),
    description = character(0),
    n_affected = integer(0),
    n_remaining = integer(0),
    stringsAsFactors = FALSE
  )

  # Starting point
  flow <- rbind(flow, data.frame(
    step = 0L,
    step_type = "count",
    description = "Starting cases",
    n_affected = 0L,
    n_remaining = n_start,
    stringsAsFactors = FALSE
  ))

  # Apply each rule in order
  step_counter <- 1L

  for (i in seq_len(nrow(rules))) {
    rule <- rules[i, ]

    if (rule$action == "exclude") {
      n_excluded <- sum(
        data$.fury_excluded_by == rule$rule_id,
        na.rm = TRUE
      )
      n_remaining <- n_remaining - n_excluded

      flow <- rbind(flow, data.frame(
        step = step_counter,
        step_type = "exclusion",
        description = paste0("Excluded: ", rule$description),
        n_affected = n_excluded,
        n_remaining = n_remaining,
        stringsAsFactors = FALSE
      ))

      step_counter <- step_counter + 1L

    } else if (rule$action == "flag") {
      # Flags do NOT decrement n_remaining
      flag_col <- paste0(".fury_flag_", rule$rule_id)
      n_flagged <- if (flag_col %in% names(data)) {
        sum(data[[flag_col]], na.rm = TRUE)
      } else {
        0L
      }

      flow <- rbind(flow, data.frame(
        step = step_counter,
        step_type = "flag",
        description = paste0("Flagged: ", rule$description),
        n_affected = n_flagged,
        n_remaining = n_remaining,  # No change
        stringsAsFactors = FALSE
      ))

      step_counter <- step_counter + 1L
    }
    # Partition rules do not appear in flow
  }

  # Add clarifying note about flags vs exclusions
  flow <- rbind(flow, data.frame(
    step = step_counter,
    step_type = "note",
    description = "NOTE: Quality flags do not remove cases unless an exclusion rule is explicitly declared.",
    n_affected = NA_integer_,
    n_remaining = NA_integer_,
    stringsAsFactors = FALSE
  ))
  step_counter <- step_counter + 1L

  # Analysis-eligible pool (not "final sample")
  n_eligible <- sum(data$.fury_pool_main, na.rm = TRUE)
  flow <- rbind(flow, data.frame(
    step = step_counter,
    step_type = "count",
    description = "Analysis-eligible pool (declared rules)",
    n_affected = 0L,
    n_remaining = n_eligible,
    stringsAsFactors = FALSE
  ))

  flow
}

#' Build CONSORT by Reason Table
#'
#' @param data Data frame with .fury_* columns
#' @param rules Rule table
#' @return Data frame with exclusion reasons and counts
#' @noRd
fury_build_consort_by_reason_ <- function(data, rules) {
  exclude_rules <- rules[rules$action == "exclude", ]

  if (nrow(exclude_rules) == 0) {
    return(data.frame(
      reason = character(0),
      n_excluded = integer(0),
      stringsAsFactors = FALSE
    ))
  }

  by_reason <- data.frame(
    reason = character(0),
    n_excluded = integer(0),
    stringsAsFactors = FALSE
  )

  for (i in seq_len(nrow(exclude_rules))) {
    rule <- exclude_rules[i, ]
    n_excluded <- sum(
      data$.fury_excluded_by == rule$rule_id,
      na.rm = TRUE
    )

    by_reason <- rbind(by_reason, data.frame(
      reason = rule$description,
      n_excluded = n_excluded,
      stringsAsFactors = FALSE
    ))
  }

  by_reason
}

#' Build Screening Summary (Novice-Friendly)
#'
#' Simple table with line_order, line_text, n.
#' Now includes explicit status lines for partitioning, flags, and exclusions.
#'
#' @param data Data frame with .fury_* columns
#' @param rules Rule table
#' @return Data frame with summary lines
#' @noRd
fury_build_screening_summary_ <- function(data, rules) {
  summary_lines <- list()
  line_counter <- 1L

  # Partitioning status (explicit declaration)
  partition_rules <- rules[rules$action == "partition", ]
  has_partitioning <- nrow(partition_rules) > 0

  summary_lines[[length(summary_lines) + 1]] <- data.frame(
    line_order = line_counter,
    line_text = paste0("Partitioning declared: ", if (has_partitioning) "Yes" else "No"),
    n = NA_integer_,
    stringsAsFactors = FALSE
  )
  line_counter <- line_counter + 1L

  # Check for specific partitions
  has_pretest <- any(partition_rules$assign_value == "pretest")
  has_pilot <- any(partition_rules$assign_value == "pilot")

  summary_lines[[length(summary_lines) + 1]] <- data.frame(
    line_order = line_counter,
    line_text = paste0("Pretest partition present: ", if (has_pretest) "Yes" else "No"),
    n = if (has_pretest) sum(data$.fury_partition == "pretest", na.rm = TRUE) else 0L,
    stringsAsFactors = FALSE
  )
  line_counter <- line_counter + 1L

  summary_lines[[length(summary_lines) + 1]] <- data.frame(
    line_order = line_counter,
    line_text = paste0("Pilot partition present: ", if (has_pilot) "Yes" else "No"),
    n = if (has_pilot) sum(data$.fury_partition == "pilot", na.rm = TRUE) else 0L,
    stringsAsFactors = FALSE
  )
  line_counter <- line_counter + 1L

  # Partitions detail (if any)
  if (has_partitioning) {
    for (i in seq_len(nrow(partition_rules))) {
      rule <- partition_rules[i, ]
      n_part <- sum(data$.fury_partition == rule$assign_value, na.rm = TRUE)

      summary_lines[[length(summary_lines) + 1]] <- data.frame(
        line_order = line_counter,
        line_text = paste0(
          "  ",
          tools::toTitleCase(rule$assign_value),
          " cases (declared partition):"
        ),
        n = n_part,
        stringsAsFactors = FALSE
      )
      line_counter <- line_counter + 1L
    }
  }

  # Exclusions status
  n_excluded <- sum(data$.fury_excluded, na.rm = TRUE)
  summary_lines[[length(summary_lines) + 1]] <- data.frame(
    line_order = line_counter,
    line_text = "Excluded cases (declared exclusion rules only):",
    n = n_excluded,
    stringsAsFactors = FALSE
  )
  line_counter <- line_counter + 1L

  # Flags status
  flag_rules <- rules[rules$action == "flag", ]
  n_flagged_total <- 0L
  if (nrow(flag_rules) > 0) {
    for (i in seq_len(nrow(flag_rules))) {
      flag_col <- paste0(".fury_flag_", flag_rules$rule_id[i])
      if (flag_col %in% names(data)) {
        n_flagged_total <- n_flagged_total + sum(data[[flag_col]], na.rm = TRUE)
      }
    }
  }

  summary_lines[[length(summary_lines) + 1]] <- data.frame(
    line_order = line_counter,
    line_text = "Flagged cases (declared quality checks):",
    n = n_flagged_total,
    stringsAsFactors = FALSE
  )
  line_counter <- line_counter + 1L

  # Flagged cases in pool (critical warning indicator)
  n_flagged_in_pool <- 0L
  if (nrow(flag_rules) > 0) {
    for (i in seq_len(nrow(flag_rules))) {
      flag_col <- paste0(".fury_flag_", flag_rules$rule_id[i])
      if (flag_col %in% names(data)) {
        n_flagged_in_pool <- n_flagged_in_pool + sum(
          data[[flag_col]] & data$.fury_pool_main,
          na.rm = TRUE
        )
      }
    }
  }

  summary_lines[[length(summary_lines) + 1]] <- data.frame(
    line_order = line_counter,
    line_text = "Flagged cases present in pool:",
    n = n_flagged_in_pool,
    stringsAsFactors = FALSE
  )
  line_counter <- line_counter + 1L

  # Analysis-eligible pool
  n_eligible <- sum(data$.fury_pool_main, na.rm = TRUE)
  summary_lines[[length(summary_lines) + 1]] <- data.frame(
    line_order = line_counter,
    line_text = "Analysis-eligible pool (declared):",
    n = n_eligible,
    stringsAsFactors = FALSE
  )

  if (length(summary_lines) == 0) {
    return(data.frame(
      line_order = integer(0),
      line_text = character(0),
      n = integer(0),
      stringsAsFactors = FALSE
    ))
  }

  do.call(rbind, summary_lines)
}

#' Detect Warnings (Risk States)
#'
#' Detects observable risk states in data and rules. No inference; only facts.
#' Returns list of warning data frames.
#'
#' @param data Data frame with .fury_* columns
#' @param rules Rule table
#' @return List of warning data frames
#' @noRd
fury_detect_warnings_ <- function(data, rules) {
  warnings_list <- list()
  warning_counter <- 1L

  # Risk state 1: Partitioning not declared
  partition_rules <- rules[rules$action == "partition", ]
  if (nrow(partition_rules) == 0) {
    warnings_list[[warning_counter]] <- data.frame(
      warning_id = sprintf("W%03d", warning_counter),
      severity = "WARN",
      message = "No partitioning rules declared (pretest/pilot rules absent)",
      related_artifact = "screening_summary.csv",
      stringsAsFactors = FALSE
    )
    warning_counter <- warning_counter + 1L
  }

  # Risk state 2: Quality flags present in analysis pool
  flag_rules <- rules[rules$action == "flag", ]
  if (nrow(flag_rules) > 0) {
    n_flagged_in_pool <- 0L
    for (i in seq_len(nrow(flag_rules))) {
      flag_col <- paste0(".fury_flag_", flag_rules$rule_id[i])
      if (flag_col %in% names(data)) {
        n_flagged_in_pool <- n_flagged_in_pool + sum(
          data[[flag_col]] & data$.fury_pool_main,
          na.rm = TRUE
        )
      }
    }

    if (n_flagged_in_pool > 0) {
      warnings_list[[warning_counter]] <- data.frame(
        warning_id = sprintf("W%03d", warning_counter),
        severity = "WARN",
        message = paste0(
          "Quality flags present in analysis pool (n=", n_flagged_in_pool, "). ",
          "Flagged cases are NOT excluded unless an exclusion rule is declared."
        ),
        related_artifact = "screening_summary.csv",
        stringsAsFactors = FALSE
      )
      warning_counter <- warning_counter + 1L
    }
  }

  # Risk state 3: Exclusions declared (INFO, not warning)
  exclude_rules <- rules[rules$action == "exclude", ]
  if (nrow(exclude_rules) > 0) {
    n_excluded <- sum(data$.fury_excluded, na.rm = TRUE)
    warnings_list[[warning_counter]] <- data.frame(
      warning_id = sprintf("W%03d", warning_counter),
      severity = "INFO",
      message = paste0(
        "Exclusion rules applied (n=", n_excluded, " cases excluded)"
      ),
      related_artifact = "consort_by_reason.csv",
      stringsAsFactors = FALSE
    )
    warning_counter <- warning_counter + 1L
  }

  # Risk state 4: No screening rules declared at all
  if (nrow(rules) == 0) {
    warnings_list[[warning_counter]] <- data.frame(
      warning_id = sprintf("W%03d", warning_counter),
      severity = "INFO",
      message = "No partitioning/eligibility/quality rules declared",
      related_artifact = "screening_summary.csv",
      stringsAsFactors = FALSE
    )
  }

  warnings_list
}

#' Build Decision Registry
#'
#' Deterministic registry of whether key decisions were declared.
#' No inference; only observable facts from rules and data.
#'
#' @param data Data frame with .fury_* columns
#' @param rules Rule table
#' @return Data frame with decision keys and values
#' @noRd
fury_build_decision_registry_ <- function(data, rules) {
  # Initialize registry
  registry <- list()

  # Partitioning decisions
  partition_rules <- rules[rules$action == "partition", ]
  has_pretest <- any(partition_rules$assign_value == "pretest")
  has_pilot <- any(partition_rules$assign_value == "pilot")

  registry[[length(registry) + 1]] <- data.frame(
    decision_key = "pretest_partitioning_declared",
    decision_value = as.character(has_pretest),
    decision_source = if (has_pretest) "spec" else "not_declared",
    notes = if (has_pretest) {
      paste0("n=", sum(data$.fury_partition == "pretest", na.rm = TRUE))
    } else {
      "No pretest partition declared in spec/recipe"
    },
    stringsAsFactors = FALSE
  )

  registry[[length(registry) + 1]] <- data.frame(
    decision_key = "pilot_partitioning_declared",
    decision_value = as.character(has_pilot),
    decision_source = if (has_pilot) "spec" else "not_declared",
    notes = if (has_pilot) {
      paste0("n=", sum(data$.fury_partition == "pilot", na.rm = TRUE))
    } else {
      "No pilot partition declared in spec/recipe"
    },
    stringsAsFactors = FALSE
  )

  # Eligibility rules
  eligibility_rules <- rules[rules$category == "eligibility", ]
  has_eligibility <- nrow(eligibility_rules) > 0

  registry[[length(registry) + 1]] <- data.frame(
    decision_key = "eligibility_rules_declared",
    decision_value = as.character(has_eligibility),
    decision_source = if (has_eligibility) "spec" else "not_declared",
    notes = if (has_eligibility) {
      paste0(nrow(eligibility_rules), " eligibility rule(s)")
    } else {
      "No eligibility rules declared"
    },
    stringsAsFactors = FALSE
  )

  # Quality rules
  quality_rules <- rules[rules$category == "quality", ]
  has_quality <- nrow(quality_rules) > 0

  registry[[length(registry) + 1]] <- data.frame(
    decision_key = "quality_rules_declared",
    decision_value = as.character(has_quality),
    decision_source = if (has_quality) "spec" else "not_declared",
    notes = if (has_quality) {
      paste0(nrow(quality_rules), " quality rule(s)")
    } else {
      "No quality rules declared"
    },
    stringsAsFactors = FALSE
  )

  # Exclusions
  exclude_rules <- rules[rules$action == "exclude", ]
  has_exclusions <- nrow(exclude_rules) > 0
  n_excluded <- sum(data$.fury_excluded, na.rm = TRUE)

  registry[[length(registry) + 1]] <- data.frame(
    decision_key = "exclusions_declared",
    decision_value = as.character(has_exclusions),
    decision_source = if (has_exclusions) "spec" else "not_declared",
    notes = if (has_exclusions) {
      paste0(nrow(exclude_rules), " exclusion rule(s)")
    } else {
      "No exclusion rules declared"
    },
    stringsAsFactors = FALSE
  )

  registry[[length(registry) + 1]] <- data.frame(
    decision_key = "exclusions_applied",
    decision_value = as.character(n_excluded > 0),
    decision_source = "observed",
    notes = paste0("n=", n_excluded, " cases excluded"),
    stringsAsFactors = FALSE
  )

  # Flags
  flag_rules <- rules[rules$action == "flag", ]
  has_flags <- nrow(flag_rules) > 0
  n_flagged_total <- 0L
  n_flagged_in_pool <- 0L

  if (has_flags) {
    for (i in seq_len(nrow(flag_rules))) {
      flag_col <- paste0(".fury_flag_", flag_rules$rule_id[i])
      if (flag_col %in% names(data)) {
        n_flagged_total <- n_flagged_total + sum(data[[flag_col]], na.rm = TRUE)
        n_flagged_in_pool <- n_flagged_in_pool + sum(
          data[[flag_col]] & data$.fury_pool_main,
          na.rm = TRUE
        )
      }
    }
  }

  registry[[length(registry) + 1]] <- data.frame(
    decision_key = "flags_present",
    decision_value = as.character(n_flagged_total > 0),
    decision_source = "observed",
    notes = paste0("n=", n_flagged_total, " cases flagged"),
    stringsAsFactors = FALSE
  )

  registry[[length(registry) + 1]] <- data.frame(
    decision_key = "flags_present_in_pool",
    decision_value = as.character(n_flagged_in_pool > 0),
    decision_source = "observed",
    notes = paste0("n=", n_flagged_in_pool, " flagged cases in analysis pool"),
    stringsAsFactors = FALSE
  )

  # Pool definition (always declared via .fury_pool_main)
  registry[[length(registry) + 1]] <- data.frame(
    decision_key = "pool_definition_declared",
    decision_value = "TRUE",
    decision_source = "observed",
    notes = ".fury_pool_main column present",
    stringsAsFactors = FALSE
  )

  do.call(rbind, registry)
}
