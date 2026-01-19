# Internal SPSS .sav Reader
#
# Reads SPSS .sav files using haven package, preserving haven_labelled columns
# exactly as imported. This is an internal function, not exported.

#' Read SPSS .sav File
#'
#' Internal reader for SPSS .sav files. Requires haven package (Suggests).
#' Preserves haven_labelled columns as-is without conversion.
#'
#' @param path Character scalar. Path to .sav file.
#' @param ... Additional arguments (reserved for future use).
#'
#' @return Data frame with haven_labelled columns preserved.
#' @noRd
fury_read_sav_ <- function(path, ...) {
  # Validate input
  nicheCore::assert_is_scalar_character(path)
  nicheCore::assert_is_existing_file(path)

  # Check haven availability
  if (!requireNamespace("haven", quietly = TRUE)) {
    nicheCore::niche_abort(
      "Reading SPSS .sav files requires the 'haven' package. Install it with install.packages('haven') and re-run."
    )
  }

  # Capture warnings during import
  import_warnings <- character(0)

  withCallingHandlers(
    {
      # Read .sav file (preserves haven_labelled classes)
      data <- haven::read_sav(file = path, ...)
    },
    warning = function(w) {
      import_warnings <<- c(import_warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  # Attach warnings as attribute for audit trail
  attr(data, "import_warnings") <- import_warnings

  data
}
