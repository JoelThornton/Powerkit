# Input screens for the end points powerkit runs (forms.yaml, R/forms.R).
# The engine is loaded read-only for validate_spec(). Tests that need it
# are skipped where it isn't available, except on GitHub: the app-tests job
# installs the engine and sets POWERKIT_APP_TESTS_NEED_ENGINE, so there a
# missing engine fails the tests instead.

form_ids <- names(forms$forms)
validate <- engine_validator(file.path(repo_dir, "engine"))
skip_without_engine <- function() {
  if (is.null(validate) && identical(Sys.getenv("POWERKIT_APP_TESTS_NEED_ENGINE"), "true")) {
    fail("powerkit's engine couldn't be loaded, but this run needs it (POWERKIT_APP_TESTS_NEED_ENGINE).")
  }
  skip_if(is.null(validate), "powerkit's engine isn't available here")
}

values_for <- function(ep) form_examples[[ep]]
fields_for <- function(ep, k = 2) form_fields(form_groups(forms, ep, k))

test_that("every end point that runs has an input screen, and only those", {
  runs <- names(Filter(function(e) e$status %in% c("runs_validated", "runs_validation_in_progress"), tree$endpoints))
  expect_setequal(form_ids, runs)
  expect_setequal(form_ids, c(paste0("E", 1:14), "E18", "E23", "E24", "E25", "E26", "E48", "E49", "E50"))
})

test_that("each screen asks for every line of the card's 'What you would enter', in order", {
  for (ep in form_ids) {
    lines <- unlist(lapply(forms$forms[[ep]]$groups, `[[`, "input"))
    expect_identical(lines, unlist(tree$endpoints[[ep]]$inputs), label = ep)
  }
})

test_that("every field has a label tied to its input, and hints sit beside the card's lines", {
  for (ep in form_ids) {
    groups <- form_groups(forms, ep)
    html <- as.character(form_ui(tree, forms, ep, groups))
    for (f in form_fields(groups)) {
      expect_match(html, sprintf('<label class="control-label" id="f_%s-label" for="f_%s">', f$id, f$id), fixed = TRUE, label = paste(ep, f$id))
    }
    for (g in groups) for (h in if (!is.null(g$input)) glossary_for(tree, g$input) else list()) {
      expect_match(html, sprintf("<dfn>%s</dfn>", htmltools::htmlEscape(h$term)), fixed = TRUE, label = paste(ep, h$term))
    }
  }
})

test_that("effect sizes start empty and are required; nothing suggests a value", {
  for (ep in form_ids) {
    groups <- form_groups(forms, ep)
    effect <- Filter(function(f) isTRUE(f$effect), form_fields(groups))
    expect_gt(length(effect), 0, label = ep)
    for (f in effect) {
      expect_null(f[["default"]], label = paste(ep, f$id))
      html <- as.character(field_ui(f, f[["default"]]))
      expect_match(html, if (identical(f$type, "table")) '"></textarea>' else 'value=""', fixed = TRUE, label = paste(ep, f$id))
      expect_match(html, "(required; starts empty)", fixed = TRUE)
      expect_match(html, 'aria-required="true"', fixed = TRUE)
    }
    # E24's effect sizes appear once its question is chosen.
    start <- if (identical(ep, "E24")) list(question = "r2_increase") else list()
    problems <- form_problems(form_fields(groups), start)
    # Fields shown only for another choice (E7's per-cell SDs) are checked
    # in their own test.
    for (f in Filter(function(f) field_applies(f, start), effect)) {
      expect_true(any(grepl(f$label, problems, fixed = TRUE)), label = paste(ep, f$id))
    }
    expect_true(any(grepl("powerkit doesn't fill in effect sizes", problems, fixed = TRUE)))
  }
})

