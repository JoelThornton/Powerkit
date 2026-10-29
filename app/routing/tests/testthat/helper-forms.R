# Valid example values for each input screen (the engine's example specs in
# engine/inst/specs/, where there is one), used by test-forms.R.
closing_ok <- list(goal = "sample_size", power = "0.8", alpha = "0.05",
  just_type = "smallest_effect_of_interest", just_source = "Example only")

form_examples <- list(
  E1 = c(list(Y_label = "Change in wellbeing", d = "0.3", method = "t_test", alternative = "two_sided"), closing_ok),
  E2 = c(list(X_label = "Condition", X_level1 = "Control", X_level2 = "Training", Y_label = "Recall score",
              d = "0.4", allocation_ratio = "1", method = "welch_t", alternative = "two_sided"), closing_ok),
  E3 = c(list(X_label = "Session", X_level1 = "Before", X_level2 = "After", Y_label = "Anxiety score",
              dz = "0.35", method = "t_test", alternative = "two_sided"), closing_ok),
  E4 = c(list(X_label = "Trait mindfulness", Y_label = "Rumination", r = "-0.2", alternative = "two_sided"), closing_ok),
  E5 = c(list(X_label = "Reminder", X_level1 = "No reminder", X_level2 = "Text reminder", Y_label = "Attended",
              p1 = "0.6", p2 = "0.7", allocation_ratio = "1", method = "z_test", alternative = "two_sided"), closing_ok),
  E6 = c(list(X_label = "Attachment style", X_levels = "Secure, Anxious, Avoidant", Y_label = "Relationship status",
              Y_levels = "Single, In a relationship", probabilities = "0.3, 0.25\n0.12, 0.08\n0.15, 0.1"), closing_ok),
  E7 = c(list(A_label = "Feedback", A_level1 = "None", A_level2 = "Praise", B_label = "Task difficulty",
              B_level1 = "Easy", B_level2 = "Hard", Y_label = "Persistence (minutes)", metric = "raw",
              m11 = "10", m12 = "10", m21 = "10", m22 = "13", sd_mode = "one", sd = "6", effect = "interaction", method = "exact"), closing_ok),
  E8 = c(list(A_label = "Group", A_level1 = "Waitlist", A_level2 = "Therapy", B_label = "Time",
              B_level1 = "Pre", B_level2 = "Post", Y_label = "Depression score", metric = "standardised",
              m11 = "0", m12 = "0", m21 = "0", m22 = "-0.4", sd = "1", r = "0.6", effect = "interaction", method = "exact"), closing_ok),
  E9 = c(list(X_label = "Daily stress", W_label = "Social support", Y_label = "Sleep quality",
              r_X_Y = "-0.3", r_W_Y = "0.2", r_XW_Y = "0.1", r_X_W = "-0.1", rel_X = "0.8", rel_W = "0.85"), closing_ok),
  E10 = c(list(X_label = "Workload", M_label = "Exhaustion", Y_label = "Turnover intention",
               p_X_M = "0.3", p_M_Y = "0.3", p_X_Y = "0.1"), closing_ok),
  E11 = c(list(n_mediators = "2", X_label = "Workload", M1_label = "Exhaustion", M2_label = "Cynicism", Y_label = "Turnover intention",
               p_X_M1 = "0.4", p_M1_Y = "0.3", p_X_M2 = "0.3", p_M2_Y = "0.2", p_X_Y = "0.05", rc_M1_M2 = "0.3",
               target_path = "X->M2->Y"), closing_ok),
  E12 = c(list(n_mediators = "2", X_label = "Training", M1_label = "Mindset beliefs", M2_label = "Effort", Y_label = "Grades",
               p_X_M1 = "0.3", p_X_M2 = "0", p_M1_M2 = "0.35", p_M1_Y = "0.05", p_M2_Y = "0.3", p_X_Y = "0",
               target_path = "X->M1->M2->Y"), closing_ok),
  E13 = c(list(X_label = "Condition", W_label = "Group identification", M_label = "Perceived threat", Y_label = "Support for policy",
               p_X_M = "0.2", p_W_M = "0.1", p_XW_M = "0.15", p_M_Y = "0.3", p_X_Y = "0.05"), closing_ok),
  E18 = c(list(A_label = "Feedback", A_levels = "None, Neutral, Praise", Y_label = "Persistence (minutes)",
               metric = "raw", means = "10, 11, 13", sd = "6", test_version = "anova_f", method = "exact"), closing_ok),
  E54 = c(list(A_label = "Task difficulty", A_levels = "Easy, Medium, Hard", Y_label = "Reaction time (ms)",
               metric = "raw", means = "600, 620, 650", sd = "100", r = "0.6", method = "exact"), closing_ok),
  E55 = c(list(A_label = "Group", A_levels = "Therapy, Waiting list", B_label = "Time", B_levels = "Before, After, Follow-up",
               Y_label = "Anxiety score", metric = "raw", means = "20, 16, 15\n20, 19, 18.5", sd = "6", r = "0.5",
               effect = "interaction", method = "exact"), closing_ok),
  E56 = c(list(A_label = "Group", A_levels = "Control, Training", B_label = "Time", B_levels = "Before, After",
               C_label = "Task difficulty", C_levels = "Easy, Hard", Y_label = "Accuracy", within = "BC", metric = "raw",
               means = "80, 60\n81, 61\n80, 60\n84, 70", sd = "12", r = "0.5", effect = "interaction_ABC", method = "exact"), closing_ok),
  E20 = c(list(A_label = "Cue", A_levels = "Valid, Invalid", B_label = "Delay", B_levels = "Short, Medium, Long",
               Y_label = "Reaction time (ms)", metric = "raw", means = "400, 410, 420\n430, 450, 470", sd = "80", r = "0.6",
               effect = "interaction", method = "exact"), closing_ok),
  E21 = c(list(A_label = "Feedback", A_levels = "None, Praise", B_label = "Task difficulty", B_levels = "Easy, Medium, Hard",
               Y_label = "Persistence (minutes)", metric = "standardised", means = "0, 0, 0\n0.1, 0.3, 0.5", sd = "1",
               effect = "interaction", method = "exact"), closing_ok),
  E19 = c(list(A_label = "Training dose", A_levels = "None, One session, Four sessions, Eight sessions", Y_label = "Reading score",
               metric = "raw", means = "1.5, 2, 3, 4", sd = "2", weights = "-3, -1, 1, 3"), closing_ok),
  E23 = c(list(factors = "oneway_ancova", A_label = "Intervention", A_levels = "Control, Brief, Full", Y_label = "Anxiety after",
               metric = "raw", means = "20, 18, 16", sd = "6", r2_covariates = "0.36", covariates = "1"), closing_ok),
  E24 = c(list(Y_label = "Wellbeing score", question = "r2_increase", r2_full = "0.15", r2_reduced = "0.1",
               predictors_total = "5", predictors_tested = "2"), closing_ok),
  E25 = c(list(Y_label = "Correct guess", p = "0.65", p0 = "0.5", alternative = "two_sided"), closing_ok),
  E26 = c(list(X_label = "Session", X_level1 = "Before training", X_level2 = "After training", Y_label = "Passed",
               p_first_only = "0.1", p_second_only = "0.25", alternative = "two_sided"), closing_ok),
  E36 = c(list(comparison = "tost_independent", X_label = "Condition", X_level1 = "Paper", X_level2 = "Screen", Y_label = "Reading comprehension",
               effect_units = "standardised", bound = "0.5", d = "0", allocation_ratio = "1"), closing_ok),
  E48 = c(list(Y_label = "Preferred study method", Y_levels = "Rereading, Highlighting, Practice testing",
               probabilities = "0.25, 0.3, 0.45"), closing_ok),
  E27 = c(list(Y_label = "Seeks help", X_label = "Loneliness", X_type = "continuous",
               odds_ratio = "1.5", base_prob = "0.3", r2_other = "0", alternative = "two_sided"), closing_ok),
  E28 = c(list(Y_label = "Clinic visits in a year", X_label = "Social support", X_type = "continuous",
               rate_ratio = "0.8", base_rate = "3", mean_exposure = "1", r2_other = "0", alternative = "two_sided"), closing_ok),
  E34 = c(list(assignment = "cluster_randomised", outcome_type = "standardised", adjust_baseline = "no", X_label = "Programme", X_level1 = "Usual lessons", X_level2 = "Wellbeing programme",
               Y_label = "Wellbeing score", d = "0.3", icc = "0.05", cluster_size = "20", cluster_size_sd = "0",
               alternative = "two_sided"), closing_ok),
  E37 = c(list(question = "model_fit", model_kind = "cfa", indicators = "12", factors = "3", rmsea = "0.05"), closing_ok),
  E49 = c(list(G_label = "Sample", G_level1 = "Students", G_level2 = "Community", X_label = "Self-control",
               Y_label = "Wellbeing", r1 = "0.2", r2 = "0.45", allocation_ratio = "1", alternative = "two_sided"), closing_ok),
  E50 = c(list(generic_test = "t", ncp = "2.5", df = "30", alternative = "two_sided"),
          modifyList(closing_ok, list(goal = "power"))),
  E51 = c(list(comparison = "overlapping_correlations", X_label = "Wellbeing", Y_label = "Self-control", Z_label = "Grit",
               r_X_Y = "0.4", r_X_Z = "0.2", r_Y_Z = "0.5", alternative = "two_sided"), closing_ok),
  E52 = c(list(Y_label = "Reaction time", var = "1", var0 = "1.5", alternative = "less"), closing_ok),
  E53 = c(list(G_label = "Group", G_level1 = "Trained", G_level2 = "Untrained", Y_label = "Reaction time",
               var1 = "1.5", var2 = "1", alternative = "two_sided"), closing_ok),
  E14 = c(list(X_label = "Abusive supervision", W_label = "Coping self-efficacy", M_label = "Emotional exhaustion",
               Y_label = "Job performance", p_X_M = "0.35", p_M_Y = "-0.25", p_W_Y = "0.15", p_MW_Y = "0.12",
               p_X_Y = "-0.05", c_X_W = "-0.1"), closing_ok)
)

