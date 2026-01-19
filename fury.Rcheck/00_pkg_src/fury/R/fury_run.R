#' Run the Complete fury Workflow from a Spec File
#'
#' Novice-friendly entry point that reads a spec file, validates it,
#' builds a recipe, and executes data ingestion with audit artifacts.
#'
#' This function orchestrates the full fury workflow:
#' 1. Reads and validates the spec via `vision::read_spec()` and `vision::validate_spec()`
#' 2. Builds a recipe via `vision::build_recipe()`
#' 3. Executes the recipe via `fury_execute_recipe()`
#'
#' @param spec_path Character scalar. Path to a spec file (YAML or JSON).
#' @param out_dir Character scalar. Output directory for audit artifacts.
#'   Defaults to `tempdir()`. Directory will be created if it does not exist.
#'
#' @return A `niche_result` object (defined by nicheCore) containing audit
#'   artifacts and metadata.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Create a minimal spec
#' spec_path <- tempfile(fileext = ".yaml")
#' vision::write_spec_template(spec_path)
#'
#' # Run fury workflow
#' result <- fury_run(spec_path)
#' print(result)
#' }
fury_run <- function(spec_path, out_dir = tempdir()) {
  # Input validation
  nicheCore::assert_is_scalar_character(spec_path)
  nicheCore::assert_is_existing_file(spec_path)
  nicheCore::assert_is_scalar_character(out_dir)

  # Read and validate spec
  spec <- vision::read_spec(spec_path)
  vision::validate_spec(spec)

  # Build recipe
  recipe <- vision::build_recipe(spec)

  # Execute recipe
  fury_execute_recipe(recipe, out_dir = out_dir)
}