test_that("other settings start at the wrapped tool's default, and say whose default it is", {
  alpha <- function(ep) Filter(function(f) f$id == "alpha", fields_for(ep))[[1]]
  for (ep in form_ids) {
    f <- alpha(ep)
    expect_equal(f[["default"]], 0.05, label = ep)
    expect_match(f$default_source, forms$forms[[ep]]$tool, fixed = TRUE, label = ep)
    html <- as.character(field_ui(f, f[["default"]]))
    expect_match(html, 'value="0.05"', fixed = TRUE)
    expect_match(html, "Starts at 0.05:", fixed = TRUE)
  }
  power <- function(ep) Filter(function(f) f$id == "power", fields_for(ep))[[1]]
  expect_null(power("E1")$default)
  expect_match(power("E1")$default_source, "no default target power", fixed = TRUE)
  expect_equal(power("E10")$default, 0.8)
  expect_match(power("E10")$default_source, "target_power = 0.8", fixed = TRUE)
  direction <- Filter(function(f) f$id == "alternative", fields_for("E2"))[[1]]
  # Asked, not pre-filled, and first (docs/decisions.md, 19 October 2026).
  expect_null(direction[["default"]])
  expect_match(direction$label, "Does your hypothesis predict a direction?", fixed = TRUE)
  expect_match(direction$default_source, "Not filled in for you", fixed = TRUE)
  expect_equal(form_groups(forms, "E2")[[1]]$title, "Your hypothesis")
  expect_match(form_problems(fields_for("E2"), modifyList(form_examples[["E2"]], list(alternative = ""))),
    "Does your hypothesis predict a direction?", fixed = TRUE, all = FALSE)
  expect_length(Filter(function(f) f$id == "alternative", fields_for("E9")), 0)
})

test_that("the screen catches empty, non-numeric and out-of-range values, naming each field", {
  v <- values_for("E4")
  v$r <- "0,3"; v$alpha <- "0.7"; v$X_label <- ""
  problems <- form_problems(fields_for("E4"), v)
  expect_true(any(grepl("“Correlation r” should be a number written with a decimal point", problems, fixed = TRUE)))
  expect_true(any(grepl("“Significance level (alpha)” must be at most 0.5.", problems, fixed = TRUE)))
  expect_true(any(grepl("“First variable” is empty.", problems, fixed = TRUE)))
  v <- values_for("E4"); v$r <- "1.5"
  expect_match(form_problems(fields_for("E4"), v), "“Correlation r” must be at most 1.", fixed = TRUE)
  # What the goal needs: power for a sample size, n for power.
  v <- values_for("E1"); v$power <- NULL
  expect_match(form_problems(fields_for("E1"), v), "Target power", fixed = TRUE)
  v <- values_for("E1"); v$goal <- "power"
  expect_match(form_problems(fields_for("E1"), v), "Number of participants analysed", fixed = TRUE)
  v$n <- "80.5"
  expect_match(form_problems(fields_for("E1"), v), "must be a whole number", fixed = TRUE)
  # A previous study needs its adjustment.
  v <- values_for("E1"); v$just_type <- "prior_study"
  expect_match(form_problems(fields_for("E1"), v), "How you adjusted it", fixed = TRUE)
  # The table of proportions must fit the categories.
  v <- values_for("E6"); v$probabilities <- "0.3, 0.25\n0.12, 0.08"
  expect_match(form_problems(fields_for("E6"), v), "should have 3 lines", fixed = TRUE)
})

test_that("the example values build the spec the engine expects", {
  for (ep in form_ids) {
    v <- values_for(ep)
    fields <- fields_for(ep, as.integer(v$n_mediators %||% 2))
    expect_length(form_problems(fields, v), 0)
    spec <- build_spec(forms, ep, fields, v)
    # The generic tests (E50) have no sample size to find.
    goal <- if (ep == "E50") list(type = "power") else list(type = "sample_size", power = 0.8)
    expect_identical(spec$goal, goal, label = ep)
    expect_null(spec$goal$n)
  }
  spec <- build_spec(forms, "E7", fields_for("E7"), values_for("E7"))
  expect_identical(spec$population$means, list(list(10, 10), list(10, 13)))
  expect_identical(spec$variables$A$levels, list("None", "Praise"))
  spec <- build_spec(forms, "E6", fields_for("E6"), values_for("E6"))
  expect_identical(spec$variables$X$levels, list("Secure", "Anxious", "Avoidant"))
  expect_length(spec$population$probabilities, 3)
  spec <- build_spec(forms, "E10", fields_for("E10"), values_for("E10"))
  expect_identical(spec$population$paths, list(`X->M` = 0.3, `M->Y` = 0.3, `X->Y` = 0.1))
})

