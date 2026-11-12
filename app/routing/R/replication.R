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
  "1. The original study" = "original",
  "2. Goals and sample size" = "goals",
  "3. How the replication differs" = "differences",
  "4. Write-up" = "writeup"
)

replication_designs_ui <- c(
  "Two separate groups compared on a score (Cohen's d)" = "two_groups",
  "The same people measured twice (d_z)" = "paired",
  "One group against a fixed value (Cohen's d)" = "one_sample",
  "Two scores and how they are related (r)" = "correlation"
)

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

replication_card_note <- function(forms, ep_id) {
  planner <- !is.null(replication_card_design(forms, ep_id))
  div(class = "labs-return replication-card-note", role = "note",
    p(tags$strong("Planning a replication. "),
      "Enter the original study's effect on the next screen; its source starts as an earlier study. ",
      "A published effect is often larger than the true one, because larger effects are more likely to be published, so consider planning for a smaller effect as well, such as the smallest that would matter."),
    if (planner) {
      p(class = "mb-0", "For this design, the replication planner gives the sample size for each goal a replication can have (a significant result again, a pooled estimate, agreement with the original, Bayes factors) and a write-up. ",
        actionLink("rep_open_planner", "Open the replication planner"), " (in Labs, experimental), or carry on here for a significant result again.")
    } else {
      p(class = "mb-0", "This card plans the replication for a significant result again. The replication planner's other goals cover t-tests and correlations only for now.")
    })
}

# The input screen's starting values when replicating: the effect comes
# from an earlier study, unless the user has already chosen.
replication_form_values <- function(values) {
  if (is.null(values$just_type)) values$just_type <- "prior_study"
  values
}

# How much the true effect may vary between studies (Kenny & Judd, 2019,
# whose representative values for d these are).
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
  bf_replication = "Strong evidence that the original's effect was found again (replication Bayes factor)",
  bf_sceptical = "Strong evidence for the effect that would convince a sceptic (sceptical Bayes factor)",
  small_telescopes = "Show the original study was too small to have detected the effect (small telescopes)",
  negligible = "Show the effect is too small to matter (equivalence test)"
)

