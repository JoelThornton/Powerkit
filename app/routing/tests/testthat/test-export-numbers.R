# Exports keep the researcher's words as written and give the study's own
# numbers: the power reached at the N found, the unit counted, the event a
# probability is for, and a retrospective calculation called one.

numbers_engine <- function(name) engine_function(name, file.path(repo_dir, "engine"))

numbers_calc <- function(ep, set = list(), fields = form_fields(form_groups(forms, ep)), nrep = NULL, seed = 1L) {
  run <- numbers_engine("run_spec")
  skip_if(is.null(run), "powerkit's engine isn't available here")
  values <- form_examples[[ep]]
  for (k in names(set)) values[[k]] <- set[[k]]
  spec <- build_spec(forms, ep, fields, values)
  if (!is.null(nrep)) spec$options$nrep <- nrep
  calc <- suppressWarnings(run_calculation(spec, run, seed = seed))
  expect_identical(calc$status, "ok", label = ep)
  list(calc = calc, values = values, fields = fields,
    writeup = writeup_text(forms$forms[[ep]], calc$spec, calc$result, fields, values))
}

test_that("the researcher's quoted source is kept as written, and occasions are counted as observations", {
  quote <- "Our pilot enrolled 140 participants (two sites)."
  x <- numbers_calc("E41", list(goal = "power", n = "1120", just_source = quote), nrep = 100L)
  for (part in c("short", "full", "ethics")) {
    expect_match(x$writeup[[part]], paste0("“", quote, "”"), fixed = TRUE, label = part)
    expect_no_match(x$writeup[[part]], "140 observations", fixed = TRUE, label = part)
  }
  expect_match(x$writeup[["full"]], "1,120 observations (80 people measured on 14 occasions each)", fixed = TRUE)
  expect_no_match(x$writeup[["full"]], "1,120 participants", fixed = TRUE)
  expect_match(x$writeup[["ethics"]], "1,120 observations (80 people measured on 14 occasions each)", fixed = TRUE)
})

test_that("a reason with a number in it is kept as written in a unit-reworded write-up", {
  # Pairs: the dyadic cards reword "participants" as pairs.
  held <- hold_user_text(list(just_source = "We had 30 participants in total.", power_reason = "Our funder asks for 90 participants."))
  text <- c(short = paste("Example:", writeup_quote(held$just_source), "chosen because", held$power_reason))
  text <- dyad_units(text)
  out <- restore_user_text(text, attr(held, "held_text"))
  expect_identical(unname(out[["short"]]), "Example: “We had 30 participants in total.” chosen because Our funder asks for 90 participants")
})

test_that("the ethics paragraph gives the power reached at the N found, beside the target", {
  # One proportion, .90 against .50, two-sided binom.test(): N = 12 reaches
  # 88.9% for an 80% target.
  x <- numbers_calc("E25", list(p = "0.9", p0 = "0.5", method = "binom_test", goal = "sample_size", power = "0.8"))
  expect_identical(x$calc$result$n_required$n, 12)
  ethics <- x$writeup[["ethics"]]
  expect_match(ethics, "the 80% power we aimed for; at this number the power is 88.9%", fixed = TRUE)
  expect_match(ethics, "is 88.9%, and the chance that it misses it is 11.1%", fixed = TRUE)
  expect_no_match(ethics, "is 80%, and the chance", fixed = TRUE)
  expect_match(x$writeup[["short"]], "88.9%", fixed = TRUE)
})

test_that("a claim needing several tests says the ethics chance is for one test, and names the study's goal", {
  fields <- form_fields(form_groups(forms, "E2", start = list(claim = "all")))
  x <- numbers_calc("E2", list(claim = "all", n_tests = "3", all_dependence = "independent", goal = "sample_size", power = "0.8"), fields = fields)
  expect_match(x$writeup[["ethics"]], "That chance is for this one test. Our claim needs all 3 of its tests to succeed, and the plan aims for at least an 80% chance that they all do.", fixed = TRUE)
})

test_that("a meta-analysis's ethics paragraph names what it tests", {
  base <- form_examples$E61
  for (case in list(list(q = "subgroups", words = "If the kinds of study really differ by that much"),
                    list(q = "heterogeneity", words = "If the studies' true effects really vary that much"))) {
    values <- modifyList(base, list(meta_question = case$q))
    fields <- form_fields(form_groups(forms, "E61"))
    spec <- tryCatch(build_spec(forms, "E61", fields, values), error = function(e) NULL)
    skip_if(is.null(spec), paste("the example doesn't build for", case$q))
    result <- list(goal_type = "power", curve = data.frame(n = 40, power = 0.7), provenance = list(backend = "metapower", packages = list(powerkit = "0.81.0", metapower = "0.2.2")))
    e <- ethics_text(spec, result, fields, values)
    expect_match(e, case$words, fixed = TRUE, label = case$q)
    expect_no_match(e, "average effect is real", fixed = TRUE, label = case$q)
  }
})

test_that("observed power is described as retrospective, with no case for recruiting", {
  x <- numbers_calc("E2", list(just_type = "own_study_result", goal = "sample_size", power = "0.8"))
  expect_match(x$writeup[["short"]], "^A retrospective power analysis, using the finished study's own result, was conducted")
  expect_no_match(x$writeup[["short"]], "a priori", fixed = TRUE)
  expect_match(x$writeup[["ethics"]], "it is not a justification for recruiting participants", fixed = TRUE)
  expect_no_match(x$writeup[["ethics"]], "We plan to include", fixed = TRUE)
})

test_that("the ethics paragraph leaves the investigators' judgement for them to state", {
  x <- numbers_calc("E2", list(goal = "sample_size", power = "0.8"))
  expect_match(x$writeup[["ethics"]], "[Say how you weighed this balance.]", fixed = TRUE)
  expect_no_match(x$writeup[["ethics"]], "our judgement of that balance", fixed = TRUE)
})