test_that("a valid set of answers passes validate_spec() for every screen", {
  skip_without_engine()
  for (ep in form_ids) {
    v <- values_for(ep)
    fields <- fields_for(ep, as.integer(v$n_mediators %||% 2))
    check <- check_spec(build_spec(forms, ep, fields, v), fields, validate)
    expect_identical(check$status, "ok", label = paste(ep, paste(check$problems, collapse = "; ")))
  }
})

test_that("parallel mediation offers two mediators only (decided 22 October 2026); serial offers up to four", {
  choices <- function(ep) unname(unlist(Filter(function(f) f$id == "n_mediators", fields_for(ep, 2))[[1]]$choices))
  expect_identical(choices("E11"), "2")
  expect_identical(choices("E12"), c("2", "3", "4"))
  expect_identical(setting_by_key(tree, "parallel_mediators_max")$value, "two")
  # Three asked for (e.g. from an older project file) gives two for parallel mediation.
  ids <- vapply(fields_for("E11", 3), `[[`, "", "id")
  expect_false(any(c("M3_label", "p_X_M3") %in% ids))
  target <- Filter(function(f) f$id == "target_path", fields_for("E11", 3))[[1]]
  expect_identical(unname(unlist(target$choices)), c("X->M1->Y", "X->M2->Y"))
})

test_that("three serial mediators give the extra paths", {
  serial <- Filter(function(f) f$id == "target_path", fields_for("E12", 3))[[1]]
  expect_true("X->M1->M2->M3->Y" %in% unlist(serial$choices))
  expect_true("M3_label" %in% vapply(fields_for("E12", 3), `[[`, "", "id"))
})

test_that("the engine's messages name the screen's fields, in plain English", {
  skip_without_engine()
  spec <- build_spec(forms, "E1", fields_for("E1"), values_for("E1"))
  spec$target_test$alpha <- 0.7
  check <- check_spec(spec, fields_for("E1"), validate)
  expect_identical(check$status, "problems")
  expect_match(check$problems, "“Significance level (alpha)” must be at most 0.5", fixed = TRUE, all = FALSE)
  # Advice from the checker is passed on (here: a pilot study's estimate).
  v <- values_for("E1"); v$just_type <- "pilot_study"
  check <- check_spec(build_spec(forms, "E1", fields_for("E1"), v), fields_for("E1"), validate)
  expect_identical(check$status, "ok")
  expect_match(check$advice, "Pilot estimates are very imprecise", fixed = TRUE)
})

test_that("E7 takes one SD or one per cell, as validate_spec() accepts", {
  fields <- fields_for("E7")
  ids <- vapply(fields, `[[`, "", "id")
  expect_true(all(c("sd_mode", "sd", "sd11", "sd12", "sd21", "sd22") %in% ids))
  # One SD: the per-cell fields are ignored, even if filled.
  one <- values_for("E7")
  one$sd11 <- "99"
  expect_length(form_problems(fields, one), 0)
  spec <- build_spec(forms, "E7", fields, one)
  expect_identical(spec$population$sd, 6)
  # One per cell: a 2 x 2 array (rows = levels of A); the single SD is ignored.
  per_cell <- utils::modifyList(values_for("E7"), list(sd_mode = "per_cell", sd = "", sd11 = "5", sd12 = "6", sd21 = "5.5", sd22 = "7"))
  expect_length(form_problems(fields, per_cell), 0)
  spec <- build_spec(forms, "E7", fields, per_cell)
  expect_identical(spec$population$sd, list(list(5, 6), list(5.5, 7)))
  # Missing or non-positive cell SDs are caught on the screen.
  bad <- utils::modifyList(per_cell, list(sd12 = "", sd22 = "0"))
  problems <- form_problems(fields, bad)
  expect_match(problems, "“SD: A level 1, B level 2” is empty", fixed = TRUE, all = FALSE)
  expect_match(problems, "“SD: A level 2, B level 2” must be more than 0", fixed = TRUE, all = FALSE)
  # The copied answers list only the SDs that apply.
  text <- answers_text(tree, "Help me choose", list(), "E7", fields, per_cell)
  expect_match(text, "SD: A level 2, B level 2: 7", fixed = TRUE)
  expect_no_match(text, "SD (one value for all four cells)", fixed = TRUE)
  # The screen hides the fields that don't apply, in the browser.
  html <- as.character(form_ui(tree, forms, "E7", form_groups(forms, "E7")))
  expect_match(html, "input.f_sd_mode == &#39;per_cell&#39;|input.f_sd_mode == 'per_cell'")
  expect_match(html, "input.f_sd_mode != &#39;per_cell&#39;|input.f_sd_mode != 'per_cell'")
  # And the engine accepts per-cell SDs.
  skip_without_engine()
  check <- check_spec(spec, fields, validate)
  expect_identical(check$status, "ok", label = paste(check$problems, collapse = "; "))
})

