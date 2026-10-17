# Valid example values for each input screen (the engine's example specs in
# engine/inst/specs/, where there is one), used by test-forms.R.
closing_ok <- list(goal = "sample_size", power = "0.8", alpha = "0.05",
  just_type = "smallest_effect_of_interest", just_source = "Example only")

form_examples <- list(
  E1 = c(list(Y_label = "Change in wellbeing", d = "0.3", alternative = "two_sided"), closing_ok),
  E2 = c(list(X_label = "Condition", X_level1 = "Control", X_level2 = "Training", Y_label = "Recall score",
              d = "0.4", allocation_ratio = "1", method = "welch_t", alternative = "two_sided"), closing_ok),
  E3 = c(list(X_label = "Session", X_level1 = "Before", X_level2 = "After", Y_label = "Anxiety score",
              dz = "0.35", alternative = "two_sided"), closing_ok),
  E4 = c(list(X_label = "Trait mindfulness", Y_label = "Rumination", r = "-0.2", alternative = "two_sided"), closing_ok),
  E5 = c(list(X_label = "Reminder", X_level1 = "No reminder", X_level2 = "Text reminder", Y_label = "Attended",
              p1 = "0.6", p2 = "0.7", allocation_ratio = "1", alternative = "two_sided"), closing_ok),
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
  E14 = c(list(X_label = "Abusive supervision", W_label = "Coping self-efficacy", M_label = "Emotional exhaustion",
               Y_label = "Job performance", p_X_M = "0.35", p_M_Y = "-0.25", p_W_Y = "0.15", p_MW_Y = "0.12",
               p_X_Y = "-0.05", c_X_W = "-0.1"), closing_ok)
)
