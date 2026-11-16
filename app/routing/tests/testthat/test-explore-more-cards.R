# "If the effect were different" and "What if the true effect is smaller?"
# on the formula cards whose effect is one number (16 November 2026). Each
# card's panels set the effect in the spec, call the engine, and at the
# plan's own effect give the plan's own power.

explore_case <- function(ep, extra = list()) {
  fields <- form_fields(form_groups(forms, ep))
  values <- modifyList(form_examples[[ep]], c(list(goal = "power", n = "120", alpha = "0.05"), extra))
  expect_length(form_problems(fields, values), 0)
  spec <- build_spec(forms, ep, fields, values)
  calc <- run_calculation(spec, seed = forms$default_seed)
  expect_identical(calc$status, "ok", label = ep)
  calc
}

explore_cases <- list(
  E24 = list(extra = list(), weaker = 0.12, stronger = 0.2),
  E27 = list(extra = list(), weaker = 1.3, stronger = 2),
  E28 = list(extra = list(), weaker = 0.9, stronger = 0.7),
  E5 = list(extra = list(), weaker = NULL, stronger = NULL),
  E25 = list(extra = list(), weaker = 0.6, stronger = 0.7),
  E49 = list(extra = list(), weaker = 0.35, stronger = 0.6),
  E9 = list(extra = list(interaction_metric = "r2_change", r2_change = "0.04", r2_main = "0.1"), weaker = 0.02, stronger = 0.08),
  E18 = list(extra = list(metric = "eta_squared", eta_squared = "0.06", means = "", sd = ""), weaker = 0.03, stronger = 0.1)
)

test_that("each formula card explores its own effect, and the plan's effect gives the plan's power", {
  for (ep in names(explore_cases)) {
    case <- explore_cases[[ep]]
    calc <- explore_case(ep, case$extra)
    e <- explore_effect(calc$spec)
    expect_false(is.null(e), label = ep)
    planned <- explore_planned(calc$spec, calc$result, e)
    expect_true(planned >= e$min && planned <= e$max, label = ep)
    html <- as.character(explore_ui(calc$spec, calc$result))
    expect_match(html, e$label, fixed = TRUE, label = ep)
    df <- explore_curve(calc$spec, calc$result, planned, seed = forms$default_seed)
    expect_false(anyNA(df$power), label = ep)
    at_plan <- df$power[df$n == 120]
    if (length(at_plan)) expect_equal(at_plan, calc$result$curve$power[1], tolerance = 1e-8, label = ep)
    # Power grows with the sample size (an exact test's saw-tooth aside).
    if (!ep %in% c("E25")) expect_true(all(diff(df$power) >= -1e-8), label = ep)
  }
})

test_that("the smaller-effect panel compares a weaker and a stronger effect, in the effect's own terms", {
  for (ep in setdiff(names(explore_cases), "E5")) {
    case <- explore_cases[[ep]]
    calc <- explore_case(ep, case$extra)
    html <- as.character(scenarios_ui(calc$spec, calc$result))
    expect_match(html, "Conservative", fixed = TRUE, label = ep)
    curves <- scenario_curves(calc$spec, calc$result, case$weaker, case$stronger, n = 120, seed = forms$default_seed)
    expect_setequal(unique(curves$scenario), c("conservative", "expected", "optimistic"))
    at <- function(k) curves$power[curves$scenario == k & curves$n == 120]
    expect_lt(at("conservative"), at("expected"), label = ep)
    expect_gt(at("optimistic"), at("expected"), label = ep)
    n <- scenario_n(calc$spec, calc$result, case$weaker, case$stronger, seed = forms$default_seed)
    expect_gt(n[["conservative"]], n[["optimistic"]], label = ep)
  }
})

test_that("a ratio's weaker effect is closer to 1, and a difference's closer to the value it is compared with", {
  calc <- explore_case("E27")
  expect_match(as.character(scenarios_ui(calc$spec, calc$result)), "closer to 1,", fixed = TRUE)
  expect_identical(explore_effect(calc$spec)$min, 1.05)
  calc <- explore_case("E28")
  expect_identical(explore_effect(calc$spec)$max, 0.95)
  calc <- explore_case("E25")
  expect_match(as.character(scenarios_ui(calc$spec, calc$result)), "closer to 0.5, no difference", fixed = TRUE)
  calc <- explore_case("E2")
  expect_match(as.character(scenarios_ui(calc$spec, calc$result)), "closer to zero", fixed = TRUE)
})

test_that("an effect converted from Cohen's f-squared is explored on the R-squared scale", {
  calc <- explore_case("E24", list(r2_given = "f2", f2 = "0.0588", r2_full = ""))
  e <- explore_effect(calc$spec)
  expect_identical(e$field, "r2_full")
  planned <- explore_planned(calc$spec, calc$result, e)
  expect_equal(planned, 0.15, tolerance = 1e-3)
  # The same curve as the plan entered as R-squared (0.15 over 0.10).
  df <- explore_curve(calc$spec, calc$result, planned, seed = forms$default_seed)
  direct <- explore_case("E24")
  df2 <- explore_curve(direct$spec, direct$result, 0.15, seed = forms$default_seed)
  shared <- intersect(df$n, df2$n)
  expect_gt(length(shared), 0)
  expect_equal(df$power[match(shared, df$n)], df2$power[match(shared, df2$n)], tolerance = 1e-3)
})

test_that("simulated and Bayes factor versions of these cards have no panels", {
  calc <- list(design = "poisson_regression", template = "single_predictor_count", population = list(rate_ratio = 0.8),
    target_test = list(method = "negative_binomial"), options = list())
  expect_null(explore_effect(calc))
  expect_null(explore_effect(list(design = "basic_test", template = "one_proportion", population = list(p = 0.6, p0 = 0.5),
    target_test = list(method = "bayes_factor"), options = list())))
  expect_null(explore_effect(list(design = "multiple_regression", template = "single_coefficient", population = list(partial_r2 = 0.05),
    target_test = list(method = "ols_hc3"), options = list())))
})
