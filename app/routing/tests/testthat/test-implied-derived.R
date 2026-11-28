# Quantities the screen's numbers give, shown as they are typed (input-
# screen review of 28 November 2026, I-17 to I-23). The engine works them
# out (implied_effect_size()); the app only shows them.

test_that("the screens whose numbers give another quantity show the line", {
  shown <- function(ep) implied_effect_shown(form_fields(form_groups(forms, ep)), forms$forms[[ep]]$base)
  for (ep in c("E10", "E11", "E12", "E16", "E5", "E6", "E48", "E59", "E34", "E47")) expect_true(shown(ep), label = ep)
  expect_false(shown("E4"))
})

test_that("the line names each quantity with its value", {
  implied <- list(kind = "derived", items = list(list(name = "indirect effect through M1", value = 0.12),
    list(name = "total indirect effect", value = 0.045)))
  text <- as.character(implied_effect_text(implied, list()))
  expect_match(text, "From these numbers: ", fixed = TRUE)
  expect_match(text, "indirect effect through M1 = 0.12; total indirect effect = 0.045.", fixed = TRUE)
})

test_that("the engine's quantity reaches the screen for two proportions", {
  implied <- engine_function("implied_effect_size", file.path(repo_dir, "engine"))
  skip_if(is.null(implied), "powerkit's engine isn't available here")
  fields <- form_fields(form_groups(forms, "E5"))
  spec <- build_spec(forms, "E5", fields, form_examples$E5)
  text <- as.character(implied_effect_text(implied(spec), form_examples$E5))
  expect_match(text, "odds ratio (group 2 against group 1) = ", fixed = TRUE)
  expect_match(text, "Cohen's h = ", fixed = TRUE)
})
