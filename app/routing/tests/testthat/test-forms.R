# Input screens for the end points powerkit runs (forms.yaml, R/forms.R).
# The engine is loaded read-only for validate_spec(); tests that need it are
# skipped where it isn't available (the app-tests CI job installs only the
# app's packages).

form_ids <- names(forms$forms)
validate <- engine_validator(file.path(repo_dir, "engine"))
skip_without_engine <- function() skip_if(is.null(validate), "powerkit's engine isn't available here")

values_for <- function(ep) form_examples[[ep]]
fields_for <- function(ep, k = 2) form_fields(form_groups(forms, ep, k))

test_that("every end point that runs has an input screen, and only those", {
  runs <- names(Filter(function(e) e$status %in% c("runs_validated", "runs_validation_in_progress"), tree$endpoints))
  expect_setequal(form_ids, runs)
  expect_setequal(form_ids, paste0("E", 1:14))
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
    problems <- form_problems(form_fields(groups), list())
    for (f in effect) expect_true(any(grepl(f$label, problems, fixed = TRUE)), label = paste(ep, f$id))
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
  expect_equal(direction$default, "two_sided")
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
    expect_identical(spec$goal, list(type = "sample_size", power = 0.8), label = ep)
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

test_that("three mediators give the extra paths, and the spec still passes", {
  fields <- fields_for("E11", 3)
  ids <- vapply(fields, `[[`, "", "id")
  expect_true(all(c("M3_label", "p_X_M3", "p_M3_Y", "rc_M1_M3", "rc_M2_M3") %in% ids))
  target <- Filter(function(f) f$id == "target_path", fields)[[1]]
  expect_identical(unname(unlist(target$choices)), c("X->M1->Y", "X->M2->Y", "X->M3->Y"))
  serial <- Filter(function(f) f$id == "target_path", fields_for("E12", 3))[[1]]
  expect_true("X->M1->M2->M3->Y" %in% unlist(serial$choices))
  skip_without_engine()
  v <- c(values_for("E11"), list(n_mediators = "3", M3_label = "Detachment", p_X_M3 = "0.2", p_M3_Y = "0.1"))
  v <- v[!duplicated(names(v), fromLast = TRUE)]
  expect_identical(check_spec(build_spec(forms, "E11", fields, v), fields, validate)$status, "ok")
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

test_that("results say plainly that nothing is calculated", {
  html <- as.character(form_result_ui(tree$endpoints$E1, character(), list(status = "ok", problems = character(), advice = character()), list(a = 1)))
  expect_match(html, "Calculation not wired in yet", fixed = TRUE)
  expect_match(html, "doesn&#39;t calculate anything|doesn't calculate anything")
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
  expect_no_match(as.character(card_nav_ui(forms, "E23")), "Enter your values", fixed = TRUE)
})

test_that("whether effect sizes start empty is an undecided setting, shown on the screens", {
  s <- setting_by_key(tree, "effect_size_inputs")
  expect_null(s$value)
  expect_true("form" %in% unlist(s$shown_at))
  html <- as.character(form_ui(tree, forms, "E1", form_groups(forms, "E1")))
  expect_match(html, htmltools::htmlEscape(s$question), fixed = TRUE)
})
