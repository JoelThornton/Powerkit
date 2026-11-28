# The justification box and the write-up's effect sentence (input-screen
# review of 28 November 2026): the box asks about the numbers on the
# screen, not an effect size the screen may never show; the write-up says
# which value is the effect tested and which are the other values assumed,
# leaves out the design's counts, and gives the other values' own source.

run <- engine_function("run_spec", file.path(repo_dir, "engine"))
skip_without_run <- function() {
  if (is.null(run) && identical(Sys.getenv("POWERKIT_APP_TESTS_NEED_ENGINE"), "true")) {
    fail("powerkit's engine couldn't be loaded, but this run needs it (POWERKIT_APP_TESTS_NEED_ENGINE).")
  }
  skip_if(is.null(run), "powerkit's engine isn't available here")
}

field <- function(ep, id) Filter(function(f) identical(f$id, id), form_fields(form_groups(forms, ep)))

test_that("the justification box asks where the numbers come from, on every screen", {
  for (ep in names(forms$forms)) {
    groups <- form_groups(forms, ep)
    box <- Filter(function(g) any(vapply(g$fields, function(f) identical(f$id, "just_type"), logical(1))), groups)
    if (!length(box)) next
    expect_identical(box[[1]]$title, "Where these numbers come from", label = ep)
    expect_identical(field(ep, "just_source")[[1]]$label, "Why these numbers?", label = ep)
  }
})

test_that("'where the other numbers come from' is asked only where the screen has such numbers", {
  # An ANOVA from means and an SD has an SD; a correlation has none.
  expect_length(field("E18", "just_other"), 1)
  expect_length(field("E33", "just_other"), 1)
  expect_length(field("E4", "just_other"), 0)
  expect_identical(field("E18", "just_other")[[1]]$path, "effect_justification.other_sources")
})

test_that("each effect field is the effect, an assumed value or a count of the design", {
  role <- function(ep, id) effect_role(field(ep, id)[[1]])
  expect_identical(role("E18", "means"), "tested")
  expect_identical(role("E18", "sd"), "assumed")
  expect_identical(role("E33", "difference"), "tested")
  expect_identical(role("E33", "sd_participant"), "assumed")
  expect_identical(role("E33", "items"), "design")
  # A label's explanation after the colon names the SD it is divided by,
  # but d is the effect.
  expect_identical(role("E2", "d"), "tested")
})

test_that("safeguard power is offered in the conversion help only where the screen has it", {
  expect_match(field("E1", "conv_from")[[1]]$help, "safeguard power below", fixed = TRUE)
  for (ep in c("E5", "E7", "E8", "E18", "E21", "E22", "E23", "E54", "E55", "E56")) {
    f <- field(ep, "conv_from")
    if (length(f)) expect_no_match(f[[1]]$help, "safeguard", fixed = TRUE, label = ep)
  }
})

test_that("the write-up separates the effect tested from the other values assumed and their source", {
  skip_without_run()
  fields <- form_fields(form_groups(forms, "E18"))
  values <- modifyList(form_examples$E18, list(goal = "power", n = "60", alpha = "0.05", metric = "raw", test_version = "anova_f",
    just_type = "pilot_study", just_source = "the means from our pilot", just_other = "the SD from the test's norms"))
  calc <- run_calculation(build_spec(forms, "E18", fields, values), run, seed = forms$default_seed)
  expect_identical(calc$status, "ok")
  expect_identical(calc$spec$effect_justification$other_sources, "the SD from the test's norms")
  text <- writeup_text(forms$forms$E18, calc$spec, calc$result, fields, values)
  expect_match(text[["short"]], "The effect tested, group means = ", fixed = TRUE)
  expect_match(text[["short"]], "The other values assumed were SD = ", fixed = TRUE)
  expect_match(text[["short"]], "from “the SD from the test's norms”", fixed = TRUE)
  expect_no_match(text[["short"]], "The effect size, ", fixed = TRUE)
})

test_that("the write-up leaves the design's counts out of the effect sentence", {
  skip_without_run()
  fields <- form_fields(form_groups(forms, "E33"))
  values <- modifyList(form_examples$E33, list(goal = "power", n = "40", alpha = "0.05"))
  effect <- writeup_effect(fields, values, "tested")
  assumed <- writeup_effect(fields, values, "assumed")
  expect_no_match(paste(effect, assumed), "number of items", fixed = TRUE)
  expect_match(assumed, "SD of participants' averages", fixed = TRUE)
  expect_no_match(effect, "SD", fixed = TRUE)
})
