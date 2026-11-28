# "How you'll give the effect" starts with nothing chosen on every screen
# (input-screen review of 28 November 2026), as the ANOVAs' route question
# does: a preselected way in steers the researcher to numbers they may not
# have.

route_ids <- c("effect_units", "interaction_metric", "x_effects", "r2_given", "manova_metric", "chisq_metric")

test_that("no screen preselects how the effect is given", {
  for (ep in names(forms$forms)) {
    for (f in form_fields(form_groups(forms, ep))) {
      if (f$id %in% route_ids && identical(f$type, "select")) {
        expect_null(f[["default"]], label = paste(ep, f$id))
        expect_true(isTRUE(f$required), label = paste(ep, f$id, "required"))
      }
    }
  }
})

test_that("with no way in chosen, the screen asks for one and shows no effect boxes", {
  fields <- form_fields(form_groups(forms, "E2"))
  values <- form_examples$E2
  values$effect_units <- ""
  applies <- Filter(function(f) field_applies(f, values), fields)
  expect_false("d" %in% vapply(applies, `[[`, "", "id"))
  expect_true(length(form_problems(applies, values)) > 0)
})
