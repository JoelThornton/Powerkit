test_that("joint power never replaces a different independent-group test", {
  spec <- list(design = "basic_test", template = "independent_t",
    population = list(metric = "standardised", d = 0.5), options = list(),
    target_test = list(method = "student_t", alpha = 0.05))
  expect_null(joint_power_problem(list(spec, spec)))
  for (method in c("welch_t", "mann_whitney", "brunner_munzel", "minimum_effect", "bayes_factor")) {
    other <- spec
    other$target_test$method <- method
    expect_match(joint_power_problem(list(spec, other)), "Student's pooled-variance t-test only", fixed = TRUE)
  }
})
