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
  "Its test statistic (z or t)" = "statistic")

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
  if (!is.null(e$multi_df)) {
    return(sprintf("This card's test has several degrees of freedom, so it has no one number for the plan's goals; plan them for the focal contrast instead: %s.", e$multi_df))
  }
  if (!is.null(e$none)) return(e$none)
  sprintf("For the plan's goals, enter the original's %s with its standard error, interval or test statistic, under \u201cAnother design\u201d.", e$effect)
}

replication_card_note <- function(forms, ep_id, plan = NULL) {
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
# from an earlier study, unless the user has already chosen.
replication_form_values <- function(values) {
  if (is.null(values$just_type)) values$just_type <- "prior_study"
  values
}

# How the original was analysed (queue item 21): a test, a Bayes factor
# (a default-prior t-test) or a posterior.
replication_analyses_ui <- c("A significance test (a p-value)" = "test", "A Bayes factor" = "bayes_factor",
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
  "bfpwr_method")

# The replication planner's sections, inside a replication plan's
# workspace (replication_workspace_ui(), R/study-plan-replication.R; a Labs tool
# until 14 November 2026). Their fields are kept in the plan.
replication_planner_sections <- function() {
  field <- function(id, label, value = "", help = NULL) {
    div(class = "form-field", textInput(id, label, value = value, width = "100%"),
      if (!is.null(help)) p(class = "small text-muted", help))
  }
  box <- function(id, label, rows = 3) div(class = "form-field", textAreaInput(id, label, rows = rows, width = "100%"))
  section <- function(id, ...) conditionalPanel(sprintf("input.rep_section == '%s'", id), ...)
  tagList(
    section("original",
      tags$fieldset(class = "form-group-box", tags$legend(class = "h6", "The original study"),
        uiOutput("rep_from_notes_study"),
        field("rep_study", "The original study (authors, year, title or link)"),
        selectInput("rep_design", "Its design", choices = replication_designs_ui, selectize = FALSE, width = "100%"),
        radioButtons("rep_analysis", "How it was analysed", choices = replication_analyses_ui, selected = "test", width = "100%"),
        conditionalPanel("input.rep_analysis == 'bayes_factor'",
          field("rep_bf", "Its Bayes factor for an effect, BF10",
            help = "If the paper gives BF01 (for no effect), enter 1 / BF01. Powerkit reads the effect from it for a t-test (two groups, one group or pairs), as JASP's Summary Statistics do the other way (Ly et al., 2018).")),
        conditionalPanel("input.rep_analysis == 'posterior'",
          radioButtons("rep_original_prior", "Its prior", choices = replication_original_priors_ui, selected = "default", width = "100%"),
          p(class = "small text-muted", "A posterior stands in for the original's estimate only when its prior was vague or a default one: an informative prior's posterior mixes the prior's beliefs into what the original found (McLatchie, Warmelink & Tkacheva, 2020). For an informative prior, give the estimate with its standard error, or the Bayes factor.")),
        conditionalPanel("input.rep_analysis != 'test' && (input.rep_design == 'two_groups' || input.rep_design == 'one_sample' || input.rep_design == 'paired')",
          field("rep_prior_scale", "The scale of its Cauchy prior on the effect", value = "0.707",
            help = "0.707 is the default in JASP and the BayesFactor package. It is used to read the Bayes factor and to repeat the original's test.")),
        conditionalPanel("input.rep_design == 'generic'",
          field("rep_effect_name", "What the effect is",
            help = "For example \u201cthe interaction coefficient\u201d or \u201codds ratio\u201d. The original's card suggests one."),
          selectInput("rep_scale", "Its scale", choices = replication_scales_ui, selectize = FALSE, width = "100%")),
        conditionalPanel("input.rep_analysis != 'bayes_factor'",
          field("rep_effect", "The effect it reported, with its sign",
            help = "As the paper reported it: d, d_z or r for the first four designs (if it gave a t or F instead, the Effect size converter in Tools turns it into d or r); for another design, on its own scale, a ratio as the ratio. For a posterior, its mean.")),
        conditionalPanel("input.rep_analysis == 'posterior'",
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
            field("rep_statistic", "Its z or t statistic", help = "The estimate divided by its standard error, as the paper reported it."))),
        conditionalPanel("input.rep_design == 'two_groups'",
          field("rep_n1", "People in its first group"),
          field("rep_n2", "People in its second group")),
        conditionalPanel("input.rep_design != 'two_groups'",
          field("rep_n", "People (or pairs) it analysed, in total")),
        conditionalPanel("input.rep_design == 'generic'",
          p(class = "small text-muted", "The replication is taken to copy the original's design, so its standard error shrinks with the square root of its sample size. Small telescopes needs the original's own test, so it is planned on the design's card.")),
        conditionalPanel("input.rep_analysis == 'test'",
          field("rep_original_alpha", "Its significance level (two-sided)", value = "0.05")),
        # The simple answer first (colleague review C-14, 12 November
        # 2026): the sample size to find the effect significant again,
        # with the usual settings, before the goals and beliefs.
        div(class = "rep-quick",
          p(class = "rep-routes", "Two ways to the sample size: the quick answer here, from the numbers above, or the original's design on its own card, below, with that card's full options and its exact test. The quick answer uses a normal approximation, so for a t-test it can ask for a few people fewer than the card."),
          actionButton("rep_run_quick", "Show the sample size to replicate it", class = "btn btn-primary"),
          p(class = "small text-muted mt-1", "It opens Goals, where you choose the significance level and the chance of success (one click each for the usual values), and shows what other goals of a replication need."))),
      uiOutput("rep_card_status")),

    section("goals",
      tags$fieldset(class = "form-group-box", tags$legend(class = "h6", "Goals and sample size"),
        p(class = "group-note", "A replication can aim for more than a significant result (Anderson & Maxwell, 2016). The table gives the sample size each goal needs, under three beliefs about the true effect. Choose the goal that answers your question, and the belief you can defend."),
        uiOutput("rep_from_notes_smallest"),
        field("rep_smallest", "The smallest effect that would matter (positive: d, d_z or r, or another design's effect on its own scale, a ratio above 1)",
          help = "Needed for the goals of agreement and of an effect too small to matter. Leave blank to skip those two."),
        selectInput("rep_tau", "How much the true effect may vary between studies (as an SD in d)", choices = replication_taus, selected = "0.05", selectize = FALSE, width = "100%"),
        p(class = "small text-muted", "Laboratories, samples and procedures differ, so the true effect can differ from study to study, and assuming it can't makes a replication look easier than it is. The best source is a meta-analysis of this effect that reports tau. Kenny and Judd (2019) use 0.05, 0.125 and 0.20 as examples and argue zero should not be the default; they are a quarter of Cohen's 0.2, 0.5 and 0.8, so treat them as illustrations, not estimates for your field. It starts at the smallest. It applies to the uncertain and shrunk beliefs. For a correlation it is on Fisher's z scale, close to r for small values."),
        shortcut_field("rep_alpha", "The replication's significance level (two-sided)", c("0.05", "0.01", "0.005"),
          c("Use 0.05, the usual level", "0.01", "0.005"),
          help = "0.01 or 0.005 fit a replication that runs many tests, or a claim that needs stronger evidence."),
        shortcut_field("rep_power", "The chance of success to aim for", c("0.8", "0.9", "0.95"), c("80%", "90%", "95%"),
          help = "The table shows the sample size each goal needs for this chance; a higher chance needs more people."),
        radioButtons("rep_threshold", "Evidence threshold for the Bayes factor goals: the Bayes factor the replication should reach",
          choiceNames = c("3", "6", "10 (a common threshold)", "30"), choiceValues = c("3", "6", "10", "30"), selected = "10", inline = TRUE),
        p(class = "small text-muted", "Choose the evidence your claim needs: 10 is a common threshold, and so is 3; there is no correct one."),
        field("rep_n_at", "Optional: a sample size you could recruit (in total), to see each goal's chance at it"),
        actionButton("rep_run", "Show the sample sizes", class = "btn btn-primary"),
        uiOutput("rep_result"),
        uiOutput("rep_choice"))),

    section("differences",
      tags$fieldset(class = "form-group-box", tags$legend(class = "h6", "How the replication differs"),
        p(class = "group-note", "No replication repeats a study exactly. Writing down what changes, and why, says how the result should be read: whether a different result would count against the finding, or point to a condition it depends on. If much changes, allow for more variation between studies under Goals."),
        box("rep_diff_people", "The people: who takes part, where and when, and how they differ from the original sample"),
        box("rep_diff_materials", "The materials and measures: what is translated, updated or replaced"),
        box("rep_diff_procedure", "The procedure and setting: for example online instead of in the lab"),
        box("rep_diff_analysis", "The analysis: the original's test, and anything added or changed"),
        box("rep_diff_expect", "Would the original authors expect the same effect under these conditions? If not, why replicate this way?"))),

    section("writeup",
      tags$fieldset(class = "form-group-box", tags$legend(class = "h6", "Write-up"),
        p(class = "group-note", "One plan built from everything here, the notes, the original study, the goals, how the replication differs and the original's analysis on its card, for a preregistration or a registered report. Sections not filled in yet are marked, so it can be downloaded at any stage."),
        div(class = "nav-buttons",
          document_menu("rep_document", "rep_docx", "rep_markdown", "Save as PDF or print", "the replication plan", class = "btn btn-primary"),
          download_button("rep_script", "Download the R script", class = "btn btn-outline-primary")),
        uiOutput("rep_writeup_note"))))
}

