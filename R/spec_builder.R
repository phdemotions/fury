# Tidyverse-Style Spec Builder
#
# Provides a fluent API for building fury screening specs interactively,
# with YAML export for preregistration and reproducibility.
#
# Primary creator & maintainer-of-record: Josh Gonzales (GitHub: phdemotions)
# Part of the niche R universe

#' Start Building a Fury Screening Spec
#'
#' Creates a spec builder object that can be configured using tidyverse-style
#' piped functions, then exported to YAML for preregistration.
#'
#' @param data_file Character. Path to data file (e.g., "my_data.sav")
#' @param format Character. Data format ("spss", "csv", etc.). Default "spss".
#'
#' @return A `fury_spec_builder` object that can be piped to configuration functions.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Interactive spec building
#' spec <- fury_spec() %>%
#'   fury_source("my_data.sav", format = "spss") %>%
#'   fury_partition_pilot(
#'     date_var = "StartDate",
#'     start = "2024-01-01",
#'     end = "2024-01-15"
#'   ) %>%
#'   fury_exclude_missing(c("consent", "age")) %>%
#'   fury_flag_attention(
#'     var = "attn_check_1",
#'     pass_values = 3,
#'     description = "Select 3 to continue"
#'   ) %>%
#'   fury_to_yaml("my_screening_spec.yaml")
#'
#' # Then use the YAML for reproducible execution
#' result <- fury_run("my_screening_spec.yaml")
#' }
fury_spec <- function(data_file = NULL, format = "spss") {
  builder <- list(
    data = list(
      sources = list(),
      screening = list(
        partitioning = list(),
        eligibility = list(),
        quality_flags = list(
          attention_checks = list()
        )
      )
    )
  )

  # Add data source if provided
  if (!is.null(data_file)) {
    builder$data$sources[[1]] <- list(
      file = data_file,
      format = format
    )
  }

  class(builder) <- c("fury_spec_builder", "list")
  builder
}

#' Add Data Source to Spec
#'
#' @param builder A `fury_spec_builder` object
#' @param file Character. Path to data file
#' @param format Character. Data format (default "spss")
#'
#' @return Modified `fury_spec_builder` object
#' @export
fury_source <- function(builder, file, format = "spss") {
  if (!inherits(builder, "fury_spec_builder")) {
    nicheCore::niche_abort("builder must be a fury_spec_builder object")
  }

  builder$data$sources[[1]] <- list(
    file = file,
    format = format
  )

  builder
}

#' Declare Pilot Partition
#'
#' @param builder A `fury_spec_builder` object
#' @param date_var Character. Name of date/datetime variable
#' @param start Character. Start date (YYYY-MM-DD or YYYY-MM-DD HH:MM:SS)
#' @param end Character. End date (YYYY-MM-DD or YYYY-MM-DD HH:MM:SS)
#'
#' @return Modified `fury_spec_builder` object
#' @export
fury_partition_pilot <- function(builder, date_var, start, end) {
  if (!inherits(builder, "fury_spec_builder")) {
    nicheCore::niche_abort("builder must be a fury_spec_builder object")
  }

  builder$data$screening$partitioning$pilot <- list(
    by = "date_range",
    date_var = date_var,
    start = start,
    end = end
  )

  builder
}

#' Declare Pretest Partition
#'
#' @param builder A `fury_spec_builder` object
#' @param date_var Character. Name of date/datetime variable
#' @param start Character. Start date (YYYY-MM-DD or YYYY-MM-DD HH:MM:SS)
#' @param end Character. End date (YYYY-MM-DD or YYYY-MM-DD HH:MM:SS)
#'
#' @return Modified `fury_spec_builder` object
#' @export
fury_partition_pretest <- function(builder, date_var, start, end) {
  if (!inherits(builder, "fury_spec_builder")) {
    nicheCore::niche_abort("builder must be a fury_spec_builder object")
  }

  builder$data$screening$partitioning$pretest <- list(
    by = "date_range",
    date_var = date_var,
    start = start,
    end = end
  )

  builder
}

#' Exclude Cases with Missing Values
#'
#' @param builder A `fury_spec_builder` object
#' @param vars Character vector. Variable names that must be non-missing
#'
#' @return Modified `fury_spec_builder` object
#' @export
fury_exclude_missing <- function(builder, vars) {
  if (!inherits(builder, "fury_spec_builder")) {
    nicheCore::niche_abort("builder must be a fury_spec_builder object")
  }

  builder$data$screening$eligibility$required_nonmissing <- vars
  builder$data$screening$eligibility$action <- "exclude"

  builder
}

#' Flag Cases with Missing Values (Don't Exclude)
#'
#' @param builder A `fury_spec_builder` object
#' @param vars Character vector. Variable names that must be non-missing
#'
#' @return Modified `fury_spec_builder` object
#' @export
fury_flag_missing <- function(builder, vars) {
  if (!inherits(builder, "fury_spec_builder")) {
    nicheCore::niche_abort("builder must be a fury_spec_builder object")
  }

  builder$data$screening$eligibility$required_nonmissing <- vars
  builder$data$screening$eligibility$action <- "flag"

  builder
}

