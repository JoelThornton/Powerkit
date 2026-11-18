# Replication planner (Labs, experimental): planning a replication of a
# published finding, in four sections the researcher can fill in any
# order and come back to: the original study, the goals and sample size,
# how the replication differs, and the write-up.
#
# It comes after the pre-replication notes (Karhulahti, Martončik &
# Adamkovič, 2025), which stay their own tool: the notes decide whether to
# replicate at all, and the planner never rewrites them. It reads two
# things from them, the original study's name and the smallest effect that
# would matter, and includes the notes in the write-up when they are
# filled in.
#
# Every number comes from the engine's replication_planning() (BayesRepDesign,
# and pwr and pwrss for small telescopes); the app only lays them out. The
# fields live in the browser tab like the notes (labs_js), and "Save to a
# file" keeps them for another day.

replication_sections <- c(
  "Whether to replicate" = "whether",
  "The original study" = "original",
  "Goals and sample size" = "goals",
  "How the replication differs" = "differences",
  "Write-up" = "writeup"
)

replication_designs_ui <- c(
  "Two separate groups compared on a score (Cohen's d)" = "two_groups",
  "The same people measured twice (d_z)" = "paired",
  "One group against a fixed value (Cohen's d)" = "one_sample",
  "Two scores and how they are related (r)" = "correlation",
  "An ANOVA effect, reported as an F or a partial eta-squared (different people, the same people measured several times, or both)" = "anova",
  "Another design: its effect as one number (an estimate with its standard error, interval or test statistic)" = "generic"
)

# For another design: the estimate's scale, and where its uncertainty
# comes from (queue item 21).
replication_scales_ui <- c(
  "As reported: a difference, a coefficient or another estimate" = "none",
  "A ratio (odds, risk, hazard, rate or variance ratio), planned on the log scale" = "log",
  "A correlation, planned on Fisher's z scale" = "fisher_z"
)
replication_se_from_ui <- c("Its standard error" = "se", "Its confidence interval" = "ci",
  "Its test statistic (z or t)" = "statistic", "Its F statistic, with one numerator df" = "f")

# An ANOVA original (queue item 28; decisions.md, 17 November 2026): its
# design, the effect the replication tests, and its F or partial
# eta-squared, planned with BUCSS (Anderson, Kelley & Maxwell, 2017), not
# the goals of the one-number designs. The first factor is the
# between-subjects one in a mixed design, the second the within-subjects one.
replication_anova_kinds_ui <- c(
  "Different people in every group (between-subjects)" = "between",
  "The same people in every condition (within-subjects, repeated measures)" = "within",
  "Groups of different people, each measured in several conditions (mixed)" = "mixed"
)
replication_anova_effects_ui <- c(
  "The first factor's main effect (the between-subjects factor in a mixed design)" = "factor_a",
  "The second factor's main effect (the within-subjects factor in a mixed design)" = "factor_b",
  "The interaction of the two factors" = "interaction"
)
replication_f_from_ui <- c("Its F" = "f", "Its partial eta-squared, with its F test's error degrees of freedom" = "eta")
# Assurance: the chance the planned power is reached once the original's
# effect is corrected for publication bias and uncertainty. 80% is BUCSS's
# default; 50% plans from the corrected estimate itself.
replication_assurances_ui <- c("80% (BUCSS's default)" = "0.8", "50% (the corrected estimate itself)" = "0.5",
  "90%" = "0.9", "95%" = "0.95")
replication_assurance_levels <- c(0.5, 0.8, 0.9, 0.95)

# Designs the list doesn't name. An ANCOVA's effect with one degree of
# freedom (the adjusted difference between two groups) is one number, so
# "Another design" gives it every goal; BUCSS has no ANCOVA function. No
# package plans a replication of a MANOVA from its original, so it is an
# ordinary power analysis from the smallest effect that would matter.
replication_design_list_note <- paste(
  "An ANCOVA: its adjusted difference between two groups is one number, so enter it under \u201cAnother design\u201d, with its standard error, interval or F (one numerator degree of freedom), and every goal applies. With three or more groups, enter the one comparison the hypothesis is about the same way.",
  "A MANOVA: no published method plans a replication from a MANOVA's result, so plan it as an ordinary power analysis on the MANOVA card, from the smallest effect that would matter to you, or replicate the one outcome and comparison the hypothesis is about as its own design.",
  "Anything else whose focal effect is one number goes under \u201cAnother design\u201d too.")

replication_is_anova <- function(values) identical(trimws(as.character(values$rep_design %||% "")), "anova")

# An ANOVA effect with one degree of freedom (a factor with two levels, or
# a 2 x 2 interaction) is a comparison of two means, F(1, df) = t^2, so it
# goes through every goal as that comparison (the engine's
# replication-anova.R); one with several degrees of freedom is planned
# with BUCSS, and from the smallest effect that would matter
# (decisions.md, 18 November 2026).
replication_anova_effect_choice <- function(values) {
  v <- function(id) trimws(as.character(values[[id]] %||% ""))
  kind <- if (v("rep_anova_kind") %in% replication_anova_kinds_ui) v("rep_anova_kind") else "between"
  effect <- if (v("rep_anova_effect") %in% replication_anova_effects_ui) v("rep_anova_effect") else "factor_a"
  if (!nzchar(v("rep_levels_b")) && !identical(kind, "mixed")) effect <- "factor_a"
  list(kind = kind, effect = effect)
}

replication_anova_one_df <- function(values) {
  if (!replication_is_anova(values)) return(FALSE)
  level <- function(id) suppressWarnings(as.numeric(trimws(as.character(values[[id]] %||% ""))))
  two <- function(id) isTRUE(level(id) == 2)
  switch(replication_anova_effect_choice(values)$effect,
    factor_a = two("rep_levels_a"), factor_b = two("rep_levels_b"),
    interaction = two("rep_levels_a") && two("rep_levels_b"))
}

# Planned with BUCSS alone (and the smallest effect): an ANOVA effect with
# several degrees of freedom.
replication_bucss_only <- function(values) replication_is_anova(values) && !replication_anova_one_df(values)

# The same in the browser, for the Goals step's panels.
replication_one_df_js <- paste0("(function () { var a = Number((input.rep_levels_a || '').trim()), bt = (input.rep_levels_b || '').trim(), ",
  "b = Number(bt), e = input.rep_anova_effect || 'factor_a'; if (bt === '' && input.rep_anova_kind !== 'mixed') e = 'factor_a'; ",
  "return (e === 'factor_a' && a === 2) || (e === 'factor_b' && bt !== '' && b === 2) || (e === 'interaction' && a === 2 && bt !== '' && b === 2); })()")
replication_one_number_js <- sprintf("(input.rep_design != 'anova' || %s)", replication_one_df_js)
replication_bucss_only_js <- sprintf("(input.rep_design == 'anova' && !%s)", replication_one_df_js)

# The engine function a plan's fields go to.
replication_engine_name <- function(values) if (replication_bucss_only(values)) "replication_bucss" else "replication_planning"

# What the paper gave for a t-test original (Lakens, 2013): the design's
# own d, its t statistic, or for pairs a repeated-measures d (d_rm, or
# d_av when the two SDs are about equal) with the correlation between the
# two measurements, which the engine converts to d_z.
replication_effect_types_ui <- c("Its d (d_z for pairs), as the paper reported it" = "d", "Its t statistic" = "t",
  "For pairs: d_rm, or d_av when the two SDs are about equal, with the correlation between the measurements" = "d_rm")

# The card's entry in forms.yaml's replication_effects: how a replication
# plan takes its original effect.
replication_card_effect <- function(forms, ep_id) forms$replication_effects[[ep_id %||% ""]]

# Replicating a published finding from the design finder (12 November
# 2026): the aim asks the original's design like any other, and the card
# it ends on says how to plan the replication. The planner's own designs
# (above) are offered it, on the same design; every other card plans the
# replication itself, for a significant result again.
replication_card_templates <- c(independent_t = "two_groups", paired_t = "paired", one_sample_t = "one_sample", correlation = "correlation")

replicating <- function(start) identical(start$aim, "replicate")

replication_card_design <- function(forms, ep_id) {
  template <- forms$forms[[ep_id %||% ""]]$base$template %||% ""
  if (template %in% names(replication_card_templates)) unname(replication_card_templates[[template]]) else NULL
}

# The plan's goals for the card, in one sentence: what the goals table
# takes from it, or why it has none.
replication_card_effect_note <- function(forms, ep_id) {
  e <- replication_card_effect(forms, ep_id)
  if (is.null(e) || !is.null(e$exact)) return(NULL)
  anova <- if (!is.null(e$anova)) " If the paper reports the effect's F or partial eta-squared, enter it under \u201cAn ANOVA effect\u201d instead: an effect with one degree of freedom (two levels, or a 2 x 2 interaction) then gets every goal, with BUCSS's correction for publication bias and uncertainty beside them, and one with several gets BUCSS's correction and a plan from the smallest effect that would matter."
  paste0(replication_card_effect_note_words(e), anova %||% "")
}

replication_card_effect_note_words <- function(e) {
  if (!is.null(e$multi_df)) {
    return(sprintf("This card's test has several degrees of freedom, so it has no one number for the plan's goals; plan them for the focal contrast instead: %s.", e$multi_df))
  }
  if (!is.null(e$none)) return(e$none)
  sprintf("For the plan's goals, enter the original's %s with its standard error, interval or test statistic, under \u201cAnother design\u201d.", e$effect)
}

replication_card_note <- function(forms, ep_id, plan = NULL) {
  # A card with no input screen (the safety net, a guide) plans nothing,
  # so it is not kept as the original's design.
  if (is.null(forms$forms[[ep_id %||% ""]])) {
    return(div(class = "labs-return replication-card-note", role = "note",
      p(class = "mb-0", tags$strong("Planning a replication. "),
        "Powerkit can't plan this design on a card, so it isn't kept as the original's design. ",
        "The replication plan's goals can still be worked out from the original's effect, as one number with its standard error, interval or test statistic, under \u201cAnother design\u201d.",
        if (!is.null(plan)) tagList(" ", actionLink("rep_view_plan", "Open the replication plan.")))))
  }
  planner <- !is.null(replication_card_design(forms, ep_id))
  div(class = "labs-return replication-card-note", role = "note",
    p(tags$strong("Planning a replication. "),
      "Enter the original study's effect and choose the test it used: the replication uses the same. The effect's source starts as an earlier study. ",
      "A published effect is often larger than the true one, because larger effects are more likely to be published, so consider planning for a smaller effect as well, such as the smallest that would matter."),
    p(class = "mb-0",
      if (!is.null(plan)) tagList(sprintf("This is kept in the replication plan \u201c%s\u201d, with its notes, goals and write-up. ", plan$name),
        actionLink("rep_view_plan", "Open the replication plan."), " ") else NULL,
      if (planner) "For this design, the plan's Goals give the sample size for each goal a replication can have (a significant result again, a pooled estimate, agreement with the original, Bayes factors)."
      else tagList("This card plans the replication for a significant result again. ", replication_card_effect_note(forms, ep_id))))
}

# The input screen's starting values when replicating: the effect comes
# from an earlier study, unless the user has already chosen. With the
# replication plan (queue item 28), the card starts on the sample-size
# question at the plan's significance level and chance of success, and,
# for the four designs whose effect the card takes as entered (d, d_z or
# r), with the original's reported effect: entered once, in the plan.
replication_form_values <- function(values, ep = NULL, plan_values = NULL) {
  if (is.null(values$just_type)) values$just_type <- "prior_study"
  if (is.null(plan_values)) return(values)
  given <- function(id) {
    x <- trimws(as.character(plan_values[[id]] %||% ""))
    if (length(x) == 1 && nzchar(x) && !is.na(suppressWarnings(as.numeric(x)))) x else NULL
  }
  keep <- function(id, x) if (is.null(values[[id]]) && !is.null(x)) values[[id]] <<- x
  keep("goal", "sample_size")
  keep("alpha", given("rep_alpha"))
  keep("power", given("rep_power"))
  field <- replication_card_effect_field(ep, plan_values)
  if (!is.null(field)) {
    if (!identical(field, "r")) keep("effect_units", "standardised")
    keep(field, given("rep_effect"))
  }
  values
}

# The card field that takes the original's effect as the plan holds it:
# d on E1 and E2, d_z on E3 (only when the paper gave d_z, not a t
# statistic or d_rm) and r on E4, for an original analysed with a test.
replication_card_effect_field <- function(ep, plan_values) {
  v <- function(id) as.character(plan_values[[id]] %||% "")
  if (!v("rep_analysis") %in% c("", "test", "both")) return(NULL)
  type <- v("rep_effect_type")
  d_given <- !nzchar(type) || identical(type, "d")
  switch(ep %||% "",
    E1 = if (d_given && identical(v("rep_design"), "one_sample")) "d",
    E2 = if (d_given && identical(v("rep_design"), "two_groups")) "d",
    E3 = if (d_given && identical(v("rep_design"), "paired")) "dz",
    E4 = if (identical(v("rep_design"), "correlation")) "r",
    NULL)
}

# How the original was analysed (queue item 21): a test, a Bayes factor
# (a default-prior t-test) or a posterior.
replication_analyses_ui <- c("A significance test (a p-value)" = "test",
  "Both: a significance test and a Bayes factor" = "both", "A Bayes factor" = "bayes_factor",
  "A posterior distribution" = "posterior")
replication_original_priors_ui <- c("Vague (flat, or nearly)" = "vague",
  "A default prior (for example JASP's Cauchy prior, scale 0.707)" = "default",
  "An informative prior (built from earlier findings or a theory)" = "informative")
replication_post_from_ui <- c("Its posterior SD" = "sd", "Its credible interval" = "ci")

# How much the true effect may vary between studies (Kenny & Judd, 2019,
# whose example values for d these are). It starts at Small (0.05):
# Kenny and Judd argue zero should not be the default (decided 15
# November 2026).
replication_taus <- c(
  "None: the same effect in every study" = "0",
  "Small (0.05)" = "0.05",
  "Medium (0.125)" = "0.125",
  "Large (0.20)" = "0.2"
)

# The same for a correlation, on Fisher's z: Kenny and Judd's rule of 25%
# of the effect applied to r = .1, .3 and .5, as on the correlation card
# (E4; docs/conventions.md, "Correlations that vary between studies").
replication_taus_r <- c(
  "None: the same correlation in every study" = "0",
  "Small (0.025)" = "0.025",
  "Medium (0.075)" = "0.075",
  "Large (0.125)" = "0.125"
)

# The variation the plan uses, on the effect's own scale: Kenny and
# Judd's values in d for the designs planned in d, the correlation card's
# on Fisher's z, and for another design the number entered on the
# estimate's scale (log units for a ratio), or none, because values in d
# have no meaning on another scale.
replication_tau_value <- function(values) {
  v <- function(id) trimws(as.character(values[[id]] %||% ""))
  design <- if (nzchar(v("rep_design"))) v("rep_design") else "two_groups"
  pick <- switch(design, correlation = v("rep_tau_r"), generic = v("rep_tau_value"), v("rep_tau"))
  fallback <- switch(design, correlation = "0.025", generic = "0", "0.05")
  if (!nzchar(pick)) pick <- fallback
  x <- suppressWarnings(as.numeric(pick))
  if (is.na(x)) NA_real_ else x
}

replication_goal_labels <- c(
  significance = "A significant result in the original's direction",
  pooled = "A significant result when the two studies are pooled",
  agreement = "A result that agrees with the original's, within the smallest effect that matters",
  bf_replication = "Evidence, at your threshold, that the original's effect was found again (replication Bayes factor)",
  bf_sceptical = "Evidence, at your threshold, for the effect that would convince a sceptic (sceptical Bayes factor)",
  bf_repeat = "Evidence for an effect, at your threshold, from the original's own Bayes factor test, repeated",
  small_telescopes = "Show the original study was too small to have detected the effect (small telescopes)",
  negligible = "Show the effect is too small to matter (equivalence test)",
  bf_null = "Evidence for no effect, at your threshold, from the original's Bayes factor test, if there is none"
)

# Short notes on what each goal answers (Anderson & Maxwell, 2016; Pawel,
# Consonni & Held, 2026).
replication_goal_notes <- c(
  significance = "The usual definition of a successful replication. On its own it says little about how large the effect is.",
  pooled = "Combines both studies' estimates. The original's own result counts towards it, so the bar is set stricter: a one-sided level of alpha/2 squared.",
  agreement = "Asks whether the two estimates are close, not whether either differs from zero. A small original rarely allows it.",
  bf_replication = "Compares the original's effect with no effect, using the new data.",
  bf_sceptical = "Asks whether the two studies together would persuade someone who doubts the effect. A weak original may never allow it.",
  bf_repeat = "The test the original used, with its prior, run on the new data alone: the Bayesian counterpart of a significant result again.",
  small_telescopes = "Planned for a true effect of zero. A result below the yardstick says the original was too small to see an effect that size, not that it was a false positive.",
  negligible = "Planned for a true effect of zero. It needs the smallest effect that matters, and usually a large sample.",
  bf_null = "Planned for a true effect of zero. Evidence for no effect needs many more people than evidence for an effect (McLatchie, Warmelink & Tkacheva, 2020)."
)

# What the replication should show, asked first (decisions.md, 17 November
# 2026): it picks the usual main criterion, which the researcher can
# change.
# A significance test in the original's direction: at alpha / 2 one-sided
# (two-sided alpha, the usual) or at alpha one-sided.
replication_sided_ui <- c(
  "Two-sided (the usual): a significant result at this level, in the original's direction" = "two.sided",
  "One-sided, in the original's direction, at this level" = "one.sided"
)

replication_purposes_ui <- c(
  "That the original's effect is there again" = "confirm",
  "Whether the effect is there or not: either answer would tell me something" = "either",
  "That the effect is absent or too small to matter (the original may be a false positive)" = "absent"
)

