# Prediction models (E77): the minimum sample size for developing a model,
# by the criteria of Riley and colleagues as pmsampsize's pmsampsize()
# computes them, or for validating an existing model of a yes/no outcome,
# as pmvalsampsize's pmvalsampsize() computes them. There is no power: the result screen shows each criterion's sample
# size and the one that sets the answer. All numbers come from the engine
# (result$prediction); nothing here calculates.

is_prediction <- function(spec) identical(spec$design, "prediction_model")

prediction_outcome_words <- function(outcome) {
  switch(outcome, binary = "a yes/no outcome", continuous = "a continuous outcome", survival = "a time-to-event outcome")
}

prediction_performance_text <- function(spec) {
  pop <- spec$population
  switch(pop$metric,
    c_statistic = sprintf("a C-statistic of %s", format(pop$c_statistic)),
    cox_snell_r2 = sprintf("a Cox-Snell R-squared of %s", format(pop$cox_snell_r2)),
    nagelkerke_r2 = sprintf("a Nagelkerke R-squared of %s", format(pop$nagelkerke_r2)),
    r2 = sprintf("an R-squared of %s", format(pop$r2)))
}

prediction_people <- function(n) sprintf("%s participants", whole(n))

is_prediction_validation <- function(spec) is_prediction(spec) && identical(spec$template, "validation")

prediction_validation_assumes <- function(spec) {
  pop <- spec$population
  c(sprintf("A C-statistic of %s in the new population", format(pop$c_statistic)),
    sprintf("%s%% with the outcome", format(100 * pop$prevalence)),
    if (identical(pop$lp_distribution, "normal")) sprintf("A linear predictor with mean %s and SD %s", format(pop$lp_mean), format(pop$lp_sd))
    else sprintf("Predicted risks from a beta(%s, %s) distribution", format(pop$beta_a), format(pop$beta_b)),
    if (!is.null(pop$threshold)) sprintf("A risk threshold of %s", format(pop$threshold)))
}

prediction_validation_sentences <- function(spec, result) {
  pr <- result$prediction
  label <- spec$variables$Y$label %||% "the outcome"
  headline <- sprintf("To validate the existing model of %s in new data, at least %s are needed.", label, prediction_people(pr$n))
  events <- if (!is.na(pr$events)) sprintf(" That is about %s people with the outcome.", whole(ceiling(pr$events))) else ""
  reading <- paste0(sprintf("This is the largest of the sample sizes the criteria need; the one that sets it is %s.", binding_phrase(pr$binding)), events,
    " It is a minimum for estimating the model's calibration and discrimination precisely, not a power calculation.")
  how <- sprintf("Calculated with pmvalsampsize (pmvalsampsize()), which powerkit called with your answers, assuming a C-statistic of %s and %s%% with the outcome.",
    format(spec$population$c_statistic), format(100 * spec$population$prevalence))
  c(headline = headline, reading = reading, detail = how)
}

prediction_sentences <- function(spec, result) {
  if (is_prediction_validation(spec)) return(prediction_validation_sentences(spec, result))
  pr <- result$prediction
  label <- spec$variables$Y$label %||% "the outcome"
  headline <- sprintf("To develop a model predicting %s from %s candidate predictor parameters, at least %s are needed.",
    label, whole(pr$parameters), prediction_people(pr$n))
  events <- if (!is.na(pr$events)) sprintf(" That is about %s %s, or %s per candidate parameter.", whole(ceiling(pr$events)),
    if (identical(pr$outcome, "survival")) "events" else "people with the outcome", format(round(pr$events_per_parameter, 1), nsmall = 1)) else ""
  reading <- paste0(sprintf("This is the largest of the sample sizes the criteria need; the one that sets it is %s.", binding_phrase(pr$binding)), events,
    " It is a minimum for developing the model, not a power calculation: a smaller sample risks a model that overfits and predicts less well in new people.")
  how <- sprintf("Calculated by formula with pmsampsize (pmsampsize()), which powerkit called with your answers, assuming %s for a model of %s.",
    prediction_performance_text(spec), prediction_outcome_words(pr$outcome))
  c(headline = headline, reading = reading, detail = how)
}

