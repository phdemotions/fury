# RAW Codebook Generation
#
# Generates reviewer-legible, APA7-friendly RAW documentation artifacts
# that inventory variables exactly as observed at import.
# NO analysis, scoring, recoding, or construct claims.

#' Generate RAW Codebook from Data
#'
#' Creates a codebook table that inventories variables exactly as imported.
#' Includes response-option format details suitable for APA7 Methods reporting.
#'
#' @param data Data frame (possibly with haven_labelled columns).
#' @param source_file Character scalar. Source file name for provenance.
#' @param wave Character scalar. Wave identifier (default: NA).
#' @param module Character scalar. Module identifier (default: NA).
#' @param language Character scalar. Language identifier (default: NA).
#'
#' @return Data frame with RAW codebook columns in stable order.
#' @noRd
fury_codebook_raw <- function(data,
                               source_file,
                               wave = NA_character_,
                               module = NA_character_,
                               language = NA_character_) {
  # Validate inputs
  stopifnot(is.data.frame(data))
  nicheCore::assert_is_scalar_character(source_file)

  # Initialize codebook rows (one per variable)
  n_vars <- ncol(data)
  var_names <- names(data)

  codebook_rows <- vector("list", n_vars)

  for (i in seq_len(n_vars)) {
    var_name <- var_names[i]
    x <- data[[var_name]]

    # Extract metadata
    var_label <- attr(x, "label")
    if (is.null(var_label)) var_label <- NA_character_
    var_label <- as.character(var_label)[1]

    # item_text_raw: best-available verbatim item text
    # For .sav, use var_label verbatim when present
    item_text_raw <- if (!is.na(var_label)) var_label else NA_character_

    # storage_class: exact R class
    storage_class <- paste(class(x), collapse = ",")

    # is_haven_labelled
    is_haven_labelled <- inherits(x, "haven_labelled")

    # Extract value labels if present
    value_labels <- NULL
    if (is_haven_labelled) {
      value_labels <- attr(x, "labels")
    }

    # response_scale_type (descriptive only; deterministic)
    response_scale_type <- fury_classify_response_scale_(x, value_labels)

    # response_scale_n_options
    response_scale_n_options <- if (!is.null(value_labels)) {
      length(value_labels)
    } else {
      NA_integer_
    }

    # response_scale_min_label / max_label
    min_max_labels <- fury_extract_min_max_labels_(value_labels)
    response_scale_min_label <- min_max_labels$min_label
    response_scale_max_label <- min_max_labels$max_label

    # value_labels_preview (deterministic)
    value_labels_preview <- fury_format_value_labels_preview_(value_labels)

    # value_labels_ref
    value_labels_ref <- if (!is.null(value_labels)) {
      paste0("raw_codebook_value_labels.json#", var_name)
    } else {
      NA_character_
    }

    # user_missing (SPSS user-missing codes)
    user_missing <- fury_extract_user_missing_(x)

    # Missingness stats
    n_total <- length(x)
    n_missing <- sum(is.na(x))
    n_non_missing <- n_total - n_missing
    pct_missing <- if (n_total > 0) {
      round(100 * n_missing / n_total, 2)
    } else {
      NA_real_
    }

    # distinct_values (count distinct non-missing underlying values)
    distinct_values <- fury_count_distinct_(x)

    # Assemble row
    codebook_rows[[i]] <- data.frame(
      var_name = var_name,
      item_text_raw = item_text_raw,
      var_label = var_label,
      storage_class = storage_class,
      is_haven_labelled = is_haven_labelled,
      response_scale_type = response_scale_type,
      response_scale_n_options = response_scale_n_options,
      response_scale_min_label = response_scale_min_label,
      response_scale_max_label = response_scale_max_label,
      value_labels_preview = value_labels_preview,
      value_labels_ref = value_labels_ref,
      user_missing = user_missing,
      n_non_missing = n_non_missing,
      n_missing = n_missing,
      pct_missing = pct_missing,
      distinct_values = distinct_values,
      source_file = source_file,
      wave = wave,
      module = module,
      language = language,
      stringsAsFactors = FALSE
    )
  }

  # Combine rows
  codebook <- do.call(rbind, codebook_rows)

  # Stable ordering: group by provenance, then alphabetical by var_name
  codebook <- nicheCore::stable_order(
    codebook,
    cols = c("source_file", "wave", "module", "language", "var_name")
  )

  codebook
}


#' Classify Response Scale Type (Descriptive Only)
#'
#' @param x Vector (variable column).
#' @param value_labels Named vector of value labels (or NULL).
#' @return Character scalar (response_scale_type).
#' @noRd
fury_classify_response_scale_ <- function(x, value_labels) {
  is_labelled <- inherits(x, "haven_labelled")

  if (is_labelled && !is.null(value_labels) && length(value_labels) > 0) {
    return("labelled_options")
  }

  if (is.character(x)) {
    return("free_text")
  }

  if (is.numeric(x) && !is_labelled) {
    return("numeric_unlabelled")
  }

  if (inherits(x, c("Date", "POSIXct", "POSIXt")) && !is_labelled) {
    return("datetime_unlabelled")
  }

  "unknown"
}