# What the replication keeps (queue item 28, decided 17 November 2026):
# everything it can (close), the original comparison with something added
# (an extension, whose analyses join the plan under their own heading),
# the idea in changed conditions (a conceptual replication, planned from
# the shrunk belief with more variation between studies), or not the
# original comparison (a new study, planned as an ordinary study plan).
replication_keeps_ui <- c(
  "Everything it can: the same comparison, measures and procedure (a close replication)" = "close",
  "The original comparison, with something added: a new condition, measure or group (a replication with an extension)" = "extension",
  "The idea, tested in changed conditions: other materials, measures or people (a conceptual replication)" = "conceptual",
  "Not the original comparison: it asks a different question (a new study)" = "new"
)
replication_keeps_words <- c(close = "a close replication", extension = "a replication with an extension",
  conceptual = "a conceptual replication", new = "a new study rather than a replication")

# A conceptual replication's settings: the shrunk belief and the next
# larger variation between studies than the one chosen (the design's
# medium value at least), as the decision says; for an ANOVA original, a
# higher assurance. A generic effect's
# variation is on its own scale, so it is left to the researcher.
replication_conceptual_settings <- function(values) {
  v <- function(id) trimws(as.character(values[[id]] %||% ""))
  design <- if (nzchar(v("rep_design"))) v("rep_design") else "two_groups"
  # An ANOVA original (BUCSS): nothing is changed. BUCSS's assurance
  # allows for the original's sampling error and publication bias, not for
  # a changed procedure changing the effect, so raising it would not answer
  # the question; the researcher chooses the assurance (decisions.d,
  # replication-bucss.md).
  if (identical(design, "anova") && !replication_anova_one_df(values)) return(list())
  out <- list(rep_prior = "shrunk")
  bump <- function(choices, now) {
    vals <- unname(choices)
    at <- match(now, vals)
    medium <- vals[[3]]
    if (is.na(at) || at < 3) medium else vals[[min(at + 1L, length(vals))]]
  }
  if (identical(design, "correlation")) out$rep_tau_r <- bump(replication_taus_r, v("rep_tau_r"))
  else if (!identical(design, "generic")) out$rep_tau <- bump(replication_taus, v("rep_tau"))
  out
}

# The same in the browser, for the note under Goals.
replication_changes_js <- paste0("input.rep_keeps == 'conceptual' || input.rep_keeps == 'extension' || ",
  paste(sprintf("(input.%s || '').trim() !== ''", c("rep_diff_people", "rep_diff_materials", "rep_diff_procedure", "rep_diff_analysis", "rep_diff_checks")),
    collapse = " || "))

# The main criterion's box: the purpose's usual one first, then any goal.
replication_goal_choices <- c("The usual one for what it should show" = "auto",
  stats::setNames(names(replication_goal_labels), replication_goal_labels))

# "Also report": a criterion that can show the effect is absent starts
# ticked, because a non-significant replication alone can't tell a failed
# replication from an inconclusive one (decisions.md, 17 November 2026).
# Was the original published because it was significant? BUCSS's
# publication filter (alpha_prior), or none (alpha_prior = 1).
replication_published_ui <- c(
  "Yes, or I don't know: most published findings were (BUCSS's usual assumption)" = "significant",
  "No: it would have been published whatever it found, such as a Registered Report" = "any")

replication_also_choices <- c(
  "A criterion that could show the effect is absent (an equivalence test; with a Bayes factor as the main criterion, a Bayes factor for no effect)" = "absence",
  stats::setNames(names(replication_goal_labels), replication_goal_labels))

# "Also report" as one text field, and back: the ticks joined by new
# lines, "none" for no tick.
replication_also_value <- function(v) {
  v <- as.character(unlist(v))
  v <- v[nzchar(v)]
  if (!length(v)) "none" else paste(v, collapse = "\n")
}
replication_also_selected <- function(text) {
  v <- strsplit(as.character(text %||% ""), "\n")[[1]]
  v <- intersect(v, replication_also_choices)
  if (length(v)) v else character(0)
}

replication_bf_goals <- c("bf_replication", "bf_sceptical", "bf_repeat", "bf_null")

# The goals a plan's sample size and chances come from. `available`: the
# goals the plan can give (with agreement and too small to matter counted
# when a bound can be found for them). Returns the main goal and the goals
# also reported, in the table's order.
replication_resolve_goals <- function(values, available) {
  v <- function(id) trimws(as.character(values[[id]] %||% ""))
  purpose <- if (v("rep_purpose") %in% replication_purposes_ui) v("rep_purpose") else "confirm"
  bayes_original <- v("rep_analysis") %in% c("bayes_factor", "posterior")
  goal <- v("rep_goal")
  auto <- !goal %in% names(replication_goal_labels)
  if (auto) goal <- switch(purpose,
    confirm = if (bayes_original && "bf_repeat" %in% available) "bf_repeat" else "significance",
    either = if ("bf_repeat" %in% available) "bf_repeat" else "bf_replication",
    absent = "negligible")
  also <- strsplit(v("rep_also"), "\n")[[1]]
  # The criterion that can show absence: with a Bayes factor main
  # criterion, the default Bayes factor for no effect where the original
  # was a t-test, else the replication Bayes factor (no effect against the
  # original's); with any other, the equivalence test.
  absence <- if (!goal %in% replication_bf_goals) "negligible" else if ("bf_null" %in% available) "bf_null" else "bf_replication"
  also <- unique(ifelse(also == "absence", absence, also))
  also <- setdiff(intersect(names(replication_goal_labels), intersect(also, available)), goal)
  absence_missing <- "absence" %in% strsplit(v("rep_also"), "\\n")[[1]] && !absence %in% c(goal, also)
  list(goal = goal, also = also, auto = auto, purpose = purpose, absence_missing = absence_missing,
    prior = if (v("rep_prior") %in% names(replication_prior_labels)) v("rep_prior") else "uncertain")
}

replication_prior_labels <- c(
  as_reported = "As reported",
  uncertain = "With its uncertainty",
  shrunk = "Shrunk towards zero"
)
replication_prior_notes <- c(
  as_reported = "The true effect is the original's estimate, exactly. This is the usual power analysis, and the most optimistic.",
  uncertain = "The original's estimate, with the uncertainty its sample size leaves. Effects a little smaller or larger are as plausible as the data say.",
  shrunk = "The original's estimate pulled towards zero, more so the weaker its evidence. It allows for published effects being too large."
)

replication_ref_keys <- c("Pawel2026_replication", "Anderson2016_replication", "Simonsohn2015_telescopes", "Kenny2019_heterogeneity",
  "VerhagenWagenmakers2014_replication", "Ly2019_replication_bf", "Ly2018_summary_reanalysis", "McLatchie2020_bayes_factors",
  "bfpwr_method", "Lakens2013_effectsizes", "Anderson2017_bucss", "AndersonKelley2024_replication_design")

# The replication planner's sections, inside a replication plan's
# workspace (replication_workspace_ui(), R/study-plan-replication.R; a Labs tool
# until 14 November 2026). Their fields are kept in the plan.
# A conditionalPanel condition: true when the main criterion or a ticked
# "Also report" criterion is one of `goals` (or the purpose's usual
# criterion is, with `absent` or `either`).
replication_needs_js <- function(goals, absent = FALSE, either = FALSE, confirm = FALSE) {
  list_js <- sprintf("[%s]", paste0("'", goals, "'", collapse = ", "))
  also <- if (absent) c(goals, "absence") else goals
  paste0("(", list_js, ".indexOf(input.rep_goal) >= 0",
    if (absent) " || (input.rep_goal == 'auto' && input.rep_purpose == 'absent')",
    if (either) " || (input.rep_goal == 'auto' && input.rep_purpose == 'either')",
    if (confirm) " || (input.rep_goal == 'auto' && input.rep_purpose == 'confirm')",
    sprintf(" || (input.rep_also || []).some(function(g) { return [%s].indexOf(g) >= 0; }))", paste0("'", also, "'", collapse = ", ")))
}

# Guidance on the replication pages follows the "Show explanations" switch
# and the forms' layout (design review D-11): one sentence in view, the
# rest under "More", closed to start with; with explanations off the
# sentence folds behind an info button too. `keep`: a caveat or a prompt
# the researcher must see, which stays in view in both modes.
rep_note <- function(text, label = "About this", keep = FALSE) {
  lead <- help_lead(text)
  rest <- help_rest(text)
  more <- if (!is.null(rest)) tags$details(class = if (keep) "rep-more small" else "input-guide rep-more small",
    tags$summary("More"), p(class = "small mb-0", rest))
  if (keep) return(div(class = "rep-note", p(class = "small mb-1", lead), more))
  explanation_ui(paste0("rep-note-", rep_note_id(text)), label, class = "inline-more rep-note",
    p(class = "small mb-1", lead), more)
}
rep_note_id <- function(text) {
  codes <- utf8ToInt(text)
  sprintf("%d-%d", length(codes), sum(as.numeric(codes) * seq_along(codes)) %% 999983)
}

# A text field with help, laid out as the forms' fields are: the first
# sentence under the box, the whole help behind the info button beside
# the label (closed in both modes; with explanations off the line folds).
# Number boxes are sized for a number, as the input screens' are; those
# that can't be negative also bring up a number keyboard on phones.
replication_number_fields <- c("rep_levels_a", "rep_levels_b", "rep_anova_f", "rep_eta", "rep_df_error", "rep_epsilon", "rep_anova_smallest",
  "rep_bf", "rep_bf_both", "rep_prior_scale", "rep_post_sd", "rep_cri_level", "rep_se", "rep_ci_level", "rep_f",
  "rep_n1", "rep_n2", "rep_n", "rep_original_alpha", "rep_smallest", "rep_tau_value", "rep_n_at", "rep_alpha", "rep_power")
replication_signed_fields <- c("rep_effect", "rep_effect_r", "rep_statistic", "rep_cri_lower", "rep_cri_upper",
  "rep_ci_lower", "rep_ci_upper")
rep_number_input <- function(input, id) {
  if (id %in% replication_number_fields) {
    return(htmltools::tagAppendAttributes(input, class = "rep-num", inputmode = "decimal", .cssSelector = "input"))
  }
  if (id %in% replication_signed_fields) return(htmltools::tagAppendAttributes(input, class = "rep-num", .cssSelector = "input"))
  input
}

rep_field <- function(id, label, value = "", help = NULL) {
  input <- rep_number_input(textInput(id, label, value = value, width = "100%"), id)
  if (is.null(help)) return(div(class = "form-field", input))
  lead <- help_lead(help)
  rest <- help_rest(help)
  more <- explanation_ui(paste0(id, "_info"), label, class = "field-more",
    div(class = "field-help field-lead-copy", lead), if (!is.null(rest)) div(class = "field-help", rest))
  input <- htmltools::tagInsertChildren(input, more, after = 1)
  div(class = "form-field has-field-more", input, div(class = "field-help field-lead small text-muted", lead))
}

# A step's title, numbered as the input screens' sections are, and a
# titled card for each group of questions within it.
rep_section_title <- function(id) {
  ids <- unname(replication_sections)
  h3(class = "form-section-title rep-section-title", sprintf("%d. %s", match(id, ids), names(replication_sections)[[match(id, ids)]]))
}
rep_card <- function(title, ..., class = NULL) {
  tags$fieldset(class = paste(c("form-group-box", class), collapse = " "), tags$legend(class = "h6", title), ...)
}

