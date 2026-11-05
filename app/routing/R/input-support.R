# Route people to existing, supported translations; never impute an input.
input_support_ui <- function(form, fields) {
  ids <- vapply(fields, `[[`, "", "id")
  has <- function(id) id %in% ids
  tags$details(class = "input-support mb-3",
    tags$summary("I have published results, raw scores, or missing information"),
    if (has("metric") || has("effect_units")) p("For means and SDs in the original measure, choose the raw-score option in the effect/units selector below. Use SDs, not standard errors or variances. Keep means and SDs in the same measure units."),
    if (has("conv_from")) p("For a published t, F or another effect size, use â€˜Is your effect size published in another form?â€™ below. Only the conversions supported by this analysis are offered. Use the original study's degrees of freedom and group sizes, not your planned sample size. An F statistic loses the direction of an effect; check the original contrast before choosing a one-sided decision."),
    if (has("eta_source")) p("A published repeated-measures effect and an effect derived from population means use different conventions. Select the source that matches your information; do not copy partial eta-squared from a different design."),
    if (has("raw_r") && identical(form$base$template, "paired_t")) p("For paired scores, the correlation must describe the two measurements on the same people. Marginal means and SDs alone do not identify the SD of changes. If you have the SD of changes, use the change-score option; otherwise save a draft or compare explicitly labelled correlation assumptions."),
    if (any(grepl("^(p_|r_)", ids))) p("Regression and mediation need the stated model's component coefficients and correlations. A total indirect effect, an unadjusted correlation, or a p-value alone does not identify the full population. Keep raw versus standardised units and binary-variable coding consistent."),
    p("If an input is missing, open its â€˜What this means and where to find itâ€™ help. You can record it as unknown under assumptions/sources and save an unfinished draft. Named alternatives can compare defensible assumptions; they do not establish which assumption is true."),
    if (has("just_type") && has("goal") && isTRUE(form$base$design == "basic_test")) p("If you cannot justify an effect but know your available sample size, choose the smallest effect you could detect under â€˜Your goalâ€™. This describes sensitivity at that budget; it does not choose a meaningful effect for you."),
    p("An unsupported published summary cannot always be converted uniquely. Keep the draft and seek the matching model output or data. Do not put zero, a conventional â€˜mediumâ€™ effect, or a package default in a box simply to obtain an answer."))
}
