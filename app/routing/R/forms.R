# Input screens for the end points powerkit runs (forms.yaml).
#
# A screen collects the values on a card's "What you would enter" list,
# builds a design spec and checks it with the engine's validate_spec().
# Nothing is calculated: the prototype only shows the checked spec.
#
# Functions here are pure (no Shiny state), so the tests can call them
# directly. The engine is loaded read-only, on first use.

load_forms <- function(path = "forms.yaml") yaml::read_yaml(path)

has_form <- function(forms, ep_id) !is.null(forms$forms[[ep_id]])

# Number of mediators offered. Two is the validated case. Parallel
# mediation stays at two until three or more are validated (open question
# 10, decided 22 October 2026: setting parallel_mediators_max, `two`);
# serial mediation offers up to four.
mediator_choices <- 2:4
mediator_choices_for <- function(kind) if (identical(kind, "parallel")) 2L else mediator_choices

# Mediator roles for k mediators.
mediator_roles <- function(k) paste0("M", seq_len(k))

# Indirect paths a hypothesis can be about.
indirect_path_choices <- function(kind, k) {
  ms <- mediator_roles(k)
  if (identical(kind, "parallel")) return(paste0("X->", ms, "->Y"))
  # Serial: every ordered, non-empty subset of the mediators.
  subsets <- unlist(lapply(seq_len(k), function(size) {
    combos <- utils::combn(ms, size, simplify = FALSE)
    vapply(combos, paste, character(1), collapse = "->")
  }))
  paste0("X->", subsets, "->Y")
}

path_field <- function(from, to, label = NULL, optional = FALSE) {
  list(
    id = paste0("p_", gsub("[^A-Za-z0-9]", "", from), "_", gsub("[^A-Za-z0-9]", "", to)),
    label = label %||% sprintf("Path %s -> %s", from, to),
    type = "number", path = sprintf("population.paths.%s->%s", from, to),
    effect = TRUE
  )
}

# Fields for a generated group (mediation with k mediators).
generated_fields <- function(kind, generator, k) {
  ms <- mediator_roles(k)
  switch(
    generator,
    parallel_paths = c(
      unlist(lapply(ms, function(m) list(path_field("X", m), path_field(m, "Y"))), recursive = FALSE),
      list(path_field("X", "Y", "Path X -> Y (direct)"))
    ),
    serial_paths = {
      nodes <- c("X", ms)
      fields <- list()
      for (i in seq_along(ms)) {
        for (from in nodes[seq_len(i)]) fields <- c(fields, list(path_field(from, ms[i])))
      }
      c(fields, lapply(ms, function(m) path_field(m, "Y")), list(path_field("X", "Y", "Path X -> Y (direct)")))
    },
    residual_correlations = {
      pairs <- utils::combn(ms, 2, simplify = FALSE)
      lapply(pairs, function(p) list(
        id = paste0("rc_", p[1], "_", p[2]),
        label = sprintf("Residual correlation of %s with %s (optional; empty = 0)", p[1], p[2]),
        type = "number", path = sprintf("population.residual_correlations.%s<->%s", p[1], p[2]),
        optional = TRUE, min = -1, max = 1
      ))
    },
    target_path = {
      choices <- indirect_path_choices(kind, k)
      list(list(
        id = "target_path", label = "Indirect path", type = "select", path = "target_test.path",
        required = TRUE, choices = stats::setNames(as.list(choices), choices)
      ))
    }
  )
}

# The names group, for forms whose card doesn't list variable names.
names_group <- function(form, k) {
  roles <- unlist(form$names)
  if (!is.null(form$mediators)) roles <- c("X", mediator_roles(k), "Y")
  describe <- c(X = "X (the cause or predictor)", W = "W (the moderator)", M = "M (the mediator)", Y = "Y (the outcome)")
  list(
    input = NULL, title = "What you call each variable",
    fields = lapply(roles, function(role) list(
      id = paste0(role, "_label"),
      label = if (role %in% names(describe)) describe[[role]] else sprintf("%s (mediator %s)", role, sub("M", "", role)),
      type = "text", path = sprintf("variables.%s.label", role), required = TRUE
    ))
  )
}

