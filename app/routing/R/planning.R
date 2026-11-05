planning_decision_ui <- function(form) {
  design <- form$base$design
  current <- if (isTRUE(form$precision))
    "This screen plans the width of an interval, rather than the chance of rejecting a null hypothesis. Expected width is an average; assurance, where offered, specifies a chance of meeting the width target." else
    if (identical(design, "equivalence_test"))
      "This screen plans evidence relative to your equivalence or non-inferiority bounds. A non-significant ordinary test is not evidence of equivalence." else
    if (identical(design, "sem"))
      "Check whether you selected overall model fit or a particular factor correlation/path. Power to detect poor overall fit is not power for a particular path, and the assumed model matters." else
      "Ordinary significance planning asks how often the selected test rejects its null under your stated population. A study powered at the smallest worthwhile effect does not thereby test that the effect exceeds that threshold."
  div(class = "planning-decision small",
    tags$strong("Check the decision you want. "), current,
    tags$details(tags$summary("Different questions need different planning goals"),
      tags$ul(tags$li("Detect a departure from the null: choose the relevant significance test and expected population effect."),
        tags$li("Establish that an effect exceeds a worthwhile threshold: choose a minimum-effect test, enter the threshold and an expected effect beyond it. T-test screens offer this test version."),
        tags$li("Establish practical similarity: choose equivalence planning and justify both bounds; do not treat a non-significant difference as similarity."),
        tags$li("Estimate precisely: choose precision planning; distinguish average interval width from assurance of reaching it."),
        tags$li("Plan a structural equation model: distinguish overall fit from the specific path or correlation you want to test.")),
      p("A directional scientific prediction can accompany a two-sided test. Choose the statistical decision rule before seeing the data.")))
}

decision_rule_text <- function(spec) {
  if (identical(spec$design, "precision")) return(paste(
    "Precision planning, not a significance decision.",
    if (is.null(spec$goal$assurance)) "Target: expected (average) interval width; no probability guarantee of meeting that width is specified." else
      sprintf("Target: width %s with assurance %s.", spec$goal$width, spec$goal$assurance)))
  if (identical(spec$design, "equivalence_test")) return("Equivalence/non-inferiority decision relative to the stated bounds and selected test; a non-significant ordinary test does not establish equivalence.")
  if (identical(spec$target_test$method, "minimum_effect")) return("Minimum-effect decision: the effect exceeds the stated worthwhile threshold in the chosen direction. The expected population effect and threshold are separate assumptions.")
  if (identical(spec$target_test$method, "bayes_factor")) return("Bayes factor evidence decision using the stated prior and evidence threshold, rather than a p-value significance rule.")
  paste("Selected significance test at alpha", spec$target_test$alpha,
    "with alternative", gsub("_", " ", spec$target_test$alternative %||% "two_sided"),
    if (identical(spec$design, "sem")) "; distinguish the selected model-fit hypothesis from a target path/correlation." else
      "; rejection concerns the selected null hypothesis, not proof of practical importance or of the scientific theory.")
}

