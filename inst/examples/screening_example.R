# Example: Using fury Screening (Simple Mode)
#
# This example demonstrates how to use fury's CONSORT-style screening
# with SIMPLE MODE (novice-friendly, no predicates required).
#
# Primary creator & maintainer-of-record: Josh Gonzales (GitHub: phdemotions)
# Part of the niche R universe

# Create example data
survey_data <- data.frame(
  response_id = 1:20,
  start_time = as.Date(c(
    # Pretest (3 cases)
    "2024-01-10", "2024-01-11", "2024-01-12",
    # Pilot (2 cases)
    "2024-01-20", "2024-01-21",
    # Main study (15 cases)
    rep("2024-02-01", 15)
  )),
  age = c(25, NA, 30, 35, NA, 40, 45, 50, NA, 55,
          60, 22, 28, 33, 38, 42, 47, 52, 57, 62),
  consent = c(1, 1, 1, NA, 1, 1, 1, 1, 1, 1,
              1, 1, 1, 1, NA, 1, 1, 1, 1, 1),
  attn_check_1 = c(3, 3, 2, 3, 1, 3, 3, 2, 3, 3,
                   3, 3, 3, 2, 3, 3, 1, 3, 3, 3),
  attn_check_2 = c("correct", "correct", "wrong", "correct", "correct",
                   "correct", "wrong", "correct", "correct", "correct",
                   "correct", "correct", "correct", "correct", "correct",
                   "wrong", "correct", "correct", "correct", "correct")
)

# Define screening configuration (SIMPLE MODE)
screening_config <- list(
  # Partition cases by date ranges
  partitioning = list(
    pretest = list(
      by = "date_range",
      date_var = "start_time",
      start = "2024-01-01",
      end = "2024-01-15"
    ),
    pilot = list(
      by = "date_range",
      date_var = "start_time",
      start = "2024-01-16",
      end = "2024-01-31"
    )
    # Remainder automatically assigned to "main" partition
  ),

  # Eligibility criteria (design-defined)
  eligibility = list(
    required_nonmissing = c("age", "consent"),
    action = "exclude"  # Default for eligibility
  ),

  # Quality flags (attention checks)
  quality_flags = list(
    attention_checks = list(
      list(
        var = "attn_check_1",
        pass_values = c(3),
        action = "flag",
        description = "Attention check 1: Please select 3"
      ),
      list(
        var = "attn_check_2",
        pass_values = c("correct"),
        action = "flag",
        description = "Attention check 2: Select 'correct'"
      )
    ),
    default_action = "flag"
  )
)

# Compile rules from simple mode config
rules <- fury:::fury_compile_rules_(screening_config, survey_data)

print("Compiled Rules:")
print(rules)

# Apply screening rules to data
screened_data <- fury:::fury_screen(survey_data, rules, drop_excluded = FALSE)

print("\nScreened Data (first 10 rows):")
print(screened_data[1:10, c("response_id", ".fury_partition", ".fury_excluded",
                             ".fury_pool_main", ".fury_pool_note")])

# Generate CONSORT artifacts
temp_audit <- tempdir()
artifacts <- fury:::fury_write_screening_artifacts(screened_data, rules, temp_audit)

print("\nGenerated Artifacts:")
print(names(artifacts))

# Read and display screening summary (novice-friendly)
screening_summary <- read.csv(artifacts$screening_summary)
print("\nScreening Summary:")
print(screening_summary)

# Read and display CONSORT flow
consort_flow <- read.csv(artifacts$consort_flow)
print("\nCONSORT Flow:")
print(consort_flow)

# Key takeaways:
# - Pretest cases are NOT in analysis-eligible pool (.fury_pool_main = FALSE)
# - Pilot cases ARE in pool but explicitly noted via .fury_partition
# - Exclusions are logged with rule_id in .fury_excluded_by
# - Flags do NOT exclude, just mark for researcher attention
# - Language is conservative: "analysis-eligible pool (declared)" not "final sample"