#' Extract Min/Max Labels from Value Labels
#'
#' @param value_labels Named vector from haven (names = labels, values = codes).
#' @return List with min_label and max_label (or NA).
#' @noRd
fury_extract_min_max_labels_ <- function(value_labels) {
  if (is.null(value_labels) || length(value_labels) == 0) {
    return(list(min_label = NA_character_, max_label = NA_character_))
  }

  # Haven structure: names = labels, values = codes
  # We need to sort by codes (the values), then extract labels (the names)
  codes <- as.numeric(value_labels)
  labels <- names(value_labels)

  # Sort by codes
  codes_num <- suppressWarnings(as.numeric(codes))

  if (all(!is.na(codes_num))) {
    # Numeric codes
    sorted_idx <- order(codes_num)
  } else {
    # Lexicographic (unlikely for haven)
    sorted_idx <- order(codes)
  }

  sorted_labels <- labels[sorted_idx]

  min_label <- sorted_labels[1]
  max_label <- sorted_labels[length(sorted_labels)]

  list(min_label = min_label, max_label = max_label)
}


#' Format Value Labels Preview (Deterministic)
#'
#' @param value_labels Named vector from haven (names = labels, values = codes).
#' @return Character scalar (preview string).
#' @noRd
fury_format_value_labels_preview_ <- function(value_labels) {
  if (is.null(value_labels) || length(value_labels) == 0) {
    return("(none)")
  }

  # Haven structure: names = labels, values = codes
  codes <- as.numeric(value_labels)
  labels <- names(value_labels)

  # Sort by codes deterministically
  codes_num <- suppressWarnings(as.numeric(codes))

  if (all(!is.na(codes_num))) {
    sorted_idx <- order(codes_num)
  } else {
    sorted_idx <- order(codes)
  }

  sorted_codes <- codes[sorted_idx]
  sorted_labels <- labels[sorted_idx]

  # Take first 10
  n_total <- length(sorted_codes)
  n_preview <- min(10, n_total)

  preview_codes <- sorted_codes[seq_len(n_preview)]
  preview_labels <- sorted_labels[seq_len(n_preview)]

  # Format as "code = label; code = label; ..."
  preview_parts <- paste0(preview_codes, " = ", preview_labels)
  preview_str <- paste(preview_parts, collapse = "; ")

  # Append "... (+N more)" if truncated
  if (n_total > 10) {
    n_more <- n_total - 10
    preview_str <- paste0(preview_str, " ... (+", n_more, " more)")
  }

  preview_str
}


#' Extract SPSS User-Missing Metadata
#'
#' @param x Vector (variable column).
#' @return Character scalar (user-missing description or NA).
#' @noRd
fury_extract_user_missing_ <- function(x) {
  # Attempt to extract user-missing codes from haven attributes
  # (This is a simplified extraction; full SPSS user-missing is complex)
  na_values <- attr(x, "na_values")
  na_range <- attr(x, "na_range")

  if (!is.null(na_values) || !is.null(na_range)) {
    parts <- character(0)
    if (!is.null(na_values)) {
      parts <- c(parts, paste0("values: ", paste(na_values, collapse = ", ")))
    }
    if (!is.null(na_range)) {
      parts <- c(parts, paste0("range: ", na_range[1], " to ", na_range[2]))
    }
    return(paste(parts, collapse = "; "))
  }

  NA_character_
}


#' Count Distinct Non-Missing Values
#'
#' @param x Vector (variable column).
#' @return Integer (count of distinct non-missing values).
#' @noRd
fury_count_distinct_ <- function(x) {
  # For haven_labelled, count underlying values
  if (inherits(x, "haven_labelled")) {
    x_underlying <- unclass(x)
  } else {
    x_underlying <- x
  }

  x_non_missing <- x_underlying[!is.na(x_underlying)]
  length(unique(x_non_missing))
}


#' Build Full Value Labels JSON Artifact
#'
#' Creates a JSON artifact with full value-label mappings for all variables
#' that have value labels.
#'
#' @param data Data frame (possibly with haven_labelled columns).
#' @return List (JSON-ready structure).
#' @noRd
fury_build_value_labels_json_ <- function(data) {
  var_names <- names(data)
  result <- list()

  for (var_name in var_names) {
    x <- data[[var_name]]
    value_labels <- NULL

    if (inherits(x, "haven_labelled")) {
      value_labels <- attr(x, "labels")
    }

    if (!is.null(value_labels) && length(value_labels) > 0) {
      # Haven structure: names = labels, values = codes
      codes <- as.numeric(value_labels)
      labels <- names(value_labels)

      # Sort by codes deterministically
      codes_num <- suppressWarnings(as.numeric(codes))

      if (all(!is.na(codes_num))) {
        sorted_idx <- order(codes_num)
      } else {
        sorted_idx <- order(codes)
      }

      sorted_codes <- codes[sorted_idx]
      sorted_labels <- labels[sorted_idx]

      # Build array of {code, label} objects
      mapping <- lapply(seq_along(sorted_codes), function(i) {
        list(
          code = as.character(sorted_codes[i]),
          label = sorted_labels[i]
        )
      })

      result[[var_name]] <- mapping
    }
  }

  result
}