tolower_first <- function(x) paste0(tolower(substr(x, 1, 1)), substr(x, 2, nchar(x)))

# The criteria, one row each, with the binding one marked.
prediction_criteria_ui <- function(result) {
  pr <- result$prediction
  rows <- lapply(seq_len(nrow(pr$criteria)), function(i) {
    row <- pr$criteria[i, ]
    tags$tr(class = if (identical(row$criterion, pr$binding)) "table-active" else NULL,
      tags$td(row$criterion), tags$td(class = "text-end", whole(row$n)),
      tags$td(if (identical(row$criterion, pr$binding)) "Sets the answer" else ""))
  })
  tags$table(class = "table table-sm result-criteria",
    tags$caption("The sample size each criterion needs"),
    tags$thead(tags$tr(tags$th(scope = "col", "Criterion"), tags$th(scope = "col", class = "text-end", "Participants"), tags$th(scope = "col", ""))),
    tags$tbody(rows))
}

prediction_hero_ui <- function(spec, result) {
  pr <- result$prediction
  assumes <- if (is_prediction_validation(spec)) prediction_validation_assumes(spec) else c(
    sprintf("%s, %s", paste0(toupper(substr(prediction_outcome_words(pr$outcome), 1, 1)), substr(prediction_outcome_words(pr$outcome), 2, 100)),
      prediction_performance_text(spec)),
    sprintf("%s candidate predictor parameters", whole(pr$parameters)),
    sprintf("Shrinkage of at least %s", format(pr$target_shrinkage)))
  div(class = "result-hero",
    div(class = "result-figure",
      tags$span(class = "result-figure-value", whole(pr$n)),
      tags$span(class = "result-figure-label", "participants at least"),
      if (!is.na(pr$events)) tags$span(class = "result-figure-sub",
        sprintf("about %s %s", whole(ceiling(pr$events)), if (identical(pr$outcome, "survival")) "events" else "with the outcome"))),
    div(class = "result-assumes",
      tags$span(class = "result-assumes-title", "Assuming"),
      tags$ul(lapply(assumes, tags$li))))
}

prediction_writeup <- function(form, spec, result, fields, values, departures = character()) {
  if (isTRUE(values$source_stale)) return(NULL)
  if (blank(values$just_source)) {
    values$just_source <- no_reason_token
    return(without_reason(prediction_writeup(form, spec, result, fields, values, departures)))
  }
  if (is_prediction_validation(spec)) return(prediction_validation_writeup(spec, result, values, departures))
  pr <- result$prediction
  p <- result$provenance
  label <- spec$variables$Y$label %||% "the outcome"
  aim <- sprintf(paste("We calculated the minimum sample size for developing a prediction model of %s (%s) with %s candidate predictor parameters,",
    "by the criteria of Riley et al.: an expected shrinkage of the predictor effects of at least %s, a small difference between the apparent and adjusted R-squared, and %s.",
    "This requires at least %s%s; the criterion that sets it is %s."),
    label, prediction_outcome_words(pr$outcome), whole(pr$parameters), format(pr$target_shrinkage),
    if (identical(pr$outcome, "continuous")) "precise estimates of the residual SD and the mean outcome" else "a precise estimate of the outcome risk",
    prediction_people(pr$n),
    if (!is.na(pr$events)) sprintf(" (about %s %s, %s per candidate parameter)", whole(ceiling(pr$events)),
      if (identical(pr$outcome, "survival")) "events" else "with the outcome", format(round(pr$events_per_parameter, 1), nsmall = 1)) else "",
    tolower_first(pr$binding))
  basis <- sprintf("The model's anticipated performance, %s, was based on %s: %s.", prediction_performance_text(spec),
    writeup_source[[values$just_type %||% "prior_study"]] %||% "our reasoning", writeup_quote(values$just_source))
  recruit <- result$recruitment
  recruit_line <- if (is.list(recruit)) sprintf("Allowing for %s attrition, we will recruit %s.", percent_attrition(recruit$attrition), whole(recruit$n_recruit))
  software <- sprintf("The calculation used the R package pmsampsize (version %s; pmsampsize()), set up by %s in %s.",
    p$packages[["pmsampsize"]], powerkit_cited(p$packages[["powerkit"]]), p$r_version)
  short <- paste(c(aim, basis, recruit_line, software), collapse = " ")
  full <- paste(c(short,
    if (length(departures)) paste("Departures from the established tools' defaults:", paste(unname(departures), collapse = " ")),
    sprintf("Spec hash: %s.", p$spec_hash)), collapse = "\n\n")
  ethics <- paste(c(
    sprintf("We plan to include %s.", prediction_people(pr$n)), recruit_line,
    "This number is the minimum needed to develop the prediction model reliably, not the result of a power analysis.",
    "With fewer people, the model would be more likely to fit chance features of this sample and to predict less well for new people.",
    basis,
    sprintf("The calculation was made with %s and the R package pmsampsize (version %s) and can be reproduced from the saved plan.",
      powerkit_cited(p$packages[["powerkit"]]), p$packages[["pmsampsize"]])
  ), collapse = " ")
  c(short = short, full = full, ethics = ethics)
}