# Short notes on what each goal answers (Anderson & Maxwell, 2016; Pawel,
# Consonni & Held, 2026).
replication_goal_notes <- c(
  significance = "The usual definition of a successful replication. On its own it says little about how large the effect is.",
  pooled = "Combines both studies' estimates. The original's own result counts towards it, so the bar is set stricter: a one-sided level of alpha/2 squared.",
  agreement = "Asks whether the two estimates are close, not whether either differs from zero. A small original rarely allows it.",
  bf_replication = "Compares the original's effect with no effect, using the new data.",
  bf_sceptical = "Asks whether the two studies together would persuade someone who doubts the effect. A weak original may never allow it.",
  small_telescopes = "Planned for a true effect of zero. A result below the yardstick says the original was too small to see an effect that size, not that it was a false positive.",
  negligible = "Planned for a true effect of zero. It needs the smallest effect that matters, and usually a large sample."
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

replication_ref_keys <- c("Pawel2026_replication", "Anderson2016_replication", "Simonsohn2015_telescopes", "Kenny2019_heterogeneity")

replication_ui <- function() {
  field <- function(id, label, value = "", help = NULL) {
    div(class = "form-field", textInput(id, label, value = value, width = "100%"),
      if (!is.null(help)) p(class = "small text-muted", help))
  }
  box <- function(id, label, rows = 3) div(class = "form-field", textAreaInput(id, label, rows = rows, width = "100%"))
  section <- function(id, ...) conditionalPanel(sprintf("input.rep_section == '%s'", id), ...)
  conditionalPanel("input.labs_tool == 'replication'",
    labs_tool_head("replication"),
    p("Plan a replication of a published finding. The sections can be filled in any order, and you can come back to them: what you enter stays in this browser tab, and “Save to a file” keeps it for another day."),
    p(class = "small", "Still deciding whether the finding is worth replicating? ",
      tags$a(href = "#", onclick = "pkLabsOpen('prereplication'); return false;", "Pre-replication notes"),
      " come first. The planner uses their study and smallest effect, and the write-up includes them."),
    div(class = "rep-file",
      download_button("rep_save", "Save to a file", class = "btn btn-outline-primary btn-sm"),
      fileInput("rep_open", "Or open a saved planner file", accept = c(".json", "application/json"), width = "100%")),
    uiOutput("rep_open_status"),
    radioButtons("rep_section", NULL, choices = replication_sections, selected = "original", inline = TRUE, width = "100%"),

    section("original",
      tags$fieldset(class = "form-group-box", tags$legend(class = "h6", "1. The original study"),
        uiOutput("rep_from_notes_study"),
        field("rep_study", "The original study (authors, year, title or link)"),
        selectInput("rep_design", "Its design", choices = replication_designs_ui, selectize = FALSE, width = "100%"),
        field("rep_effect", "The effect it reported (d, d_z or r, with its sign)",
          help = "As the paper reported it. If it gave a t or F instead, the Effect size converter in Labs turns it into d or r."),
        conditionalPanel("input.rep_design == 'two_groups'",
          field("rep_n1", "People in its first group"),
          field("rep_n2", "People in its second group")),
        conditionalPanel("input.rep_design != 'two_groups'",
          field("rep_n", "People (or pairs) it analysed")),
        field("rep_original_alpha", "Its significance level (two-sided)", value = "0.05"))),

    section("goals",
      tags$fieldset(class = "form-group-box", tags$legend(class = "h6", "2. Goals and sample size"),
        p(class = "group-note", "A replication can aim for more than a significant result (Anderson & Maxwell, 2016). The table gives the sample size each goal needs, under three beliefs about the true effect. Choose the goal that answers your question, and the belief you can defend."),
        uiOutput("rep_from_notes_smallest"),
        field("rep_smallest", "The smallest effect that would matter (d, d_z or r, positive)",
          help = "Needed for the goals of agreement and of an effect too small to matter. Leave blank to skip those two."),
        selectInput("rep_tau", "How much the true effect may vary between studies", choices = replication_taus, selected = "0", selectize = FALSE, width = "100%"),
        p(class = "small text-muted", "Labs, samples and procedures differ, so the true effect can differ too. Kenny and Judd (2019) suggest 0.05, 0.125 and 0.20 (in d) as small, medium and large, and argue zero should not be the default. It applies to the uncertain and shrunk beliefs. For a correlation it is on Fisher's z scale, close to r for small values."),
        field("rep_alpha", "The replication's significance level (two-sided)", value = "0.05"),
        field("rep_power", "The chance of success to aim for", value = "0.8"),
        radioButtons("rep_threshold", "Strong evidence, for the Bayes factor goals", choices = c("3", "6", "10", "30"), selected = "10", inline = TRUE),
        field("rep_n_at", "Optional: a sample size you could recruit (in total), to see each goal's chance at it"),
        actionButton("rep_run", "Show the sample sizes", class = "btn btn-primary"),
        uiOutput("rep_result"),
        uiOutput("rep_choice"))),

    section("differences",
      tags$fieldset(class = "form-group-box", tags$legend(class = "h6", "3. How the replication differs"),
        p(class = "group-note", "No replication repeats a study exactly. Writing down what changes, and why, says how the result should be read: whether a different result would count against the finding, or point to a condition it depends on. If much changes, allow for more variation between studies in section 2."),
        box("rep_diff_people", "The people: who takes part, where and when, and how they differ from the original sample"),
        box("rep_diff_materials", "The materials and measures: what is translated, updated or replaced"),
        box("rep_diff_procedure", "The procedure and setting: for example online instead of in the lab"),
        box("rep_diff_analysis", "The analysis: the original's test, and anything added or changed"),
        box("rep_diff_expect", "Would the original authors expect the same effect under these conditions? If not, why replicate this way?"))),

    section("writeup",
      tags$fieldset(class = "form-group-box", tags$legend(class = "h6", "4. Write-up"),
        p(class = "group-note", "A plan built from what you have entered, for a preregistration or a registered report. Sections not filled in yet are marked, so it can be downloaded at any stage."),
        div(class = "nav-buttons",
          document_menu("rep_document", "rep_docx", "rep_markdown", "Save as PDF or print", "the replication plan", class = "btn btn-primary"),
          download_button("rep_script", "Download the R script", class = "btn btn-outline-primary")),
        uiOutput("rep_writeup_note"))),
    p(class = "small text-muted", "References: ", replication_citations())
  )
}

replication_citations <- function(path = labs_refs_path(), keys = replication_ref_keys) {
  texts <- vapply(keys, function(k) labs_citation(path, key = k, fallback = ""), character(1))
  paste(texts[nzchar(texts)], collapse = " ")
}

# Every field the planner keeps, for the file and the write-up.
replication_field_ids <- c("rep_study", "rep_design", "rep_effect", "rep_n1", "rep_n2", "rep_n", "rep_original_alpha",
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
    power = num("rep_power", 0.8), tau = num("rep_tau", 0), smallest_effect = num("rep_smallest"),
    threshold = num("rep_threshold", 10), n = num("rep_n_at"))
  if (identical(design, "two_groups")) {
    args$original_n1 <- num("rep_n1", NA_real_)
    args$original_n2 <- num("rep_n2", NA_real_)
  } else {
    args$original_n <- num("rep_n", NA_real_)
  }
  args
}

