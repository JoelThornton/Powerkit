test_that("prediction and decision direction are explicitly separated", {
  group <- direction_group(forms$tool_defaults$pwr)
  expect_match(direction_note, "still use a two-sided test", fixed = TRUE)
  expect_match(group$fields[[1]]$choices$two_sided, "directional prediction", fixed = TRUE)
  html <- as.character(planning_decision_ui(forms$forms$E2))
  for (word in c("minimum-effect", "equivalence", "assurance", "overall fit")) expect_match(html, word, fixed = TRUE)
})

test_that("accuracy presets change only replication controls and old answers retain their settings", {
  fields <- form_fields(form_groups(forms, "E2"))
  old <- form_examples$E2
  old$calc_method <- "exact"
  baseline <- build_spec(forms, "E2", fields, old)
  for (preset in c(quick = 400L, standard = 1000L, precise = 10000L)) {
    key <- names(c(quick = 400L, standard = 1000L, precise = 10000L))[match(preset, c(400L, 1000L, 10000L))]
    changed <- build_spec(forms, "E2", fields, c(old, list(simulation_accuracy = key)))
    expect_equal(changed$options$nrep, preset)
    expect_identical(changed$population, baseline$population)
  }
  expect_null(baseline$options$nrep)
  custom <- build_spec(forms, "E2", fields, c(old, list(simulation_accuracy = "custom", nrep = "2345")))
  expect_equal(custom$options$nrep, 2345L)
  html <- as.character(group_ui_build(tree, simulation_accuracy_group(forms, "E2")[[1]], list(), 1))
  expect_match(html, "do not resolve uncertainty", fixed = TRUE)
  expect_match(html, "Failures can reduce", fixed = TRUE)
})

test_that("unfamiliar numeric families have meanings, illustrations, sources and an honest unknown route", {
  for (f in list(list(id = "sd", label = "SD", type = "number"),
    list(id = "icc", label = "Intraclass correlation", type = "number"),
    list(id = "rel_X", label = "Reliability", type = "number"),
    list(id = "alpha", label = "Significance level", type = "number"))) {
    guide <- input_guide(f)
    expect_true(all(nzchar(unlist(guide))))
    html <- as.character(input_guide_ui(f))
    expect_match(html, "not a recommended value", fixed = TRUE)
    expect_match(html, "Do not replace an unknown value with 0", fixed = TRUE)
  }
})

test_that("assumption sources and named nuisance alternatives survive draft and calculation snapshots", {
  fields <- form_fields(form_groups(forms, "E2"))
  v <- modifyList(form_examples$E2, list(method = "student_t", calc_method = "exact", goal = "power", n = "120",
    research_question = "Does training improve recall?"))
  record <- list(field = "d", value = "0.4", status = "assumed", source = "A sensitivity assumption, not a measured effect")
  library <- list(version = 1, assumptions = list(record), alternatives = list(
    list(name = "Equal groups", values = list(allocation_ratio = "1"), assumptions = list(record)),
    list(name = "Twice as many in group 2", values = list(allocation_ratio = "2"), assumptions = list(record))))
  v$scenario_library <- jsonlite::toJSON(library, auto_unbox = TRUE)
  expect_equal(length(read_scenario_library(v$scenario_library, fields)$alternatives), 2)
  path <- tempfile()
  on.exit(unlink(path))
  route <- list(app = "routing-prototype", endpoint = "E2", route = "know", form_values = v, form_k = 2L)
  write_draft(route, path)
  expect_identical(restore_draft(read_draft_record(path), tree, forms)$form_values$scenario_library, as.character(v$scenario_library))
  run <- engine_function("run_spec")
  skip_if(is.null(run))
  calc <- run_calculation(build_spec(forms, "E2", fields, v))
  calc$route <- route
  doc <- paste(planning_document(tree, forms, calc), collapse = "\n")
  for (word in c(v$research_question, "Equal groups", "assumed", calc$result$provenance$spec_hash, "not register a preregistration")) expect_match(doc, word, fixed = TRUE)
  comparison <- compare_named_alternatives(forms, "E2", fields, v)
  expect_equal(nrow(comparison), 2)
  expect_false(identical(comparison$value[1], comparison$value[2]))
  altered <- v
  altered$d <- "0.6"
  expect_match(paste(assumption_record_lines(altered, fields), collapse = " "), "source needs review", fixed = TRUE)
  calc$route$form_values$source_stale <- TRUE
  expect_error(planning_document(tree, forms, calc), "current source reasoning")
  bad <- library
  bad$assumptions[[1]]$status <- "unknown"
  expect_error(read_scenario_library(jsonlite::toJSON(bad, auto_unbox = TRUE), fields), "invalid field")
  bad$alternatives <- list("unsupported")
  expect_error(read_scenario_library(jsonlite::toJSON(bad, auto_unbox = TRUE), fields), "not supported")
})

test_that("planning recruitment keeps the counted units instead of relabelling pairs as participants", {
  result <- list(recruitment = list(n_analysed = 40, n_recruit = 50,
    groups_analysed = 40, groups_recruit = 50, attrition = 0.2))
  lines <- paste(planning_recruitment_lines(result, list(unit = "pairs")), collapse = " ")
  expect_match(lines, "Analysed: 40 pairs. Recruitment target: 50 pairs.", fixed = TRUE)
  expect_no_match(lines, "50 participants", fixed = TRUE)
  expect_match(planning_recruitment_lines(list(recruitment = NA), list(unit = "pairs")), "does not establish", fixed = TRUE)
})