prediction_validation_writeup <- function(spec, result, values, departures) {
  pr <- result$prediction
  p <- result$provenance
  pop <- spec$population
  goal <- spec$goal
  label <- spec$variables$Y$label %||% "the outcome"
  widths <- c(goal$oe_ci_width %||% 0.2, goal$cslope_ci_width %||% 0.2, goal$cstat_ci_width %||% 0.1)
  aim <- sprintf(paste("We calculated the minimum sample size for validating an existing prediction model of %s (a yes/no outcome) in new data,",
    "by the criteria of Riley et al.: 95%% confidence intervals no wider than %s for the observed/expected ratio, %s for the calibration slope and %s for the C-statistic%s.",
    "This requires at least %s%s; the criterion that sets it is %s."),
    label, format(widths[1]), format(widths[2]), format(widths[3]),
    if (!is.null(pop$threshold)) sprintf(", and %s for the standardised net benefit at a risk threshold of %s", format(goal$nb_ci_width %||% 0.2), format(pop$threshold)) else "",
    prediction_people(pr$n), if (!is.na(pr$events)) sprintf(" (about %s with the outcome)", whole(ceiling(pr$events))) else "", tolower_first(pr$binding))
  basis <- sprintf("We assumed a C-statistic of %s and %s%% with the outcome in the new population, based on %s: %s.",
    format(pop$c_statistic), format(100 * pop$prevalence), writeup_source[[values$just_type %||% "prior_study"]] %||% "our reasoning", writeup_quote(values$just_source))
  recruit <- result$recruitment
  recruit_line <- if (is.list(recruit)) sprintf("Allowing for %s attrition, we will recruit %s.", percent_attrition(recruit$attrition), whole(recruit$n_recruit))
  software <- sprintf("The calculation used the R package pmvalsampsize (version %s; pmvalsampsize(), with its default seed for simulating the linear predictor), set up by %s in %s.",
    p$packages[["pmvalsampsize"]], powerkit_cited(p$packages[["powerkit"]]), p$r_version)
  short <- paste(c(aim, basis, recruit_line, software), collapse = " ")
  full <- paste(c(short,
    if (length(departures)) paste("Departures from the established tools' defaults:", paste(unname(departures), collapse = " ")),
    sprintf("Spec hash: %s.", p$spec_hash)), collapse = "\n\n")
  ethics <- paste(c(
    sprintf("We plan to include %s.", prediction_people(pr$n)), recruit_line,
    "This number is the minimum needed to judge reliably how well the existing model predicts in this population, not the result of a power analysis.",
    "With fewer people, the estimates of the model's calibration and discrimination would be too imprecise to tell whether it is safe to use.",
    basis,
    sprintf("The calculation was made with %s and the R package pmvalsampsize (version %s) and can be reproduced from the saved plan.",
      powerkit_cited(p$packages[["powerkit"]]), p$packages[["pmvalsampsize"]])
  ), collapse = " ")
  c(short = short, full = full, ethics = ethics)
}