#' Add Attention Check (Flag by Default)
#'
#' @param builder A `fury_spec_builder` object
#' @param var Character. Variable name of attention check
#' @param pass_values Numeric or character vector. Values that indicate passing
#' @param description Character. Description of the attention check
#' @param action Character. "flag" (default) or "exclude"
#'
#' @return Modified `fury_spec_builder` object
#' @export
fury_flag_attention <- function(builder, var, pass_values, description,
                                 action = "flag") {
  if (!inherits(builder, "fury_spec_builder")) {
    nicheCore::niche_abort("builder must be a fury_spec_builder object")
  }

  if (!action %in% c("flag", "exclude")) {
    nicheCore::niche_abort("action must be 'flag' or 'exclude'")
  }

  # Add to attention_checks list
  check <- list(
    var = var,
    pass_values = pass_values,
    description = description,
    action = action
  )

  builder$data$screening$quality_flags$attention_checks <- c(
    builder$data$screening$quality_flags$attention_checks,
    list(check)
  )

  builder
}

#' Export Spec Builder to YAML File
#'
#' Writes the spec builder to a YAML file that can be used with fury_run().
#' This file should be committed to version control and/or preregistered.
#'
#' @param builder A `fury_spec_builder` object
#' @param path Character. Output path for YAML file
#' @param overwrite Logical. Overwrite existing file? Default FALSE.
#'
#' @return Invisibly returns the builder object (for further piping)
#' @export
fury_to_yaml <- function(builder, path, overwrite = FALSE) {
  if (!inherits(builder, "fury_spec_builder")) {
    nicheCore::niche_abort("builder must be a fury_spec_builder object")
  }

  # Check if yaml package is available
  if (!requireNamespace("yaml", quietly = TRUE)) {
    nicheCore::niche_abort(
      paste0(
        "Package 'yaml' is required for fury_to_yaml().\n",
        "Install it with: install.packages(\"yaml\")"
      )
    )
  }

  # Check if file exists
  if (file.exists(path) && !overwrite) {
    nicheCore::niche_abort(
      paste0(
        "File already exists: ", path,
        "\nSet overwrite = TRUE to replace it."
      )
    )
  }

  # Convert to YAML
  yaml_content <- yaml::as.yaml(builder, indent.mapping.sequence = TRUE)

  # Write to file
  writeLines(yaml_content, path)

  cli::cli_alert_success("Spec written to {.file {path}}")
  cli::cli_alert_info(
    "Commit this file to version control or preregister it before data collection"
  )

  invisible(builder)
}

#' Print Spec Builder Summary
#'
#' @param x A `fury_spec_builder` object
#' @param ... Additional arguments (ignored)
#'
#' @return Invisibly returns the builder object
#' @export
print.fury_spec_builder <- function(x, ...) {
  cli::cli_h1("Fury Screening Spec Builder")

  # Data sources
  if (length(x$data$sources) > 0) {
    cli::cli_h2("Data Sources")
    for (i in seq_along(x$data$sources)) {
      src <- x$data$sources[[i]]
      cli::cli_li("{.file {src$file}} (format: {src$format})")
    }
  } else {
    cli::cli_alert_warning("No data sources declared")
  }

  # Partitioning
  has_partitioning <- length(x$data$screening$partitioning) > 0
  if (has_partitioning) {
    cli::cli_h2("Partitioning")
    if (!is.null(x$data$screening$partitioning$pilot)) {
      cli::cli_li("Pilot: {x$data$screening$partitioning$pilot$start} to {x$data$screening$partitioning$pilot$end}")
    }
    if (!is.null(x$data$screening$partitioning$pretest)) {
      cli::cli_li("Pretest: {x$data$screening$partitioning$pretest$start} to {x$data$screening$partitioning$pretest$end}")
    }
  }

  # Eligibility
  has_eligibility <- !is.null(x$data$screening$eligibility$required_nonmissing)
  if (has_eligibility) {
    cli::cli_h2("Eligibility Rules")
    vars <- paste(x$data$screening$eligibility$required_nonmissing, collapse = ", ")
    action <- x$data$screening$eligibility$action
    cli::cli_li("Required non-missing: {vars} (action: {action})")
  }

  # Quality checks
  n_checks <- length(x$data$screening$quality_flags$attention_checks)
  if (n_checks > 0) {
    cli::cli_h2("Quality Checks")
    cli::cli_li("{n_checks} attention check{?s} declared")
  }

  # Next steps
  cli::cli_h2("Next Steps")
  cli::cli_li("Export to YAML: {.code fury_to_yaml(spec, \"my_spec.yaml\")}")
  cli::cli_li("Run screening: {.code fury_run(\"my_spec.yaml\")}")

  invisible(x)
}