# The groups of fields a form shows, with generated groups expanded.
# `k` is the number of mediators (parallel and serial mediation only).
# `start`: the answers to screen A (situation, aim, claim), which set the
# goal's starting choice and add the claim's questions.
form_groups <- function(forms, ep_id, k = 2, start = list()) {
  form <- forms$forms[[ep_id]]
  # A number of mediators not offered (e.g. from an older project file) is
  # brought within range.
  if (!is.null(form$mediators)) k <- min(max(k, 2L), max(mediator_choices_for(form$mediators)))
  groups <- lapply(form$groups, function(g) {
    if (!is.null(g$generated)) g$fields <- generated_fields(form$mediators, g$generated, k)
    # The basic tests need no effect size for the smallest detectable
    # effect: the engine solves for it (an empty value counts as zero, or
    # as the field's `when_empty`, and the result is positive). A
    # `baseline` field (group 1's proportion) is still needed.
    if (isTRUE(form$sensitivity_without_effect)) {
      has_effect <- any(vapply(g$fields, function(f) isTRUE(f$effect), logical(1)))
      g$fields <- lapply(g$fields, function(f) {
        if (isTRUE(f$effect) && !isTRUE(f$baseline)) f$optional_for <- c("sensitivity", "sensitivity_curve")
        f
      })
      if (has_effect) g$note <- form$sensitivity_note %||% "For the smallest effect you could detect, this can stay empty if you have no estimate; a negative value sets the direction."
    }
    g
  })
  if (!is.null(form$mediators)) {
    groups <- c(list(list(input = NULL, title = "How many mediators", fields = list(list(
      id = "n_mediators", label = "Number of mediators", type = "select", required = TRUE,
      choices = stats::setNames(as.list(as.character(mediator_choices_for(form$mediators))), mediator_choices_for(form$mediators)),
      default = "2", default_source = if (identical(form$mediators, "parallel"))
        "two, the number powerkit has validated for parallel mediation; more will be offered once checked"
      else "the number powerkit has validated (two)"
    )))), groups)
  }
  if (!is.null(form$names) || !is.null(form$mediators)) groups <- c(list(names_group(form, k)), groups)
  # A generic test asks for the direction after the test type, since only
  # t and z tests have one.
  if (isTRUE(form$directional)) {
    direction <- direction_group(forms$tool_defaults[[form$tool]], form$direction_shown_if)
    groups <- if (isTRUE(form$generic)) c(groups, list(direction)) else c(list(direction), groups)
  }
  if (!is.null(form$extra)) groups <- c(groups, list(list(input = NULL, title = "How power is worked out", fields = form$extra)))
  # method_extra: further choices about the formula, shown with the method
  # (E5's z test or Cohen's h).
  if (isTRUE(form$basic_method)) groups <- c(groups, list(list(input = NULL, title = "How power is worked out", fields = c(list(basic_method_field(forms, ep_id)), form$method_extra))))
  c(groups, closing_groups(forms, ep_id, start))
}

# The direction, asked first and not filled in: the choice of a one- or
# two-sided test should follow from the hypothesis (Rubin, 2022), not from
# a pre-filled default. The packages' default is still named.
direction_group <- function(tool, shown_if = NULL) {
  list(input = NULL, title = "Your hypothesis", note = direction_note, fields = list(
    list(
      id = "alternative", label = "Does your hypothesis predict a direction?", type = "select", path = "target_test.alternative", required = TRUE,
      choices = list(
        greater = "Yes: it predicts a positive effect (one-sided test)",
        less = "Yes: it predicts a negative effect (one-sided test)",
        two_sided = "No: an effect in either direction would support it (two-sided test)"),
      default_source = paste0("Not filled in for you (for reference: ", tool[["alternative_source"]], ")"),
      shown_if = shown_if
    ),
    list(
      id = "alternative_reason", label = "Why your hypothesis predicts this direction", help = "Goes in the write-up; for example \"the theory predicts that training raises scores\".",
      type = "text", optional = TRUE, shown_if = if (is.null(shown_if)) list(field = "alternative", is_not = "two_sided") else c(list(list(field = "alternative", is_not = "two_sided")), shown_if)
    )
  ))
}

direction_note <- paste(
  "Answer this from your hypothesis, before the numbers.",
  "If it says which way the effect goes (for example, that training raises scores), a one-sided test in that direction fits it.",
  "If any difference would support it, a two-sided test fits; its p-value doesn't support a claim about which way the effect goes",
  "(Rubin, 2022, Significance)."
)

# E1-E6: pwr's formula or Spower's simulation (forms.yaml,
# basic_method_field). Where the form has a test version (`method`), the
# choice is shown only with its default version: Welch's t-test (E2) has no
# pwr formula, and Fisher's exact test (E5) is pwrss's formula only.
basic_method_field <- function(forms, ep_id) {
  field <- forms$basic_method_field
  version <- Filter(function(f) identical(f$id, "method"), form_fields(forms$forms[[ep_id]]$groups))
  if (length(version)) field$shown_if <- list(field = "method", is = version[[1]][["default"]])
  field
}