replication_planner_sections <- function() {
  field <- rep_field
  box <- function(id, label, rows = 3) div(class = "form-field", textAreaInput(id, label, rows = rows, width = "100%"))
  section <- function(id, ...) conditionalPanel(sprintf("input.rep_section == '%s'", id), class = "form-section", rep_section_title(id), ...)
  tagList(
    section("original",
      rep_card("Which study, and how it was analysed",
        uiOutput("rep_from_notes_study"),
        field("rep_study", "The original study (authors, year, title or link)"),
        selectInput("rep_design", "Its design", choices = replication_designs_ui, selectize = FALSE, width = "100%"),
        # Where the designs not in the list go (decisions.md, 18 November 2026).
        rep_note(replication_design_list_note, label = "Not in the list?"),
        conditionalPanel("input.rep_design != 'anova'",
          radioButtons("rep_analysis", "How it was analysed", choices = replication_analyses_ui, selected = "test", width = "100%"))),
      rep_card("What it reported",
        conditionalPanel("input.rep_design == 'anova'",
          radioButtons("rep_anova_kind", "Who was in each condition", choices = replication_anova_kinds_ui, selected = "between", width = "100%"),
          field("rep_levels_a", "Levels of its first factor (in a mixed design, the between-subjects factor: its number of groups)"),
          field("rep_levels_b", "Levels of its second factor (in a mixed design, the within-subjects factor: its number of conditions or times)",
            help = "Leave it empty for a design with one factor, such as a one-way ANOVA."),
          selectInput("rep_anova_effect", "The effect the replication tests", choices = replication_anova_effects_ui, selectize = FALSE, width = "100%"),
          radioButtons("rep_f_from", "What the paper gave for it", choices = replication_f_from_ui, selected = "f", width = "100%"),
          conditionalPanel("input.rep_f_from != 'eta'",
            field("rep_anova_f", "Its F statistic", help = "For example 15.38 from F(1, 118) = 15.38.")),
          conditionalPanel("input.rep_f_from == 'eta'",
            field("rep_eta", "Its partial eta-squared"),
            field("rep_df_error", "Its F test's error degrees of freedom: the second number in F(df1, df2)",
              help = "The partial eta-squared is moved to its F with these and the effect's own degrees of freedom (Lakens, 2013).")),
          conditionalPanel("input.rep_anova_kind != 'between'",
            field("rep_epsilon", "The sphericity correction, epsilon (optional)", value = "1",
              help = "1 assumes sphericity, as most papers' F tests do. With a Greenhouse-Geisser or Huynh-Feldt correction, its epsilon, if the paper gives it.")),
          rep_note("An ANOVA effect is planned with BUCSS (Anderson, Kelley & Maxwell, 2017): the replication's sample size for a significant F test, with the original's effect corrected for publication bias and the uncertainty of its estimate. For a one-degree-of-freedom effect with its estimate and standard error, \u201cAnother design\u201d gives the other goals too.")),
        conditionalPanel("input.rep_analysis == 'bayes_factor' && input.rep_design != 'anova'",
          field("rep_bf", "Its Bayes factor for an effect, BF10",
            help = "If the paper gives BF01 (for no effect), enter 1 / BF01. Powerkit reads the effect from it for a t-test (two groups, one group or pairs), as JASP's Summary Statistics do the other way (Ly et al., 2018).")),
        conditionalPanel("input.rep_analysis == 'both' && input.rep_design != 'anova'",
          field("rep_bf_both", "Its Bayes factor for an effect, BF10 (optional)",
            help = "If the paper gives BF01 (for no effect), enter 1 / BF01. The effect is taken from the significance test below, its most direct report; the Bayes factor and its prior are recorded in the write-up, and the prior's scale is used to repeat the original's Bayes factor test as a goal.")),
        conditionalPanel("input.rep_analysis == 'posterior' && input.rep_design != 'anova'",
          radioButtons("rep_original_prior", "Its prior", choices = replication_original_priors_ui, selected = "default", width = "100%"),
          rep_note("A posterior stands in for the original's estimate only when its prior was vague or a default one: an informative prior's posterior mixes the prior's beliefs into what the original found (McLatchie, Warmelink & Tkacheva, 2020). For an informative prior, give the estimate with its standard error, or the Bayes factor.", keep = TRUE)),
        conditionalPanel("input.rep_analysis != 'test' && (input.rep_design == 'two_groups' || input.rep_design == 'one_sample' || input.rep_design == 'paired')",
          field("rep_prior_scale", "The scale of its Cauchy prior on the effect", value = "0.707",
            help = "0.707 is the default in JASP and the BayesFactor package. It is used to read the Bayes factor and to repeat the original's test.")),
        conditionalPanel("input.rep_design == 'generic'",
          field("rep_effect_name", "What the effect is",
            help = "For example \u201cthe interaction coefficient\u201d or \u201codds ratio\u201d. The original's card suggests one."),
          selectInput("rep_scale", "Its scale", choices = replication_scales_ui, selectize = FALSE, width = "100%")),
        conditionalPanel("(input.rep_analysis == 'test' || input.rep_analysis == 'both') && (input.rep_design == 'two_groups' || input.rep_design == 'one_sample' || input.rep_design == 'paired')",
          radioButtons("rep_effect_type", "What the paper gave for the effect", choices = replication_effect_types_ui, selected = "d", width = "100%"),
          # The d_rm choice is for pairs only: hidden for other designs.
          tags$script(HTML("$(document).on('shiny:inputchanged', function(e) { if (e.name === 'rep_design') $('input[name=rep_effect_type][value=d_rm]').closest('.radio').toggle(e.value === 'paired'); });")),
          conditionalPanel("input.rep_design == 'paired'", rep_note("For the same people measured twice, papers report several kinds of d, and they can differ by a factor of two or more: d_z divides the mean difference by the SD of the differences, d_rm and d_av by the scores' own SDs. If you're not sure which, give the t statistic (Lakens, 2013)."))),
        conditionalPanel("input.rep_analysis != 'bayes_factor' && input.rep_design != 'anova'",
          field("rep_effect", "The effect it reported, with its sign",
            help = "For the first four designs, in the form chosen above: d, d_z or r, or the t statistic (for an F with one numerator df, its square root, with the effect's sign). For another design, the estimate on its own scale, a ratio as the ratio. For a posterior, its mean.")),
        conditionalPanel("(input.rep_analysis == 'test' || input.rep_analysis == 'both') && input.rep_design == 'paired' && input.rep_effect_type == 'd_rm'",
          field("rep_effect_r", "The correlation between the two measurements in the original study",
            help = "Often in a table of correlations, or the supplement. Without it, give the t statistic instead.")),
        conditionalPanel("input.rep_analysis == 'posterior' && input.rep_design != 'anova'",
          radioButtons("rep_post_from", "How sure it was", choices = replication_post_from_ui, selected = "sd", inline = TRUE, width = "100%"),
          conditionalPanel("input.rep_post_from == 'sd'",
            field("rep_post_sd", "Its posterior SD", help = "For d, d_z or r, as reported; for another design, as a standard error would be: a ratio's of its log, a correlation's of Fisher's z.")),
          conditionalPanel("input.rep_post_from == 'ci'",
            field("rep_cri_lower", "The credible interval's lower end (on the reported scale)"),
            field("rep_cri_upper", "The credible interval's upper end"),
            field("rep_cri_level", "The interval's level (%)", value = "95"))),
        conditionalPanel("input.rep_design == 'generic' && input.rep_analysis != 'posterior'",
          radioButtons("rep_se_from", "How sure the original was of it", choices = replication_se_from_ui, selected = "se", inline = TRUE, width = "100%"),
          conditionalPanel("input.rep_se_from == 'se'",
            field("rep_se", "Its standard error", help = "For a ratio, the standard error of its log (as a logistic or Poisson regression reports it beside b); for a correlation, of Fisher's z.")),
          conditionalPanel("input.rep_se_from == 'ci'",
            field("rep_ci_lower", "The interval's lower end (on the reported scale)"),
            field("rep_ci_upper", "The interval's upper end"),
            field("rep_ci_level", "The interval's level (%)", value = "95")),
          conditionalPanel("input.rep_se_from == 'statistic'",
            field("rep_statistic", "Its z or t statistic", help = "The estimate divided by its standard error, as the paper reported it.")),
          conditionalPanel("input.rep_se_from == 'f'",
            field("rep_f", "Its F statistic", help = "Only an F with one numerator degree of freedom, such as F(1, 118) for a 2 x 2 interaction or one contrast: its square root is the estimate's t. Enter the estimate above, such as the interaction contrast (the difference between the two simple effects)."))),
        conditionalPanel("input.rep_design == 'two_groups'",
          field("rep_n1", "People in its first group"),
          field("rep_n2", "People in its second group")),
        conditionalPanel("input.rep_design != 'two_groups'",
          field("rep_n", "People (or pairs) it analysed, in total")),
        conditionalPanel("input.rep_design == 'generic'",
          rep_note("The replication is taken to copy the original's design, so its standard error shrinks with the square root of its sample size. Small telescopes needs the original's own test, so it is planned on the design's card.")),
        NULL),
      conditionalPanel("input.rep_analysis == 'test' || input.rep_analysis == 'both' || input.rep_design == 'anova'",
        rep_card("Its significance test, and how it was published",
          field("rep_original_alpha", "Its significance level (two-sided)", value = "0.05"),
          # The publication filter BUCSS corrects for (Anderson, Kelley &
          # Maxwell, 2017): off for an original that faced none.
          radioButtons("rep_published", "Was it published because it was significant?", choices = replication_published_ui,
            selected = "significant", width = "100%"),
          rep_note("BUCSS assumes the original was published because its result was significant, and corrects for that publication bias as well as for the uncertainty in its estimate. A Registered Report, or a journal that publishes whatever a study finds, had no such filter: choose that, and only the uncertainty is corrected for (Anderson, Kelley & Maxwell, 2017). The other goals are the same either way."),
        NULL)),
      # The simple answer first (colleague review C-14, 12 November
      # 2026): the sample size to find the effect significant again,
      # with the usual settings, before the goals and beliefs.
      rep_card("The quick answer", class = "rep-quick-card",
        div(class = "rep-quick",
          rep_note("Two ways to the sample size: the quick answer here, from the numbers above, or the original's design on its own card, below, with that card's full options and its exact test. The quick answer uses a normal approximation, so for a t-test it can ask for a few people fewer than the card."),
          actionButton("rep_run_quick", "Show the sample size to replicate it", class = "btn btn-primary",
            onclick = "var r = document.querySelector('input[name=rep_section][value=goals]'); if (r) { r.click(); r.closest('.replication-workspace').scrollIntoView(); }"),
          rep_note("It opens Goals and uses the usual settings (a significance level of .05 and 80% power) unless you have chosen others there, where you can also change what the replication should show."))),
      uiOutput("rep_card_status")),

    section("goals",
      rep_card("What the replication should show",
        conditionalPanel(replication_one_number_js,
          conditionalPanel("input.rep_design == 'anova'",
            p(class = "small rep-anova-one-df", role = "note", "This ANOVA effect has one degree of freedom, so it is a comparison of two means: its F is the square of that comparison's t (F(1, df) = t\u00b2). So every goal below applies, with its effect as a d (d_z when the same people are compared); the results say which comparison it is. BUCSS's correction of the original is shown beside them.")),
          rep_note("Start with what the replication should show. One main criterion sets the sample size; any others you tick are reported beside it, as their chance at that sample size, so the plan can use p-values, Bayes factors or both (Anderson & Maxwell, 2016). Fix them before collecting data."),
          radioButtons("rep_purpose", "What should the replication show?", choices = replication_purposes_ui, selected = "confirm", width = "100%"),
          selectInput("rep_goal", "The main criterion: the one that sets the sample size", choices = replication_goal_choices,
            selected = "auto", selectize = FALSE, width = "100%"),
          rep_note("The usual one: a significant result in the original's direction to show it again (the original's Bayes factor test for a Bayesian original), a Bayes factor to settle it either way, and an equivalence test to show it is absent."),
          radioButtons("rep_prior", "What you believe about the true effect", choiceNames = lapply(names(replication_prior_labels), function(p)
            tags$span(tags$strong(replication_prior_labels[[p]]), tags$span(class = "rep-tile-text", replication_prior_notes[[p]]))),
            choiceValues = names(replication_prior_labels), selected = "uncertain", width = "100%"),
          # Ten criteria: folded, with what is ticked by default said on the fold.
          tags$details(class = "rep-also-fold",
            tags$summary("Also report other criteria, as their chance at that sample size",
              tags$span(class = "small text-muted", " (ticked to start: a criterion that could show the effect is absent)")),
            checkboxGroupInput("rep_also", "Also report", choices = replication_also_choices,
              selected = "absence", width = "100%")),
          conditionalPanel(replication_needs_js(c("agreement", "negligible"), absent = TRUE),
            uiOutput("rep_from_notes_smallest"),
            field("rep_smallest", "The smallest effect that would matter to you (positive: d, d_z or r; for another design, on its own scale, a ratio above 1)",
              help = "An effect smaller than this would not matter for the theory or in practice; the equivalence test and agreement are judged against it. Left blank, the plan uses the effect the original study had a one-in-three chance of detecting (d33, Simonsohn, 2015), a bound for when nothing else justifies one; another design needs a number here.")),
          NULL),
        conditionalPanel(replication_bucss_only_js,
          rep_note("This ANOVA effect has several degrees of freedom, so it has no one number for the goals the one-number designs have. Two routes plan a significant F test for it: from the original, with its effect corrected for publication bias, because a study is more likely to be published when its test is significant, and for the uncertainty in its estimate, by BUCSS (Anderson, Kelley & Maxwell, 2017); and from the smallest effect that would matter to you, by the ANOVA card's own F test. The second doesn't depend on the original's effect at all."),
          radioButtons("rep_assurance", "Assurance: how sure you want to be that the replication reaches the power below", choices = replication_assurances_ui,
            selected = "0.8", width = "100%"),
          rep_note("The corrected effect is itself uncertain. At 50% assurance the plan uses its best estimate, so the replication reaches the power aimed for about half the time; at 80% it uses a smaller effect, so it reaches it four times in five. More assurance needs more people. The original's significance level, under The original study, is taken as the threshold its result had to pass to be published."),
          conditionalPanel(replication_changes_js,
            p(class = "small rep-changes-note", role = "note",
              "You noted changes under How the replication differs. The more a replication changes, the more its true effect can differ from the original's; BUCSS has no setting for variation between studies, so choose a higher assurance here, or plan from the smallest effect that would matter.")),
          field("rep_anova_smallest", "Optional: the smallest effect that would matter to you, as a partial eta-squared",
            help = "An effect smaller than this would not matter for the theory or in practice. There is no default: it is your judgement, from theory, practice or earlier work, and the original's effect is not a good guide to it. For a repeated-measures or mixed design, give it as those analyses report it (SPSS, R and JASP), so no correlation between measurements is needed. A two-factor within-subjects design is planned from its means on its own card.")),
        NULL),
      conditionalPanel(replication_one_number_js,
        rep_card("How much the effect may vary between studies",
          conditionalPanel(replication_changes_js,
            p(class = "small rep-changes-note", role = "note",
              "You noted changes under How the replication differs. The more a replication changes, the more its true effect can differ from the original's, so allow more variation between studies here, and consider the shrunk belief above; a conceptual replication should use both.")),
          conditionalPanel("input.rep_design != 'correlation' && input.rep_design != 'generic'",
            selectInput("rep_tau", "How much the true effect may vary between studies (an SD in d, or d_z for pairs)", choices = replication_taus, selected = "0.05", selectize = FALSE, width = "100%"),
            rep_note("Kenny and Judd (2019) use 0.05, 0.125 and 0.20 as examples and argue zero should not be the default; they are a quarter of Cohen's 0.2, 0.5 and 0.8, so treat them as illustrations, not estimates for your field. It starts at the smallest.")),
          conditionalPanel("input.rep_design == 'correlation'",
            selectInput("rep_tau_r", "How much the true correlation may vary between studies (an SD on Fisher's z, close to r for small values)", choices = replication_taus_r, selected = "0.025", selectize = FALSE, width = "100%"),
            rep_note("The correlation card's values: Kenny and Judd's (2019) rule of a quarter of the effect, applied to r = .1, .3 and .5. It starts at the smallest.")),
          conditionalPanel("input.rep_design == 'generic'",
            field("rep_tau_value", "How much the true effect may vary between studies (optional): an SD on the effect's own scale",
              help = "In the units of the effect you entered: for a ratio, of its log; for a correlation, of Fisher's z. Kenny and Judd's examples are in d, so they can't be used here; a meta-analysis of this effect that reports tau is the best source. Empty plans for no variation.")),
          rep_note("Laboratories, samples and procedures differ, so the true effect can differ from study to study, and assuming it can't makes a replication look easier than it is. The best source is a meta-analysis of this effect that reports tau. It applies to the uncertain and shrunk beliefs."),
        NULL)),
      rep_card("How sure the replication should be",
        shortcut_field("rep_alpha", "The replication's significance level", c("0.05", "0.01", "0.005"),
          c("Use 0.05, the usual level", "0.01", "0.005"),
          help = "0.01 or 0.005 fit a replication that runs many tests, or a claim that needs stronger evidence."),
        conditionalPanel(paste(replication_one_number_js, "&&", replication_needs_js(c("significance", "pooled"), confirm = TRUE)),
          radioButtons("rep_sided", "Is the significance test two-sided or one-sided?", choices = replication_sided_ui,
            selected = "two.sided", width = "100%"),
          rep_note("Either way, only a result in the original's direction counts as a success. A one-sided test at .05 needs fewer people than a two-sided test at .05, as a one-sided test at .025 is the two-sided one; choose it only if the replication's preregistration says so.")),
        shortcut_field("rep_power", "The chance of success to aim for", c("0.8", "0.9", "0.95"), c("80%", "90%", "95%"),
          help = "The main criterion's sample size gives it this chance; a higher chance needs more people."),
        conditionalPanel(paste(replication_one_number_js, "&&", replication_needs_js(replication_bf_goals, either = TRUE)),
          radioButtons("rep_threshold", "Evidence threshold for the Bayes factors: the Bayes factor the replication should reach",
            choiceNames = c("3", "6", "10 (a common threshold)", "30"), choiceValues = c("3", "6", "10", "30"), selected = "10", inline = TRUE),
          rep_note("Choose the evidence your claim needs: 10 is a common threshold, and so is 3; there is no correct one.")),
        conditionalPanel(replication_one_number_js,
          field("rep_n_at", "Optional: a sample size you could recruit (in total), to see each goal's chance at it")),
        NULL),
      # One bar for what is still needed and the button, kept in view
      # as the input screens' is.
      div(class = "action-bar rep-run-bar d-flex align-items-center gap-2", role = "region", `aria-label` = "Show the sample size",
        uiOutput("rep_still_needed", inline = TRUE),
        actionButton("rep_run", "Show the sample size", class = "btn btn-primary")),
      div(class = "rep-answer", uiOutput("rep_result"))),

    section("differences",
      tags$fieldset(class = "form-group-box rep-keeps", tags$legend(class = "h6", "What the replication keeps"),
        radioButtons("rep_keeps", "Which describes your study best?", choices = replication_keeps_ui, selected = character(0), width = "100%"),
        conditionalPanel("input.rep_keeps == 'extension'",
          rep_note("The original comparison is planned as a replication under Goals and on the original's card. Each thing you add (a new condition, a moderator, another measure) is an analysis of its own, with its own effect size: an extension's effect has no original estimate, so it is planned as an ordinary power analysis and reported under its own heading. Plan for whichever needs more people."),
          actionButton("rep_add_extension", "Add an extension analysis", class = "btn btn-outline-primary")),
        conditionalPanel(paste("input.rep_keeps == 'conceptual' &&", replication_bucss_only_js),
          rep_note("With changed materials, measures or people, the true effect can differ more from the original's than in a close replication, and a failure is harder to read: it may mean the idea is wrong, or that the change mattered. BUCSS's assurance allows for the original's sampling error and publication bias, but nothing in it allows for a changed procedure changing the effect, so powerkit changes no setting for you. Choose the assurance under Goals from the table of every level in the results, and say why in your write-up; or, if the original's effect is a weak guide to the new procedure, plan from the smallest effect that would matter to you, under Goals.")),
        conditionalPanel(paste("input.rep_keeps == 'conceptual' &&", replication_one_number_js),
          rep_note("With changed materials, measures or people, the true effect can differ more from the original's than in a close replication, and a failure is harder to read: it may mean the idea is wrong, or that the change mattered. So plan from the shrunk belief and allow more variation between studies, and keep the checks below."),
          actionButton("rep_use_conceptual", "Plan it this way: the shrunk belief and more variation", class = "btn btn-outline-primary"),
          uiOutput("rep_conceptual_done")),
        conditionalPanel("input.rep_keeps == 'new'",
          rep_note("If the study doesn't test the original comparison, the original's effect doesn't tell you what to expect, and a replication plan's goals don't apply. Plan it as an ordinary study, with the smallest effect that would matter to you or one from earlier work."),
          actionButton("rep_start_study_plan", "Start a study plan instead", class = "btn btn-outline-primary"))),
      tags$fieldset(class = "form-group-box", tags$legend(class = "h6", "How the replication differs"),
        rep_note("No replication repeats a study exactly. Writing down what changes, and why, says how the result should be read: whether a different result would count against the finding, or point to a condition it depends on. If much changes, allow for more variation between studies under Goals."),
        box("rep_diff_people", "The people: who takes part, where and when, and how they differ from the original sample"),
        box("rep_diff_materials", "The materials and measures: what is translated, updated or replaced"),
        box("rep_diff_procedure", "The procedure and setting: for example online instead of in the lab"),
        box("rep_diff_analysis", "The analysis: the original's test, and anything added or changed"),
        box("rep_diff_expect", "Would the original authors expect the same effect under these conditions? If not, why replicate this way?"),
        conditionalPanel("input.rep_keeps == 'extension' || input.rep_keeps == 'conceptual'",
          box("rep_diff_checks", "The checks that show the changed study still tests the same thing: for example a manipulation check, the original's measure kept beside a new one, or a condition where the effect is known to appear")))),

    section("writeup",
      tags$fieldset(class = "form-group-box", tags$legend(class = "h6", "Write-up"),
        conditionalPanel("input.labs_outcome != 'not_worth'", rep_note("One plan built from everything here, the notes, the original study, the goals, how the replication differs and the original's analysis on its card, for a preregistration or a registered report. Sections not filled in yet are marked, so it can be downloaded at any stage.")),
        div(class = "nav-buttons",
          document_menu("rep_document", "rep_docx", "rep_markdown", "Save as PDF or print", "the replication plan", class = "btn btn-primary"),
          conditionalPanel("input.labs_outcome != 'not_worth'", inline = TRUE,
            download_button("rep_script", "Download the R script", class = "btn btn-outline-primary"))),
        uiOutput("rep_writeup_note")),
      # The document as it will read, updated as the plan is filled in.
      tags$details(class = "rep-preview", open = NA,
        tags$summary("Preview the write-up"),
        uiOutput("rep_preview"))))
}

# A text box with buttons that fill in conventional values, as the input
# screens' alpha and power boxes have (forms_ui.R): the box starts empty,
# so choosing a value stays the user's act (colleague review P-04).
shortcut_field <- function(id, label, values, labels, help = NULL) {
  div(class = "form-field", rep_number_input(textInput(id, label, value = "", width = "100%"), id),
    div(class = "usual-values", lapply(seq_along(values), function(i) tags$button(type = "button",
      class = "btn btn-sm btn-outline-secondary usual-value", id = sprintf("%s_usual%s", id, if (i > 1) paste0("_", i) else ""),
      `data-target` = id, `data-value` = values[[i]],
      onclick = "var e = document.getElementById(this.getAttribute('data-target')); e.value = this.getAttribute('data-value'); e.dispatchEvent(new Event('input', {bubbles: true})); e.dispatchEvent(new Event('change', {bubbles: true})); e.focus();",
      labels[[i]]))),
    if (!is.null(help)) rep_note(help))
}

replication_citations <- function(path = labs_refs_path(), keys = replication_ref_keys) {
  texts <- vapply(keys, function(k) labs_citation(path, key = k, fallback = ""), character(1))
  paste(texts[nzchar(texts)], collapse = " ")
}

# One reference's text with its <https://...> links as links.
reference_with_links <- function(text) {
  parts <- regmatches(text, gregexpr("<https?://[^>]+>", text), invert = NA)[[1]]
  lapply(parts, function(x) if (grepl("^<https?://", x)) {
    url <- substr(x, 2L, nchar(x) - 1L)
    tags$a(href = url, target = "_blank", rel = "noopener", url)
  } else x)
}

