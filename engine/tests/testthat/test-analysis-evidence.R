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
})