# The closing questions every form asks (decision-tree.md, table 2.2).
closing_groups <- function(forms, ep_id, start = list()) {
  form <- forms$forms[[ep_id]]
  tool <- forms$tool_defaults[[form$tool]]
  goals <- list(sample_size = "The sample size I need", power = "The power I'd have at a given sample size")
  # Generic tests have no sample size: the noncentrality reflects it.
  if (isTRUE(form$generic)) goals <- list(power = "The power for this noncentrality", sensitivity = "The noncentrality I'd need for a target power")
  if (isTRUE(form$sensitivity)) goals$sensitivity <- "The smallest effect I could detect at a given sample size"
  if (isTRUE(form$sensitivity_without_effect)) goals$sensitivity_curve <- "The smallest effect I could detect across a range of sample sizes"
  goal <- list(id = "goal", label = "What do you want to find out?", type = "select", path = "goal.type", required = TRUE, choices = goals)
  if (identical(start$situation, "fixed")) {
    goal$default <- if (isTRUE(form$sensitivity)) "sensitivity" else "power"
    goal$default_source <- "you said your sample size is fixed"
  }
  # Whether the sample size is fixed (asked on the start screen until 26
  # October 2026): with the goals that take a sample size, for the
  # write-up ("fixed by resource constraints").
  situation <- list(id = "situation", label = "Is this number of participants fixed?", type = "select",
    choices = list(choose = "No: I'm seeing what power a sample this size gives",
      fixed = "Yes: a participant pool, a budget or a rare group sets it"),
    default = if (identical(start$situation, "fixed")) "fixed" else "choose",
    shown_for_goals = c("power", "sensitivity"), optional = TRUE)
  test <- list(
    goal,
    list(id = "power", label = "Target power", help = "As a proportion, for example 0.9.",
         type = "number", path = "goal.power", needed_for = c("sample_size", "sensitivity"), min_exclusive = 0, max_exclusive = 1,
         default = tool[["power"]], default_source = tool[["power_source"]]),
    list(id = "power_reason", label = "Why this target power", help = "Goes in the write-up; for example \"95% because a miss would waste a year of recruitment\".",
         type = "text", optional = TRUE, shown_for_goals = c("sample_size", "sensitivity")),
    list(id = "n", label = "Number of participants analysed",
         type = "number", path = "goal.n", needed_for = c("power", "sensitivity"), min = 2, integer = TRUE),
    list(id = "n_max", label = "The largest number of participants you could analyse",
         type = "number", needed_for = "sensitivity_curve", min = 16, integer = TRUE),
    situation,
    list(id = "alpha", label = "Significance level (alpha)", type = "number", path = "target_test.alpha", required = TRUE,
         min_exclusive = 0, max = 0.5, default = tool[["alpha"]], default_source = tool[["alpha_source"]]),
    # Shown only when alpha is changed from its default (decided 18 October
    # 2026, judgement call G8); goes in the write-up.
    list(id = "alpha_reason", label = "Why this significance level", help = "Goes in the write-up; for example \"the claim is new, so stronger evidence is wanted\".",
         type = "text", optional = TRUE, shown_if = list(field = "alpha", is_not = as.character(tool[["alpha"]] %||% 0.05)))
  )
  if (isTRUE(form$generic)) test <- Filter(function(f) !f$id %in% c("n", "n_max"), test)
  Filter(Negate(is.null), c(list(
    list(input = NULL, title = "What you want to find out", fields = test)),
    claim_groups(start$claim, start$n_tests),
    list(
    list(input = NULL, title = "Where your effect size comes from", fields = c(list(
      list(id = "just_type", label = "Source of the effect size", type = "select", path = "effect_justification.type", required = TRUE,
           choices = c(list(
             smallest_effect_of_interest = "The smallest effect that would matter",
             meta_analysis = "A meta-analysis", prior_study = "A previous study", pilot_study = "A pilot study",
             own_study_result = "The result of my finished study (observed power)"),
             if (isTRUE(form$sensitivity_without_effect)) list(none = "I can't justify an effect size"))),
      list(id = "just_source", label = "Why this effect size? (needed to save or export the plan)",
           help = "In your own words: where the number comes from, or why there isn't one. Any length, any language. You can calculate without it.",
           type = "text", path = "effect_justification.source", optional = TRUE),
      list(id = "just_adjustment", label = "How you adjusted it", help = "Published effects tend to be too large; for example, halved for publication bias.",
           type = "text", path = "effect_justification.adjustment", needed_if_just = "prior_study",
           shown_if = list(list(field = "just_type", is = "prior_study"), list(field = "sg_use", is_not = "yes")))
    ), safeguard_fields(form$base$template))),
    if (!isTRUE(form$generic)) list(input = NULL, title = "Participants you expect to lose", fields = list(
      list(id = "attrition", label = "Proportion you expect to lose", help = "For example 0.1 for 10%.", type = "number",
           path = "options.attrition", optional = TRUE, min = 0, max_exclusive = 1)
    )),
    # A fixed default seed, so the same answers give the same result
    # (judgement-calls.md B15); the user can change it.
    list(input = NULL, title = "Random seed", fields = list(
      list(id = "seed", label = "Random seed", help = sprintf("A whole number, used when power is simulated, so the same seed gives the same result; empty = %s.", forms$default_seed),
           type = "number", path = "options.seed", optional = TRUE, integer = TRUE, min = 1, max = 2147483647,
           default = forms$default_seed, default_source = "powerkit's fixed default seed (judgement-calls.md B15)")
    )),
    # Guess first (optional teaching mode): the guess is shown next to the
    # answer and goes nowhere else (no spec path, not in the exports).
    list(input = NULL, title = "Guess first (optional)", note = guess_note, fields = list(
      list(id = "guess", label = "Your guess", type = "number", optional = TRUE, min = 0,
           shown_if = list(field = "goal", is_not = "sensitivity_curve"))
    ))
  )))
}