# The plan's references, once, folded at its foot (colleague review P-07):
# the pre-replication notes' paper and the planner's, one per line.
replication_references_ui <- function(path = labs_refs_path(), keys = c(labs_ref_key, replication_ref_keys)) {
  texts <- vapply(keys, function(k) labs_citation(path, key = k, fallback = ""), character(1))
  texts <- unique(texts[nzchar(texts)])
  if (!length(texts)) return(NULL)
  tags$details(class = "rep-references small mt-3",
    tags$summary(sprintf("References (%d)", length(texts))),
    tags$ul(class = "list-unstyled mt-2", lapply(texts, function(t) tags$li(class = "mb-1", reference_with_links(t)))))
}

# Every field the planner keeps, for the file and the write-up.
replication_field_ids <- c("rep_study", "rep_design", "rep_analysis", "rep_bf", "rep_bf_both", "rep_original_prior", "rep_prior_scale",
  "rep_post_from", "rep_post_sd", "rep_cri_lower", "rep_cri_upper", "rep_cri_level", "rep_effect_name", "rep_scale", "rep_effect", "rep_effect_type", "rep_effect_r", "rep_se_from", "rep_se",
  "rep_ci_lower", "rep_ci_upper", "rep_ci_level", "rep_statistic", "rep_f", "rep_n1", "rep_n2", "rep_n", "rep_original_alpha", "rep_published",
  "rep_purpose", "rep_also", "rep_sided", "rep_smallest", "rep_tau", "rep_tau_r", "rep_tau_value", "rep_alpha", "rep_power", "rep_threshold", "rep_n_at", "rep_goal", "rep_prior",
  "rep_diff_people", "rep_diff_materials", "rep_diff_procedure", "rep_diff_analysis", "rep_diff_expect", "rep_keeps", "rep_diff_checks",
  "rep_anova_kind", "rep_levels_a", "rep_levels_b", "rep_anova_effect", "rep_f_from", "rep_anova_f", "rep_eta", "rep_df_error",
  "rep_epsilon", "rep_assurance", "rep_anova_smallest")

# The fields a calculation depends on: a result is out of date once any
# of them changes (the study's name and how the replication differs only
# label the write-up).
replication_calc_fields <- setdiff(replication_field_ids,
  c("rep_study", "rep_effect_name", "rep_keeps", grep("^rep_diff_", replication_field_ids, value = TRUE)))
replication_calc_key <- function(values) {
  lapply(stats::setNames(replication_calc_fields, replication_calc_fields), function(id) {
    x <- values[[id]] %||% ""
    if (is.character(x)) trimws(x) else x
  })
}

# The engine's arguments from the fields: numbers parsed, blanks NULL.
replication_args <- function(values) {
  v <- function(id) trimws(as.character(values[[id]] %||% ""))
  num <- function(id, default = NULL) {
    if (!nzchar(v(id))) return(default)
    x <- suppressWarnings(as.numeric(v(id)))
    if (is.na(x)) NA_real_ else x
  }
  design <- v("rep_design")
  if (!nzchar(design)) design <- "two_groups"
  if (identical(design, "anova") && !replication_anova_one_df(values)) return(replication_anova_args(values))
  args <- list(design = design, original_effect = num("rep_effect", NA_real_),
    original_alpha = num("rep_original_alpha", 0.05), alpha = num("rep_alpha", 0.05),
    power = num("rep_power", 0.8), tau = replication_tau_value(values), smallest_effect = num("rep_smallest"),
    threshold = num("rep_threshold", 10), n = num("rep_n_at"))
  if (identical(v("rep_published"), "any")) args$publication_filter <- FALSE
  if (identical(v("rep_sided"), "one.sided")) args$alternative <- "one.sided"
  if (identical(design, "anova")) {
    # A 1-df ANOVA effect: its design, levels, effect and F (or partial
    # eta-squared), which the engine plans as the two-mean comparison.
    anova <- replication_anova_args(values)
    args$original_effect <- NULL
    args$design <- anova$design
    args[c("original_n", "levels_a", "levels_b", "effect")] <- anova[c("original_n", "levels_a", "levels_b", "effect")]
    if (!is.null(anova$original_partial_eta)) {
      args$original_partial_eta <- anova$original_partial_eta
      args$original_df_error <- anova$original_df_error
    } else {
      args$original_f <- anova$original_statistic
    }
    return(Filter(Negate(is.null), args))
  }
  if (identical(design, "two_groups")) {
    args$original_n1 <- num("rep_n1", NA_real_)
    args$original_n2 <- num("rep_n2", NA_real_)
  } else {
    args$original_n <- num("rep_n", NA_real_)
  }
  if (identical(design, "generic")) {
    args$scale <- if (v("rep_scale") %in% c("none", "log", "fisher_z")) v("rep_scale") else "none"
    args$effect_name <- if (nzchar(v("rep_effect_name"))) v("rep_effect_name") else NULL
    from <- if (nzchar(v("rep_se_from"))) v("rep_se_from") else "se"
    if (identical(from, "ci")) {
      args$original_ci <- c(num("rep_ci_lower", NA_real_), num("rep_ci_upper", NA_real_))
      level <- num("rep_ci_level", 95)
      args$original_ci_level <- if (!is.na(level) && level > 1) level / 100 else level
    } else if (identical(from, "statistic")) {
      args$original_statistic <- num("rep_statistic", NA_real_)
    } else if (identical(from, "f")) {
      args$original_f <- num("rep_f", NA_real_)
    } else {
      args$original_se <- num("rep_se", NA_real_)
    }
  }
  analysis <- if (v("rep_analysis") %in% replication_analyses_ui) v("rep_analysis") else "test"
  # Both a test and a Bayes factor: the effect comes from the test, and
  # the Bayes factor's prior scale repeats the original's own test.
  both <- identical(analysis, "both")
  if (both) {
    analysis <- "test"
    if (design %in% c("two_groups", "one_sample", "paired")) args$original_prior_scale <- num("rep_prior_scale", 1 / sqrt(2))
  }
  type <- v("rep_effect_type")
  if (identical(analysis, "test") && design %in% c("two_groups", "one_sample", "paired") &&
      type %in% c("t", "d_rm") && !(identical(type, "d_rm") && !identical(design, "paired"))) {
    args$original_effect_type <- type
    if (identical(type, "d_rm")) args$original_r <- num("rep_effect_r", NA_real_)
  }
  if (!identical(analysis, "test")) {
    args$original_analysis <- analysis
    args$original_prior_scale <- num("rep_prior_scale", 1 / sqrt(2))
  }
  if (identical(analysis, "bayes_factor")) {
    args$original_effect <- NULL
    args$original_bf <- num("rep_bf", NA_real_)
  }
  if (identical(analysis, "posterior")) {
    args[c("original_se", "original_ci", "original_ci_level", "original_statistic")] <- NULL
    args$original_prior <- if (nzchar(v("rep_original_prior"))) v("rep_original_prior") else "default"
    if (identical(v("rep_post_from"), "ci")) {
      args$original_ci <- c(num("rep_cri_lower", NA_real_), num("rep_cri_upper", NA_real_))
      level <- num("rep_cri_level", 95)
      args$original_ci_level <- if (!is.na(level) && level > 1) level / 100 else level
    } else {
      args$original_se <- num("rep_post_sd", NA_real_)
    }
  }
  args
}

# An ANOVA original's arguments for the engine's replication_bucss(): a
# design with one factor tests that factor; in a mixed design the first
# factor is the between-subjects one and the second the within-subjects one.
replication_anova_args <- function(values) {
  v <- function(id) trimws(as.character(values[[id]] %||% ""))
  num <- function(id, default = NULL) {
    if (!nzchar(v(id))) return(default)
    x <- suppressWarnings(as.numeric(v(id)))
    if (is.na(x)) NA_real_ else x
  }
  kind <- if (v("rep_anova_kind") %in% replication_anova_kinds_ui) v("rep_anova_kind") else "between"
  effect <- if (v("rep_anova_effect") %in% replication_anova_effects_ui) v("rep_anova_effect") else "factor_a"
  levels_b <- num("rep_levels_b")
  if (is.null(levels_b) && !identical(kind, "mixed")) effect <- "factor_a"
  if (identical(kind, "mixed")) effect <- c(factor_a = "between", factor_b = "within", interaction = "interaction")[[effect]]
  assurance <- num("rep_assurance", 0.8)
  args <- list(design = paste0("anova_", kind), original_n = num("rep_n", NA_real_), levels_a = num("rep_levels_a", NA_real_),
    levels_b = levels_b, effect = effect, original_alpha = num("rep_original_alpha", 0.05), alpha = num("rep_alpha", 0.05),
    power = num("rep_power", 0.8), assurance = sort(unique(c(replication_assurance_levels, assurance))))
  if (!identical(kind, "between")) args$epsilon <- num("rep_epsilon", 1)
  if (identical(v("rep_published"), "any")) args$publication_filter <- FALSE
  if (identical(v("rep_f_from"), "eta")) {
    args$original_partial_eta <- num("rep_eta", NA_real_)
    args$original_df_error <- num("rep_df_error", NA_real_)
  } else {
    args$original_statistic <- num("rep_anova_f", NA_real_)
  }
  args
}

# What is missing before the engine can plan, in the field's words.
# The replication's own settings under Goals, which start empty (P-04):
# what is still to choose, in words.
replication_settings_missing <- function(values) {
  v <- function(id) nzchar(trimws(as.character(values[[id]] %||% "")))
  c(if (!v("rep_alpha")) "the significance level", if (!v("rep_power")) "the chance of success to aim for")
}

replication_missing <- function(values) {
  v <- function(id) nzchar(trimws(as.character(values[[id]] %||% "")))
  if (replication_is_anova(values)) {
    eta <- identical(values$rep_f_from, "eta")
    return(c(
      if (!eta && !v("rep_anova_f")) "its F statistic",
      if (eta && !v("rep_eta")) "its partial eta-squared",
      if (eta && !v("rep_df_error")) "its F test's error degrees of freedom",
      if (!v("rep_levels_a")) "the levels of its first factor",
      if (identical(values$rep_anova_kind, "mixed") && !v("rep_levels_b")) "the levels of its second (within-subjects) factor",
      if (!v("rep_n")) "the number of people the original study analysed"))
  }
  two <- identical(values$rep_design %||% "two_groups", "two_groups") || !v("rep_design")
  generic <- identical(values$rep_design, "generic")
  from <- if (v("rep_se_from")) values$rep_se_from else "se"
  analysis <- if (v("rep_analysis")) values$rep_analysis else "test"
  if (identical(analysis, "both")) analysis <- "test"
  from_bf <- identical(analysis, "bayes_factor")
  posterior <- identical(analysis, "posterior")
  by_se <- generic && !posterior
  missing <- c(
    if (from_bf && !v("rep_bf")) "the original's Bayes factor",
    if (!from_bf && !v("rep_effect")) if (posterior) "the posterior's mean" else "the effect the original study reported",
    if (posterior && !identical(values$rep_post_from, "ci") && !v("rep_post_sd")) "its posterior SD",
    if (posterior && identical(values$rep_post_from, "ci") && (!v("rep_cri_lower") || !v("rep_cri_upper"))) "its credible interval",
    if (by_se && identical(from, "se") && !v("rep_se")) "its standard error",
    if (by_se && identical(from, "ci") && (!v("rep_ci_lower") || !v("rep_ci_upper"))) "its confidence interval",
    if (by_se && identical(from, "statistic") && !v("rep_statistic")) "its test statistic",
    if (by_se && identical(from, "f") && !v("rep_f")) "its F statistic",
    if (identical(analysis, "test") && identical(values$rep_design, "paired") && identical(values$rep_effect_type, "d_rm") &&
      !v("rep_effect_r")) "the correlation between the original's two measurements",
    if (two && (!v("rep_n1") || !v("rep_n2"))) "the original study's two group sizes",
    if (!two && !v("rep_n")) "the number of people (or pairs) the original study analysed"
  )
  missing
}

replication_problem <- function(e) {
  if (!inherits(e, "powerkit_error")) {
    return("Powerkit couldn't work this out: something went wrong in its engine. Please report this, with the values you entered.")
  }
  conditionMessage(e)
}

# A plain-words problem for the screen, as the engine's are.
replication_stop <- function(message) {
  stop(structure(class = c("powerkit_error", "error", "condition"), list(message = message, call = NULL)))
}

# Runs a plan: every goal's sample size from the engine, then, at the main
# criterion's sample size, the chance of it and of each criterion also
# reported (the engine's at_n; the app only chooses which to ask for).
# Agreement and too small to matter need a bound: left blank, it is d33
# (Simonsohn, 2015), from the same plan's small-telescopes yardstick.
replication_run <- function(values, engine, bucss = NULL, smallest = NULL) {
  args <- replication_args(values)
  if (replication_bucss_only(values)) {
    plan <- do.call(bucss, args)
    plan$anova <- TRUE
    plan$chosen_assurance <- suppressWarnings(as.numeric(values$rep_assurance %||% "0.8"))
    if (is.na(plan$chosen_assurance) || !plan$chosen_assurance %in% plan$sizes$assurance) plan$chosen_assurance <- 0.8
    # From the smallest effect that would matter, when given: the ANOVA
    # card's own F test (the engine's replication_anova_smallest()).
    eta <- suppressWarnings(as.numeric(trimws(as.character(values$rep_anova_smallest %||% ""))))
    if (!is.na(eta) && !is.null(smallest)) {
      plan$smallest <- tryCatch(do.call(smallest, c(args[c("design", "levels_a", "levels_b", "effect")],
        list(smallest_effect = eta, alpha = args$alpha, power = args$power))),
        error = function(e) list(problem = replication_problem(e)))
    }
    return(plan)
  }
  plan <- do.call(engine, args)
  bounded <- c("agreement", "negligible")
  bound_possible <- !is.null(args$smallest_effect) || !is.null(plan$telescope)
  choice <- replication_resolve_goals(values, c(unique(plan$goals$goal), if (bound_possible) bounded))
  if (choice$goal %in% bounded && !bound_possible) {
    replication_stop(sprintf("%s needs the smallest effect that would matter: enter it under Goals. The default bound, d33, comes from the original's significance test, which %s.",
      if (identical(choice$goal, "negligible")) "The equivalence test" else "Agreement with the original",
      if (identical(plan$inputs$design, "generic")) "isn't known for another design" else "a Bayesian original didn't have"))
  }
  if (!choice$goal %in% plan$goals$goal && !choice$goal %in% bounded) {
    replication_stop(sprintf("The main criterion you chose (%s) isn't available for this original: %s Choose another under Goals.",
      replication_lc(replication_goal_labels[[choice$goal]]),
      if (choice$goal %in% c("bf_repeat", "bf_null")) "the default Bayes factor t-test needs a t-test design (two groups, one group or pairs)."
      else if (identical(choice$goal, "small_telescopes")) "small telescopes needs the original's own significance test, so for another design it is planned on the design's card."
      else "it can't be planned from what was entered."))
  }
  if (any(bounded %in% c(choice$goal, choice$also)) && is.null(args$smallest_effect)) {
    args$smallest_effect <- plan$telescope$effect
    plan <- do.call(engine, args)
    choice$bound <- "d33"
  }
  plan$choice <- choice
  main <- replication_main(plan, choice$goal, choice$prior)
  if (!is.na(main$row$n)) {
    at <- do.call(engine, utils::modifyList(args, list(n = main$row$n)))$at_n
    plan$at_main <- list(n = main$row$n, chances = at[at$goal %in% c(choice$goal, choice$also), , drop = FALSE])
  }
  plan
}

replication_n_words <- function(plan, n) {
  if (is.na(n)) return(NA_character_)
  # A 1-df ANOVA effect planned as pairs: the same people in each condition.
  if (!is.null(plan$anova_effect) && identical(plan$inputs$design, "paired")) return(sprintf("%s participants", format(n, big.mark = ",")))
  switch(plan$inputs$design,
    two_groups = sprintf("%s participants (%s per group)", format(n, big.mark = ","), format(n / 2, big.mark = ",")),
    paired = sprintf("%s pairs", format(n, big.mark = ",")),
    sprintf("%s participants", format(n, big.mark = ",")))
}

replication_cell <- function(plan, row) {
  if (!is.na(row$n)) return(replication_n_words(plan, row$n))
  switch(row$reason %||% "",
    any_size = sprintf("Any size: even the smallest replication has %s, because the original's result already carries it",
      if (is.na(row$limit)) "more than the chance aimed for" else if (row$limit >= 0.995) "a chance above 99%"
      else paste(replication_a_pct(row$limit), "chance")),
    not_reachable = if (is.na(row$limit) || row$limit < 0.005) "Not reachable with this original study, however large the replication" else
      sprintf("Not reachable: at most %s, however large the replication", replication_pct(row$limit)),
    over_max = "More than 100,000",
    "Not found")
}

replication_pct <- function(x) if (is.na(x)) "unknown" else sprintf("%.0f%%", 100 * x)
# With its article: "an 80%", "a 90%" (said "eighty", "ninety").
# A label in a sentence: its first letter in lower case, the rest as written
# ("Bayes factor" stays capitalised).
replication_lc <- function(x) paste0(tolower(substr(x, 1, 1)), substring(x, 2))

replication_a_pct <- function(x) {
  pct <- replication_pct(x)
  if (grepl("^(8|11%|18%|11[.]|18[.])", pct)) paste("an", pct) else paste("a", pct)
}

# The table: one row per goal, a column per belief; the goals planned for
# no effect have one value across the row.
replication_table_ui <- function(plan) {
  g <- plan$goals
  goals <- intersect(names(replication_goal_labels), unique(g$goal))
  head <- tags$tr(tags$th(scope = "col", "Goal"),
    lapply(names(replication_prior_labels), function(p) tags$th(scope = "col", replication_prior_labels[[p]])))
  rows <- lapply(goals, function(goal) {
    rows <- g[g$goal == goal, ]
    label <- tags$th(scope = "row", replication_goal_labels[[goal]], tags$br(), tags$span(class = "small text-muted", replication_goal_notes[[goal]]))
    if (all(is.na(rows$prior))) {
      return(tags$tr(label, tags$td(colspan = 3, replication_cell(plan, rows[1, ]), " (planned for no effect)")))
    }
    tags$tr(label, lapply(names(replication_prior_labels), function(p) tags$td(replication_cell(plan, rows[rows$prior %in% p, ][1, ]))))
  })
  tags$table(class = "table table-sm result-table", id = "rep-table",
    tags$caption(sprintf("Replication sample size (in total) for %s chance of each goal", replication_a_pct(plan$inputs$power))),
    tags$thead(head), tags$tbody(rows))
}