test_that("screens that don't calculate yet say so plainly", {
  html <- as.character(form_result_ui(tree$endpoints$E10, character(), list(status = "ok", problems = character(), advice = character()), list(a = 1)))
  expect_match(html, "Calculation not wired in yet", fixed = TRUE)
  expect_match(html, "isn&#39;t wired into the prototype yet|isn't wired into the prototype yet")
  html <- as.character(form_result_ui(tree$endpoints$E1, "“Cohen's d” is empty.", NULL))
  expect_match(html, 'role="alert"', fixed = TRUE)
  html <- as.character(form_result_ui(tree$endpoints$E1, character(), list(status = "unavailable")))
  expect_match(html, "couldn&#39;t be checked here|couldn't be checked here")
})

test_that("'Copy my answers' gives the route, the end point and the values as text", {
  history <- list(list(node = "s1", answer = "A score or scale"), list(node = "s2", answer = "Independent people"))
  text <- answers_text(tree, "Help me choose", history, "E2", fields_for("E2"), values_for("E2"))
  expect_match(text, "Route: Help me choose", fixed = TRUE)
  expect_match(text, paste0("- ", tree$nodes$s1$text, " A score or scale"), fixed = TRUE)
  expect_match(text, "End point: E2, ", fixed = TRUE)
  expect_match(text, "- Cohen's d: 0.4", fixed = TRUE)
  expect_match(text, "- Test version: Welch's t-test", fixed = TRUE)
  expect_no_match(text, "Number of participants", fixed = TRUE)  # not needed for a sample size
})

test_that("cards with an input screen offer it; others don't", {
  expect_match(as.character(card_nav_ui(forms, "E2")), "Enter your values", fixed = TRUE)
  expect_no_match(as.character(card_nav_ui(forms, "E19")), "Enter your values", fixed = TRUE)
})

test_that("effect sizes start empty (decided 22 October 2026), shown as a decision in the maintainer's view", {
  withr::local_options(powerkit.maintainer_view = TRUE)
  s <- setting_by_key(tree, "effect_size_inputs")
  expect_identical(s$value, "empty_required")
  expect_true("form" %in% unlist(s$shown_at))
  html <- as.character(form_ui(tree, forms, "E1", form_groups(forms, "E1")))
  expect_match(html, "Maintainer decision", fixed = TRUE)
  expect_match(html, htmltools::htmlEscape(s$options$empty_required), fixed = TRUE)
})

# Screen A (the new design, docs/decisions.md, 18 October 2026) -------------

test_that("screen A asks the situation, aim and claim, with the first option preselected", {
  html <- as.character(start_ui(tree))
  for (q in tree$start_questions) {
    expect_match(html, q$question, fixed = TRUE, info = q$id)
    for (o in q$options) expect_match(html, htmltools::htmlEscape(o$label), fixed = TRUE, info = o$label)
  }
  expect_match(html, "Several claims, each standing on its own", fixed = TRUE)
  expect_match(html, "Your claim is about the set, not each test", fixed = TRUE)
  expect_equal(start_answers(tree, list()), list(situation = "choose", aim = "predict", claim = "one"))
})