# Safeguard power (Perugini, Gallucci & Costantini, 2014): for an effect
# size from one earlier study, plan with the lower end of a confidence
# interval around it. The engine works the interval out (psych); the form
# asks for the earlier study's sample size and the protection wanted.
safeguard_sizes <- list(one_sample_t = "n", paired_t = "n", correlation = "n", independent_t = c("n1", "n2"))

safeguard_fields <- function(template) {
  sizes <- safeguard_sizes[[template %||% ""]]
  if (is.null(sizes)) return(list())
  from_one_study <- list(field = "just_type", is_one_of = c("prior_study", "pilot_study"))
  using <- list(from_one_study, list(field = "sg_use", is = "yes"))
  size_field <- function(id, label, min) list(id = paste0("sg_", id), label = label, type = "number", integer = TRUE, min = min,
    required = TRUE, path = paste0("effect_justification.safeguard.", id), shown_if = using)
  c(list(
    list(id = "sg_use", label = "Plan with the safeguard effect size?", type = "select", default = "no",
         help = paste("One study's estimate is uncertain, and may be too large. Safeguard power plans with the lower end of a",
                      "confidence interval around it instead, so the study is protected if the true effect is smaller (Perugini, Gallucci & Costantini, 2014).",
                      "Enter the earlier study's effect size above as it was reported."),
         choices = list(no = "No: plan with the effect size as it is", yes = "Yes: use the safeguard effect size"),
         shown_if = from_one_study)),
    if (identical(sizes, "n")) list(size_field("n", "How many people the earlier study had", 4))
    else list(size_field("n1", "People in group 1 of the earlier study", 2), size_field("n2", "People in group 2 of the earlier study", 2)),
    list(list(id = "sg_protection", label = "Protection against the estimate being too large", type = "number",
         help = "0.8 uses the lower end of a 60% confidence interval; 0.95 uses the lower end of a 90% one.",
         path = "effect_justification.safeguard.protection", required = TRUE, default = 0.8, min_exclusive = 0.5, max_exclusive = 1,
         default_source = "Perugini, Gallucci & Costantini (2014)", shown_if = using)))
}

guess_note <- paste(
  "Before you press \u201cCheck my answers\u201d, write down what you expect:",
  "the number of participants (for the sample size), the power as a percentage (for power),",
  "or the size of the smallest effect you could detect. Your guess is shown next to the answer;",
  "it isn't part of the plan, the R script or the write-up."
)

# The claim, on the input screen (on the start screen until 26 October
# 2026): one test unless the user says otherwise, with a note for each of
# the other claims, and the number of tests for "any of several" (which
# divides alpha between them: Bonferroni; docs/decisions.md, 18 October
# 2026) and for "all of several" (which raises each test's target power so
# that all succeed together with the target power; docs/decisions.md, 19
# October 2026). From a plan or an older project, it starts at the claim
# given then. It sits with the settings: most studies have one test.
claim_choices <- list(
  one = "One test: my conclusion rests on this test alone",
  each = "Several claims, each standing on its own",
  any = "Any of several tests: the claim holds if at least one is significant",
  all = "All of several tests: the claim needs every one to be significant"
)

claim_notes <- function() list(
  each = paste(
    "You said each test supports its own claim. Power this test on its own; run the input screen again for each of the others.",
    "No correction for several tests is needed, because no single conclusion rests on more than one test (Rubin, 2021).",
    philosophy_note
  ),
  any = "You said your claim is about the set: it is supported if any one of the tests is significant. So the chance of a false positive is spread over the set: powerkit divides your significance level by the number of tests (Bonferroni) and uses that for this test.",
  all = paste(
    "You said your claim needs every test to be significant. No correction to the significance level is needed, but the chance that all succeed is lower than any one test's power:",
    "two independent tests at 0.8 each succeed together only about 0.8 x 0.8 = 0.64 of the time.",
    "So powerkit raises this test's target power so that all the tests together reach your target power, if each test is planned the same way."
  )
)