# Build from the calculation's captured answers, never the live input boxes.
planning_document <- function(tree, forms, calc) {
  stopifnot(identical(calc$status, "ok"), !isFALSE(calc$form_consistent))
  route <- calc$route
  id <- route$endpoint
  values <- route$form_values
  if (is.null(id) || is.null(values)) stop("This result has no captured form answers. Recalculate before downloading a planning document.")
  if (blank(values$just_source) || isTRUE(values$source_stale)) stop("Add current source reasoning and recalculate before keeping this plan.")
  spec <- calc$spec
  result <- calc$result
  fields <- form_fields(form_groups(forms, id, k = route$form_k %||% 2L))
  active <- Filter(function(f) field_applies(f, values) && !blank(values[[f$id]]) && !is.null(f$path), fields)
  assumption <- function(f) {
    value <- as.character(values[[f$id]])
    if (identical(f$type, "select")) value <- f$choices[[value]] %||% value
    paste0("- ", f$label, ": ", value)
  }
  units <- engine_function("sample_structure")(spec)
  text <- if (identical(spec$design, "precision")) precision_writeup(forms$forms[[id]], spec, result, fields, values) else
    writeup_text(forms$forms[[id]], spec, result, fields, values,
      departures = departures_for(forms, id, spec),
      known_methods = vapply(known_difference_keys(forms, id, spec), function(k) forms$known_differences_methods[[k]], ""),
      known = known_differences_for(forms, id, spec))
  alternatives <- named_alternative_lines(values, fields)
  c("# Study planning decision document", "",
    "Planning draft for review. This file does not register a preregistration or guarantee the assumptions are correct.", "",
    "## Scientific question", if (blank(values$research_question)) "Not recorded." else values$research_question, "",
    "## Analysis and decision", tree$endpoints[[id]]$plain_name %||% tree$endpoints[[id]]$doc_name,
    decision_rule_text(spec),
    paste("Effect/source reasoning:", values$just_source %||% "Not recorded."),
    if (!blank(values$alternative_reason)) paste("One-sided decision reasoning:", values$alternative_reason), "",
    "## Assumptions and sources", "Entered values below are planning assumptions unless their source establishes otherwise. Defaults are not study-specific evidence.",
    vapply(active, assumption, ""), assumption_record_lines(values, fields), "",
    "## Sample units and recruitment", paste("N counts", units$unit, ".", units$note),
    paste("Allocation weights/ratio:", paste(unlist(spec$options$allocation_ratio %||% spec$options$cell_ratio %||% spec$options$group_ratio %||% "as specified by the design"), collapse = ", ")),
    planning_recruitment_lines(result, units), "",
    "## Alternatives considered", alternatives, "",
    "## Result and methods", unname(text["full"]), "",
    "## Evidence and provenance", provenance_lines(result), "",
    "Keep the matching project file for the complete structured specification, raw-to-derived conversions and machine-readable result. Review these assumptions and the selected decision rule before using the plan.")
}

planning_recruitment_lines <- function(result, units) {
  r <- result$recruitment
  if (!is.list(r)) return("No attrition inflation was requested. This does not establish that no observations will be lost.")
  c(sprintf("Analysed: %s %s. Recruitment target: %s %s.", r$n_analysed, units$unit, r$n_recruit, units$unit),
    if (length(r$groups_analysed) > 1) paste("Analysed counts in allocation order:", paste(r$groups_analysed, collapse = ", ")),
    if (length(r$groups_recruit) > 1) paste("Recruitment counts in allocation order:", paste(r$groups_recruit, collapse = ", ")),
    paste("Assumed loss proportion:", r$attrition, ". The adjustment applies to the counted units; partial-pair or other missing-data mechanisms are not simulated by this inflation."))
}

