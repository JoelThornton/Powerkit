# Replication plan review fixes (18 November 2026): guidance follows the
# "Show explanations" switch, an original analysed with both a test and a
# Bayes factor, and "Not worth replicating" skipping the planning steps.

test_that("replication help is labelled or attached to its input", {
  note <- as.character(rep_note("First sentence here. Second sentence follows.", label = "What this setting does"))
  expect_match(note, "<summary>What this setting does</summary>", fixed = TRUE)
  expect_no_match(note, "explanation-help", fixed = TRUE)
  field <- as.character(rep_field("x_id", "A label", help = "This explains the field."))
  expect_match(field, 'aria-describedby="x_id_help"', fixed = TRUE)
  expect_match(field, 'id="x_id_help">This explains the field.', fixed = TRUE)
  html <- as.character(replication_workspace_ui(tree))
  expect_length(regmatches(html, gregexpr("How to interpret the between-study SD", html, fixed = TRUE))[[1]], 1)
  expect_match(html, 'name="rep_threshold" value="10" checked="checked"', fixed = TRUE)
})

both <- list(rep_design = "two_groups", rep_analysis = "both", rep_effect = "0.5", rep_n1 = "40", rep_n2 = "40",
  rep_bf_both = "3.2", rep_prior_scale = "0.707", rep_original_alpha = "0.05", rep_alpha = "0.05", rep_power = "0.8",
  rep_tau = "0.05", rep_goal = "significance", rep_prior = "uncertain")

test_that("an original analysed with both a test and a Bayes factor plans from the test, and keeps the Bayes factor", {
  expect_true("both" %in% replication_analyses_ui)
  args <- replication_args(both)
  # The engine sees a test: the effect comes from its most direct report.
  expect_null(args$original_analysis)
  expect_equal(args$original_effect, 0.5)
  expect_null(args$original_bf)
  # The Bayes factor's prior scale repeats the original's own test.
  expect_equal(args$original_prior_scale, 0.707)
  expect_length(replication_missing(both), 0)
  # The Bayes factor is optional.
  expect_length(replication_missing(modifyList(both, list(rep_bf_both = ""))), 0)
  expect_identical(replication_missing(modifyList(both, list(rep_effect = ""))), "the effect the original study reported")
  report <- paste(replication_report(both), collapse = "\n")
  expect_match(report, "- How it was analysed: a significance test and a Bayes factor", fixed = TRUE)
  expect_match(report, "- Its Bayes factor (BF10): 3.2", fixed = TRUE)
  expect_match(report, "- Reported effect: 0.5", fixed = TRUE)
  expect_match(report, "- Significance level: 0.05", fixed = TRUE)
  # The card takes the effect, as for a test.
  expect_identical(replication_card_effect_field("E2", both), "d")
  html <- as.character(replication_workspace_ui(tree))
  expect_match(html, "rep_bf_both", fixed = TRUE)
  expect_true("rep_bf_both" %in% replication_field_ids)
})

test_that("an original with both is planned, with BUCSS's figures beside, as a test original is", {
  skip_if_not_installed("BayesRepDesign")
  plan <- replication_run(both, engine_function("replication_planning"), engine_function("replication_bucss"))
  test_plan <- replication_run(modifyList(both, list(rep_analysis = "test")), engine_function("replication_planning"),
    engine_function("replication_bucss"))
  expect_equal(plan$table, test_plan$table)
})

test_that("Not worth replicating goes to the write-up, which is the negative pre-replication report", {
  notes <- list(labs_study = "Smith (2010)", labs_finding = "The effect of X on Y.", labs_quality = "Too small a sample.",
    labs_value = "A new study would tell us more.")
  report <- replication_report(list(), NULL, notes, "not_worth", version = "0.1.0")
  expect_identical(report[[1]], "# Pre-replication of: Smith (2010)")
  text <- paste(report, collapse = "\n")
  expect_match(text, "Written with Powerkit's replication plan, version 0.1.0", fixed = TRUE)
  expect_match(text, "Too small a sample.", fixed = TRUE)
  # None of the planning sections.
  expect_no_match(text, "## Goals and sample size", fixed = TRUE)
  expect_no_match(text, "## The original study", fixed = TRUE)
  expect_no_match(text, "not filled in yet", fixed = TRUE)
  # The notes' button goes to the write-up; the steps say they aren't needed.
  expect_match(as.character(labs_next_ui("not_worth")), "Next: the write-up", fixed = TRUE)
  html <- as.character(replication_workspace_ui(tree))
  expect_match(html, "this step isn't needed", fixed = TRUE)
  expect_match(html, "input.labs_outcome != &#39;not_worth&#39;", fixed = TRUE)
  # Go ahead still gets the full plan.
  expect_match(paste(replication_report(list(), NULL, notes, "go"), collapse = "\n"), "## Goals and sample size", fixed = TRUE)
})
