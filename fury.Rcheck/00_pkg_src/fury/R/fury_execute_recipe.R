#' Execute a Recipe to Produce Audit Artifacts
#'
#' Takes a validated `niche_recipe` and produces audit artifacts
#' in the specified output directory.
#'
#' This is the core execution function of fury. It creates output directories,
#' generates audit artifacts (source manifest, import log, codebook, session info),
#' and returns a `niche_result` object.
#'
#' @param recipe A `niche_recipe` object built by `vision::build_recipe()`.
#' @param out_dir Character scalar. Output directory for audit artifacts.
#'   Defaults to `tempdir()`. Directory will be created if it does not exist.
#'
#' @return A `niche_result` object (defined by nicheCore) containing paths
#'   to audit artifacts and execution metadata.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Assuming you have a recipe
#' spec <- vision::read_spec("path/to/spec.yaml")
#' recipe <- vision::build_recipe(spec)
#' result <- fury_execute_recipe(recipe)
#' }
fury_execute_recipe <- function(recipe, out_dir = tempdir()) {
  # Input validation
  if (!nicheCore::is_niche_recipe(recipe)) {
    nicheCore::niche_abort("recipe must be a niche_recipe object")
  }
  nicheCore::validate_niche_recipe(recipe)
  nicheCore::assert_is_scalar_character(out_dir)

  # Create output paths (nicheCore creates standard subdirs including audit/)
  paths <- nicheCore::niche_output_paths(out_dir)

  # Write recipe to audit directory
  recipe_path <- fs::path(paths$audit, "recipe.json")
  vision::write_recipe(recipe, recipe_path)

  # Generate placeholder audit artifacts
  fury_write_source_manifest(paths$audit)
  fury_write_import_log(paths$audit)
  fury_write_raw_codebook(paths$audit)
  fury_write_session_info(paths$audit)

  # Construct niche_result with required fields per nicheCore contract
  result <- nicheCore::new_niche_result(list(
    recipe = recipe,
    outputs = list(),  # No outputs yet (placeholder)
    artifacts = list(
      audit_dir = paths$audit,
      recipe_path = recipe_path,
      source_manifest = fs::path(paths$audit, "source_manifest.csv"),
      import_log = fs::path(paths$audit, "import_log.csv"),
      raw_codebook = fs::path(paths$audit, "raw_codebook.csv"),
      session_info = fs::path(paths$audit, "session_info.txt")
    ),
    session_info = utils::sessionInfo(),
    warnings = character(0),
    created = Sys.time(),
    # fury-specific optional fields
    fury_metadata = list(
      package = "fury",
      version = utils::packageVersion("fury"),
      out_dir = out_dir
    )
  ))

  nicheCore::validate_niche_result(result)
  result
}