replication_chances_ui <- function(plan) {
  a <- plan$at_n
  if (is.null(a)) return(NULL)
  goals <- intersect(names(replication_goal_labels), unique(a$goal))
  rows <- lapply(goals, function(goal) {
    rows <- a[a$goal == goal, ]
    label <- tags$th(scope = "row", replication_goal_labels[[goal]])
    if (all(is.na(rows$prior))) return(tags$tr(label, tags$td(colspan = 3, replication_pct(rows$chance[1]), " (if there is no effect)")))
    tags$tr(label, lapply(names(replication_prior_labels), function(p) tags$td(replication_pct(rows$chance[rows$prior %in% p][1]))))
  })
  tags$table(class = "table table-sm result-table", id = "rep-chances",
    tags$caption(sprintf("The chance of each goal with %s", replication_n_words(plan, plan$inputs$n))),
    tags$thead(tags$tr(tags$th(scope = "col", "Goal"),
      lapply(replication_prior_labels, function(l) tags$th(scope = "col", l)))),
    tags$tbody(rows))
}

# What a goal asks, as the end of "a chance of ...", for the headline.
replication_goal_aims <- c(
  significance = "finding the effect significant again, in the original's direction",
  pooled = "a significant result when the two studies are pooled",
  agreement = "a result that agrees with the original's, within the smallest effect that matters",
  bf_replication = "evidence that the original's effect was found again (a replication Bayes factor)",
  bf_sceptical = "evidence for the effect that would convince a sceptic (a sceptical Bayes factor)",
  bf_repeat = "evidence for the effect from a default Bayes factor t-test",
  small_telescopes = "showing the original study was too small to have detected the effect (small telescopes)",
  negligible = "showing the effect is too small to matter (an equivalence test)",
  bf_null = "evidence for no effect from a default Bayes factor t-test"
)

# The answer first: the main criterion's sample size, under the chosen
# belief, in one sentence.
replication_main_headline <- function(plan) {
  ch <- plan$choice
  i <- plan$inputs
  m <- replication_main(plan, ch$goal, ch$prior)
  level <- if (ch$goal %in% replication_bf_goals) sprintf(" (a Bayes factor of at least %s)", format(i$threshold))
    else if (ch$goal %in% c("significance", "pooled", "agreement", "negligible", "small_telescopes")) sprintf(" (alpha = %s)", sub("^0", "", format(i$alpha))) else ""
  when <- if (m$no_effect) "if there is no effect" else switch(ch$prior,
    as_reported = "if the true effect is as large as reported",
    uncertain = "allowing for the uncertainty in the original's estimate",
    shrunk = "if the true effect is shrunk towards zero, as published effects often are")
  aim <- sprintf("%s chance of %s%s, %s", replication_a_pct(i$power), replication_goal_aims[[ch$goal]], level, when)
  if (!is.na(m$row$n)) return(p(class = "result-headline lead", sprintf("For %s, the replication needs %s.", aim, replication_n_words(plan, m$row$n))))
  p(class = "result-headline lead", sprintf("For %s: %s. Choose another main criterion under Goals to set the sample size.",
    aim, tolower(replication_cell(plan, m$row))))
}

# The original, read from its Bayes factor or posterior, in a sentence.
replication_bayes_original_words <- function(plan) {
  i <- plan$inputs
  o <- plan$original
  scale_words <- if (identical(i$design, "correlation") || identical(i$scale, "fisher_z")) " on Fisher's z scale"
    else if (identical(i$scale, "log")) " on the log scale" else ""
  if (identical(i$original_analysis, "bayes_factor")) {
    return(sprintf("The original's Bayes factor of %s (BF10), with its sample size and a Cauchy prior of scale %s, comes from a t statistic of %s: an effect of %s with a standard error of %s.",
      format(signif(i$original_bf, 3)), format(signif(i$original_prior_scale, 3)), format(signif(o$t, 3)),
      format(signif(o$estimate, 3)), format(signif(o$se, 3))))
  }
  sprintf("The original's posterior (from a %s prior) has a mean of %s and a standard deviation of %s%s, which stand in for its estimate and standard error.",
    i$original_prior, format(signif(i$original_effect, 3)), format(signif(o$se, 3)), scale_words)
}

# Where the replication goals' validation stands (docs/validation-log.md,
# "Replication plans"): every goal's chance agrees with a simulation of the
# method's model written separately, and small telescopes with t-tests on
# simulated data, but the published examples are still to be transcribed,
# so the plan says validation is in progress.
replication_validation_text <- paste(
  "Each goal's chance agrees with a separate simulation of the method's model, and small telescopes",
  "with t-tests on simulated people; the check against published examples is still to come.")

# The main criterion and those also reported, as their chance at the main
# criterion's sample size: the chosen belief first, the others beside it.
replication_main_chances_ui <- function(plan) {
  ch <- plan$choice
  if (is.null(ch)) return(NULL)
  notes <- tagList(
    if (identical(ch$bound, "d33")) p(class = "small", sprintf("The smallest effect that matters was left blank, so the equivalence test and agreement use %s = %s, the effect the original study had a one-in-three chance of detecting (Simonsohn, 2015). Enter your own under Goals if you can justify one.",
      plan$telescope$effect_name, format(signif(plan$telescope$effect, 3)))),
    if (isTRUE(ch$absence_missing)) rep_note("A criterion that could show the effect is absent is ticked, but it needs the smallest effect that would matter, and the default (d33) needs the original's significance test: enter the smallest effect under Goals to add it.", keep = TRUE))
  at <- plan$at_main
  if (is.null(at)) return(notes)
  a <- at$chances
  goals <- c(ch$goal, setdiff(intersect(names(replication_goal_labels), unique(a$goal)), ch$goal))
  priors <- c(ch$prior, setdiff(names(replication_prior_labels), ch$prior))
  rows <- lapply(goals, function(goal) {
    r <- a[a$goal == goal, ]
    label <- tags$th(scope = "row", replication_goal_labels[[goal]], if (identical(goal, ch$goal)) tags$span(class = "small text-muted", " (main criterion)"))
    if (all(is.na(r$prior))) return(tags$tr(label, tags$td(colspan = 3, replication_pct(r$chance[1]), " (if there is no effect)")))
    tags$tr(label, lapply(priors, function(p) tags$td(replication_pct(r$chance[r$prior %in% p][1]))))
  })
  tagList(
    tags$table(class = "table table-sm result-table", id = "rep-main-chances",
      tags$caption(sprintf("The chance of each criterion with %s", replication_n_words(plan, at$n))),
      tags$thead(tags$tr(tags$th(scope = "col", "Criterion"),
        lapply(priors, function(p) tags$th(scope = "col", replication_prior_labels[[p]], if (identical(p, ch$prior)) " (your belief)")))),
      tags$tbody(rows)),
    if (length(goals) == 1) p(class = "small text-muted", "Tick others under “Also report other criteria” to see their chance at this sample size."),
    notes)
}

# BUCSS's sample sizes (the engine's replication_bucss()), in words: the
# total, with the size of each group or cell where BUCSS gives one.
replication_bucss_n_words <- function(res, row) {
  if (is.na(row$n)) return(NA_character_)
  unit <- res$unit %||% ""
  pairs <- identical(res$inputs$design, "paired")
  total <- sprintf("%s %s", format(row$n, big.mark = ","), if (pairs) "pairs" else "participants")
  if (is.na(row$per_unit)) return(total)
  sprintf("%s (%s in each %s)", total, format(row$per_unit, big.mark = ","), if (grepl("cell", unit) && !grepl("between", unit)) "cell" else "group")
}

# What BUCSS corrected for: publication bias and uncertainty, or, for an
# original published whatever it found, uncertainty only.
replication_bucss_filtered <- function(res) !isFALSE(res$inputs$publication_filter)
replication_bucss_corrects <- function(res) {
  if (replication_bucss_filtered(res)) "publication bias and uncertainty" else "uncertainty (with no publication filter)"
}

# When BUCSS's numbers grow far past the original's (most often at 80%
# assurance for a result near its threshold): what that means, and the
# other routes to a sample size, offered as equals. TRUE when the larger
# assurance needs over three times the 50% figure, or over ten times the
# original's sample size.
replication_bucss_explodes <- function(res) {
  sz <- res$sizes[!is.na(res$sizes$n), ]
  if (!nrow(sz)) return(FALSE)
  if (nrow(sz) < nrow(res$sizes)) return(TRUE)
  half <- sz$n[sz$assurance == 0.5]
  top <- max(sz$n)
  (length(half) && top > 3 * half[[1]]) || top > 10 * res$inputs$original_n
}

replication_routes_ui <- function(res, anova = FALSE) {
  filtered <- replication_bucss_filtered(res)
  div(class = "rep-routes mt-2", id = "rep-routes",
    if (replication_bucss_explodes(res)) p(class = "small", tags$strong("Why the numbers are so large. "),
      if (filtered) "Corrected for publication bias, an original near its significance threshold is consistent with a much smaller effect than it reported, and the higher assurances plan for that small effect. "
      else "The original's estimate is uncertain, and the higher assurances plan for the low end of what it allows. ",
      "This is a finding about the original: how little it pins down the effect. It is not a sample size you have to reach."),
    p(class = "small mb-1", "Other ways to a sample size, each as sound as this one; say in the write-up which you use:"),
    tags$ul(class = "small",
      tags$li(tags$strong("The smallest effect that would matter. "), if (anova)
        "Plan from the effect you would not want to miss, rather than the original's: enter it under Goals, as a partial eta-squared, and the ANOVA card's own F test plans it beside BUCSS's numbers."
        else "Plan from the effect you would not want to miss, rather than the original's: enter it under Goals. This suits a conceptual replication or an extension, where the original's effect is a weaker guide anyway."),
      tags$li(tags$strong("What your resources allow. "), if (anova)
        "Fix the sample size you can reach and report the effect it can detect, on the design's card (Lakens, 2022)."
        else "Fix the sample size you can reach, enter it under Goals as the sample size to report chances at, and report what it can and cannot show (Lakens, 2022)."),
      tags$li(tags$strong("A sequential design. "), "Collect in stages and stop once the evidence is clear, which needs fewer people on average than a fixed sample planned for the worst case. The Bayesian planning tool under Tools plans one with a Bayes factor."),
      tags$li(tags$strong("Several originals, or a meta-analysis. "), "Where more than one study of the effect exists, their pooled estimate is a firmer start than any one of them."),
      if (filtered) tags$li(tags$strong("No publication filter. "), "If the original would have been published whatever it found, such as a Registered Report, say so under The original study: BUCSS then corrects for uncertainty only.")))
}

replication_bucss_reason_words <- function(res) {
  reasons <- res$sizes$reason
  if (any(reasons %in% "not_significant")) {
    return(sprintf("The original's result wasn't significant at its level of %s, so there is no publication threshold to correct for, and BUCSS can't plan from it. If the literature published results at a more lenient level, enter that as the original's significance level; if it would have been published whatever it found, say so under The original study.",
      format(res$inputs$original_alpha)))
  }
  if (any(!is.na(res$sizes$n))) return(sprintf("At the higher assurances, the original's result, corrected for %s, leaves no effect to plan for, so those can't be planned.", replication_bucss_corrects(res)))
  if (!replication_bucss_filtered(res)) return("Once corrected for the uncertainty in its estimate, the original's result leaves no effect to plan for: it is too weak to plan a replication from with BUCSS. Plan from the smallest effect that would matter instead, under Goals.")
  "Once corrected for publication bias and the uncertainty in its estimate, the original's result leaves no effect to plan for: it is too weak to plan a replication from with BUCSS. Plan from the smallest effect that would matter instead, under Goals."
}

# An ANOVA original: BUCSS's sample size for a significant F test at the
# chosen assurance, then every assurance for comparison.
replication_bucss_result_ui <- function(plan) {
  i <- plan$inputs
  sz <- plan$sizes
  chosen <- sz[sz$assurance == plan$chosen_assurance, ][1, ]
  aim <- sprintf("a significant F test for the %s (alpha = %s) with %s power, and %s assurance that the power is reached once the original's effect is corrected for %s",
    replication_anova_effect_words(i), sub("^0", "", format(i$alpha)), replication_pct(i$power), replication_pct(plan$chosen_assurance),
    replication_bucss_corrects(plan))
  headline <- if (!is.na(chosen$n)) sprintf("For %s, the replication needs %s.", aim, replication_bucss_n_words(plan, chosen))
    else sprintf("For %s: BUCSS can't plan this.", aim)
  # 50% beside the chosen assurance: the corrected estimate itself, the
  # middle of what the original allows (80% stays the default, BUCSS's own).
  half <- sz[sz$assurance == 0.5, ][1, ]
  beside <- if (!identical(plan$chosen_assurance, 0.5) && !is.na(half$n)) p(class = "small", sprintf(
    "At 50%% assurance, planning for the corrected estimate itself rather than allowing for it being too large, it needs %s.",
    replication_bucss_n_words(plan, half)))
  rows <- lapply(seq_len(nrow(sz)), function(k) {
    r <- sz[k, ]
    tags$tr(tags$th(scope = "row", replication_pct(r$assurance), if (identical(r$assurance, plan$chosen_assurance)) tags$span(class = "small text-muted", " (chosen)")),
      tags$td(if (is.na(r$n)) "Can't be planned" else replication_bucss_n_words(plan, r)),
      tags$td(if (is.na(r$actual_power)) "" else replication_pct(r$actual_power)))
  })
  div(class = "result-panel mt-2", role = "status",
    p(class = "result-headline lead", headline),
    beside,
    p(class = "small", tags$span(class = "badge-progress", "Validation in progress"), " ", replication_bucss_validation_text),
    if (any(!is.na(sz$reason))) p(replication_bucss_reason_words(plan)),
    replication_anova_smallest_ui(plan),
    tags$table(class = "table table-sm result-table", id = "rep-bucss-table",
      tags$caption(sprintf("Replication sample size (in total) for %s power, at each assurance", replication_pct(i$power))),
      tags$thead(tags$tr(tags$th(scope = "col", "Assurance"), tags$th(scope = "col", "Sample size"), tags$th(scope = "col", "Its power"))),
      tags$tbody(rows)),
    p(class = "small", replication_bucss_original_words(plan)),
    if (any(!is.na(sz$n))) replication_routes_ui(plan, anova = TRUE),
    rep_note("BUCSS plans the replication as the same design with the same number of levels, analysed with the same F test. A replication that changes the design, or tests one contrast instead of the omnibus effect, is planned on that analysis's card."),
    p(class = "small text-muted", sprintf("Calculated by powerkit's engine with BUCSS %s: %s.", plan$packages[[1]]$version,
      sub("assurance = a", "assurance", plan$function_used, fixed = TRUE))))
}

# Beside BUCSS: the sample size from the smallest effect that would
# matter, by the ANOVA card's own F test (the engine's
# replication_anova_smallest()), or a prompt for it.
replication_anova_smallest_ui <- function(plan) {
  s <- plan$smallest
  i <- plan$inputs
  if (is.null(s)) {
    return(p(class = "small", id = "rep-anova-smallest", tags$strong("From the smallest effect that would matter. "),
      "Enter it under Goals, as a partial eta-squared, to plan the same F test from it instead of the original's effect."))
  }
  if (!is.null(s$problem)) return(p(class = "small", id = "rep-anova-smallest", tags$strong("From the smallest effect that would matter. "), s$problem))
  cells <- if (!is.na(s$per_unit)) sprintf(" (%s in each %s)", format(s$per_unit, big.mark = ","),
    if (identical(i$design, "anova_mixed") || is.null(i$levels_b)) "group" else "cell") else ""
  div(class = "mt-2", id = "rep-anova-smallest",
    h4(class = "h6", "From the smallest effect that would matter"),
    p(sprintf("If the true effect is a partial eta-squared of %s, the smallest that would matter to you, a significant F test for the %s (alpha = %s) with %s power needs %s participants%s.",
      format(s$inputs$smallest_effect), replication_anova_effect_words(i), sub("^0", "", format(s$inputs$alpha)), replication_pct(s$inputs$power),
      format(s$n, big.mark = ","), cells)),
    p(class = "small", "This is the ANOVA card's own calculation, and it doesn't depend on the original's effect, so it fits a conceptual replication as well as a close one. If the original's corrected effect asks for fewer people than this, the replication could miss an effect you would care about; if more, it plans for an effect larger than you need to detect."),
    p(class = "small text-muted", sprintf("Calculated by powerkit's engine with %s.", s$function_used)))
}

replication_anova_effect_words <- function(i) {
  switch(i$effect, interaction = "interaction",
    between = "between-subjects factor", within = "within-subjects factor",
    factor_a = if (is.null(i$levels_b)) "factor" else "first factor", factor_b = "second factor")
}

replication_bucss_original_words <- function(plan) {
  i <- plan$inputs
  levels <- if (is.null(i$levels_b)) sprintf("one factor with %s levels", i$levels_a) else sprintf("a %s x %s design", i$levels_a, i$levels_b)
  from <- if (!is.null(i$original_partial_eta)) sprintf("its partial eta-squared of %s with F(%s, %s), which is an F of %s (Lakens, 2013)",
    format(i$original_partial_eta), format(plan$df_effect), format(i$original_df_error), format(signif(plan$f, 4)))
    else sprintf("its F of %s, with %s numerator degree%s of freedom", format(i$original_statistic), format(plan$df_effect), if (identical(plan$df_effect, 1)) "" else "s")
  sprintf("The original (%s, %s, %s people in total) is read from %s, %s%s.",
    replication_lc(plan$design_label), levels, format(i$original_n, big.mark = ","), from,
    if (replication_bucss_filtered(plan)) sprintf("assuming its literature published results significant at %s (BUCSS's alpha_prior)", format(i$original_alpha))
    else "with no publication filter, as it would have been published whatever it found (BUCSS's alpha_prior = 1)",
    if (!is.null(i$epsilon) && i$epsilon < 1) sprintf(", with a sphericity correction of epsilon = %s", format(i$epsilon)) else "")
}

