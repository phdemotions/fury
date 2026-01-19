# Script to create minimal test SPSS fixture for fury package
# This creates a tiny non-licensed toy dataset for testing .sav ingestion
# Run this script manually if you need to regenerate the fixture

if (!requireNamespace("haven", quietly = TRUE)) {
  stop("haven package required to create .sav fixture")
}

# Create minimal toy dataset with labelled variables
test_data <- data.frame(
  participant_id = 1:5,
  condition = c(1, 2, 1, 2, 1),
  satisfaction = c(7, 5, 6, 4, 7),
  would_recommend = c(1, 0, 1, 0, 1),
  age_group = c(1, 2, 3, 2, 1),
  comments = c("Great", "Okay", "Good", NA, "Excellent"),
  stringsAsFactors = FALSE
)

# Add value labels for labelled variables FIRST
test_data$condition <- haven::labelled(
  test_data$condition,
  labels = c("Control" = 1, "Treatment" = 2),
  label = "Experimental condition assignment"
)

test_data$satisfaction <- haven::labelled(
  test_data$satisfaction,
  labels = c(
    "Extremely dissatisfied" = 1,
    "Dissatisfied" = 2,
    "Somewhat dissatisfied" = 3,
    "Neutral" = 4,
    "Somewhat satisfied" = 5,
    "Satisfied" = 6,
    "Extremely satisfied" = 7
  ),
  label = "How satisfied are you with the product?"
)

test_data$would_recommend <- haven::labelled(
  test_data$would_recommend,
  labels = c("No" = 0, "Yes" = 1),
  label = "Would you recommend this product to a friend?"
)

test_data$age_group <- haven::labelled(
  test_data$age_group,
  labels = c("18-24" = 1, "25-34" = 2, "35-44" = 3, "45-54" = 4, "55+" = 5),
  label = "What is your age group?"
)

# Add variable labels (item text) for non-labelled variables
attr(test_data$participant_id, "label") <- "Participant ID"
attr(test_data$comments, "label") <- "Additional comments (open-ended)"

# Write as SPSS .sav file
out_path <- file.path("inst", "extdata", "test_minimal.sav")
haven::write_sav(test_data, out_path)

message("Created test fixture: ", out_path)
message("File size: ", file.size(out_path), " bytes")
message("Variables: ", ncol(test_data))
message("Observations: ", nrow(test_data))