claim_groups <- function(claim = "one", n_tests = NULL) {
  claim <- claim %||% "one"
  if (!claim %in% names(claim_choices)) claim <- "one"
  fields <- list(
    list(id = "claim", label = "Your claim: how many tests does your conclusion rest on?", type = "select",
         choices = claim_choices, default = claim, choice_notes = claim_notes()),
    list(id = "n_tests", label = "Number of tests", type = "number", required = TRUE, min = 2, integer = TRUE,
         default = n_tests, applies_if_claim = c("any", "all"),
         shown_if = list(list(field = "claim", is_not = "one"), list(field = "claim", is_not = "each")))
  )
  list(list(input = NULL, title = "Your claim", fields = fields))
}

# Whether separate claims need a correction depends on one's philosophy of
# significance testing (Rubin, 2024, Journal of Trial and Error; Mayo, 2018).
philosophy_note <- paste(
  "Not everyone agrees: whether to correct depends on your view of significance testing.",
  "Under the more common error-statistical view, a correction may be expected when the tests form a related group, such as several outcomes of the same treatment,",
  "especially if some of them could go unreported (Mayo, 2018, pp. 275\u2013276). Rubin (2024, Journal of Trial and Error) sets out the difference."
)

claim_tests <- function(values) {
  # One test, or claims standing on their own: no set of tests, whatever
  # number was typed before the claim was changed back.
  if (isTRUE(values$claim %in% c("one", "each"))) return(NA)
  k <- parse_number(values$n_tests)
  if (length(k) != 1 || is.na(k) || k < 2) NA else k
}

# One line for the result screen on how the claim was handled, or NULL.
# `goal`: the goal type; the target power was raised only for the sample
# size and the smallest detectable effect.
claim_result_note <- function(values, alpha_used, goal = NULL) {
  k <- claim_tests(values)
  switch(
    values$claim %||% "one",
    one = NULL,
    each = "Your claim: several claims, each standing on its own. This result is for one test, with no correction; work out each of the others the same way.",
    any = sprintf(
      "Your claim: any of %s tests. The significance level for this test is %s divided by %s (Bonferroni): %s.",
      values$n_tests, format(signif(alpha_used * as.numeric(values$n_tests), 3)), values$n_tests, format(signif(alpha_used, 3))
    ),
    all = if (!is.na(k) && isTRUE(goal %in% c("sample_size", "sensitivity"))) {
      target <- parse_number(values$power)
      sprintf(paste(
        "Your claim: all of %s tests. So that all of them succeed together with a chance of %s, this test is planned at %s^(1/%s) = %s power; plan each of the others at the same power.",
        "This assumes the tests are independent. Tests on the same people are usually positively related, which makes the chance a little higher, so this errs on the safe side.",
        "Another approach raises each test's significance level instead (a \"reverse Bonferroni\": Francis & Thunell, 2021); powerkit doesn't do that."),
        whole(k), format(target), format(target), whole(k), format(signif(claim_power(target, values), 3)))
    } else {
      "Your claim: all of several tests. The power shown is for this test alone. The chance that every test succeeds is about the product of their powers (for two tests at 0.8, about 0.64), or a little higher for related tests on the same people."
    }
  )
}

# Alpha for this test: the significance level entered, divided by the
# number of tests when the claim is "any of several".
claim_alpha <- function(alpha, values) {
  k <- claim_tests(values)
  if (identical(values$claim, "all") || is.na(k)) return(alpha)
  alpha / k
}

# Target power for this test: when the claim is "all of several", the
# k-th root of the target, so that k independent tests planned this way
# all succeed with the target power (power^k = target).
claim_power <- function(power, values) {
  k <- claim_tests(values)
  if (!identical(values$claim, "all") || is.na(k) || is.null(power)) return(power)
  power^(1 / k)
}

form_fields <- function(groups) unlist(lapply(groups, `[[`, "fields"), recursive = FALSE)

# --- Reading values ------------------------------------------------------------

blank <- function(x) is.null(x) || length(x) == 0 || all(is.na(x)) || identical(trimws(as.character(x[[1]])), "")

parse_number <- function(x) {
  if (blank(x)) return(NA_real_)
  x <- trimws(as.character(x))
  if (!grepl("^[-+]?([0-9]+\\.?[0-9]*|\\.[0-9]+)([eE][-+]?[0-9]+)?$", x)) return(NaN)
  as.numeric(x)
}

parse_levels <- function(x) {
  if (blank(x)) return(character())
  out <- trimws(strsplit(as.character(x), ",", fixed = TRUE)[[1]])
  out[nzchar(out)]
}