# Where BUCSS's validation stands: its numbers are BUCSS's own, checked
# against direct calls and the figures recorded when it was chosen; the
# published example is still to be transcribed (docs/validation-log.md).
replication_bucss_validation_text <- paste(
  "These are BUCSS's own numbers, checked against direct calls to it and against the figures recorded when the method was chosen;",
  "the check against a published example is still to come.")

# Beside a t-test or correlation original's goals: BUCSS's sample size for
# a significant result, corrected for publication bias and uncertainty, at
# 50% and 80% assurance (the engine's plan$bias_corrected).
replication_bias_corrected_ui <- function(plan) {
  b <- plan$bias_corrected
  if (is.null(b)) return(NULL)
  sz <- b$sizes
  at <- function(a) {
    r <- sz[sz$assurance == a, ][1, ]
    if (is.na(r$n)) "can't be planned" else replication_bucss_n_words(b, r)
  }
  two <- identical(plan$inputs$design, "two_groups")
  unequal <- two && !identical(plan$inputs$original_n1, plan$inputs$original_n2)
  div(class = "mt-2", id = "rep-bias-corrected",
    h4(class = "h6", if (replication_bucss_filtered(b)) "Allowing for publication bias (BUCSS)" else "Allowing for uncertainty (BUCSS)"),
    if (all(!is.na(sz$reason))) p(class = "small", replication_bucss_reason_words(b))
    else p(class = "small", sprintf("Corrected for %s (Anderson, Kelley & Maxwell, 2017), a significant result with %s power needs %s at 50%% assurance (the corrected estimate itself) and %s at 80%% assurance (BUCSS's default). %s",
      if (replication_bucss_filtered(b)) "publication bias and the uncertainty in the original's estimate" else "the uncertainty in the original's estimate, as it faced no publication filter",
      replication_pct(plan$inputs$power), at(0.5), at(0.8),
      if (replication_bucss_filtered(b)) "It is another way to allow for published effects being too large, beside the shrunk belief above; say in the write-up which one the sample size uses."
      else "It is another way to allow for the original's uncertainty, beside the belief with its uncertainty above; say in the write-up which one the sample size uses.")),
    rep_note(paste("Why there are several numbers for one goal: each answers a different question about the original's effect.",
      "As reported takes it as exact. With its uncertainty allows for its sampling error. Shrunk towards zero, and BUCSS, also allow",
      "for published effects being too large: shrinking pulls the belief towards zero, the more so the weaker the evidence, and BUCSS",
      "undoes the significance filter that got the original published. BUCSS's 50% plans for its corrected estimate; its 80% plans",
      "for an effect the original can't rule out, which grows quickly when the original was near its threshold. None is the right one:",
      "choose the question that fits your study, and say which in the write-up."), label = "Why several numbers"),
    if (!all(!is.na(sz$reason))) replication_routes_ui(b),
    p(class = "small text-muted", paste0(
      "BUCSS's test is two-sided",
      if (identical(plan$inputs$alternative, "one.sided")) ", so the one-sided test is planned as a two-sided test at twice its level" else "",
      if (unequal) "; it assumes two equal groups, so it uses the original's total sample size" else "",
      sprintf(". Calculated with BUCSS %s.", b$packages[[1]]$version))))
}

# A 1-df ANOVA effect: which comparison it was planned as, and its F.
replication_anova_one_df_note <- function(plan) {
  a <- plan$anova_effect
  if (is.null(a)) return(NULL)
  df_note <- if (!identical(a$df_error, a$df_t)) sprintf(" The ANOVA's error degrees of freedom (%s) differ from that t-test's (%s); only small telescopes and the Bayes factor t-test use them, and the difference matters only in small samples.",
    format(a$df_error), format(a$df_t)) else ""
  p(class = "small", id = "rep-anova-one-df", sprintf(
    "The ANOVA effect has one degree of freedom, so it is planned as a comparison of two means: F(1, %s) = %s is the square of its t, %s (Lakens, 2013). Its effect is %s, so the smallest effect and the variation between studies are on that scale.%s",
    format(a$df_error), format(signif(a$f, 4)), format(signif(a$t, 4)), a$effect_words, df_note))
}

replication_result_ui <- function(plan) {
  if (isTRUE(plan$anova)) return(replication_bucss_result_ui(plan))
  o <- plan$original
  bayes <- !identical(plan$inputs$original_analysis %||% "test", "test")
  tagList(
    div(class = "result-panel mt-2", role = "status",
      if (is.null(plan$choice)) replication_headline_ui(plan) else replication_main_headline(plan),
      p(class = "small", tags$span(class = "badge-progress", "Validation in progress"), " ", replication_validation_text),
      replication_anova_one_df_note(plan),
      replication_main_chances_ui(plan),
      if (bayes) p(replication_bayes_original_words(plan)) else p(sprintf("The original estimate is %s with a standard error of %s%s (two-sided p = %s, by the normal approximation). %s",
        format(signif(o$estimate, 3)), format(signif(o$se, 3)),
        if (identical(plan$inputs$design, "correlation") || identical(plan$inputs$scale, "fisher_z")) " on Fisher's z scale"
        else if (identical(plan$inputs$scale, "log")) " on the log scale" else "",
        format(signif(o$p, 2)),
        if (o$p > plan$inputs$original_alpha) "It was not significant at its own level, so most goals here, which ask the replication to confirm it, may not fit; showing the effect is too small to matter may." else "")),
      replication_tau_note(plan$inputs$tau, plan$inputs$design, plan$inputs$scale),
      replication_direction_note(plan),
      # Once only: when d33 is also the default bound, the chances' note
      # below explains it, so this sentence just names the yardstick.
      if (!is.null(plan$telescope)) p(class = "small", if (identical(plan$choice$bound, "d33"))
        sprintf("Small telescopes' yardstick is the same %s.", plan$telescope$effect_name)
        else sprintf("Small telescopes' yardstick is %s = %s, the effect the original study had a one-in-three chance of detecting.",
          plan$telescope$effect_name, format(signif(plan$telescope$effect, 3))))
      else if (bayes && !identical(plan$inputs$design, "generic")) p(class = "small", "Small telescopes is left out: it rests on the original's significance test, and the original was analysed with Bayes factors.")
      else p(class = "small", sprintf("The replication's standard error is the original's scaled by the square root of the ratio of sample sizes, which assumes it copies the original's design. Small telescopes is planned on the design's card.")),
      replication_bias_corrected_ui(plan),
      tags$details(class = "mt-2", id = "rep-every-goal", open = if (is.null(plan$choice)) NA,
        tags$summary("Every goal under every belief"),
        p(class = "small", "For comparison: the sample size each goal needs, under each belief. The plan's sample size comes from its main criterion alone."),
        replication_table_ui(plan),
        tags$dl(class = "small", lapply(names(replication_prior_labels), function(p) tagList(
          tags$dt(replication_prior_labels[[p]]), tags$dd(replication_prior_notes[[p]])))),
        replication_chances_ui(plan)),
      if (!is.null(plan$sequential)) div(class = "mt-2",
        rep_note("The replication could also collect data until its Bayes factor is strong either way, a sequential design. The Bayesian planning tool under Tools works it out, with the belief chosen under Goals as its design prior and the original's prior as the analysis prior."),
        actionButton("rep_to_sequential", "Plan it as a sequential Bayes factor study", class = "btn btn-outline-primary btn-sm")),
      p(class = "small text-muted", paste0("Calculated by powerkit's engine with ",
        paste(vapply(plan$packages, function(p) sprintf("%s %s", p$name, p$version), ""), collapse = ", "),
        if (identical(plan$inputs$design, "generic")) ". Every goal uses a normal approximation to the original's estimate (Pawel, Consonni & Held, 2026)."
        else ". Every goal judged against the original's effect uses a normal approximation (Pawel, Consonni & Held, 2026), which for a t-test asks for a few people fewer than the t-test cards; small telescopes is the cards' own calculation."))))
}

# The replication and sceptical Bayes factors count a success only in the
# original's direction, where BayesRepDesign by default counts either side
# (docs/conventions.md, Departure 31). Shown when the plan uses either.
replication_direction_text <- "A replication Bayes factor or sceptical Bayes factor counts as a success only when the replication's estimate is in the original's direction: a large Bayes factor for an effect on the other side of zero is not evidence for the original's effect. BayesRepDesign counts either side by default, which can ask for far fewer people when the belief is shrunk towards zero."
replication_direction_used <- function(plan) {
  ch <- plan$choice
  goals <- if (is.null(ch)) unique(plan$goals$goal) else c(ch$goal, ch$also)
  any(c("bf_replication", "bf_sceptical") %in% goals)
}
replication_direction_note <- function(plan) {
  if (!replication_direction_used(plan)) return(NULL)
  p(class = "small", id = "rep-direction-note", replication_direction_text)
}

# The variation between studies the uncertain and shrunk beliefs allow,
# and powerkit's departure from BayesRepDesign's default of none
# (docs/conventions.md, "Variation between studies in replication plans").
replication_tau_note <- function(tau, design = "two_groups", scale = "none") {
  if (is.null(tau) || is.na(tau)) return(NULL)
  units <- switch(design, correlation = " on Fisher's z", paired = " in d_z",
    generic = switch(scale %||% "none", log = " on the log scale", fisher_z = " on Fisher's z", " in the effect's own units"), " in d")
  start <- switch(design, correlation = "0.025, the correlation card's smallest value", generic = NA_character_, "0.05")
  if (tau > 0) {
    why <- if (is.na(start)) "BayesRepDesign's own default is no variation; this is the value you entered."
      else sprintf("BayesRepDesign's own default is no variation; Powerkit starts at %s, because assuming none makes a replication look easier than it is.", start)
    return(p(class = "small", sprintf("The uncertain and shrunk beliefs allow the true effect to vary between studies with an SD of %s%s (Kenny & Judd, 2019). %s Choose None under Goals to see the numbers without it.",
      format(tau), units, why)))
  }
  if (identical(design, "generic")) {
    return(rep_note("No variation between studies is allowed for: the true effect is taken to be the same in the replication as in the original. Kenny and Judd (2019) argue this should not be the default, but their example values are in d and have no meaning on this effect's scale; enter tau under Goals, on the effect's own scale, from a meta-analysis of this effect.", keep = TRUE))
  }
  rep_note("No variation between studies is allowed for: the true effect is taken to be the same in the replication as in the original (BayesRepDesign's default). Kenny and Judd (2019) argue this should not be the default.", keep = TRUE)
}

# The simple answer above the table (C-14): the sample size for a
# significant result again, if the true effect is as reported and if it is
# shrunk towards zero, both from the table's own first row.
replication_headline_ui <- function(plan) {
  repeated <- "bf_repeat" %in% plan$goals$goal && !identical(plan$inputs$original_analysis %||% "test", "test")
  g <- plan$goals[plan$goals$goal == if (repeated) "bf_repeat" else "significance", ]
  if (!nrow(g)) return(NULL)
  cell <- function(prior) {
    row <- g[g$prior %in% prior, ][1, ]
    if (is.na(row$n)) tolower(replication_cell(plan, row)) else replication_n_words(plan, row$n)
  }
  # All three beliefs, naming the one the write-up starts on (P-08).
  beliefs <- sprintf("%s if the true effect is as large as %s, %s allowing for the uncertainty in the original's estimate (the belief the plan you write up starts on, below), or %s if it is shrunk towards zero, as published effects often are.",
    cell("as_reported"), if (repeated) "the original's data say" else "reported", cell("uncertain"), cell("shrunk"))
  if (repeated) return(p(class = "result-headline lead", sprintf(
    "For evidence of the effect again from the original's own Bayes factor test (BF10 of at least %s), with %s chance, you need %s",
    format(plan$inputs$threshold), replication_a_pct(plan$inputs$power), beliefs)))
  p(class = "result-headline lead", sprintf(
    "To find the effect significant again, in the original's direction (two-sided test, alpha = %s), with %s power, you need %s",
    sub("^0", "", format(plan$inputs$alpha)), replication_pct(plan$inputs$power), beliefs))
}

# The sample size for the chosen goal and belief, with its words.
replication_main <- function(plan, goal, prior) {
  g <- plan$goals[plan$goals$goal == goal, ]
  row <- if (all(is.na(g$prior))) g[1, ] else g[g$prior %in% prior, ][1, ]
  list(row = row, no_effect = all(is.na(g$prior)))
}

replication_methods_paragraph <- function(plan, goal, prior) {
  i <- plan$inputs
  m <- replication_main(plan, goal, prior)
  original <- switch(i$design,
    two_groups = sprintf("%s and %s per group", i$original_n1, i$original_n2),
    paired = sprintf("%s pairs", i$original_n), sprintf("%s people", i$original_n))
  scaled <- if (identical(i$design, "generic")) sprintf("; the replication's standard error was the original's (%s%s) scaled by the square root of the ratio of sample sizes, assuming the replication copies the original's design",
    format(signif(plan$original$se, 3)), switch(i$scale %||% "none", log = ", on the log scale", fisher_z = ", on Fisher's z scale", "")) else ""
  bayes <- !identical(i$original_analysis %||% "test", "test")
  shown <- if (identical(i$original_analysis, "bayes_factor")) {
    sprintf("%s = %s, read from its Bayes factor (BF10 = %s, a default t-test with a Cauchy prior of scale %s; Ly et al., 2018), %s",
      plan$effect_name, format(signif(plan$original$estimate, 3)), format(signif(i$original_bf, 3)),
      format(signif(i$original_prior_scale, 3)), original)
  } else if (identical(i$original_analysis, "posterior")) {
    sprintf("its posterior mean, %s = %s, with its posterior SD standing in for the standard error, from a %s prior, %s",
      plan$effect_name, format(i$original_effect), i$original_prior, original)
  } else if (!is.null(plan$anova_effect)) {
    a <- plan$anova_effect
    sprintf("%s = %s, from its F(1, %s) = %s, the square of the t (%s) of the two-mean comparison it is (Lakens, 2013), %s, with %s people in total",
      plan$effect_name, format(signif(i$original_effect, 3)), format(a$df_error), format(signif(a$f, 4)), format(signif(a$t, 4)),
      a$effect_words, format(i$anova$original_n))
  } else if (identical(i$original_effect_type, "t")) {
    sprintf("%s = %s, from its t statistic of %s (Lakens, 2013), %s", plan$effect_name, format(signif(i$original_effect, 3)),
      format(i$original_reported), original)
  } else if (identical(i$original_effect_type, "d_rm")) {
    sprintf("%s = %s, from its repeated-measures d of %s with a correlation of %s between the measurements (Lakens, 2013), %s",
      plan$effect_name, format(signif(i$original_effect, 3)), format(i$original_reported), format(i$original_r), original)
  } else {
    sprintf("%s = %s, %s", plan$effect_name, format(i$original_effect), original)
  }
  belief <- switch(prior,
    as_reported = "assuming the true effect equals the original estimate",
    uncertain = "with a design prior that carries the original estimate's uncertainty (a flat initial prior updated by the original study)",
    shrunk = "with a design prior that shrinks the original estimate towards zero by empirical Bayes")
  varies <- if (i$tau > 0 && !identical(prior, "as_reported")) sprintf(", allowing the true effect to vary between studies with a standard deviation of %s", format(i$tau)) else ""
  if (is.na(m$row$n) && identical(m$row$reason, "any_size")) {
    return(sprintf("The chosen goal (%s) has more than %s chance with a replication of any size, %s, because the original study's result counts towards it; it does not set the replication's sample size, so another goal should.",
      replication_lc(replication_goal_labels[[goal]]), replication_a_pct(i$power), if (m$no_effect) "planned for no effect" else belief))
  }
  if (is.na(m$row$n)) {
    return(sprintf("The replication's sample size was planned with powerkit's replication planner, but the chosen goal (%s) cannot reach %s chance %s.",
      replication_lc(replication_goal_labels[[goal]]), replication_a_pct(i$power), if (m$no_effect) "" else belief))
  }
  calc <- if (identical(goal, "bf_repeat")) {
    sprintf("a Bayes factor of at least %s for an effect from the original's own test (a default Bayes factor t-test with a Cauchy prior of scale %s) on the replication's data, %s%s, with the original estimate (%s), calculated with bfpwr (Pawel & Held, 2025)",
      format(i$threshold), format(signif(i$original_prior_scale, 3)), belief, varies, shown)
  } else if (identical(goal, "bf_null")) {
    sprintf("a Bayes factor of at least %s for no effect from the original's test (a default Bayes factor t-test with a Cauchy prior of scale %s), planned for a true effect of zero and calculated with bfpwr (Pawel & Held, 2025)",
      format(i$threshold), format(signif(i$original_prior_scale, 3)))
  } else if (identical(goal, "small_telescopes")) {
    sprintf("the small telescopes approach (Simonsohn, 2015): a one-sided test of whether the effect is smaller than %s = %s, the effect the original study (%s) had 33%% power to detect at its two-sided significance level of %s, planned for a true effect of zero and calculated with pwr and pwrss",
      plan$telescope$effect_name, format(signif(plan$telescope$effect, 3)), original, format(i$original_alpha))
  } else if (identical(goal, "negligible")) {
    sprintf("an equivalence test (two one-sided tests at %s) with bounds of ±%s, planned for a true effect of zero, calculated with BayesRepDesign (Pawel, Consonni & Held, 2026)",
      format(i$alpha), format(i$smallest_effect))
  } else {
    sprintf("%s%s, %s%s, with the original estimate (%s) and the normal-normal hierarchical model of Pawel, Consonni and Held (2026), calculated with BayesRepDesign%s",
      replication_lc(replication_goal_labels[[goal]]), replication_sided_words(plan, goal), belief, varies, shown, scaled)
  }
  sprintf("We planned the replication's sample size for %s chance of %s. This gives %s.%s",
    replication_a_pct(i$power), calc, replication_n_words(plan, m$row$n),
    if (replication_direction_used(plan)) " A replication or sceptical Bayes factor counted as a success only with the replication's estimate in the original's direction (BayesRepDesign's paradox = FALSE)." else "")
}