# A text box with buttons that fill in conventional values, as the input
# screens' alpha and power boxes have (forms_ui.R): the box starts empty,
# so choosing a value stays the user's act (colleague review P-04).
shortcut_field <- function(id, label, values, labels, help = NULL) {
  div(class = "form-field", textInput(id, label, value = "", width = "100%"),
    div(class = "usual-values", lapply(seq_along(values), function(i) tags$button(type = "button",
      class = "btn btn-sm btn-outline-secondary usual-value", id = sprintf("%s_usual%s", id, if (i > 1) paste0("_", i) else ""),
      `data-target` = id, `data-value` = values[[i]],
      onclick = "var e = document.getElementById(this.getAttribute('data-target')); e.value = this.getAttribute('data-value'); e.dispatchEvent(new Event('input', {bubbles: true})); e.dispatchEvent(new Event('change', {bubbles: true})); e.focus();",
      labels[[i]]))),
    if (!is.null(help)) p(class = "small text-muted", help))
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
replication_field_ids <- c("rep_study", "rep_design", "rep_analysis", "rep_bf", "rep_original_prior", "rep_prior_scale",
  "rep_post_from", "rep_post_sd", "rep_cri_lower", "rep_cri_upper", "rep_cri_level", "rep_effect_name", "rep_scale", "rep_effect", "rep_se_from", "rep_se",
  "rep_ci_lower", "rep_ci_upper", "rep_ci_level", "rep_statistic", "rep_n1", "rep_n2", "rep_n", "rep_original_alpha",
  "rep_smallest", "rep_tau", "rep_alpha", "rep_power", "rep_threshold", "rep_n_at", "rep_goal", "rep_prior",
  "rep_diff_people", "rep_diff_materials", "rep_diff_procedure", "rep_diff_analysis", "rep_diff_expect")

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
  args <- list(design = design, original_effect = num("rep_effect", NA_real_),
    original_alpha = num("rep_original_alpha", 0.05), alpha = num("rep_alpha", 0.05),
    power = num("rep_power", 0.8), tau = num("rep_tau", 0.05), smallest_effect = num("rep_smallest"),
    threshold = num("rep_threshold", 10), n = num("rep_n_at"))
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
    } else {
      args$original_se <- num("rep_se", NA_real_)
    }
  }
  analysis <- if (v("rep_analysis") %in% replication_analyses_ui) v("rep_analysis") else "test"
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

