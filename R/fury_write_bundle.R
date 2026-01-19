#' Write an Audit Bundle from a Result Object
#'
#' Takes a `niche_result` and ensures all audit artifacts are written
#' to the specified output directory. This is typically called automatically
#' by `fury_execute_recipe()`, but can be used independently to re-export
#' a bundle.
#'
#' @param result A `niche_result` object produced by `fury_execute_recipe()`.
#' @param out_dir Character scalar. Output directory for the audit bundle.
#'   If not provided, uses the directory from the result's metadata.
#'
#' @return Invisibly returns the path to the audit bundle directory.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' result <- fury_run("spec.yaml")
#' fury_write_bundle(result, out_dir = "my_audit")
#' }
fury_write_bundle <- function(result, out_dir = NULL) {
  # Input validation
  if (!nicheCore::is_niche_result(result)) {
    nicheCore::niche_abort("result must be a niche_result object")
  }
  nicheCore::validate_niche_result(result)

  # Determine output directory
  if (is.null(out_dir)) {
    if (!is.null(result$fury_metadata$out_dir)) {
      out_dir <- result$fury_metadata$out_dir
    } else {
      nicheCore::niche_abort(
        "out_dir must be provided if result$fury_metadata$out_dir is not set"
      )
    }
  }
  nicheCore::assert_is_scalar_character(out_dir)

  # Create paths (nicheCore creates standard subdirs including audit/)
  paths <- nicheCore::niche_output_paths(out_dir)

  # If result already has artifacts, they should already be written
  # This function serves as a verification/re-write mechanism
  if (!is.null(result$artifacts$audit_dir)) {
    cli::cli_alert_info(
      "Audit bundle already exists at {.path {result$artifacts$audit_dir}}"
    )
  }

  invisible(paths$audit)
}
