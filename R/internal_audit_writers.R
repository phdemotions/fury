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
#' @return NULL (invisibly)
#' @noRd
fury_write_raw_codebook <- function(audit_dir) {
  codebook <- data.frame(
    source_id = character(0),
    variable_name = character(0),
    variable_type = character(0),
    n_missing = integer(0),
    n_unique = integer(0),
    stringsAsFactors = FALSE
  )

  codebook <- nicheCore::stable_order(
    codebook,
    cols = c("source_id", "variable_name")
  )

  out_path <- fs::path(audit_dir, "raw_codebook.csv")
  nicheCore::write_audit_csv(codebook, out_path)

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