prediction_panel_ui <- function(tree, forms, ep_id, fields, values, calc) {
  ep <- tree$endpoints[[ep_id]]
  spec <- calc$spec
  result <- calc$result
  words <- prediction_sentences(spec, result)
  departures <- departures_for(forms, ep_id, spec)
  p_ <- result$provenance
  can_export <- !isTRUE(values$source_stale)
  hero <- tryCatch(prediction_hero_ui(spec, result), error = function(e) NULL)
  div(
    class = "result-panel", role = "status", tabindex = "-1",
    result_sections_ui(list(`result-answer` = "The answer", `result-take` = "Write it up and save it", `result-how-card` = "How it was calculated")),
    div(class = paste("result-card result-main", if (!is.null(hero)) "has-hero"), id = "result-answer",
      h3(class = "h4", id = "result-heading", tabindex = "-1", `data-result-focus` = "true", "Your result"),
      hero,
      p(class = "result-headline lead", words[["headline"]]),
      p(class = "result-reading", words[["reading"]]),
      prediction_criteria_ui(result),
      if (!is.null(line <- reasoning_line(values))) p(class = "result-reasoning", line),
      source_stale_ui(fields, values),
      if (!is.null(recruit <- recruitment_lines(result, spec))) div(class = "result-recruitment",
        p(tags$strong(recruit[["analysed"]])), p(tags$strong(recruit[["recruit"]])),
        p(class = "small", recruit[["caveat"]])),
      p(class = "result-detail", words[["detail"]]),
      if (length(calc$notes)) tagList(h4(class = "h6", "Notes"), tags$ul(class = "result-notes", lapply(calc$notes, tags$li))),
      keep_result_ui(can_export, plan = TRUE, kept = isTRUE(calc$saved) && !isTRUE(calc$from_browser))),
    div(class = "result-card result-save", id = "result-take",
      h4(class = "h5", "Write it up and save it"),
      writeup_ui(prediction_writeup(forms$forms[[ep_id]], spec, result, fields, values, departures)),
      if (blank(values$just_source)) p(class = "export-needs-reasoning",
        tags$strong("No reason for the model's anticipated performance is recorded yet. "),
        "The write-up and saved files say so. To add one, write it under “Where your effect size comes from” and press “Calculate” again."),
      documents_ui(can_export, p_$backend, document_menu("planning_document", "download_planning_docx", "download_planning_document",
        "Planning document (PDF)", "the planning document"))),
    div(class = "result-card result-how", id = "result-how-card",
      h4(class = "h5", "How it was calculated"),
      p(class = "result-credit",
        "Calculated by the R package ", tags$strong(p_$backend), sprintf(" (version %s), with %s(). ", p_$packages[[p_$backend]], p_$backend_function),
        "powerkit built the call from your answers and checked the values it passes. Cite the package and the method paper: see Citations above."),
      validation_ui(ep, result),
      if (length(departures)) tagList(
        h4(class = "h6", "Where powerkit differs from the tool's defaults"),
        tags$ul(class = "result-departures", lapply(unname(departures), tags$li))),
      tags$details(class = "result-more",
        tags$summary("More about this result: the values it used"),
        tags$ul(class = "result-inputs", lapply(entered_lines(fields, values), tags$li))),
      tags$details(class = "result-more", tags$summary("Reproducibility record"), tags$ul(lapply(provenance_lines(result), tags$li))),
      tags$details(class = "result-more", tags$summary("The design spec that was run (JSON)"), tags$pre(class = "spec-json", spec_json(spec))))
  )
}

# "Little overfitting: expected shrinkage ..." as "little overfitting
# (expected shrinkage ...)", so the sentence has one colon.
binding_phrase <- function(binding) {
  text <- tolower_first(binding)
  sub("^([^:]+): (.+)$", "\\1 (\\2)", text)
}