test_that("estimation and equivalence go to their cards; testing a prediction goes on to the design finder", {
  expect_equal(start_exit(tree, list(aim = "estimate")), "E46")
  expect_equal(start_exit(tree, list(aim = "equivalence")), "E36")
  expect_null(start_exit(tree, list(aim = "predict")))
})

test_that("a fixed sample size starts the goal at the smallest detectable effect, or at power", {
  goal <- function(ep, start) Filter(function(f) f$id == "goal", form_fields(form_groups(forms, ep, start = start)))[[1]]
  expect_null(goal("E2", list(situation = "choose"))$default)
  expect_equal(goal("E2", list(situation = "fixed"))$default, "sensitivity")
  expect_equal(goal("E9", list(situation = "fixed"))$default, "sensitivity")
  expect_equal(goal("E10", list(situation = "fixed"))$default, "power")
  for (ep in paste0("E", 1:6)) expect_true("sensitivity" %in% names(goal(ep, list())$choices), info = ep)
})

test_that("the claim adds a note, and 'any of several' divides alpha between the tests", {
  groups <- function(claim) form_groups(forms, "E2", start = list(claim = claim))
  titles <- function(claim) vapply(groups(claim), function(g) g$input %||% g$title, "")
  expect_false("Your claim" %in% titles("one"))
  for (claim in c("each", "any", "all")) expect_true("Your claim" %in% titles(claim), info = claim)
  expect_true("n_tests" %in% vapply(form_fields(groups("any")), `[[`, "", "id"))
  expect_true("n_tests" %in% vapply(form_fields(groups("all")), `[[`, "", "id"))
  expect_match(as.character(form_ui(tree, forms, "E2", groups("all"))), "raises this test's target power", fixed = TRUE)
  expect_match(as.character(form_ui(tree, forms, "E2", groups("each"))), "error-statistical view", fixed = TRUE)

  fields <- form_fields(groups("any"))
  values <- c(form_examples[["E2"]], list(n_tests = "4"))
  expect_length(form_problems(fields, values), 0)
  expect_equal(build_spec(forms, "E2", fields, values)$target_test$alpha, 0.05 / 4)
  expect_match(form_problems(fields, form_examples[["E2"]]), "Number of tests in the set", fixed = TRUE, all = FALSE)
  values$claim <- "any"
  expect_match(claim_result_note(values, 0.0125), "0.05 divided by 4 (Bonferroni): 0.0125", fixed = TRUE)
})

test_that("the t-tests and the correlation need no effect size for the smallest detectable effect", {
  fields <- form_fields(form_groups(forms, "E2"))
  values <- form_examples[["E2"]]
  values$goal <- "sensitivity"; values$n <- "128"; values$power <- "0.8"; values$d <- ""
  expect_length(form_problems(fields, values), 0)
  expect_equal(build_spec(forms, "E2", fields, values)$population$d, 0)
  values$goal <- "sample_size"
  expect_match(form_problems(fields, values), "powerkit doesn't fill in effect sizes", fixed = TRUE, all = FALSE)
})

test_that("two proportions and chi-square need no effect size for the smallest detectable effect", {
  # Two proportions: group 2's proportion may stay empty (no difference),
  # but group 1's is still needed.
  fields <- form_fields(form_groups(forms, "E5"))
  values <- modifyList(form_examples[["E5"]], list(goal = "sensitivity", n = "200", power = "0.8", p2 = ""))
  expect_length(form_problems(fields, values), 0)
  spec <- build_spec(forms, "E5", fields, values)
  expect_equal(spec$population$p2, spec$population$p1)
  values$p1 <- ""
  expect_match(form_problems(fields, values), "Proportion of 'yes' in group 1", fixed = TRUE, all = FALSE)
  expect_match(as.character(form_ui(tree, forms, "E5", form_groups(forms, "E5"))), "group 2's proportion can stay empty", fixed = TRUE)
  # Chi-square: an empty table stands for no association, sized to the
  # categories.
  fields <- form_fields(form_groups(forms, "E6"))
  values <- modifyList(form_examples[["E6"]], list(goal = "sensitivity", n = "200", power = "0.8", probabilities = ""))
  expect_length(form_problems(fields, values), 0)
  p <- build_spec(forms, "E6", fields, values)$population$probabilities
  rows <- length(parse_levels(values$X_levels)); cols <- length(parse_levels(values$Y_levels))
  expect_equal(lengths(p), rep(cols, rows))
  expect_equal(sum(unlist(p)), 1)
  values$goal <- "sample_size"
  expect_match(form_problems(fields, values), "powerkit doesn't fill in effect sizes", fixed = TRUE, all = FALSE)
})