# How a significance or pooled goal is tested, in words.
replication_sided_words <- function(plan, goal) {
  if (!goal %in% c("significance", "pooled")) return("")
  one <- identical(plan$inputs$alternative, "one.sided")
  alpha <- format(plan$inputs$alpha)
  if (identical(goal, "significance")) {
    if (one) sprintf(" (a one-sided test at %s)", alpha) else sprintf(" (a two-sided test at %s, counted as a success only in the original's direction)", alpha)
  } else {
    sprintf(" (one-sided at %s, the significance level squared%s)", format(signif(if (one) plan$inputs$alpha^2 else (plan$inputs$alpha / 2)^2, 3)),
      if (one) "" else " after halving it")
  }
}

# The study design table a Registered Report asks for: for each criterion
# in the plan, the question, hypothesis, sampling plan, analysis plan,
# what sets the test's sensitivity, how each outcome will be read, and the
# theory (left for the researcher), as Markdown lines.
replication_design_table <- function(plan, ch) {
  i <- plan$inputs
  thr <- format(i$threshold)
  alpha <- format(i$alpha)
  bound <- if (!is.null(i$smallest_effect)) sprintf("±%s%s", format(signif(i$smallest_effect, 3)),
    if (identical(ch$bound, "d33")) " (d33, the effect the original had a one-in-three chance of detecting)" else ", the smallest effect that matters")
  question <- switch(ch$purpose %||% "confirm",
    either = "Is the original effect there or not?",
    absent = "Is the effect absent, or too small to matter?",
    "Does the original effect replicate?")
  hypothesis <- c(
    significance = "The effect is in the original's direction and not zero.",
    pooled = "With the original and the replication pooled, the effect is in the original's direction and not zero.",
    agreement = sprintf("The replication's effect is within %s of the original's.", bound %||% "the bound"),
    bf_replication = "The data support the original's effect over no effect.",
    bf_sceptical = "The data support the original's effect enough to convince a sceptic.",
    bf_repeat = "The data support an effect over no effect.",
    small_telescopes = sprintf("The effect is smaller than %s = %s, one the original study could barely have detected.",
      plan$telescope$effect_name %||% "d33", format(signif(plan$telescope$effect %||% NA, 3))),
    negligible = sprintf("The effect is within %s: too small to matter.", bound %||% "the bound"),
    bf_null = "The data support no effect over an effect.")
  analysis <- c(
    significance = sprintf("A test of the effect%s; a success if it is significant in the original's direction.", replication_sided_words(plan, "significance")),
    pooled = sprintf("A fixed-effect meta-analysis of the original and the replication%s; a success if it is significant in the original's direction.", replication_sided_words(plan, "pooled")),
    agreement = sprintf("The %s%% interval for the difference between the replication's and the original's estimates; a success if it lies within the bound.", format(100 * (1 - 2 * i$alpha))),
    bf_replication = sprintf("The replication Bayes factor, the original's effect against no effect; a success at %s or more in favour of the original's effect.", thr),
    bf_sceptical = sprintf("The sceptical Bayes factor; a success at %s or more.", thr),
    bf_repeat = sprintf("A default Bayes factor t-test (Cauchy prior of scale %s); a success if BF10 is %s or more.", format(signif(i$original_prior_scale %||% 0.707, 3)), thr),
    small_telescopes = sprintf("A one-sided test at %s of whether the effect is smaller than d33; a success if it is significant.", alpha),
    negligible = sprintf("Two one-sided tests at %s against the bounds; a success if both are significant.", alpha),
    bf_null = sprintf("The same default Bayes factor t-test; a success if BF01 is %s or more.", thr))
  reading <- c(
    significance = "Significant: the effect replicates. Not significant: inconclusive on its own; read it with the criterion for absence.",
    pooled = "Significant: the two studies together support the effect. Not significant: together they are not enough.",
    agreement = "Inside the bound: the replication agrees with the original. Outside: the two effects differ by more than matters.",
    bf_replication = sprintf("%s or more for the original's effect: it replicates. %s or more for no effect: evidence against it. In between: inconclusive.", thr, thr),
    bf_sceptical = "Reached: convincing even to a sceptic. Not reached: not convincing to a sceptic.",
    bf_repeat = sprintf("BF10 of %s or more: evidence for an effect. Less: not evidence for an effect.", thr),
    small_telescopes = "Significant: the effect is too small for the original to have detected it, so its finding is not supported. Not significant: an effect it could have detected is not ruled out.",
    negligible = "Both significant: the effect is too small to matter. Otherwise: an effect that matters is not ruled out.",
    bf_null = sprintf("BF01 of %s or more: evidence for no effect. Less: not evidence for no effect.", thr))
  belief <- tolower(replication_prior_labels[[ch$prior]])
  no_effect <- c("small_telescopes", "negligible", "bf_null")
  used <- c(ch$goal, setdiff(ch$also, ch$goal))
  a <- plan$at_main$chances
  main <- replication_main(plan, ch$goal, ch$prior)$row
  cell <- function(x) gsub("|", "\\|", x, fixed = TRUE)
  rows <- vapply(used, function(g) {
    sampling <- if (identical(g, ch$goal)) {
      sprintf("%s, set by this criterion for %s chance of success.", replication_cell(plan, main), replication_a_pct(i$power))
    } else {
      r <- if (is.null(a)) NULL else a[a$goal == g, ]
      chance <- if (is.null(r) || !nrow(r)) NA else if (all(is.na(r$prior))) r$chance[1] else r$chance[r$prior %in% ch$prior][1]
      sprintf("The same sample size: %s chance of success.", replication_a_pct(chance))
    }
    rationale <- paste(c(
      if (g %in% no_effect) "Planned for no true effect." else sprintf("The true effect %s (the original's estimate, %s)%s.",
        switch(ch$prior, as_reported = "as reported", uncertain = "with its uncertainty", shrunk = "shrunk towards zero"),
        format(signif(plan$original$estimate, 3)), if (isTRUE(i$tau > 0) && !identical(ch$prior, "as_reported")) sprintf(", varying between studies with an SD of %s", format(i$tau)) else ""),
      if (g %in% c("agreement", "negligible")) sprintf("The bound is %s.", bound),
      if (g %in% replication_bf_goals) sprintf("An evidence threshold of %s.", thr)), collapse = " ")
    sprintf("| %s |", paste(cell(c(question, hypothesis[[g]], sampling, analysis[[g]], rationale, reading[[g]], "_(fill in)_")), collapse = " | "))
  }, character(1))
  c("### Study design table", "",
    sprintf("For a Registered Report: one row for each criterion, the main one first, under one belief about the true effect (%s).", belief), "",
    "| Question | Hypothesis | Sampling plan | Analysis plan | What sets the test's sensitivity | Interpretation given different outcomes | Theory that could be shown wrong by the outcomes |",
    "|---|---|---|---|---|---|---|",
    unname(rows), "")
}

# The criteria also reported, as their chance at the plan's sample size,
# for the methods paragraph.
replication_also_sentence <- function(plan) {
  ch <- plan$choice
  at <- plan$at_main
  if (is.null(ch) || is.null(at) || !length(ch$also)) return(NULL)
  a <- at$chances
  parts <- vapply(ch$also, function(goal) {
    r <- a[a$goal == goal, ]
    if (!nrow(r)) return(NA_character_)
    no_effect <- all(is.na(r$prior))
    chance <- if (no_effect) r$chance[1] else r$chance[r$prior %in% ch$prior][1]
    sprintf("%s, %s%s", replication_lc(replication_goal_labels[[goal]]), replication_pct(chance), if (no_effect) " if there is no effect" else "")
  }, character(1))
  parts <- parts[!is.na(parts)]
  if (!length(parts)) return(NULL)
  sprintf("At this sample size, and under the same belief, the chance of each criterion also reported is: %s%s.",
    paste(parts, collapse = "; "),
    if (identical(ch$bound, "d33")) sprintf(" (the equivalence bound is %s = %s, the effect the original had 33%% power to detect; Simonsohn, 2015)",
      plan$telescope$effect_name, format(signif(plan$telescope$effect, 3))) else "")
}

# The write-up, as Markdown lines: every section, marked where empty.
# `analyses`: Markdown lines for the original's analysis as its card
# planned it (replication_analysis_lines()), or NULL; `title`, the plan's
# name.
replication_report <- function(values, plan = NULL, notes = NULL, notes_outcome = NULL, version = NULL, date = Sys.Date(),
                               analyses = NULL, title = NULL) {
  # Not worth replicating: the write-up is the negative pre-replication
  # report from the notes alone (Karhulahti et al., 2025); the planning
  # steps don't apply.
  if (identical(notes_outcome, "not_worth")) {
    report <- strsplit(labs_report(notes %||% list(), "not_worth", citation = labs_citation()), "\n", fixed = TRUE)[[1]]
    return(c(report[[1]], "",
      sprintf("Written with powerkit's replication plan%s, %s.", if (!is.null(version)) paste0(", version ", version) else "", format(date)),
      report[-1]))
  }
  v <- function(id) trimws(as.character(values[[id]] %||% ""))
  or_blank <- function(x) if (nzchar(x)) x else "_(not filled in yet)_"
  design_label <- names(replication_designs_ui)[replication_designs_ui == (if (nzchar(v("rep_design"))) v("rep_design") else "two_groups")]
  two <- identical(v("rep_design"), "two_groups") || !nzchar(v("rep_design"))
  lines <- c(if (is.null(title)) "# Replication plan" else paste("# Replication plan:", title), "",
    sprintf("Written with powerkit's replication plan%s, %s.", if (!is.null(version)) paste0(", version ", version) else "", format(date)), "",
    if (!is.null(plan)) c(paste("Validation in progress:", if (!is.null(plan$sizes)) replication_bucss_validation_text else replication_validation_text), ""),
    "## The original study", "",
    sprintf("- Study: %s", or_blank(v("rep_study"))),
    sprintf("- Design: %s", design_label),
    sprintf("- How it was analysed: %s", replication_lc(names(replication_analyses_ui)[replication_analyses_ui ==
      (if (v("rep_analysis") %in% replication_analyses_ui) v("rep_analysis") else "test")])),
    if (identical(v("rep_analysis"), "bayes_factor")) c(
      sprintf("- Its Bayes factor (BF10): %s", or_blank(v("rep_bf"))),
      sprintf("- The scale of its Cauchy prior: %s", or_blank(v("rep_prior_scale")))),
    if (identical(v("rep_analysis"), "both") && !identical(v("rep_design"), "anova")) c(
      if (nzchar(v("rep_bf_both"))) sprintf("- Its Bayes factor (BF10): %s", v("rep_bf_both")),
      if (v("rep_design") %in% c("two_groups", "one_sample", "paired", "")) sprintf("- The scale of its Cauchy prior: %s", or_blank(v("rep_prior_scale")))),
    if (identical(v("rep_analysis"), "posterior")) c(
      sprintf("- Its prior: %s", tolower(names(replication_original_priors_ui)[replication_original_priors_ui ==
        (if (v("rep_original_prior") %in% replication_original_priors_ui) v("rep_original_prior") else "default")])),
      sprintf("- Its posterior mean: %s", or_blank(v("rep_effect"))),
      if (identical(v("rep_post_from"), "ci")) sprintf("- Its %s%% credible interval: %s to %s", if (nzchar(v("rep_cri_level"))) v("rep_cri_level") else "95",
        or_blank(v("rep_cri_lower")), or_blank(v("rep_cri_upper")))
      else sprintf("- Its posterior SD: %s", or_blank(v("rep_post_sd")))),
    if (identical(v("rep_design"), "anova")) c(
      sprintf("- Who was in each condition: %s", replication_lc(names(replication_anova_kinds_ui)[replication_anova_kinds_ui ==
        (if (v("rep_anova_kind") %in% replication_anova_kinds_ui) v("rep_anova_kind") else "between")])),
      sprintf("- Levels: %s%s", or_blank(v("rep_levels_a")), if (nzchar(v("rep_levels_b"))) paste(" x", v("rep_levels_b")) else " (one factor)"),
      sprintf("- The effect: %s", replication_lc(names(replication_anova_effects_ui)[replication_anova_effects_ui ==
        (if (v("rep_anova_effect") %in% replication_anova_effects_ui) v("rep_anova_effect") else "factor_a")])),
      if (identical(v("rep_f_from"), "eta")) sprintf("- Reported effect: a partial eta-squared of %s, with %s error degrees of freedom", or_blank(v("rep_eta")), or_blank(v("rep_df_error")))
      else sprintf("- Reported effect: F = %s", or_blank(v("rep_anova_f"))),
      if (!v("rep_anova_kind") %in% c("", "between") && !v("rep_epsilon") %in% c("", "1")) sprintf("- Sphericity correction: epsilon = %s", v("rep_epsilon")))
    else if (v("rep_analysis") %in% c("bayes_factor", "posterior")) NULL
    else if (identical(v("rep_design"), "generic")) c(
      sprintf("- The effect: %s (%s)", or_blank(v("rep_effect_name")),
        names(replication_scales_ui)[replication_scales_ui == (if (nzchar(v("rep_scale"))) v("rep_scale") else "none")]),
      sprintf("- Reported effect: %s", or_blank(v("rep_effect"))),
      sprintf("- Its uncertainty: %s", switch(if (nzchar(v("rep_se_from"))) v("rep_se_from") else "se",
        ci = sprintf("a %s%% confidence interval from %s to %s", if (nzchar(v("rep_ci_level"))) v("rep_ci_level") else "95",
          or_blank(v("rep_ci_lower")), or_blank(v("rep_ci_upper"))),
        statistic = sprintf("a test statistic of %s", or_blank(v("rep_statistic"))),
        f = sprintf("an F statistic of %s, with one numerator degree of freedom", or_blank(v("rep_f"))),
        sprintf("a standard error of %s", or_blank(v("rep_se"))))))
    else if (v("rep_design") %in% c("two_groups", "one_sample", "paired", "") && identical(v("rep_effect_type"), "t"))
      sprintf("- Reported effect: a t statistic of %s", or_blank(v("rep_effect")))
    else if (identical(v("rep_design"), "paired") && identical(v("rep_effect_type"), "d_rm"))
      sprintf("- Reported effect: a repeated-measures d (d_rm or d_av) of %s, with a correlation of %s between the measurements",
        or_blank(v("rep_effect")), or_blank(v("rep_effect_r")))
    else sprintf("- Reported effect: %s", or_blank(v("rep_effect"))),
    if (two) sprintf("- Group sizes: %s and %s", or_blank(v("rep_n1")), or_blank(v("rep_n2"))) else sprintf("- Sample size: %s", or_blank(v("rep_n"))),
    if (identical(v("rep_design"), "anova") || !v("rep_analysis") %in% c("bayes_factor", "posterior")) sprintf("- Significance level: %s", or_blank(v("rep_original_alpha"))),
    if (identical(v("rep_published"), "any")) "- Published whatever it found (no publication filter), so BUCSS corrects for uncertainty only", "",
    "## Goals and sample size", "")
  if (is.null(plan)) {
    lines <- c(lines, "_(Not calculated yet: press “Show the sample size” under Goals and sample size.)_", "")
  } else if (isTRUE(plan$anova) || !is.null(plan$sizes)) {
    lines <- c(lines, replication_bucss_report_lines(plan, values))
  } else {
    ch <- plan$choice %||% replication_resolve_goals(values, unique(plan$goals$goal))
    goal <- if (ch$goal %in% plan$goals$goal) ch$goal else "significance"
    lines <- c(lines, paste(c(replication_methods_paragraph(plan, goal, ch$prior), replication_also_sentence(plan),
      replication_bias_corrected_sentence(plan)), collapse = " "), "",
      "| Criterion | Its role | Sample size it needs | Chance with the planned sample size |", "|---|---|---|---|")
    used <- c(goal, setdiff(ch$also, goal))
    a <- plan$at_main$chances
    for (g in used) {
      m <- replication_main(plan, g, ch$prior)
      chance <- if (is.null(a) || !any(a$goal == g)) "" else {
        r <- a[a$goal == g, ]
        replication_pct(if (all(is.na(r$prior))) r$chance[1] else r$chance[r$prior %in% ch$prior][1])
      }
      lines <- c(lines, sprintf("| %s | %s | %s%s | %s |", replication_goal_labels[[g]],
        if (identical(g, goal)) "Main criterion: sets the sample size" else "Also reported",
        replication_cell(plan, m$row), if (m$no_effect) " (planned for no effect)" else "", chance))
    }
    bf_used <- any(used %in% replication_bf_goals)
    bound_used <- any(used %in% c("agreement", "negligible"))
    lines <- c(lines, "",
      sprintf("Settings: replication significance level %s (%s), chance aimed for %s, belief about the true effect: %s, variation between studies %s%s%s.",
        format(plan$inputs$alpha), if (identical(plan$inputs$alternative, "one.sided")) "one-sided, in the original's direction" else "two-sided",
        replication_pct(plan$inputs$power), tolower(replication_prior_labels[[ch$prior]]), format(plan$inputs$tau),
        if (bound_used) sprintf(", smallest effect that matters %s%s", format(signif(plan$inputs$smallest_effect, 3)),
          if (identical(ch$bound, "d33")) " (d33, as none was given)" else "") else "",
        if (bf_used) sprintf(", evidence threshold a Bayes factor of %s", format(plan$inputs$threshold)) else ""),
      "", "The sample size each other goal would need, under each belief, is on the plan's Goals screen.", "",
      if (!is.null(plan$choice)) replication_design_table(plan, ch))
  }
  lines <- c(lines, "## The original's analysis, planned on its card", "",
    if (length(analyses)) analyses else c("_(Not planned yet: under The original study, find the original's design and plan it on its card.)_", ""),
    "## How the replication differs", "",
    sprintf("- What it keeps: %s", if (v("rep_keeps") %in% names(replication_keeps_words)) replication_keeps_words[[v("rep_keeps")]] else or_blank("")),
    sprintf("- The people: %s", or_blank(v("rep_diff_people"))),
    sprintf("- The materials and measures: %s", or_blank(v("rep_diff_materials"))),
    sprintf("- The procedure and setting: %s", or_blank(v("rep_diff_procedure"))),
    sprintf("- The analysis: %s", or_blank(v("rep_diff_analysis"))),
    sprintf("- Would the original authors expect the same effect? %s", or_blank(v("rep_diff_expect"))),
    if (v("rep_keeps") %in% c("extension", "conceptual") || nzchar(v("rep_diff_checks")))
      sprintf("- The checks that it still tests the same thing: %s", or_blank(v("rep_diff_checks"))), "")
  if (!is.null(notes) && any(nzchar(trimws(unlist(notes))))) {
    report <- labs_report(notes, notes_outcome, citation = labs_citation())
    report <- sub("^#", "##", report)
    lines <- c(lines, gsub("\n#", "\n##", report), "")
  }
  keys <- replication_ref_keys_used(plan)
  refs <- vapply(keys, function(k) labs_citation(key = k, fallback = ""), character(1))
  # A title's TeX math ("$t$-tests") reads as plain text in a write-up.
  refs <- gsub("$", "", refs[nzchar(refs)], fixed = TRUE)
  if (!length(refs)) return(lines)
  c(lines, "## References", "", paste0("- ", refs))
}