# Comma-separated numbers on one line (a one-way ANOVA's group means).
parse_numbers <- function(x) {
  if (blank(x)) return(numeric())
  vapply(trimws(strsplit(as.character(x), ",", fixed = TRUE)[[1]]), parse_number, numeric(1), USE.NAMES = FALSE)
}

parse_table <- function(x) {
  if (blank(x)) return(NULL)
  lines <- trimws(strsplit(as.character(x), "\n", fixed = TRUE)[[1]])
  lines <- lines[nzchar(lines)]
  lapply(lines, function(l) vapply(trimws(strsplit(l, ",", fixed = TRUE)[[1]]), parse_number, numeric(1), USE.NAMES = FALSE))
}

# Whether a field applies, given the goal, the justification and any other
# choice it depends on (`shown_if`: shown only when another field `is`, or
# `is_not`, a given value; an empty choice counts as no value; a list of
# such conditions must all hold).
field_applies <- function(field, values) {
  # The number of tests: only for a claim about a set (an empty claim is
  # one test).
  if (!is.null(field$applies_if_claim)) return(isTRUE(values$claim %in% field$applies_if_claim))
  for (cond in shown_if_conditions(field)) {
    current <- values[[cond$field]]
    current <- if (blank(current)) "" else as.character(current)
    if (!is.null(cond[["is"]]) && !identical(current, cond[["is"]])) return(FALSE)
    if (!is.null(cond[["is_not"]]) && identical(current, cond[["is_not"]])) return(FALSE)
    if (!is.null(cond[["is_one_of"]]) && !current %in% cond[["is_one_of"]]) return(FALSE)
  }
  if (!is.null(field$needed_for)) return(isTRUE(values$goal %in% field$needed_for))
  if (!is.null(field$shown_for_goals)) return(isTRUE(values$goal %in% field$shown_for_goals))
  if (!is.null(field$needed_if_just)) return(identical(values$just_type, field$needed_if_just))
  TRUE
}

# A field's `shown_if` as a list of conditions (one, or several that must
# all hold).
shown_if_conditions <- function(field) {
  if (is.null(field$shown_if)) return(list())
  if (!is.null(field$shown_if$field)) list(field$shown_if) else field$shown_if
}

quote_label <- function(field) sprintf("“%s”", field$label)

# Problems the screen can find before the engine sees the spec, in plain
# English, naming each field by its label.
form_problems <- function(fields, values) {
  problems <- character()
  # Each problem is named by its field's id, so the screen can show it next
  # to the field as well as in the list.
  add <- function(message) problems <<- c(problems, stats::setNames(message, f$id))
  for (f in fields) {
    if (!field_applies(f, values)) next
    v <- values[[f$id]]
    # Required: marked so, an effect size, or needed for the goal chosen.
    needed <- isTRUE(f$required) || isTRUE(f$effect) || !is.null(f$needed_for) || !is.null(f$needed_if_just)
    if (blank(v)) {
      if (effect_optional(f, values)) next
      if (isTRUE(f$effect)) {
        add(sprintf("%s is empty. Enter the value you expect; powerkit doesn't fill in effect sizes.", quote_label(f)))
      } else if (needed) {
        add(sprintf("%s is empty.", quote_label(f)))
      }
      next
    }
    if (identical(f$type, "number")) {
      x <- parse_number(v)
      if (is.nan(x)) {
        add(sprintf("%s should be a number written with a decimal point, such as 0.3.", quote_label(f)))
        next
      }
      if (!is.null(f[["min"]]) && x < f[["min"]]) add(sprintf("%s must be at least %s.", quote_label(f), f[["min"]]))
      if (!is.null(f[["max"]]) && x > f[["max"]]) add(sprintf("%s must be at most %s.", quote_label(f), f[["max"]]))
      if (!is.null(f$min_exclusive) && x <= f$min_exclusive) add(sprintf("%s must be more than %s.", quote_label(f), f$min_exclusive))
      if (!is.null(f$max_exclusive) && x >= f$max_exclusive) add(sprintf("%s must be less than %s.", quote_label(f), f$max_exclusive))
      if (isTRUE(f$integer) && x != round(x)) add(sprintf("%s must be a whole number.", quote_label(f)))
    }
    if (identical(f$type, "levels")) {
      lv <- parse_levels(v)
      if (length(lv) < 2) add(sprintf("%s needs at least two names, separated by commas.", quote_label(f)))
      if (anyDuplicated(lv)) add(sprintf("%s has the same name twice.", quote_label(f)))
    }
    if (identical(f$type, "numbers")) {
      xs <- parse_numbers(v)
      if (any(is.nan(xs) | is.na(xs))) {
        add(sprintf("%s: every entry should be a number written with a decimal point, such as 10.5, separated by commas.", quote_label(f)))
      } else if (!is.null(f$per_levels) && length(xs) != length(parse_levels(values[[f$per_levels]]))) {
        add(sprintf("%s should have %d numbers, one for each name you gave, in the same order.", quote_label(f), length(parse_levels(values[[f$per_levels]]))))
      }
    }
    if (identical(f$type, "table")) {
      tb <- parse_table(v)
      if (any(vapply(tb, function(r) any(is.nan(r) | is.na(r)), logical(1)))) {
        add(sprintf("%s: every entry should be a number written with a decimal point, such as 0.25.", quote_label(f)))
      } else {
        # Rows and columns follow two level fields: X_levels and Y_levels
        # unless the field names others (`rows_from`, `cols_from`).
        rows <- length(parse_levels(values[[f$rows_from %||% "X_levels"]]))
        cols <- length(parse_levels(values[[f$cols_from %||% "Y_levels"]]))
        if (length(tb) != rows || any(lengths(tb) != cols)) {
          add(sprintf("%s should have %d lines (one per %s) of %d numbers each (one per %s).", quote_label(f), rows,
                      f$rows_name %||% "category of the first variable", cols, f$cols_name %||% "category of the second"))
        }
      }
    }
  }
  c(problems, combination_problems(values))
}