# Screen C: the effect-size source -------------------------------------------

test_that("'I can't justify an effect size' is offered for the basic tests, and leads to the smallest detectable effect", {
  just <- function(ep) Filter(function(f) f$id == "just_type", form_fields(form_groups(forms, ep)))[[1]]
  for (ep in paste0("E", 1:6)) expect_true("none" %in% names(just(ep)$choices), info = ep)
  for (ep in c("E7", "E9")) expect_false("none" %in% names(just(ep)$choices), info = ep)

  fields <- form_fields(form_groups(forms, "E4"))
  values <- form_examples[["E4"]]
  values$just_type <- "none"; values$just_source <- ""; values$r <- ""
  expect_match(form_problems(fields, values), "With no effect size to plan for", fixed = TRUE, all = FALSE)
  values$goal <- "sensitivity_curve"; values$n_max <- "200"
  expect_length(form_problems(fields, values), 0)
  spec <- build_spec(forms, "E4", fields, values)
  expect_equal(spec$effect_justification, list(type = "none"))
  expect_equal(spec$goal, list(type = "sensitivity", n = 200L, power = 0.8))
  expect_equal(spec$population$r, 0)
})

test_that("the reasoning is optional to calculate", {
  fields <- form_fields(form_groups(forms, "E2"))
  values <- form_examples[["E2"]]
  values$just_source <- ""
  expect_length(form_problems(fields, values), 0)
})

test_that("one-way ANOVA takes one mean per group, and the screen counts them", {
  v <- values_for("E18")
  spec <- build_spec(forms, "E18", fields_for("E18"), v)
  expect_identical(spec$template, "oneway_between")
  expect_identical(spec$variables$A$levels, list("None", "Neutral", "Praise"))
  expect_identical(spec$population$means, list(10, 11, 13))
  v$means <- "10, 13"
  expect_match(form_problems(fields_for("E18"), v), "should have 3 numbers, one for each name you gave", fixed = TRUE)
  v$means <- "10, 11, thirteen"
  expect_match(form_problems(fields_for("E18"), v), "every entry should be a number", fixed = TRUE)
})

test_that("regression: the question sets the template and the effect, and shows only its own fields", {
  zero <- c(list(Y_label = "Wellbeing score", question = "r2_zero", r2 = "0.1", predictors = "5"), closing_ok)
  spec <- build_spec(forms, "E24", fields_for("E24"), zero)
  expect_identical(spec$template, "r2_zero")
  expect_identical(spec$target_test$effect, "r_squared")
  expect_identical(spec$population$predictors, 5L)
  expect_null(spec$population$r2_full)
  spec <- build_spec(forms, "E24", fields_for("E24"), values_for("E24"))
  expect_identical(spec$template, "r2_increase")
  expect_identical(spec$target_test$effect, "r_squared_change")
  expect_null(spec$population$r2)
  skip_without_engine()
  expect_identical(check_spec(build_spec(forms, "E24", fields_for("E24"), zero), fields_for("E24"), validate)$status, "ok")
})

