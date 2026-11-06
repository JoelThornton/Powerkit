planning_decision_ui <- function(form) {
  design <- form$base$design
  current <- if (isTRUE(form$precision))
    "This screen plans the width of an interval, rather than the chance of rejecting a null hypothesis. Expected width is an average; assurance, where offered, specifies a chance of meeting the width target." else
    if (identical(design, "equivalence_test"))
      "This screen plans evidence relative to your equivalence or non-inferiority bounds. A non-significant ordinary test is not evidence of equivalence." else
    if (identical(design, "sem"))
      "Check whether you selected overall model fit or a particular factor correlation/path. Power to detect poor overall fit is not power for a particular path, and the assumed model matters." else
      "This plans the chance that your test gives a significant result if the effect you enter is the true one. Powering a study for the smallest effect that would matter does not test that the effect is at least that big: a minimum-effect test does that."
  div(class = "planning-decision small",
    tags$strong("Check this answers your question. "), current,
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
  units <- sample_description(spec)
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
  specialist <- f$id %in% c("ncp", "df", "df1", "df2", "d", "dz", "ni_d", "ni_dz", "w", "eta_squared",
    "bound", "raw_bound", "margin", "raw_margin", "ni_margin", "evidence_threshold", "width", "conf_level", "assurance",
    "w_from", "w_to", "weights", "scores", "retention", "d1", "d2", "criterion", "trials_signal", "trials_noise", "sd_dprime", "dispersion", "zero_prob", "base_rate", "slope_difference", "difference", "mean_difference",
    "raw_mean", "raw_mean_1", "raw_mean_2", "raw_test_value", "mu0", "means", "m11", "m12", "m21", "m22") ||
    grepl("^(odds_ratio|zero_odds_ratio|rate_ratio|hazard_ratio|prior_|conv_|irt_|meta_effect|fc_loading)", f$id)
  specific <- if (specialist) additional_input_guide(f) else NULL
  guide <- if (!is.null(specific)) specific else if (identical(f$path, "target_test.alpha") || grepl("significance level", key) || (identical(f$id, "alpha") && is.null(f$path))) list(
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
    example = "An SD of 10 corresponds to variance 100.", source = "A paper's variance estimate, or square the SD from the same measure and population.") else if (identical(f$id, "sds") || grepl("standard deviation|(^|[ ._])sd[012]?([ ._]|$)|sigma", key)) list(
    meaning = "A standard deviation (SD) describes spread in the stated measure's units. The SD of changes, residual SD and between-person SD describe different variation.",
    example = "For scores measured in points, an SD of 10 is also in points. If this field asks for a ratio, SDs 10 and 15 give a ratio of 1.5.", source = "A comparable sample's descriptive statistics or the relevant variance component from the same analysis model.") else if (grepl("dprime|d'|response bias|criterion c", key)) list(
    meaning = "A signal detection quantity: d' is sensitivity, how far apart the signal and noise distributions are in SD units (0 is chance); the criterion c is the response bias (0 none, positive a tendency to say no).",
    example = "d' of 1 means about 69% correct when signal and noise trials are equally common and there is no bias; d' of 2, about 84%.", source = "Earlier studies of the same task and trial numbers, reporting d' (and c) per condition.") else if (grepl("retention|still in the study", key)) list(
    meaning = "For each occasion, the share of the people who started that is still being measured; it starts at 1 and never rises. People who leave keep their earlier measurements in the analysis, unlike recruitment inflation.",
    example = "1, 0.9, 0.8 means everyone at the first occasion, 90% at the second and 80% at the third.", source = "Retention at each wave in comparable longitudinal studies with the same schedule and population.") else if (grepl("attrition|lose|dropout", key)) list(
    meaning = "The proportion expected to be excluded from the analysed sample. Recruitment inflation does not simulate missing values or correct bias from missingness.",
    example = "0.10 means losing 10% of recruits.", source = "Retention in comparable studies, with the same follow-up period and eligibility rules.") else if (grepl("proportion|probability|prevalence", key)) list(
    meaning = "A proportion is the fraction with the specified event or category in the population. Check the reference group, time window and denominator.",
    example = "0.20 means 20%, or about 20 in 100; it is not entered as 20.", source = "Comparable event counts divided by the correct total, or a justified scenario range.") else if (grepl("path|coefficient", key)) list(
    meaning = "A regression/path coefficient describes change in an outcome for a unit change in its predictor, holding the other model terms fixed. Use the raw or standardised units specified here; it is not generally the zero-order correlation.",
    example = "For a continuous score predictor standardised to SD 1, a coefficient of 0.20 represents 0.20 outcome SDs per predictor SD. Binary and interaction terms need the model's stated coding/scaling; do not assume every term is per predictor SD.", source = "The same regression/path model fitted to comparable data. Separate component paths are needed for mediation; the product alone is insufficient.") else if (grepl("allocation|relative.*size|group.*ratio|cell.*ratio", key)) list(
    meaning = "Allocation weights describe the relative numbers in the listed groups or cells, in their displayed order.",
    example = "Weights 1 and 2 allocate twice as many people to the second group. Whole-number constraints can change the final total.", source = "Your recruitment plan, treatment capacity or available populations.") else if (identical(f$type, "table")) list(
    meaning = "This table specifies the population or model in the row/column order stated above. Keep variable ordering consistent across means, spreads and correlations.",
    example = "A correlation table has 1 on its diagonal; a means table uses the outcome's units. Use only the kind of table requested here.", source = "A comparable dataset/model or the paper's full parameter table, with variable definitions and units.") else NULL
  if (is.null(guide)) guide <- additional_input_guide(f)
  if (is.null(guide)) return(NULL)
  guide$unknown <- guide$unknown %||% "If you don't know it, keep the draft unfinished, look for a defensible source, or compare clearly labelled assumptions. Do not replace an unknown value with 0 or a conventional 'small/medium/large' number just to continue. A default is not evidence for your population."
  guide
}

# Specialized fields use their existing, model-specific help where present.
# Illustrations explain units and notation; they never populate an input.
additional_input_guide <- function(f) {
  key <- tolower(paste(f$id, f$label, f$path))
  make <- function(meaning, example, source, unknown = NULL) list(
    meaning = f$help %||% meaning, example = example, source = source, unknown = unknown)
  if (identical(f$id, "retention")) return(make("Cumulative shares still observed at each occasion, in the stated time order, not separate dropout percentages. The first is 1 and later shares cannot increase.",
    "1, 0.9, 0.8 means everyone starts, 90% remain at the second occasion and 80% at the third.", "Retention schedules from comparable longitudinal studies or a defensible protocol scenario. This does not identify a non-random missingness mechanism."))
  if (f$id %in% c("d1", "d2")) return(make("Average true signal-detection sensitivity d-prime in the named condition. This is distinct from Cohen's d for a difference between participant scores and from response bias.",
    "Sensitivities 0.8 and 1.1 differ by 0.3 d-prime units; that is not automatically Cohen's d = 0.3 for the planned t-test.", "Comparable signal-detection results from the same task, with trial counts, bias and measurement variability considered; magnitude labels are task-dependent."))
  if (identical(f$id, "criterion")) return(make("The signal-detection response criterion c. It describes response bias separately from sensitivity: positive values favour saying no under this parameterisation.",
    "c = 0 represents the unbiased-observer scenario; it is not evidence that your participants have no bias.", "A matched signal-detection fit or justified bias scenario, using criterion c rather than an unconverted alternative bias index."))
  if (f$id %in% c("trials_signal", "trials_noise")) return(make("The number of that kind of trial each person completes in each condition; this is not the number of participants.",
    "40 signal and 60 noise trials means 100 trials per condition per person, rather than N = 100 people.", "Your task protocol and feasible testing duration, with enough trials to estimate individual performance."))
  if (identical(f$id, "sd_dprime")) return(make("Between-person spread of true sensitivity, separate from estimation noise caused by finite trial counts.",
    "An observed SD of estimated d-prime from a short task cannot simply be treated as a noise-free SD of true sensitivity.", "A comparable model that separates individual variation from trial noise, or explicitly labelled assumptions when that information is unavailable."))
  if (identical(f$id, "guess")) return(make("Your optional guess for the teaching comparison; it does not enter the power calculation.",
    "A guess of 100 is compared with the calculated answer, in the unit requested.", "Your intuition; no empirical source is required.", "Leave it blank if you do not want to guess."))
  if (identical(f$id, "seed")) return(make("A fixed random-number starting point lets a simulation be repeated; it is not a study assumption or an effect size.",
    "Seed 123 is a possible identifier, not a recommended scientific value.", "Keep the recorded software setting with the result.", "You can leave the existing seed unchanged; you do not need a number from a paper."))
  if (f$id %in% c("nrep", "ci_draws")) return(make(
    if (f$id == "nrep") "The number of repeated studies at each sample size." else "The number of draws used to approximate an interval inside each repeated study; distinct from the number of repeated studies.",
    "1,000 repeated studies and 1,000 draws per interval describe different parts of a simulation.", "The analysis method and desired numerical stability, rather than a population estimate.", "Use an accuracy preset or retain the documented default. More draws cost time and do not establish that the population assumptions are right."))
  if (grepl("(^|[ .])r_|(^|[ .])c_|(^|[ .])rc_", key)) return(make(
    "A correlation for the named pair; check whether ordinary, residual, within-person or latent correlations are requested.",
    "0.30 is positive association, -0.30 negative; these are proportions, not percentages.", "A matched correlation matrix or fitted model for the same variables and population."))
  if (grepl("degrees of freedom|(^|[ ._])df[12]?([ ._]|$)", key)) return(make(
    "A parameter of the test statistic's reference distribution, determined by the design/model; it is not generally the participant count.",
    "For F(2, 97), numerator df is 2 and denominator df is 97. A t(58) has 58 df.", "The same published test's output, or the planned model's software output; SEM df come from the model specification."))
  if (identical(f$id, "ncp")) return(make("The noncentrality parameter describes the selected statistic's distribution under the alternative. Your design, effect and sample size determine it; it is not an observed t or F value.",
    "A generic t example can specify noncentrality 2.5 and 30 df; this does not mean copying an observed t = 2.5.", "A derivation for your exact model or its power-method documentation. If you have no derivation, use a design-specific card or ask a statistical colleague."))
  if (identical(f$id, "conv_value")) return(make("Copy the value of the published statistic/effect selected in the conversion menu, with its matching sample sizes and df; a p-value is a different quantity.",
    "When converting t(58) = 2.1, enter t = 2.1 and df = 58, not the p-value.", "The results table or analysis output for that same test. Do not combine df or N from another analysis."))
  if (grepl("evidence_threshold|bayes factor.*reach", key)) return(make("The evidence threshold for the stated Bayes factor, under its models and priors; not a significance level or the probability a hypothesis is true.",
    "A Bayes factor of 10 favours the numerator model over the denominator; an inclusion factor compares the selected sets of models with/without an effect.", "Your planned evidence rule, together with the exact analysis prior and model-comparison convention."))
  if (grepl("prior_scale|prior_concentration|prior_[ab]([ .]|$)", key)) return(make("A parameter of the analysis prior used by the selected Bayes factor. Its family and parameterisation matter; it is separate from the population effect.",
    if (f$id %in% c("prior_a", "prior_b", "prior_concentration")) "Beta(1, 1) is uniform over a proportion; other a and b values describe different priors." else "A Cauchy scale of 1 is wider than 0.5; this does not double the assumed true effect.", "The prior in your analysis protocol and the selected package's documented parameterisation."))
  if (f$id %in% c("cost_ratio", "prior_odds", "sg_protection")) return(make("A planning decision/protection setting, rather than a descriptive effect estimate. Use the specific definition above.",
    if (f$id == "cost_ratio") "4 means treating a false positive as four times as costly as a miss." else if (f$id == "prior_odds") "Prior odds of 1 describe equal prior odds, not a known population effect." else "Protection 0.80 uses the lower end of a 60% interval in this safeguard method.", "An explicit decision rationale or the stated safeguard method; compare alternatives if uncertain."))
  if (grepl("bound|margin", key)) return(make("A substantively justified decision boundary, distinct from the effect you expect. Equivalence, non-inferiority and minimum-effect tests use boundaries differently.",
    "For a minimum-effect plan, an expected d of 0.5 and a threshold of 0.2 are separate inputs. A symmetric equivalence bound of 0.2 denotes limits -0.2 and 0.2.", "The smallest change that would matter in this setting, justified in measure units or the stated effect-size units."))
  if (f$id %in% c("d", "dz", "ni_d", "ni_dz", "w", "eta_squared")) return(make(
    if (f$id == "w") "Cohen's w is an effect size for a population pattern of categorical probabilities, not a raw proportion." else if (f$id == "eta_squared") "Partial eta-squared uses an effect and its error sums of squares; ordinary eta-squared uses total sums of squares. Match the requested definition." else "A standardised mean difference in this screen's stated SD units. d_z uses the SD of within-person differences; other denominators are not interchangeable.",
    if (f$id %in% c("w", "eta_squared")) "0.10 is an illustrative effect-size input, not a recommendation to call your effect small or to assume that value." else "A difference of 0.30 means 0.30 of the SD unit defined by this screen; raw means/SDs are safer when a paper uses another denominator.", "Comparable data with the same effect-size definition, a synthesis, or a justified meaningful difference; do not select a conventional value merely to proceed."))
  if (identical(f$id, "dispersion")) return(make("The overdispersion parameter in the specific negative-binomial definition above; it is not the raw variance or SD and some software reports its inverse.",
    "Do not copy a fitted theta into this k field unchanged: the existing field help states the conversion used by this model.", "A matched negative-binomial fit or comparable count data, using the stated parameterisation and exposure units."))
  if (identical(f$id, "zero_prob")) return(make("The population share in the structural extra-zero component, distinct from all observed zeros; the count component can also produce zeros.",
    "30% observed zero counts does not by itself establish 30% structural zeros.", "A comparable fitted zero-inflated model or a defensible structural scenario; do not substitute the raw fraction of observed zeros."))
  if (grepl("odds.ratio|hazard.ratio|rate.ratio", key)) return(make("A multiplicative contrast for the quantity named here. Odds, event rates, hazards and probabilities are different quantities.",
    if (grepl("hazard", key)) "A hazard ratio of 2 doubles the modelled instantaneous hazard, not necessarily the cumulative event probability." else if (grepl("rate.ratio", key)) "A rate ratio of 2 doubles the event rate under the model; it is not necessarily a risk ratio." else "An odds ratio of 2 means double the odds, not necessarily double the probability; a ratio of 1 is no change.", "The matching logistic, count or survival model, with the same reference group, predictor units and adjustment set."))
  if (grepl("irt_a|irt_b|b_shift|a_change|dif_items", key)) return(make("An item-response parameter or item index in the stated 2PL parameterisation. Keep reference/focal groups, ability scale and item order consistent.",
    if (f$id == "irt_a") "Discriminations 1, 1.2, 0.8 give one slope for each of three items." else if (f$id == "irt_b") "Difficulties -0.5, 0, 1 are in the reference ability scale; larger b means a harder item at the same ability." else if (f$id == "dif_items") "1, 3 selects the first and third items, not their parameter values." else if (f$id == "a_change") "Discriminations 1.2 in the focal group and 1.0 in the reference group give a change of 0.2." else "Difficulties 0.7 in the focal group and 0.3 in the reference group give a shift of 0.4.", "A matched item calibration or published parameter table, using the same metric and anchoring conventions."))
  if (grepl("loading|intercept_difference|rmsea|i.squared|i2|quantile", key) || f$id %in% c("kappa", "kappa_null")) return(make(
    if (grepl("loading", key)) "A factor loading describes the relationship of an item to its latent factor; standardised loadings are not ordinary item means or reliabilities." else if (grepl("rmsea", key)) "A population model-fit quantity for the selected SEM test; it does not describe power for a particular path." else if (grepl("kappa", key)) "Agreement beyond the selected chance-agreement model, affected by the rating design and category distribution; not raw percent agreement." else if (grepl("quantile", key)) "The part of the outcome distribution your quantile regression targets, rather than necessarily its mean." else "The model-specific shift or heterogeneity quantity named above; retain its stated standardised units or proportion scale.",
    if (grepl("loading", key)) "A standardised loading of 0.7 is an illustrative item-factor relationship, not a universal recommended loading." else if (grepl("rmsea", key)) "RMSEA 0 represents exact population fit; positive values represent misfit, whose importance needs substantive justification." else if (grepl("quantile", key)) "0.5 is the median; 0.75 is the 75th percentile." else if (grepl("i2", key)) "I-squared of 0.50 is entered as 0.50, not 50." else if (grepl("kappa", key)) "Kappa 0.60 is entered as 0.60, not 60; it is not necessarily 60% raw agreement." else "An intercept shift of 0.3 is in the item SD units named in this field.", "A comparable fitted model or agreement/meta-analysis study, matched to the factor, rating or effect-size definition."))
  if (identical(f$id, "slope_difference")) return(make("The difference between groups' average rates of change, per unit of time in the outcome's units; not a difference at one occasion.",
    "A value of -1 can mean the outcome falls one point more per month in group 2 than group 1, when all times are in months.", "A comparable longitudinal model or a justified clinically/substantively important difference in change rates."))
  if (identical(f$id, "base_rate")) return(make("The starting expected event count per unit of exposure/time, at the predictor/reference value stated above; not an event probability.",
    "A starting rate of 2 events per month is entered as 2 when the time unit is a month, not as a 20% probability.", "Comparable event counts and exposure/person-time using the same time unit, population and reference condition."))
  if (grepl("actor|partner|moderation|(^|[ .])w_y|standardised slope", key)) return(make("A conditional regression/path effect in the model described above. Actor, partner and moderator effects are distinct; use the stated raw or standardised units.",
    "For a continuous score predictor standardised to SD 1, a main-effect slope of 0.20 means 0.20 outcome SDs per predictor SD, conditional on the other terms. Interaction terms require their stated product/coding convention.", "A matched regression/path model and substantive hypothesis, including the component paths and interactions."))
  if (grepl("width|conf_level|assurance", key)) return(make("An interval-planning target. Width, confidence level and assurance of reaching a width are different quantities.",
    if (f$id == "width") "Intervals [-0.2, 0.2] and [0.2, 0.6] are both 0.4 wide; actual interval width can vary across studies." else if (f$id == "assurance") "Assurance 0.80 targets an 80% chance of meeting the width under the specified population; average width alone does not set this chance." else "Confidence level 0.95 describes the procedure's long-run coverage under its assumptions, not a posterior probability for this fixed parameter.", "Your desired estimation precision and coverage/assurance rule, together with the selected interval method."))
  if (grepl("w_from|w_to|weights|^scores[ .]", key)) return(make("The requested moderator values, contrast weights or trend scores define the comparison. Their order and spacing can change the hypothesis.",
    if (f$id %in% c("w_from", "w_to")) "Moderator values -1 and 1 are two SDs apart when this screen standardises W." else if (f$id == "weights") "Weights -2, 1, 1 compare the first group with the average of the next two, in that group order." else "Doses 0, 10, 20, 40 are not equally spaced; use the actual scale if the trend test depends on it.", "The prespecified comparison or actual moderator/dose scale; do not choose weights after seeing the result."))
  if (grepl("meta_effect", key)) return(make("The average effect across the stated studies or study categories, in the selected metric. A standardised mean difference and a correlation are different measures.",
    "Values 0.2 and 0.5 describe two assumed average effects in the chosen metric; do not mix d and r in the same list.", "A comparable synthesis, or a justified target average effect with explicit assumptions about publication bias and heterogeneity."))
  if (grepl("mean|mu0|raw_test_value", key)) return(make("The population mean or mean difference named here, in the units selected above. Use adjusted means if requested; an individual score and a standard error are different quantities.",
    "In raw score units, expected means 20 and 24 differ by 4 points. Standardised inputs must use the stated SD definition instead.", "Comparable descriptive/model results or a justified meaningful difference; a fixed comparison value may come from a norm or decision benchmark."))
  if (grepl("probabilit|_prob([ .]|$)|share of", key)) return(make("A population share for the group/category named above, with the stated denominator and ordering.",
    "0.30 means 30%; a vector of category shares must satisfy this screen's sum and ordering rules.", "Comparable category counts, a sampling/recruitment plan or an explicit population scenario."))
  if (grepl("lr_time|accrual|follow_up", key)) return(make("A duration for the recruitment/follow-up design, in the same time unit as every other duration on this screen.",
    "Use 12 throughout for twelve months; do not mix a value in years with other fields in months.", "The study schedule and comparable event/follow-up information, with the same time origin."))
  if (grepl("number|how many|items|participants|people|pairs|predictors|covariates|groups|occasions|tested|study_size|effects_per_study|conv_n[12]", key)) return(make("A count of the units or model components named in this field. Analysed participants, pairs, items, studies and model terms are not interchangeable.",
    "40 pairs means 40 pairs, not 40 individual people. For a tested-term index, 1 denotes the first term in the stated order.", "The study protocol, sampling frame, model specification or the same earlier study's reported count."))
  return(NULL)
}

input_guide_ui <- function(f) {
  guide <- input_guide(f)
  if (is.null(guide)) return(NULL)
  tags$details(class = "input-guide small", tags$summary("What this means and where to find it", `aria-label` = paste("Help for", f$label)),
    tags$dl(tags$dt("Meaning"), tags$dd(guide$meaning), tags$dt("Illustration, not a recommended value"), tags$dd(guide$example),
      tags$dt("Where to look"), tags$dd(guide$source), tags$dt("If unknown"), tags$dd(guide$unknown)))
}
