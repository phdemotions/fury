#' Return the Scope Statement for fury
#'
#' Returns a character string describing what fury does and does not do.
#' Used in documentation and tests to prevent scope drift.
#'
#' @return A character string describing fury's scope.
#'
#' @export
#'
#' @examples
#' fury_scope()
fury_scope <- function() {
  paste(
    "fury is a pre-analysis data ingestion and audit layer.",
    "It consumes validated niche_spec and niche_recipe objects,",
    "orchestrates data ingestion, and produces audit artifacts.",
    "fury does NOT perform modeling, scoring, construct validation,",
    "or APA rendering."
  )
}