test_that("two proportions: Fisher's exact test is a test version, with no formula or simulation choice", {
  fields <- fields_for("E5")
  v <- values_for("E5")
  z <- build_spec(forms, "E5", fields, c(v, list(calc_method = "exact", proportions_formula = "z_test")))
  expect_identical(z$target_test$method, "z_test")
  expect_identical(z$options$proportions_formula, "z_test")
  # The z test's formula choice needs the formula, not simulation.
  sim <- build_spec(forms, "E5", fields, c(v, list(calc_method = "simulation", proportions_formula = "z_test")))
  expect_identical(sim$options$method, "simulation")
  expect_null(sim$options$proportions_formula)
  # With Fisher's exact test both are hidden: it is pwrss's formula only.
  fisher <- build_spec(forms, "E5", fields, modifyList(v, list(method = "fisher_exact", calc_method = "simulation", proportions_formula = "arcsine")))
  expect_identical(fisher$target_test$method, "fisher_exact")
  expect_null(fisher$options$method)
  expect_null(fisher$options$proportions_formula)
  skip_without_engine()
  expect_identical(check_spec(fisher, fields, validate)$status, "ok")
})

test_that("a field can depend on several choices at once", {
  field <- list(id = "x", shown_if = list(list(field = "a", is = "1"), list(field = "b", is_not = "2")))
  expect_true(field_applies(field, list(a = "1", b = "3")))
  expect_false(field_applies(field, list(a = "1", b = "2")))
  expect_false(field_applies(field, list(a = "0", b = "3")))
  html <- as.character(field_ui(list(id = "x", label = "X", type = "text", shown_if = field$shown_if), list()))
  expect_match(html, "input.f_a == &#39;1&#39; &amp;&amp; input.f_b != &#39;2&#39;", fixed = TRUE)
})

test_that("a reason box appears only when alpha or the direction is changed", {
  fields <- form_fields(form_groups(forms, "E2"))
  by_id <- function(id) Filter(function(f) identical(f$id, id), fields)[[1]]
  alpha_reason <- by_id("alpha_reason")
  alternative_reason <- by_id("alternative_reason")
  expect_false(field_applies(alpha_reason, list(alpha = "0.05")))
  expect_true(field_applies(alpha_reason, list(alpha = "0.01")))
  expect_false(field_applies(alternative_reason, list(alternative = "two_sided")))
  expect_true(field_applies(alternative_reason, list(alternative = "greater")))
  expect_true(isTRUE(alpha_reason$optional) && isTRUE(alternative_reason$optional))
  expect_equal(form_problems(fields, modifyList(form_examples[["E2"]], list(alpha = "0.01", alternative = "less"))), character())
})

test_that("ANCOVA takes adjusted means, one SD and the covariates' R-squared", {
  v <- values_for("E23")
  spec <- build_spec(forms, "E23", fields_for("E23"), v)
  expect_identical(spec$template, "oneway_ancova")
  expect_identical(spec$target_test$method, "ancova_f")
  expect_identical(spec$population$means, list(20, 18, 16))
  expect_identical(spec$population$r2_covariates, 0.36)
  expect_equal(spec$population$covariates, 1)
  v$r2_covariates <- "1"
  expect_match(form_problems(fields_for("E23"), v), "must be less than 1", fixed = TRUE)
  skip_without_engine()
  expect_identical(check_spec(spec, fields_for("E23"), validate)$status, "ok")
})

test_that("Welch's t-test is simulated by default, with pwrss's formula on request", {
  fields <- fields_for("E2")
  v <- values_for("E2")
  expect_identical(build_spec(forms, "E2", fields, c(v, list(welch_method = "simulation")))$options$method, "simulation")
  spec <- build_spec(forms, "E2", fields, c(v, list(welch_method = "exact")))
  expect_identical(spec$options$method, "exact")
  # With Student's test the Welch choice is hidden, and the basic choice applies.
  student <- modifyList(v, list(method = "student_t", welch_method = "simulation", calc_method = "exact"))
  expect_identical(build_spec(forms, "E2", fields, student)$options$method, "exact")
})

