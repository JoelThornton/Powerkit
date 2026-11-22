# Running a card's smallest-detectable-effect goal from its screen, for
# test-smallest-effect-*.R.

smallest_effect_values <- function(ep, extra = list()) {
  values <- modifyList(form_examples[[ep]], list(goal = "sensitivity", n = "120", power = "0.8", alpha = "0.05"))
  modifyList(values, extra)
}

smallest_effect_run <- function(ep, extra = list()) {
  fields <- form_fields(form_groups(forms, ep))
  values <- smallest_effect_values(ep, extra)
  problems <- form_problems(fields, values)
  expect_length(problems, 0)
  spec <- build_spec(forms, ep, fields, values)
  calc <- run_calculation(spec, seed = forms$default_seed)
  expect_identical(calc$status, "ok", label = ep)
  list(spec = spec, result = calc$result, values = values, fields = fields)
}
