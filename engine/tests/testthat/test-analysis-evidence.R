test_that("historical ordinary-test evidence excludes changed populations and decision rules", {
  spec <- example_spec("one_sample_t")
  expect_equal(analysis_evidence(spec)$record_id, "one-sample-t")
  spec$population$tau <- 0.1
  expect_equal(analysis_evidence(spec)$record_id, "unlinked")
  spec$population$tau <- 0
  expect_equal(analysis_evidence(spec)$record_id, "one-sample-t")
  spec$population$tau <- NULL
  spec$effect_justification$small_telescopes <- list(n = 30, alpha = 0.05)
  expect_equal(analysis_evidence(spec)$record_id, "unlinked")
})

test_that("case evidence follows the test version rather than the design card", {
  spec <- example_spec("independent_t")
  spec$target_test$method <- "student_t"
  spec$goal <- list(type = "power", n = 128)
  student <- analysis_evidence(spec, "exact")
  expect_equal(student$record_id, "independent-student")
  expect_equal(student$categories$package_agreement$status, "recorded")
  expect_equal(student$categories$published$status, "outside_scope")
  for (method in c("welch_t", "mann_whitney", "brunner_munzel", "bayes_factor")) {
    spec$target_test$method <- method
    expect_equal(analysis_evidence(spec)$record_id, "unlinked", label = method)
  }
  spec <- example_spec("correlation")
  spec$target_test$method <- "pearson"
  expect_equal(analysis_evidence(spec)$record_id, "pearson")
  spec$target_test$method <- "spearman"
  expect_equal(analysis_evidence(spec)$record_id, "unlinked")
})

test_that("conditional indirect difference evidence cannot bleed across models and variable types", {
  spec <- list(design = "moderated_mediation", template = "process_58",
    variables = list(X = list(type = "continuous"), W = list(type = "continuous"), M = list(type = "continuous")),
    target_test = list(method = "monte_carlo_ci", effect = "conditional_indirect_difference"),
    population = list(), goal = list(type = "power"))
  evidence <- analysis_evidence(spec)
  expect_equal(evidence$categories$full_validation$status, "scoped_only")
  expect_match(evidence$scope, "500", fixed = TRUE)
  spec$template <- "process_59"
  expect_equal(analysis_evidence(spec)$record_id, "unlinked")
  spec$template <- "process_58"
  spec$variables$X$type <- "binary"
  expect_equal(analysis_evidence(spec)$record_id, "unlinked")
  spec$variables$X$type <- "continuous"
  spec$variables$M2 <- list(type = "continuous")
  expect_equal(analysis_evidence(spec)$record_id, "unlinked")
})

test_that("every recorded status links a real source and scopes its evidence", {
  registry <- evidence_registry()
  for (record in registry$records) {
    expect_true(nzchar(record$scope), label = record$id)
    for (item in record$categories) {
      expect_true(item$status %in% c("recorded", "scoped_only", "pending"))
      expect_true(length(item$sources) > 0)
      expect_true(all(unlist(item$sources) %in% names(registry$sources)))
    }
  }
  expect_match(registry$sha256, "^[a-f0-9]{64}$")
  expect_match(paste(registry$limits, collapse = " "), "skipped", fixed = TRUE)
})

test_that("results and saved records preserve the evidence captured at calculation time", {
  spec <- example_spec("independent_t")
  spec$target_test$method <- "student_t"
  spec$goal <- list(type = "power", n = 128)
  result <- run_spec(spec)
  captured <- result$provenance$evidence
  expect_equal(captured$record_id, "independent-student")
  project <- read_project(write_project(spec, result))
  expect_equal(project$result$provenance$evidence$registry_sha256, captured$registry_sha256)
  expect_equal(saved_result(project)$provenance$evidence, captured)
  expect_match(export_script(spec, result), captured$registry_sha256, fixed = TRUE)
  expect_match(paste(evidence_record_text(NULL), collapse = " "), "No supported variant-level")
  unlinked <- analysis_evidence(list(design = "basic_test", template = "independent_t", target_test = list(method = "welch_t")))
  encoded <- jsonlite::fromJSON(jsonlite::toJSON(encode_value(unlinked), auto_unbox = TRUE, null = "null"), simplifyVector = FALSE)
  expect_identical(decode_value(encoded), unlinked)
})
test_that("zero-inflated evidence stays scoped and does not turn a skipped publication into a pass", {
  spec <- list(design = "poisson_regression", template = "single_predictor_count",
    variables = list(X = list(type = "continuous")), population = list(),
    target_test = list(method = "zero_inflated_poisson", effect = "rate_ratio"),
    goal = list(type = "power", n = 300))
  record <- analysis_evidence(spec)
  expect_equal(record$categories$independent$status, "scoped_only")
  expect_equal(record$categories$published$status, "pending")
  expect_match(record$scope, "recorded source revision", fixed = TRUE)
  spec$target_test$method <- "zero_inflated_negative_binomial"
  spec$target_test$effect <- "rate_and_zero"
  expect_equal(analysis_evidence(spec)$record_id, "unlinked")
  spec$target_test$effect <- "rate_ratio"
  spec$variables$X$type <- "binary"
  expect_equal(analysis_evidence(spec)$record_id, "unlinked")
})

test_that("corrected-count evidence preserves its case scope and publication gap", {
  for (name in c("two_proportions_corrected", "chi_square_independence_corrected")) {
    spec <- example_spec(name)
    evidence <- analysis_evidence(spec, "simulation")
    expect_equal(evidence$categories$independent$status, "scoped_only")
    expect_equal(evidence$categories$published$status, "pending")
    expect_match(evidence$scope, "Only these cases/revisions", fixed = TRUE)
    spec$goal <- list(type = "sample_size", power = .8)
    expect_equal(analysis_evidence(spec)$categories$full_validation$status, "outside_scope")
  }
})