# An ANOVA original's write-up: its methods paragraph and the sample size
# at each assurance.
replication_bucss_report_lines <- function(plan, values) {
  i <- plan$inputs
  assurance <- plan$chosen_assurance %||% suppressWarnings(as.numeric(values$rep_assurance %||% "0.8"))
  if (is.na(assurance) || !assurance %in% plan$sizes$assurance) assurance <- 0.8
  chosen <- plan$sizes[plan$sizes$assurance == assurance, ][1, ]
  method <- sprintf("We planned the replication's sample size for a significant F test for the %s (alpha = %s) with %s power, correcting the original's effect for %s with BUCSS (Anderson, Kelley & Maxwell, 2017; Anderson & Kelley, 2024) at %s assurance. %s",
    replication_anova_effect_words(i), format(i$alpha), replication_pct(i$power), replication_bucss_corrects(plan), replication_pct(assurance), replication_bucss_original_words(plan))
  result <- if (is.na(chosen$n)) paste(" ", replication_bucss_reason_words(plan)) else sprintf(" This gives %s.", replication_bucss_n_words(plan, chosen))
  c(paste0(method, result), "",
    "| Assurance | Sample size | Its power |", "|---|---|---|",
    vapply(seq_len(nrow(plan$sizes)), function(k) {
      r <- plan$sizes[k, ]
      sprintf("| %s%s | %s | %s |", replication_pct(r$assurance), if (identical(r$assurance, assurance)) " (chosen)" else "",
        if (is.na(r$n)) "Can't be planned" else replication_bucss_n_words(plan, r),
        if (is.na(r$actual_power)) "" else replication_pct(r$actual_power))
    }, character(1)), "",
    if (replication_bucss_filtered(plan)) sprintf("Settings: replication significance level %s, power aimed for %s; the original's significance level, taken as its literature's publication threshold, %s.",
      format(i$alpha), replication_pct(i$power), format(i$original_alpha))
    else sprintf("Settings: replication significance level %s, power aimed for %s; no publication filter, as the original would have been published whatever it found (BUCSS's alpha_prior = 1).",
      format(i$alpha), replication_pct(i$power)), "",
    if (!is.null(plan$smallest$n)) c(sprintf("From the smallest effect that would matter to us, a partial eta-squared of %s, the same F test with %s power needs %s participants (%s, as powerkit's ANOVA card calculates it).",
      format(plan$smallest$inputs$smallest_effect), replication_pct(plan$smallest$inputs$power), format(plan$smallest$n, big.mark = ","),
      plan$smallest$function_used), ""))
}

# A t-test or correlation original's BUCSS sample sizes, in the write-up.
replication_bias_corrected_sentence <- function(plan) {
  b <- plan$bias_corrected
  if (is.null(b)) return(NULL)
  sz <- b$sizes
  if (all(!is.na(sz$reason))) {
    return(sprintf("Corrected for %s with BUCSS (Anderson, Kelley & Maxwell, 2017), the original's result was too weak to plan a replication from.", replication_bucss_corrects(b)))
  }
  at <- function(a) {
    r <- sz[sz$assurance == a, ][1, ]
    if (is.na(r$n)) "could not be planned" else replication_bucss_n_words(b, r)
  }
  sprintf("For comparison, correcting the original's effect for %s with BUCSS (Anderson, Kelley & Maxwell, 2017), a significant result with %s power needs %s at 50%% assurance and %s at 80%% assurance.",
    replication_bucss_corrects(b), replication_pct(plan$inputs$power), at(0.5), at(0.8))
}

# The references the write-up's own text rests on: the goals framework
# and BayesRepDesign once goals are calculated, and each method only when
# its goal, setting or route is in the plan. The notes' report carries its
# own reference.
replication_ref_keys_used <- function(plan) {
  if (is.null(plan)) return(character())
  if (isTRUE(plan$anova) || !is.null(plan$sizes)) {
    return(intersect(replication_ref_keys, c("Anderson2017_bucss", "AndersonKelley2024_replication_design",
      if (!is.null(plan$inputs$original_partial_eta)) "Lakens2013_effectsizes")))
  }
  ch <- plan$choice
  goals <- if (is.null(ch)) unique(plan$goals$goal) else unique(c(ch$goal, ch$also))
  i <- plan$inputs
  keys <- c(if (!all(goals %in% "small_telescopes")) "Pawel2026_replication", "Anderson2016_replication",
    if ("small_telescopes" %in% goals || identical(ch$bound, "d33")) "Simonsohn2015_telescopes",
    if (isTRUE(i$tau > 0)) "Kenny2019_heterogeneity",
    if (any(c("bf_replication", "bf_sceptical") %in% goals)) c("VerhagenWagenmakers2014_replication", "Ly2019_replication_bf"),
    if (identical(i$original_analysis, "bayes_factor")) "Ly2018_summary_reanalysis",
    if (identical(i$original_analysis, "posterior") || "bf_null" %in% goals) "McLatchie2020_bayes_factors",
    if (any(c("bf_repeat", "bf_null") %in% goals)) "bfpwr_method",
    if (isTRUE(i$original_effect_type %in% c("t", "d_rm"))) "Lakens2013_effectsizes",
    if (!is.null(plan$bias_corrected)) "Anderson2017_bucss")
  intersect(replication_ref_keys, keys)
}

# The R script: for the chosen criteria once the plan has a choice (the
# main criterion's sample size under the chosen belief, and the others'
# chances at it), otherwise every goal under every belief.
replication_script_text <- function(plan, script) {
  if (isTRUE(plan$anova) || !is.null(plan$sizes)) return(paste(c(plan$script, if (!is.null(plan$smallest$n)) {
    si <- plan$smallest$inputs
    c("", "# From the smallest effect that would matter: the ANOVA card's own F test, through powerkit's engine",
      "library(powerkit)",
      sprintf("replication_anova_smallest(\"%s\", levels_a = %s%s, effect = \"%s\", smallest_effect = %s, alpha = %s, power = %s)$n",
        si$design, si$levels_a, if (is.null(si$levels_b)) "" else sprintf(", levels_b = %s", si$levels_b), si$effect,
        format(si$smallest_effect), format(si$alpha), format(si$power)))
  }), collapse = "\n"))
  ch <- plan$choice
  if (is.null(ch) || !ch$goal %in% plan$goals$goal) return(script(plan))
  script(plan, goal = ch$goal, also = intersect(ch$also, plan$goals$goal), prior = ch$prior)
}

# The run bar's status: what is still needed for the sample size, as the
# input screens' bar says it, or that everything is in.
replication_still_needed <- function(values) {
  missing <- c(replication_missing(values), replication_settings_missing(values))
  if (!length(missing)) return(tags$span(class = "form-needed form-needed-done rep-still-needed", "Everything needed is in."))
  shown <- if (length(missing) > 2) c(missing[1:2], sprintf("%d more", length(missing) - 2)) else missing
  words <- if (length(shown) == 1) shown else paste(paste(shown[-length(shown)], collapse = ", "), "and", shown[length(shown)])
  tags$span(class = "form-needed rep-still-needed", paste("Still needed:", words))
}

# The steps marked done in the step bar: the notes once their outcome is
# chosen, the original once nothing it needs is missing, the goals once
# the sample size shown is for the current answers, and the differences
# once the study's kind is chosen. The write-up is never "done".
replication_steps_done <- function(values, current_plan, outcome) {
  has <- function(id) nzchar(trimws(as.character(values[[id]] %||% "")))
  as.character(c(if (nzchar(outcome %||% "")) "whether",
    if (!length(replication_missing(values))) "original",
    if (isTRUE(current_plan)) "goals",
    if (has("rep_keeps")) "differences"))
}

# The planner's file: its fields, with what wrote them.
replication_file <- function(values, version = NULL) {
  list(app = "powerkit-replication-planner", version = version %||% "", saved = format(Sys.time(), "%Y-%m-%d %H:%M"),
    fields = values[intersect(names(values), replication_field_ids)])
}

# `analyses()`: the original's analysis lines for the write-up; `title()`,
# the plan's name; `script_extra()`, R code for the card's analysis.
replication_server <- function(input, output, session, notes = function() list(), notes_outcome = function() NULL,
                               analyses = function() NULL, title = function() NULL) {
  values <- function() stats::setNames(lapply(replication_field_ids, function(id) {
    if (identical(id, "rep_also")) replication_also_value(input$rep_also) else input[[id]] %||% ""
  }), replication_field_ids)
  plan <- reactiveVal(NULL)
  problem <- reactiveVal(NULL)
  used <- reactiveVal(NULL)

  # `usual`: settings to use where the boxes are empty (the quick button).
  run <- function(usual = list()) {
    plan(NULL); problem(NULL)
    vals <- values()
    for (id in names(usual)) if (!nzchar(trimws(vals[[id]] %||% ""))) vals[[id]] <- usual[[id]]
    missing <- replication_missing(vals)
    if (length(missing)) {
      problem(sprintf("The original study needs %s first.", paste(missing, collapse = " and ")))
      return()
    }
    settings <- replication_settings_missing(vals)
    if (length(settings)) {
      problem(sprintf("Choose %s under Goals first: the buttons below each box fill in the usual values.", paste(settings, collapse = " and ")))
      return()
    }
    result <- tryCatch(replication_run(vals, engine_function("replication_planning"), engine_function("replication_bucss"),
      engine_function("replication_anova_smallest")),
      error = function(e) list(problem = replication_problem(e)))
    if (!is.null(result$problem)) problem(result$problem) else { plan(result); used(replication_calc_key(vals)) }
  }
  observeEvent(input$rep_run, run())
  output$rep_still_needed <- renderUI(replication_still_needed(values()))
  observe({
    current <- !is.null(plan()) && identical(used(), replication_calc_key(values()))
    session$sendCustomMessage("rep-steps-done", list(done = I(as.character(replication_steps_done(values(), current, notes_outcome())))))
  })
  # d_rm is for pairs only: a hidden choice must not stay selected.
  observeEvent(input$rep_design, {
    if (!identical(input$rep_design, "paired") && identical(input$rep_effect_type, "d_rm"))
      updateRadioButtons(session, "rep_effect_type", selected = "d")
  }, ignoreInit = TRUE)
  observeEvent(input$rep_run_quick, {
    usual <- list(rep_alpha = "0.05", rep_power = "0.8")
    for (id in names(usual)) if (!nzchar(trimws(input[[id]] %||% ""))) updateTextInput(session, id, value = usual[[id]])
    run(usual)
  })
  output$rep_result <- renderUI({
    if (!is.null(problem())) return(div(class = "form-problems mt-2", role = "alert", p(problem())))
    if (is.null(plan())) return(NULL)
    # Answers changed since: say so, rather than show numbers for other inputs.
    if (!identical(used(), replication_calc_key(values()))) {
      return(div(class = "rep-stale",
        div(class = "alert alert-warning", role = "status",
          "These results are for your earlier answers. Press \u201cShow the sample size\u201d to update them."),
        div(class = "rep-stale-result", `aria-hidden` = "true", replication_result_ui(plan()))))
    }
    replication_result_ui(plan())
  })

  # From the pre-replication notes: the study's name to copy, and the
  # smallest effect in the user's words, to turn into a number here.
  output$rep_from_notes_study <- renderUI({
    study <- trimws(notes()$labs_study %||% "")
    if (!nzchar(study) || nzchar(trimws(input$rep_study %||% ""))) return(NULL)
    p(class = "small labs-signpost", sprintf("Your pre-replication notes name the study: “%s”. ", study),
      actionLink("rep_use_study", "Use it"))
  })
  observeEvent(input$rep_use_study, updateTextInput(session, "rep_study", value = trimws(notes()$labs_study %||% "")))
  output$rep_from_notes_smallest <- renderUI({
    smallest <- trimws(notes()$labs_smallest %||% "")
    if (!nzchar(smallest)) return(NULL)
    p(class = "small labs-signpost", sprintf("Your pre-replication notes say the smallest effect that would matter is: “%s”. Enter it below as a number on the effect's scale.", smallest))
  })

  report <- function() replication_report(values(), plan(), notes(), notes_outcome(), powerkit_version(),
    analyses = analyses(), title = title())
  stem <- function() sprintf("%s-%s", if (identical(notes_outcome(), "not_worth")) labs_file_stem("not_worth") else "replication-plan", format(Sys.Date()))
  output$rep_preview <- renderUI({
    req(identical(input$rep_section, "writeup"))
    div(class = "rep-preview-doc", HTML(document_body_html(report())))
  })
  output$rep_markdown <- downloadHandler(filename = function() paste0(stem(), ".md"),
    content = function(file) writeLines(report(), file, useBytes = TRUE))
  output$rep_docx <- downloadHandler(filename = function() paste0(stem(), ".docx"),
    content = function(file) docx_document(report(), file, powerkit_version()))
  observeEvent(input$rep_document, send_document(session, function() printable_document(report(), powerkit_version())))
  output$rep_script <- downloadHandler(filename = function() paste0(stem(), ".R"),
    content = function(file) {
      p <- plan() %||% if (!length(replication_settings_missing(values())))
        tryCatch(do.call(engine_function(replication_engine_name(values())), replication_args(values())), error = function(e) NULL)
      text <- if (is.null(p)) "# Fill in The original study, and the significance level and chance of success under Goals, first: the script needs them." else
        replication_script_text(p, engine_function("replication_planning_script"))
      writeLines(text, file, useBytes = TRUE)
    })
  output$rep_writeup_note <- renderUI({
    if (identical(notes_outcome(), "not_worth")) {
      return(p(class = "small", "You decided the finding isn't worth replicating, so the write-up is a negative pre-replication report from your notes: which study, why replicating it wouldn't be informative, and what would be more useful. The original study, goals and differences aren't part of it."))
    }
    missing <- replication_missing(values())
    todo <- c(if (length(missing)) "The original study", if (is.null(plan())) "the sample sizes under Goals")
    if (!length(todo)) return(p(class = "small", "Everything the plan needs is in. Sections you left blank are marked in the document."))
    p(class = "small", sprintf("Still to do: %s. The document can be downloaded now; those parts are marked.", paste(todo, collapse = " and ")))
  })

  # To Labs' Bayesian planning tool, as a sequential design: the chosen
  # belief as the design prior, the original's prior as the analysis prior.
  observeEvent(input$rep_to_sequential, {
    p <- plan()
    req(p, p$sequential)
    s <- replication_sequential_settings(p, input$rep_prior)
    updateSelectInput(session, "bayes_type", selected = s$type)
    updateNumericInput(session, "bayes_scale", value = s$prior_scale)
    updateNumericInput(session, "bayes_effect", value = s$effect)
    updateNumericInput(session, "bayes_effect_sd", value = s$effect_sd)
    if (!is.na(s$n_max)) updateNumericInput(session, "bayes_n", value = s$n_max)
    if (!is.null(s$threshold)) updateRadioButtons(session, "bayes_threshold", selected = s$threshold)
    updateRadioButtons(session, "bayes_design", selected = "sequential")
    session$sendCustomMessage("labs_open", "bayes")
    updateTabsetPanel(session, "tabs", selected = labs_tab_title)
  })

  # Called when another plan opens: its own table is calculated afresh.
  reset <- function() { plan(NULL); problem(NULL); used(NULL) }
  invisible(list(reset = reset))
}

# The Labs Bayesian tool's settings for a sequential replication: the
# chosen belief's design prior (bayes_sequential()'s effect and effect_sd),
# the original's prior scale, the threshold, and as the largest study the
# fixed design's size for the repeated test (in each group for two groups).
replication_sequential_settings <- function(plan, prior = NULL) {
  seq <- plan$sequential
  prior <- if (!is.null(prior) && prior %in% seq$prior) prior else "uncertain"
  row <- seq[seq$prior == prior, ][1, ]
  fixed <- plan$goals$n[plan$goals$goal == "bf_repeat" & plan$goals$prior %in% prior][1]
  per <- if (identical(row$type, "two.sample")) 2 else 1
  threshold <- format(plan$inputs$threshold)
  list(type = row$type, prior_scale = round(row$prior_scale, 3), effect = round(row$effect, 3),
    effect_sd = round(row$effect_sd, 3), n_max = if (is.na(fixed)) NA_real_ else fixed / per,
    threshold = if (threshold %in% bayes_thresholds) threshold)
}
