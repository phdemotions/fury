# Internal Audit Artifact Writers
#
# These functions generate placeholder audit artifacts for the initial
# fury skeleton. They produce deterministic, reviewer-legible outputs
# that will be replaced with real ingestion logic in future iterations.
#
# All functions write directly to the specified audit directory and
# return NULL invisibly.

#' Write Source Manifest Placeholder
#'
#' @param audit_dir Path to audit directory
#' @return NULL (invisibly)
#' @noRd
fury_write_source_manifest <- function(audit_dir) {
  manifest <- data.frame(
    source_id = character(0),
    file_path = character(0),
    file_hash = character(0),
    file_size_bytes = numeric(0),
    row_count = integer(0),
    stringsAsFactors = FALSE
  )

  manifest <- nicheCore::stable_order(manifest, cols = "source_id")

  out_path <- fs::path(audit_dir, "source_manifest.csv")
  nicheCore::write_audit_csv(manifest, out_path)

  invisible(NULL)
}

#' Write Import Log Placeholder
#'
#' @param audit_dir Path to audit directory
#' @return NULL (invisibly)
#' @noRd
fury_write_import_log <- function(audit_dir) {
  import_log <- data.frame(
    step = character(0),
    source_id = character(0),
    n_rows_in = integer(0),
    n_rows_out = integer(0),
    n_rows_dropped = integer(0),
    message = character(0),
    stringsAsFactors = FALSE
  )

  import_log <- nicheCore::stable_order(import_log, cols = c("step", "source_id"))

  out_path <- fs::path(audit_dir, "import_log.csv")
  nicheCore::write_audit_csv(import_log, out_path)

  invisible(NULL)
}

#' Write Raw Codebook Placeholder
#'
#' @param audit_dir Path to audit directory
#' @param data Data frame (optional; if NULL, writes empty placeholder)
#' @param source_file Character scalar (source file name)
#' @param wave Character scalar (wave identifier; default NA)
#' @param module Character scalar (module identifier; default NA)
#' @param language Character scalar (language identifier; default NA)
#' @return NULL (invisibly)
#' @noRd
fury_write_raw_codebook <- function(audit_dir,
                                     data = NULL,
                                     source_file = NA_character_,
                                     wave = NA_character_,
                                     module = NA_character_,
                                     language = NA_character_) {
  if (is.null(data)) {
    # Write empty placeholder (original behavior)
    codebook <- data.frame(
      var_name = character(0),
      item_text_raw = character(0),
      var_label = character(0),
      storage_class = character(0),
      is_haven_labelled = logical(0),
      response_scale_type = character(0),
      response_scale_n_options = integer(0),
      response_scale_min_label = character(0),
      response_scale_max_label = character(0),
      value_labels_preview = character(0),
      value_labels_ref = character(0),
      user_missing = character(0),
      n_non_missing = integer(0),
      n_missing = integer(0),
      pct_missing = numeric(0),
      distinct_values = integer(0),
      source_file = character(0),
      wave = character(0),
      module = character(0),
      language = character(0),
      stringsAsFactors = FALSE
    )
  } else {
    # Generate real codebook from data
    codebook <- fury_codebook_raw(
      data = data,
      source_file = source_file,
      wave = wave,
      module = module,
      language = language
    )
  }

  codebook <- nicheCore::stable_order(
    codebook,
    cols = c("source_file", "wave", "module", "language", "var_name")
  )

  out_path <- fs::path(audit_dir, "raw_codebook.csv")
  nicheCore::write_audit_csv(codebook, out_path)

  # Write value labels JSON if data provided
  if (!is.null(data)) {
    value_labels_json <- fury_build_value_labels_json_(data)
    json_path <- fs::path(audit_dir, "raw_codebook_value_labels.json")
    nicheCore::write_audit_json(value_labels_json, json_path)

    # Write methods helper table
    methods_table <- fury_methods_helper_table_(codebook)
    methods_path <- fs::path(audit_dir, "methods_items_response_scales.csv")
    nicheCore::write_audit_csv(methods_table, methods_path)

    # Write codebook column dictionary
    dictionary_lines <- fury_codebook_column_dictionary_()
    dictionary_path <- fs::path(audit_dir, "raw_codebook_columns.txt")
    writeLines(dictionary_lines, dictionary_path)
  }

  invisible(NULL)
}

#' Write Session Info
#'
#' Deterministic session information capturing R version and loaded packages.
#'
#' @param audit_dir Path to audit directory
#' @return NULL (invisibly)
#' @noRd
fury_write_session_info <- function(audit_dir) {
  # Capture session info
  si <- utils::sessionInfo()

  # Format as text with stable ordering
  lines <- c(
    "fury Session Information",
    "========================",
    "",
    paste("R version:", si$R.version$version.string),
    paste("Platform:", si$platform),
    "",
    "Loaded packages:",
    ""
  )

  # Extract and sort package info
  pkgs <- c(si$basePkgs, names(si$otherPkgs), names(si$loadedOnly))
  pkgs <- unique(pkgs)
  pkgs <- sort(pkgs)

  pkg_lines <- paste0("  - ", pkgs)
  lines <- c(lines, pkg_lines)

  out_path <- fs::path(audit_dir, "session_info.txt")
  writeLines(lines, out_path)

  invisible(NULL)
}

#' Write Warnings Artifact
#'
#' Deterministic warnings log capturing risk states detected during screening.
#' Warnings are persisted into audit bundle, not just console output.
#'
#' @param warnings_list List of warning data frames
#' @param audit_dir Path to audit directory
#' @return NULL (invisibly)
#' @noRd
fury_write_warnings <- function(warnings_list, audit_dir) {
  if (length(warnings_list) == 0) {
    # Write empty warnings file
    warnings_df <- data.frame(
      warning_id = character(0),
      severity = character(0),
      message = character(0),
      related_artifact = character(0),
      stringsAsFactors = FALSE
    )
  } else {
    warnings_df <- do.call(rbind, warnings_list)
    warnings_df <- nicheCore::stable_order(warnings_df, cols = "warning_id")
  }

  out_path <- fs::path(audit_dir, "warnings.csv")
  nicheCore::write_audit_csv(warnings_df, out_path)

  invisible(NULL)
}

#' Write Decision Registry Artifact
#'
#' Deterministic decision registry documenting whether key partitioning,
#' eligibility, and quality decisions were declared by the user.
#' No inference; only observable facts from spec/recipe/data.
#'
#' @param decision_registry Data frame with decision keys and values
#' @param audit_dir Path to audit directory
#' @return NULL (invisibly)
#' @noRd
fury_write_decision_registry <- function(decision_registry, audit_dir) {
  decision_registry <- nicheCore::stable_order(
    decision_registry,
    cols = "decision_key"
  )

  out_path <- fs::path(audit_dir, "decision_registry.csv")
  nicheCore::write_audit_csv(decision_registry, out_path)

  invisible(NULL)
}