#' Generate Methods Helper Table (Items + Response Scales)
#'
#' Creates a novice-friendly table for APA7 Methods reporting.
#' Contains ONLY inventory-level fields: item wording + response-option format.
#' NO construct claims, reliability, scoring, or analysis.
#'
#' @param codebook Data frame (RAW codebook).
#' @return Data frame (methods helper table).
#' @noRd
fury_methods_helper_table_ <- function(codebook) {
  # Select only the columns relevant for Methods reporting
  methods_cols <- c(
    "var_name",
    "item_text_raw",
    "response_scale_type",
    "response_scale_n_options",
    "response_scale_min_label",
    "response_scale_max_label",
    "value_labels_ref",
    "source_file",
    "wave",
    "module",
    "language"
  )

  codebook[, methods_cols, drop = FALSE]
}


#' Generate RAW Codebook Column Dictionary
#'
#' Returns fixed text defining RAW codebook columns with required disclaimers.
#'
#' @return Character vector (lines of text).
#' @noRd
fury_codebook_column_dictionary_ <- function() {
  c(
    "RAW CODEBOOK COLUMN DEFINITIONS",
    "=================================",
    "",
    "This RAW codebook inventories variables exactly as observed at import.",
    "No recoding, scoring, validation, exclusions, or construct claims are performed by fury.",
    "",
    "TERMINOLOGY NOTE:",
    "The term 'response scale' refers only to response-option format/anchors",
    "(e.g., labelled response options). It does not imply a psychometric scale",
    "or construct measurement.",
    "",
    "COLUMN DEFINITIONS:",
    "",
    "var_name",
    "  Variable name as it appears in the raw import (no renaming).",
    "",
    "item_text_raw",
    "  Best-available verbatim item/question text at import.",
    "  For SPSS .sav files, this is the variable label if present; else NA.",
    "  No cleaning of punctuation, whitespace, or language is performed.",
    "",
    "var_label",
    "  Haven variable label if present; else NA.",
    "",
    "storage_class",
    "  R storage class as reported by class() (e.g., 'haven_labelled,numeric').",
    "",
    "is_haven_labelled",
    "  Logical. TRUE if the variable inherits from haven_labelled class.",
    "",
    "response_scale_type",
    "  Descriptive classification of response-option format (deterministic):",
    "    - 'labelled_options': haven_labelled with non-empty value labels",
    "    - 'free_text': character vector",
    "    - 'numeric_unlabelled': numeric without labels",
    "    - 'datetime_unlabelled': Date/POSIXct without labels",
    "    - 'unknown': other",
    "",
    "response_scale_n_options",
    "  Number of labelled response options if present; else NA.",
    "",
    "response_scale_min_label",
    "  Label at minimum code value (after sorting codes numerically/lexicographically).",
    "  NA if no value labels present.",
    "",
    "response_scale_max_label",
    "  Label at maximum code value (after sorting codes numerically/lexicographically).",
    "  NA if no value labels present.",
    "",
    "value_labels_preview",
    "  Deterministic preview of up to the first 10 value labels in sorted code order.",
    "  Format: 'code = label; code = label; ...'",
    "  If more than 10 labels, appends '... (+N more)'.",
    "  If none, displays '(none)'.",
    "",
    "value_labels_ref",
    "  Reference to full value-label mapping artifact (JSON file).",
    "  Format: 'raw_codebook_value_labels.json#<var_name>'",
    "  NA if no value labels present.",
    "",
    "user_missing",
    "  SPSS user-missing metadata (if extractable from haven attributes).",
    "  NA if not available. No values are recoded or dropped based on this field.",
    "",
    "n_non_missing",
    "  Count of non-missing observations (based on is.na() as observed at import).",
    "",
    "n_missing",
    "  Count of missing observations (based on is.na() as observed at import).",
    "",
    "pct_missing",
    "  Percentage of missing observations (rounded to 2 decimal places).",
    "",
    "distinct_values",
    "  Number of distinct non-missing values observed.",
    "  For haven_labelled vectors, counts distinct underlying values.",
    "",
    "source_file",
    "  Source file name for provenance tracking.",
    "",
    "wave",
    "  Wave identifier (if applicable); else NA.",
    "",
    "module",
    "  Module identifier (if applicable); else NA.",
    "",
    "language",
    "  Language identifier (if applicable); else NA.",
    ""
  )
}