# What is missing before the engine can plan, in the field's words.
replication_missing <- function(values) {
  v <- function(id) nzchar(trimws(as.character(values[[id]] %||% "")))
  two <- identical(values$rep_design %||% "two_groups", "two_groups")
  missing <- c(
    if (!v("rep_effect")) "the effect the original study reported",
    if (two && (!v("rep_n1") || !v("rep_n2"))) "the original study's two group sizes",
    if (!two && !v("rep_n")) "the number of people (or pairs) the original study analysed"
  )
  missing
}

replication_problem <- function(e) {
  if (!inherits(e, "powerkit_error")) {
    return("powerkit couldn't work this out: something went wrong in its engine. Please report this, with the values you entered.")
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
    tags$caption(sprintf("Replication sample size (in total) for a %s chance of each goal", replication_pct(plan$inputs$power))),
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

replication_result_ui <- function(plan) {
  o <- plan$original
  tagList(
    div(class = "result-panel mt-2", role = "status",
      p(sprintf("The original estimate is %s with a standard error of %s%s (two-sided p = %s, by the normal approximation). %s",
        format(signif(o$estimate, 3)), format(signif(o$se, 3)),
        if (identical(plan$inputs$design, "correlation")) " on Fisher's z scale" else "",
        format(signif(o$p, 2)),
        if (o$p > plan$inputs$original_alpha) "It was not significant at its own level, so most goals here, which ask the replication to confirm it, may not fit; showing the effect is too small to matter may." else "")),
      replication_table_ui(plan),
      tags$dl(class = "small", lapply(names(replication_prior_labels), function(p) tagList(
        tags$dt(replication_prior_labels[[p]]), tags$dd(replication_prior_notes[[p]])))),
      p(class = "small", sprintf("Small telescopes' yardstick is %s = %s, the effect the original study had a one-in-three chance of detecting.",
        plan$telescope$effect_name, format(signif(plan$telescope$effect, 3)))),
      replication_chances_ui(plan),
      p(class = "small text-muted", "Calculated by powerkit's engine with ",
        paste(vapply(plan$packages, function(p) sprintf("%s %s", p$name, p$version), ""), collapse = ", "),
        ". Every goal judged against the original's effect uses a normal approximation (Pawel, Consonni & Held, 2026), which for a t-test asks for a few people fewer than the t-test cards; small telescopes is the cards' own calculation.")))
}

# The goal and belief the plan is written up with.
replication_choice_ui <- function(plan, goal = NULL, prior = NULL) {
  goals <- intersect(names(replication_goal_labels), unique(plan$goals$goal))
  tags$fieldset(class = "mt-3",
    tags$legend(class = "h6", "The plan you will write up"),
    selectInput("rep_goal", "Main goal", choices = stats::setNames(goals, replication_goal_labels[goals]),
      selected = goal %||% "significance", selectize = FALSE, width = "100%"),
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
  belief <- switch(prior,
    as_reported = "assuming the true effect equals the original estimate",
    uncertain = "with a design prior that carries the original estimate's uncertainty (a flat initial prior updated by the original study)",
    shrunk = "with a design prior that shrinks the original estimate towards zero by empirical Bayes")
  varies <- if (i$tau > 0 && !identical(prior, "as_reported")) sprintf(", allowing the true effect to vary between studies with a standard deviation of %s", format(i$tau)) else ""
  if (is.na(m$row$n)) {
    return(sprintf("The replication's sample size was planned with powerkit's replication planner, but the chosen goal (%s) cannot reach a %s chance %s.",
      tolower(replication_goal_labels[[goal]]), replication_pct(i$power), if (m$no_effect) "" else belief))
  }
  calc <- if (identical(goal, "small_telescopes")) {
    sprintf("the small telescopes approach (Simonsohn, 2015): a one-sided test of whether the effect is smaller than %s = %s, the effect the original study (%s) had 33%% power to detect at its two-sided significance level of %s, planned for a true effect of zero and calculated with pwr and pwrss",
      plan$telescope$effect_name, format(signif(plan$telescope$effect, 3)), original, format(i$original_alpha))
  } else if (identical(goal, "negligible")) {
    sprintf("an equivalence test (two one-sided tests at %s) with bounds of ±%s, planned for a true effect of zero, calculated with BayesRepDesign (Pawel, Consonni & Held, 2026)",
      format(i$alpha), format(i$smallest_effect))
  } else {
    sprintf("%s, %s%s, with the original estimate (%s = %s, %s) and the normal-normal hierarchical model of Pawel, Consonni and Held (2026), calculated with BayesRepDesign",
      tolower(replication_goal_labels[[goal]]), belief, varies, plan$effect_name, format(i$original_effect), original)
  }
  sprintf("We planned the replication's sample size for a %s chance of %s. This gives %s.",
    replication_pct(i$power), calc, replication_n_words(plan, m$row$n))
}

# The write-up, as Markdown lines: every section, marked where empty.
replication_report <- function(values, plan = NULL, notes = NULL, notes_outcome = NULL, version = NULL, date = Sys.Date()) {
  v <- function(id) trimws(as.character(values[[id]] %||% ""))
  or_blank <- function(x) if (nzchar(x)) x else "_(not filled in yet)_"
  design_label <- names(replication_designs_ui)[replication_designs_ui == (if (nzchar(v("rep_design"))) v("rep_design") else "two_groups")]
  two <- identical(v("rep_design"), "two_groups") || !nzchar(v("rep_design"))
  lines <- c("# Replication plan", "",
    sprintf("Written with powerkit's replication planner (Labs, experimental)%s, %s.", if (!is.null(version)) paste0(", version ", version) else "", format(date)), "",
    "## The original study", "",
    sprintf("- Study: %s", or_blank(v("rep_study"))),
    sprintf("- Design: %s", design_label),
    sprintf("- Reported effect: %s", or_blank(v("rep_effect"))),
    if (two) sprintf("- Group sizes: %s and %s", or_blank(v("rep_n1")), or_blank(v("rep_n2"))) else sprintf("- Sample size: %s", or_blank(v("rep_n"))),
    sprintf("- Significance level: %s", or_blank(v("rep_original_alpha"))), "",
    "## Goals and sample size", "")
  if (is.null(plan)) {
    lines <- c(lines, "_(Not calculated yet: press “Show the sample sizes” in section 2.)_", "")
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
      sprintf("Settings: replication significance level %s (two-sided), chance aimed for %s, variation between studies %s, smallest effect that matters %s, strong evidence a Bayes factor of %s.",
        format(plan$inputs$alpha), replication_pct(plan$inputs$power), format(plan$inputs$tau),
        if (is.null(plan$inputs$smallest_effect)) "not given" else format(plan$inputs$smallest_effect), format(plan$inputs$threshold)), "")
  }
  lines <- c(lines, "## How the replication differs", "",
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

# Reading a file back: only the planner's own fields, as text.
replication_read_file <- function(path) {
  data <- tryCatch(jsonlite::read_json(path), error = function(e) NULL)
  if (!is.list(data) || !identical(data$app, "powerkit-replication-planner") || !is.list(data$fields)) return(NULL)
  fields <- data$fields[intersect(names(data$fields), replication_field_ids)]
  lapply(fields, function(x) paste(as.character(unlist(x)), collapse = "\n"))
}

replication_server <- function(input, output, session, notes = function() list(), notes_outcome = function() NULL) {
  values <- function() stats::setNames(lapply(replication_field_ids, function(id) input[[id]] %||% ""), replication_field_ids)
  plan <- reactiveVal(NULL)
  problem <- reactiveVal(NULL)

  observeEvent(input$rep_run, {
    plan(NULL); problem(NULL)
    missing <- replication_missing(values())
    if (length(missing)) {
      problem(sprintf("Section 1 needs %s first.", paste(missing, collapse = " and ")))
      return()
    }
    result <- tryCatch(do.call(engine_function("replication_planning"), replication_args(values())),
      error = function(e) list(problem = replication_problem(e)))
    if (!is.null(result$problem)) problem(result$problem) else plan(result)
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

  report <- function() replication_report(values(), plan(), notes(), notes_outcome(), powerkit_version())
  stem <- function() sprintf("replication-plan-%s", format(Sys.Date()))
  output$rep_markdown <- downloadHandler(filename = function() paste0(stem(), ".md"),
    content = function(file) writeLines(report(), file, useBytes = TRUE))
  output$rep_docx <- downloadHandler(filename = function() paste0(stem(), ".docx"),
    content = function(file) docx_document(report(), file, powerkit_version()))
  observeEvent(input$rep_document, send_document(session, function() printable_document(report(), powerkit_version())))
  output$rep_script <- downloadHandler(filename = function() paste0(stem(), ".R"),
    content = function(file) {
      p <- plan() %||% tryCatch(do.call(engine_function("replication_planning"), replication_args(values())), error = function(e) NULL)
      text <- if (is.null(p)) "# Fill in section 1 (the original study) first: the script needs its effect and sample size." else
        engine_function("replication_planning_script")(p)
      writeLines(text, file, useBytes = TRUE)
    })
  output$rep_writeup_note <- renderUI({
    missing <- replication_missing(values())
    todo <- c(if (length(missing)) "section 1", if (is.null(plan())) "the sample sizes in section 2")
    if (!length(todo)) return(p(class = "small", "Everything the plan needs is in. Sections you left blank are marked in the document."))
    p(class = "small", sprintf("Still to do: %s. The document can be downloaded now; those parts are marked.", paste(todo, collapse = " and ")))
  })

  # Saving and opening the planner's file.
  output$rep_save <- downloadHandler(filename = function() sprintf("replication-planner-%s.json", format(Sys.Date())),
    content = function(file) jsonlite::write_json(replication_file(values(), powerkit_version()), file, auto_unbox = TRUE, pretty = TRUE))
  observeEvent(input$rep_open, {
    fields <- replication_read_file(input$rep_open$datapath)
    if (is.null(fields)) {
      output$rep_open_status <- renderUI(div(class = "form-problems", role = "alert",
        "That file isn't a replication planner file from powerkit. Choose a file saved with “Save to a file”."))
      return()
    }
    for (id in names(fields)) {
      if (id %in% c("rep_design", "rep_tau", "rep_goal", "rep_prior")) updateSelectInput(session, id, selected = fields[[id]])
      else if (identical(id, "rep_threshold")) updateRadioButtons(session, id, selected = fields[[id]])
      else updateTextAreaInput(session, id, value = fields[[id]])
    }
    plan(NULL); problem(NULL)
    output$rep_open_status <- renderUI(div(class = "small", role = "status",
      "Opened. Press “Show the sample sizes” in section 2 to recalculate."))
  })
  invisible(NULL)
}