# --- Building the spec ---------------------------------------------------------

set_path <- function(x, keys, value) {
  key <- keys[[1]]
  index <- suppressWarnings(as.integer(key))
  if (!is.na(index) && grepl("^[0-9]+$", key)) key <- index
  if (length(keys) == 1) {
    x[[key]] <- value
  } else {
    child <- if (is.numeric(key)) { if (length(x) >= key) x[[key]] else list() } else (x[[key]] %||% list())
    x[[key]] <- set_path(child, keys[-1], value)
  }
  x
}

split_path <- function(path) {
  # Path segments are separated by dots, except inside "A->B" or "A<->B" keys.
  strsplit(path, ".", fixed = TRUE)[[1]]
}

field_value <- function(f, v) {
  switch(
    f$type,
    number = { x <- parse_number(v); if (isTRUE(f$integer)) as.integer(x) else x },
    levels = as.list(parse_levels(v)),
    numbers = as.list(parse_numbers(v)),
    table = lapply(parse_table(v), as.list),
    trimws(as.character(v))
  )
}

# The design spec for the values entered (assumes form_problems() found none).
build_spec <- function(forms, ep_id, fields, values) {
  form <- forms$forms[[ep_id]]
  spec <- form$base
  # Mediators are added for the number chosen; each is a score.
  if (!is.null(form$mediators)) {
    for (m in mediator_roles(as.integer(values$n_mediators %||% 2))) spec$variables[[m]] <- list(type = "continuous")
  }
  for (f in fields) {
    if (is.null(f$path) || !field_applies(f, values)) next
    v <- values[[f$id]]
    if (blank(v) && effect_optional(f, values)) v <- empty_effect(f, values)
    # A field left empty may stand for another field's value (E34: the
    # baseline score's R-squared between groups starts as the one within).
    if (blank(v) && !is.null(f$copy_if_empty)) v <- values[[f$copy_if_empty]]
    if (blank(v)) next
    spec <- set_path(spec, split_path(f$path), field_value(f, v))
    # `sets`: further spec values that follow from a choice (E24's
    # question sets the template and the effect tested); an entry with a
    # `shown_if` applies only when its conditions hold (E34: the test of a
    # yes/no outcome depends on how the conditions are assigned).
    for (extra in f$sets[[as.character(v)]]) {
      if (field_applies(extra, values)) spec <- set_path(spec, split_path(extra$path), extra$value)
    }
  }
  if (!is.null(spec$target_test$alpha)) spec$target_test$alpha <- claim_alpha(spec$target_test$alpha, values)
  if (identical(spec$goal$type, "sample_size") || identical(spec$goal$type, "sensitivity")) spec$goal$power <- claim_power(spec$goal$power, values)
  # The range of sample sizes is several engine runs (sensitivity_curve());
  # the spec kept for the exports is the largest N at 80% power.
  if (identical(values$goal, "sensitivity_curve")) {
    spec$goal <- list(type = "sensitivity", n = as.integer(parse_number(values$n_max)), power = 0.8)
  }
  spec
}

# The value an empty effect size stands for: zero; group 1's proportion
# (two proportions: no difference); or, for a table of proportions, equal
# proportions in every combination (no association).
empty_effect <- function(f, values) {
  switch(
    f$when_empty %||% "zero",
    zero = "0",
    same_as_p1 = values$p1,
    no_association = {
      rows <- length(parse_levels(values$X_levels))
      cols <- length(parse_levels(values$Y_levels))
      line <- paste(rep(sprintf("%.15g", 1 / (rows * cols)), cols), collapse = ", ")
      paste(rep(line, rows), collapse = "\n")
    }
  )
}