# What is missing before the engine can plan, in the field's words.
# The replication's own settings under Goals, which start empty (P-04):
# what is still to choose, in words.
replication_settings_missing <- function(values) {
  v <- function(id) nzchar(trimws(as.character(values[[id]] %||% "")))
  c(if (!v("rep_alpha")) "the significance level", if (!v("rep_power")) "the chance of success to aim for")
}

replication_missing <- function(values) {
  v <- function(id) nzchar(trimws(as.character(values[[id]] %||% "")))
  two <- identical(values$rep_design %||% "two_groups", "two_groups") || !v("rep_design")
  generic <- identical(values$rep_design, "generic")
  from <- if (v("rep_se_from")) values$rep_se_from else "se"
  analysis <- if (v("rep_analysis")) values$rep_analysis else "test"
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

replication_n_words <- function(plan, n) {
  if (is.na(n)) return(NA_character_)
  switch(plan$inputs$design,
    two_groups = sprintf("%s (%s per group)", format(n, big.mark = ","), format(n / 2, big.mark = ",")),
    paired = sprintf("%s pairs", format(n, big.mark = ",")),
    sprintf("%s people", format(n, big.mark = ",")))
}

replication_cell <- function(plan, row) {
  if (!is.na(row$n)) return(replication_n_words(plan, row$n))
  switch(row$reason %||% "",
    not_reachable = if (is.na(row$limit) || row$limit < 0.005) "Not reachable with this original study, however large the replication" else
      sprintf("Not reachable: at most %s, however large the replication", replication_pct(row$limit)),
    over_max = "More than 100,000",
    "Not found")
}

replication_pct <- function(x) if (is.na(x)) "unknown" else sprintf("%.0f%%", 100 * x)
# With its article: "an 80%", "a 90%" (said "eighty", "ninety").
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

replication_result_ui <- function(plan) {
  o <- plan$original
  bayes <- !identical(plan$inputs$original_analysis %||% "test", "test")
  tagList(
    div(class = "result-panel mt-2", role = "status",
      replication_headline_ui(plan),
      if (bayes) p(replication_bayes_original_words(plan)) else p(sprintf("The original estimate is %s with a standard error of %s%s (two-sided p = %s, by the normal approximation). %s",
        format(signif(o$estimate, 3)), format(signif(o$se, 3)),
        if (identical(plan$inputs$design, "correlation") || identical(plan$inputs$scale, "fisher_z")) " on Fisher's z scale"
        else if (identical(plan$inputs$scale, "log")) " on the log scale" else "",
        format(signif(o$p, 2)),
        if (o$p > plan$inputs$original_alpha) "It was not significant at its own level, so most goals here, which ask the replication to confirm it, may not fit; showing the effect is too small to matter may." else "")),
      replication_table_ui(plan),
      tags$dl(class = "small", lapply(names(replication_prior_labels), function(p) tagList(
        tags$dt(replication_prior_labels[[p]]), tags$dd(replication_prior_notes[[p]])))),
      replication_tau_note(plan$inputs$tau),
      if (!is.null(plan$telescope)) p(class = "small", sprintf("Small telescopes' yardstick is %s = %s, the effect the original study had a one-in-three chance of detecting.",
        plan$telescope$effect_name, format(signif(plan$telescope$effect, 3))))
      else if (bayes && !identical(plan$inputs$design, "generic")) p(class = "small", "Small telescopes is left out: it rests on the original's significance test, and the original was analysed with Bayes factors.")
      else p(class = "small", sprintf("The replication's standard error is the original's scaled by the square root of the ratio of sample sizes, which assumes it copies the original's design. Small telescopes is planned on the design's card.")),
      replication_chances_ui(plan),
      if (!is.null(plan$sequential)) div(class = "mt-2",
        p(class = "small", "The replication could also collect data until its Bayes factor is strong either way, a sequential design. The Bayesian planning tool under Tools works it out, with the belief chosen below as its design prior and the original's prior as the analysis prior."),
        actionButton("rep_to_sequential", "Plan it as a sequential Bayes factor study", class = "btn btn-outline-primary btn-sm")),
      p(class = "small text-muted", paste0("Calculated by powerkit's engine with ",
        paste(vapply(plan$packages, function(p) sprintf("%s %s", p$name, p$version), ""), collapse = ", "),
        if (identical(plan$inputs$design, "generic")) ". Every goal uses a normal approximation to the original's estimate (Pawel, Consonni & Held, 2026)."
        else ". Every goal judged against the original's effect uses a normal approximation (Pawel, Consonni & Held, 2026), which for a t-test asks for a few people fewer than the t-test cards; small telescopes is the cards' own calculation."))))
}

# The variation between studies the uncertain and shrunk beliefs allow,
# and powerkit's departure from BayesRepDesign's default of none
# (docs/conventions.md, "Variation between studies in replication plans").
replication_tau_note <- function(tau) {
  if (is.null(tau) || is.na(tau)) return(NULL)
  if (tau > 0) p(class = "small", sprintf("The uncertain and shrunk beliefs allow the true effect to vary between studies with an SD of %s (Kenny & Judd, 2019). BayesRepDesign's own default is no variation; Powerkit starts at 0.05, because assuming none makes a replication look easier than it is. Choose None under Goals to see the numbers without it.", format(tau)))
  else p(class = "small", "No variation between studies is allowed for: the true effect is taken to be the same in the replication as in the original (BayesRepDesign's default). Kenny and Judd (2019) argue this should not be the default.")
}

# The simple answer above the table (C-14): the sample size for a
# significant result again, if the true effect is as reported and if it is
# shrunk towards zero, both from the table's own first row.
replication_headline_ui <- function(plan) {
  repeated <- "bf_repeat" %in% plan$goals$goal
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

# The goal and belief the plan is written up with.
replication_choice_ui <- function(plan, goal = NULL, prior = NULL) {
  goals <- intersect(names(replication_goal_labels), unique(plan$goals$goal))
  tags$fieldset(class = "mt-3",
    tags$legend(class = "h6", "The plan you will write up"),
    selectInput("rep_goal", "Main goal", choices = stats::setNames(goals, replication_goal_labels[goals]),
      selected = goal %||% if ("bf_repeat" %in% goals) "bf_repeat" else "significance", selectize = FALSE, width = "100%"),
    selectInput("rep_prior", "Belief about the true effect", choices = stats::setNames(names(replication_prior_labels), replication_prior_labels),
      selected = prior %||% "uncertain", selectize = FALSE, width = "100%"),
    p(class = "small text-muted", "The other goals' numbers go in the write-up too, so readers can see what the sample size allows."))
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
  } else {
    sprintf("%s = %s, %s", plan$effect_name, format(i$original_effect), original)
  }
  belief <- switch(prior,
    as_reported = "assuming the true effect equals the original estimate",
    uncertain = "with a design prior that carries the original estimate's uncertainty (a flat initial prior updated by the original study)",
    shrunk = "with a design prior that shrinks the original estimate towards zero by empirical Bayes")
  varies <- if (i$tau > 0 && !identical(prior, "as_reported")) sprintf(", allowing the true effect to vary between studies with a standard deviation of %s", format(i$tau)) else ""
  if (is.na(m$row$n)) {
    return(sprintf("The replication's sample size was planned with powerkit's replication planner, but the chosen goal (%s) cannot reach a %s chance %s.",
      tolower(replication_goal_labels[[goal]]), replication_pct(i$power), if (m$no_effect) "" else belief))
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
    sprintf("%s, %s%s, with the original estimate (%s) and the normal-normal hierarchical model of Pawel, Consonni and Held (2026), calculated with BayesRepDesign%s",
      tolower(replication_goal_labels[[goal]]), belief, varies, shown, scaled)
  }
  sprintf("We planned the replication's sample size for a %s chance of %s. This gives %s.",
    replication_pct(i$power), calc, replication_n_words(plan, m$row$n))
}

# The write-up, as Markdown lines: every section, marked where empty.
# `analyses`: Markdown lines for the original's analysis as its card
# planned it (replication_analysis_lines()), or NULL; `title`, the plan's
# name.
replication_report <- function(values, plan = NULL, notes = NULL, notes_outcome = NULL, version = NULL, date = Sys.Date(),
                               analyses = NULL, title = NULL) {
  v <- function(id) trimws(as.character(values[[id]] %||% ""))
  or_blank <- function(x) if (nzchar(x)) x else "_(not filled in yet)_"
  design_label <- names(replication_designs_ui)[replication_designs_ui == (if (nzchar(v("rep_design"))) v("rep_design") else "two_groups")]
  two <- identical(v("rep_design"), "two_groups") || !nzchar(v("rep_design"))
  lines <- c(if (is.null(title)) "# Replication plan" else paste("# Replication plan:", title), "",
    sprintf("Written with powerkit's replication plan%s, %s.", if (!is.null(version)) paste0(", version ", version) else "", format(date)), "",
    "## The original study", "",
    sprintf("- Study: %s", or_blank(v("rep_study"))),
    sprintf("- Design: %s", design_label),
    sprintf("- How it was analysed: %s", tolower(names(replication_analyses_ui)[replication_analyses_ui ==
      (if (v("rep_analysis") %in% replication_analyses_ui) v("rep_analysis") else "test")])),
    if (identical(v("rep_analysis"), "bayes_factor")) c(
      sprintf("- Its Bayes factor (BF10): %s", or_blank(v("rep_bf"))),
      sprintf("- The scale of its Cauchy prior: %s", or_blank(v("rep_prior_scale")))),
    if (identical(v("rep_analysis"), "posterior")) c(
      sprintf("- Its prior: %s", tolower(names(replication_original_priors_ui)[replication_original_priors_ui ==
        (if (v("rep_original_prior") %in% replication_original_priors_ui) v("rep_original_prior") else "default")])),
      sprintf("- Its posterior mean: %s", or_blank(v("rep_effect"))),
      if (identical(v("rep_post_from"), "ci")) sprintf("- Its %s%% credible interval: %s to %s", if (nzchar(v("rep_cri_level"))) v("rep_cri_level") else "95",
        or_blank(v("rep_cri_lower")), or_blank(v("rep_cri_upper")))
      else sprintf("- Its posterior SD: %s", or_blank(v("rep_post_sd")))),
    if (v("rep_analysis") %in% c("bayes_factor", "posterior")) NULL
    else if (identical(v("rep_design"), "generic")) c(
      sprintf("- The effect: %s (%s)", or_blank(v("rep_effect_name")),
        names(replication_scales_ui)[replication_scales_ui == (if (nzchar(v("rep_scale"))) v("rep_scale") else "none")]),
      sprintf("- Reported effect: %s", or_blank(v("rep_effect"))),
      sprintf("- Its uncertainty: %s", switch(if (nzchar(v("rep_se_from"))) v("rep_se_from") else "se",
        ci = sprintf("a %s%% confidence interval from %s to %s", if (nzchar(v("rep_ci_level"))) v("rep_ci_level") else "95",
          or_blank(v("rep_ci_lower")), or_blank(v("rep_ci_upper"))),
        statistic = sprintf("a test statistic of %s", or_blank(v("rep_statistic"))),
        sprintf("a standard error of %s", or_blank(v("rep_se"))))))
    else sprintf("- Reported effect: %s", or_blank(v("rep_effect"))),
    if (two) sprintf("- Group sizes: %s and %s", or_blank(v("rep_n1")), or_blank(v("rep_n2"))) else sprintf("- Sample size: %s", or_blank(v("rep_n"))),
    if (!v("rep_analysis") %in% c("bayes_factor", "posterior")) sprintf("- Significance level: %s", or_blank(v("rep_original_alpha"))), "",
    "## Goals and sample size", "")
  if (is.null(plan)) {
    lines <- c(lines, "_(Not calculated yet: press “Show the sample sizes” under Goals and sample size.)_", "")
  } else {
    goal <- if (nzchar(v("rep_goal"))) v("rep_goal") else "significance"
    prior <- if (nzchar(v("rep_prior"))) v("rep_prior") else "uncertain"
    if (!goal %in% plan$goals$goal) goal <- "significance"
    lines <- c(lines, replication_methods_paragraph(plan, goal, prior), "",
      "Every goal, for comparison (sample size in total):", "",
      sprintf("| Goal | %s |", paste(replication_prior_labels, collapse = " | ")),
      sprintf("|---|%s", strrep("---|", 3)))
    for (g in intersect(names(replication_goal_labels), unique(plan$goals$goal))) {
      rows <- plan$goals[plan$goals$goal == g, ]
      cells <- if (all(is.na(rows$prior))) c(paste(replication_cell(plan, rows[1, ]), "(planned for no effect)"), "", "") else
        vapply(names(replication_prior_labels), function(p) replication_cell(plan, rows[rows$prior %in% p, ][1, ]), "")
      lines <- c(lines, sprintf("| %s | %s |", replication_goal_labels[[g]], paste(cells, collapse = " | ")))
    }
    lines <- c(lines, "",
      sprintf("Settings: replication significance level %s (two-sided), chance aimed for %s, variation between studies %s, smallest effect that matters %s, evidence threshold a Bayes factor of %s.",
        format(plan$inputs$alpha), replication_pct(plan$inputs$power), format(plan$inputs$tau),
        if (is.null(plan$inputs$smallest_effect)) "not given" else format(plan$inputs$smallest_effect), format(plan$inputs$threshold)), "")
  }
  lines <- c(lines, "## The original's analysis, planned on its card", "",
    if (length(analyses)) analyses else c("_(Not planned yet: under The original study, find the original's design and plan it on its card.)_", ""),
    "## How the replication differs", "",
    sprintf("- The people: %s", or_blank(v("rep_diff_people"))),
    sprintf("- The materials and measures: %s", or_blank(v("rep_diff_materials"))),
    sprintf("- The procedure and setting: %s", or_blank(v("rep_diff_procedure"))),
    sprintf("- The analysis: %s", or_blank(v("rep_diff_analysis"))),
    sprintf("- Would the original authors expect the same effect? %s", or_blank(v("rep_diff_expect"))), "")
  if (!is.null(notes) && any(nzchar(trimws(unlist(notes))))) {
    report <- labs_report(notes, notes_outcome, citation = labs_citation())
    report <- sub("^#", "##", report)
    lines <- c(lines, gsub("\n#", "\n##", report), "")
  }
  refs <- vapply(replication_ref_keys, function(k) labs_citation(key = k, fallback = ""), character(1))
  c(lines, "## References", "", paste0("- ", refs[nzchar(refs)]))
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
  values <- function() stats::setNames(lapply(replication_field_ids, function(id) input[[id]] %||% ""), replication_field_ids)
  plan <- reactiveVal(NULL)
  problem <- reactiveVal(NULL)

  run <- function() {
    plan(NULL); problem(NULL)
    missing <- replication_missing(values())
    if (length(missing)) {
      problem(sprintf("The original study needs %s first.", paste(missing, collapse = " and ")))
      return()
    }
    settings <- replication_settings_missing(values())
    if (length(settings)) {
      problem(sprintf("Choose %s under Goals first: the buttons below each box fill in the usual values.", paste(settings, collapse = " and ")))
      return()
    }
    result <- tryCatch(do.call(engine_function("replication_planning"), replication_args(values())),
      error = function(e) list(problem = replication_problem(e)))
    if (!is.null(result$problem)) problem(result$problem) else plan(result)
  }
  observeEvent(input$rep_run, run())
  observeEvent(input$rep_run_quick, {
    updateRadioButtons(session, "rep_section", selected = "goals")
    run()
  })
  output$rep_result <- renderUI({
    if (!is.null(problem())) return(div(class = "form-problems mt-2", role = "alert", p(problem())))
    if (is.null(plan())) return(NULL)
    replication_result_ui(plan())
  })
  output$rep_choice <- renderUI({
    req(plan())
    replication_choice_ui(plan(), isolate(input$rep_goal), isolate(input$rep_prior))
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
  stem <- function() sprintf("replication-plan-%s", format(Sys.Date()))
  output$rep_markdown <- downloadHandler(filename = function() paste0(stem(), ".md"),
    content = function(file) writeLines(report(), file, useBytes = TRUE))
  output$rep_docx <- downloadHandler(filename = function() paste0(stem(), ".docx"),
    content = function(file) docx_document(report(), file, powerkit_version()))
  observeEvent(input$rep_document, send_document(session, function() printable_document(report(), powerkit_version())))
  output$rep_script <- downloadHandler(filename = function() paste0(stem(), ".R"),
    content = function(file) {
      p <- plan() %||% if (!length(replication_settings_missing(values())))
        tryCatch(do.call(engine_function("replication_planning"), replication_args(values())), error = function(e) NULL)
      text <- if (is.null(p)) "# Fill in The original study, and the significance level and chance of success under Goals, first: the script needs them." else
        engine_function("replication_planning_script")(p)
      writeLines(text, file, useBytes = TRUE)
    })
  output$rep_writeup_note <- renderUI({
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
  reset <- function() { plan(NULL); problem(NULL) }
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