# The rank tests: a test version on E1, E2, E3 and E18, with the shape of
# the scores.
form_examples_rank <- list(
  E1 = modifyList(form_examples$E1, list(method = "wilcoxon_signed_rank", score_shape = "heavy_tailed")),
  E2 = modifyList(form_examples$E2, list(method = "mann_whitney", score_shape = "skewed")),
  E3 = modifyList(form_examples$E3, list(method = "wilcoxon_signed_rank", score_shape = "normal")),
  E18 = modifyList(form_examples$E18, list(test_version = "kruskal_wallis", score_shape = "skewed", method = NULL))
)

# E23 with two crossed factors (a two-way ANCOVA): the same screen, another
# template.
form_example_ancova_two <- modifyList(form_examples$E23, list(
  factors = "factorial_ancova", A_levels = "Control, Mindfulness",
  B_label = "Delivery", B_levels = "In person, Online, App",
  cell_means = "20, 20, 20\n16, 17, 18", effect = "interaction"
))

# E37's other questions (each sets its own template).
sem_examples <- list(
  invariance = c(list(question = "invariance", level = "metric", mi_indicators = "6", mi_loading = "0.7",
                      noninvariant = "2", loading_group2 = "0.5", allocation_ratio = "1"), closing_ok),
  scalar = c(list(question = "invariance", level = "scalar", mi_indicators = "6", mi_loading = "0.7",
                  noninvariant = "2", intercept_difference = "0.3", allocation_ratio = "1.5"), closing_ok),
  factor_correlation = c(list(question = "factor_correlation", fc_items1 = "4", fc_items2 = "5",
                              fc_loading1 = "0.6", fc_loading2 = "0.7", fc_r = "0.2"), closing_ok),
  latent_regression = c(list(question = "latent_regression", slopes = "0.2, 0.3", tested = "1",
                             predictor_correlation = "0.3", lr_indicators = "4", lr_loading = "0.6"), closing_ok)
)

# E36's correlation and proportions comparisons (TOSTER's z tests).
tost_z_examples <- list(
  tost_correlation = c(list(comparison = "tost_correlation", cor_X_label = "Screen time", cor_Y_label = "Loneliness",
                            cor_bound = "0.2", cor_r = "0"), closing_ok),
  tost_two_proportions = c(list(comparison = "tost_two_proportions", X_label = "Reminder", X_level1 = "Letter",
                                X_level2 = "Text", Y_label = "Attended", prop_bound = "0.1", p1 = "0.6", p2 = "0.6"), closing_ok)
)