test_that("the generic tests ask for no sample size, and only t and z have a direction", {
  fields <- form_fields(form_groups(forms, "E50"))
  ids <- vapply(fields, `[[`, "", "id")
  expect_false(any(c("n", "n_max", "attrition") %in% ids))
  goal <- Filter(function(f) identical(f$id, "goal"), fields)[[1]]
  expect_setequal(names(goal$choices), c("power", "sensitivity"))
  shown <- function(id, test) field_applies(Filter(function(f) identical(f$id, id), fields)[[1]], list(generic_test = test, goal = "power"))
  expect_true(shown("df", "t")); expect_true(shown("df", "chi_square")); expect_false(shown("df", "f")); expect_false(shown("df", "z"))
  expect_true(shown("df1", "f")); expect_false(shown("df1", "t"))
  expect_true(shown("alternative", "z")); expect_false(shown("alternative", "chi_square"))
  # The noncentrality is needed for power, not for the noncentrality needed.
  v <- modifyList(form_examples$E50, list(ncp = ""))
  expect_match(form_problems(fields, v), "Noncentrality parameter", fixed = TRUE)
  expect_length(form_problems(fields, modifyList(v, list(goal = "sensitivity"))), 0)
  skip_without_engine()
  for (test in c("t", "f", "chi_square", "z")) {
    v <- modifyList(form_examples$E50, list(generic_test = test, df1 = "2", df2 = "40"))
    spec <- build_spec(forms, "E50", fields, v)
    expect_identical(spec$template, test)
    expect_identical(check_spec(spec, fields, validate)$status, "ok", label = test)
  }
})

test_that("'all of several' raises each test's target power, not alpha", {
  fields <- form_fields(form_groups(forms, "E2", start = list(claim = "all")))
  values <- modifyList(form_examples[["E2"]], list(claim = "all", n_tests = "2", goal = "sample_size", power = "0.8"))
  expect_length(form_problems(fields, values), 0)
  spec <- build_spec(forms, "E2", fields, values)
  expect_equal(spec$target_test$alpha, 0.05)
  expect_equal(spec$goal$power, sqrt(0.8))
  expect_equal(spec$goal$power^2, 0.8)
  expect_match(claim_result_note(values, 0.05, "sample_size"), "0.8^(1/2) = 0.894 power", fixed = TRUE)
  expect_match(claim_result_note(values, 0.05, "sample_size"), "Francis & Thunell, 2021", fixed = TRUE)
  expect_match(writeup_claim(values, spec), "planned at power 0.8^(1/2) = 0.894", fixed = TRUE)
  # Power at a fixed sample size is left as it is, with the product as guidance.
  power_values <- modifyList(values, list(goal = "power", n = "100"))
  expect_null(build_spec(forms, "E2", fields, power_values)$goal$power)
  expect_match(claim_result_note(power_values, 0.05, "power"), "product of their powers", fixed = TRUE)
  # Other claims leave the target power alone.
  expect_equal(claim_power(0.8, list(claim = "any", n_tests = "3")), 0.8)
  expect_equal(claim_alpha(0.05, list(claim = "any", n_tests = "2")), 0.025)
})

test_that("observed power is allowed as an effect-size source, with a warning (decided 22 October 2026)", {
  expect_identical(setting_by_key(tree, "observed_power")$value, "warn")
  just <- Filter(function(f) f$id == "just_type", fields_for("E2"))[[1]]
  expect_true("own_study_result" %in% names(just$choices))
  html <- as.character(observed_power_warning_ui())
  expect_match(html, "input.f_just_type == &#39;own_study_result&#39;|input.f_just_type == 'own_study_result'")
  expect_match(html, "useless at best, misleading at worst", fixed = TRUE)
  expect_match(html, "Rubin, 2025, p. 14", fixed = TRUE)
  # The write-up, the reasoning line and the plan checker all name it.
  expect_match(writeup_source[["own_study_result"]], "observed power", fixed = TRUE)
  expect_match(reasoning_line(list(just_type = "own_study_result")), "observed power", fixed = TRUE)
  expect_true(any(grepl("observed power", plan_questions(list(just_type = "own_study_result", just_source = "x"), list()), fixed = TRUE)))
  # The engine's schema accepts it.
  schema <- readLines(file.path(repo_dir, "engine", "inst", "schema", "design.schema.json"))
  expect_true(any(grepl('"own_study_result"', schema, fixed = TRUE)))
})