input_guide <- function(f) {
  if (!f$type %in% c("number", "numbers", "table")) return(NULL)
  key <- tolower(paste(f$id, f$label, f$path))
  guide <- if (grepl("alpha|significance level", key)) list(
    meaning = "The false-positive probability for the specified test under its null assumptions, not the probability that a significant finding is false.",
    example = "0.05 means a 5% long-run false-positive rate for this test under those assumptions.",
    source = "Use your planned decision rule, field requirements and consequences of the two kinds of error.") else if (identical(f$id, "power")) list(
    meaning = "The chance that the selected test succeeds under the population effect and model you specify. It is not the probability that your hypothesis is true.",
    example = "0.90 means about 90 in 100 repeated studies under those assumptions.", source = "Choose a target from the cost of missing an effect and the feasibility of recruitment.") else if (grepl("intraclass|icc", key)) list(
    meaning = "An intraclass correlation describes similarity within the stated grouping or reliability model; the grouping and ICC definition matter.",
    example = "An ICC of 0.10 can mean 10% of variance is between clusters in a random-intercept model.", source = "A comparable multilevel or reliability study, or a pilot fitted with the same model and grouping.") else if (grepl("reliability|rel_", key)) list(
    meaning = "Reliability describes how much of the variation is reproducible signal under the measurement model. It is distinct from the effect being tested.",
    example = "A reliability of 0.80 is entered as 0.80, not 80.", source = "Reliability evidence for the same instrument, population and scoring procedure.") else if (grepl("correlation|rho|(^| )r($| )", key)) list(
    meaning = "A correlation describes how two measurements vary together. Check whether this field asks for an ordinary, within-person, residual or latent correlation; these are not interchangeable.",
    example = "0.30 is a positive correlation; -0.30 is negative. A correlation matrix must also be jointly possible.", source = "A comparable dataset or paper's correlation matrix, matched to the variables and model in this field.") else if (grepl("r.squared|r-squared|r2|explained variance", key)) list(
    meaning = "R-squared is a share of outcome variance explained by a specified model. An increase compares two models and is distinct from total R-squared.",
    example = "0.20 means 20% of the outcome variance; a change from 0.20 to 0.25 is an increase of 0.05.", source = "A comparable model fitted to data, with the same outcome and predictor sets.") else if (grepl("variance|(^| )var[012]?($| )", key) && !grepl("covariance", key)) list(
    meaning = "Variance measures spread in squared outcome units. It is the square of the standard deviation (SD), not another name for the SD.",
    example = "An SD of 10 corresponds to variance 100.", source = "A paper's variance estimate, or square the SD from the same measure and population.") else if (grepl("standard deviation|(^|[ ._])sd[012]?([ ._]|$)|sigma", key)) list(
    meaning = "A standard deviation (SD) describes spread in the stated measure's units. The SD of changes, residual SD and between-person SD describe different variation.",
    example = "For scores measured in points, an SD of 10 is also in points. If this field asks for a ratio, SDs 10 and 15 give a ratio of 1.5.", source = "A comparable sample's descriptive statistics or the relevant variance component from the same analysis model.") else if (grepl("attrition|lose|dropout", key)) list(
    meaning = "The proportion expected to be excluded from the analysed sample. Recruitment inflation does not simulate missing values or correct bias from missingness.",
    example = "0.10 means losing 10% of recruits.", source = "Retention in comparable studies, with the same follow-up period and eligibility rules.") else if (grepl("proportion|probability|prevalence", key)) list(
    meaning = "A proportion is the fraction with the specified event or category in the population. Check the reference group, time window and denominator.",
    example = "0.20 means 20%, or about 20 in 100; it is not entered as 20.", source = "Comparable event counts divided by the correct total, or a justified scenario range.") else if (grepl("path|coefficient", key)) list(
    meaning = "A regression/path coefficient describes change in an outcome for a unit change in its predictor, holding the other model terms fixed. Use the raw or standardised units specified here; it is not generally the zero-order correlation.",
    example = "A standardised coefficient of 0.20 means 0.20 outcome SDs per predictor SD, conditional on the other terms in that model.", source = "The same regression/path model fitted to comparable data. Separate component paths are needed for mediation; the product alone is insufficient.") else if (grepl("allocation|relative.*size|group.*ratio|cell.*ratio", key)) list(
    meaning = "Allocation weights describe the relative numbers in the listed groups or cells, in their displayed order.",
    example = "Weights 1 and 2 allocate twice as many people to the second group. Whole-number constraints can change the final total.", source = "Your recruitment plan, treatment capacity or available populations.") else if (identical(f$type, "table")) list(
    meaning = "This table specifies the population or model in the row/column order stated above. Keep variable ordering consistent across means, spreads and correlations.",
    example = "A correlation table has 1 on its diagonal; a means table uses the outcome's units. Use only the kind of table requested here.", source = "A comparable dataset/model or the paper's full parameter table, with variable definitions and units.") else NULL
  if (is.null(guide)) return(NULL)
  guide$unknown <- "If you don't know it, keep the draft unfinished, look for a defensible source, or compare clearly labelled assumptions. Do not replace an unknown value with 0 or a conventional 'small/medium/large' number just to continue. A default is not evidence for your population."
  guide
}

input_guide_ui <- function(f) {
  guide <- input_guide(f)
  if (is.null(guide)) return(NULL)
  tags$details(class = "input-guide small", tags$summary("What this means and where to find it"),
    tags$dl(tags$dt("Meaning"), tags$dd(guide$meaning), tags$dt("Illustration, not a recommended value"), tags$dd(guide$example),
      tags$dt("Where to look"), tags$dd(guide$source), tags$dt("If unknown"), tags$dd(guide$unknown)))
}