# An effect size may stay empty for the smallest detectable effect, or
# when the user can't justify one (the basic tests only).
effect_optional <- function(f, values) {
  isTRUE(f$effect) && length(f$optional_for) > 0 &&
    (isTRUE(values$goal %in% f$optional_for) || identical(values$just_type, "none"))
}

# Problems with the combination of answers, beyond single fields.
combination_problems <- function(values) {
  if (identical(values$just_type, "none") && !isTRUE(values$goal %in% c("sensitivity", "sensitivity_curve"))) {
    return("With no effect size to plan for, there is no sample size or power to work out. Under \u201cWhat do you want to find out?\u201d, choose the smallest effect you could detect, at a given sample size or across a range of sample sizes.")
  }
  character()
}

# --- The engine's check ----------------------------------------------------------

engine_cache <- new.env(parent = emptyenv())

# A function from powerkit's engine: the installed powerkit package, or
# engine/ loaded read-only with pkgload. NULL when neither is available.
engine_function <- function(name, engine_dir = file.path(routing_root(), "..", "..", "engine")) {
  key <- paste0("fn_", name)
  if (!is.null(engine_cache[[key]])) return(engine_cache[[key]])
  fn <- tryCatch({
    if (requireNamespace("powerkit", quietly = TRUE)) {
      getExportedValue("powerkit", name)
    } else if (requireNamespace("pkgload", quietly = TRUE) && dir.exists(engine_dir)) {
      if (!"powerkit" %in% loadedNamespaces()) {
        suppressMessages(pkgload::load_all(engine_dir, export_all = FALSE, helpers = FALSE, quiet = TRUE, attach = FALSE))
      }
      get(name, envir = asNamespace("powerkit"))
    }
  }, error = function(e) NULL)
  engine_cache[[key]] <- fn
  fn
}

# validate_spec(), or NULL where the engine isn't available.
engine_validator <- function(engine_dir = file.path(routing_root(), "..", "..", "engine")) {
  engine_function("validate_spec", engine_dir)
}

routing_root <- function() getOption("powerkit.routing_dir", getwd())

# Put the user's field labels in place of spec paths in the engine's
# messages (e.g. 'target_test > alpha' becomes "Significance level (alpha)").
plain_engine_message <- function(message, fields) {
  for (f in fields) {
    if (is.null(f$path)) next
    engine_path <- gsub(".", " > ", f$path, fixed = TRUE)
    message <- gsub(sprintf("'%s'", engine_path), quote_label(f), message, fixed = TRUE)
  }
  message
}

# Check a spec with validate_spec(). Returns status "ok", "problems" or
# "unavailable", with the engine's problems and advice in plain English.
check_spec <- function(spec, fields, validate = engine_validator()) {
  if (is.null(validate)) return(list(status = "unavailable", problems = character(), advice = character()))
  advice <- character()
  result <- tryCatch(
    withCallingHandlers(
      { validate(spec); "ok" },
      warning = function(w) { advice <<- c(advice, conditionMessage(w)); invokeRestart("muffleWarning") }
    ),
    error = function(e) e
  )
  if (identical(result, "ok")) {
    return(list(status = "ok", problems = character(), advice = vapply(advice, plain_engine_message, "", fields = fields, USE.NAMES = FALSE)))
  }
  problems <- result$problems %||% conditionMessage(result)
  list(status = "problems", problems = vapply(problems, plain_engine_message, "", fields = fields, USE.NAMES = FALSE),
       advice = vapply(advice, plain_engine_message, "", fields = fields, USE.NAMES = FALSE))
}

spec_json <- function(spec) as.character(jsonlite::toJSON(spec, auto_unbox = TRUE, pretty = TRUE, digits = NA))

# --- Copying answers -------------------------------------------------------------

# The route taken and the values entered, as plain text to paste anywhere.
answers_text <- function(tree, route_label, history, ep_id, fields, values) {
  ep <- tree$endpoints[[ep_id]]
  lines <- c("powerkit routing prototype: my answers", "", paste0("Route: ", route_label))
  lines <- c(lines, path_lines(tree, history))
  lines <- c(lines, "", sprintf("End point: %s, %s (%s)", ep_id, ep$plain_name, ep$doc_name), "", "Values entered:")
  for (f in fields) {
    v <- values[[f$id]]
    if (blank(v) || !field_applies(f, values)) next
    shown <- if (!is.null(f$choices) && !is.null(f$choices[[as.character(v)]])) f$choices[[as.character(v)]] else gsub("\n", " / ", as.character(v))
    lines <- c(lines, sprintf("- %s: %s", f$label, shown))
  }
  paste(lines, collapse = "\n")
}
