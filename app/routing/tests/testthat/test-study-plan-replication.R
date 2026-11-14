# Replication plans (R/study-plan-replication.R): a study plan that holds a
# replication's notes and planner fields, saved, reopened and compared like
# any study plan, and opening the Labs planner's old files.

rep_engine <- function(name) engine_function(name, file.path(repo_dir, "engine"))

test_that("a new replication plan is named as one and holds an empty record", {
  plan <- new_replication_plan(now = as.POSIXct("2026-11-14 10:00:00", tz = "UTC"))
  expect_identical(plan$name, "Replication plan, 14 Nov 2026")
  expect_true(plan_is_replication(plan))
  expect_true(plan_has_content(plan))
  expect_identical(plan$replication$format, "powerkit-replication-plan")
  expect_length(plan$replication$fields, 0)
  expect_false(plan_is_replication(new_plan("Plain")))
})

test_that("the record keeps known fields only, as text, and blanks are left out", {
  r <- replication_record(list(rep_study = "Smith (2020)", rep_effect = 0.45, labs_goals = "  ", nonsense = "x"), endpoint = "E2")
  expect_identical(names(r$fields), c("rep_effect", "rep_study"))
  expect_identical(r$fields$rep_effect, "0.45")
  expect_identical(r$endpoint, "E2")
  expect_null(replication_record(endpoint = "not an id")$endpoint)
  # The screen gets every field, with the planner's starting values.
  v <- replication_values(r)
  expect_identical(v$rep_alpha, "0.05")
  expect_identical(v$labs_goals, "")
  expect_setequal(names(v), replication_plan_field_ids)
})

test_that("changing the fields marks the plan changed only when they change", {
  t0 <- as.POSIXct("2026-11-14 10:00:00", tz = "UTC")
  plan <- new_replication_plan(now = t0)
  same <- plan_set_replication(plan, fields = list(), now = t0 + 60)
  expect_identical(same$changed, t0)
  edited <- plan_set_replication(plan, fields = list(rep_study = "Smith (2020)"), now = t0 + 60)
  expect_identical(edited$changed, t0 + 60)
  expect_false(identical(plan_content(plan), plan_content(edited)))
  # Setting the original's card keeps the fields.
  carded <- plan_set_replication(edited, endpoint = "E16", now = t0 + 120)
  expect_identical(carded$replication$endpoint, "E16")
  expect_identical(carded$replication$fields$rep_study, "Smith (2020)")
})

test_that("a replication plan with no analysis saves as the planner's file, which opens as the same plan", {
  plan <- plan_set_replication(new_replication_plan(), fields = list(rep_study = "Smith (2020)", rep_effect = "0.45", labs_finding = "Priming slows walking"))
  text <- plan_to_text(plan, write = rep_engine("write_study_plan"))
  raw <- jsonlite::parse_json(text)
  # The version before this one opens it in the Labs planner, from these.
  expect_identical(raw$app, "powerkit-replication-planner")
  expect_identical(raw$fields$rep_study, "Smith (2020)")
  expect_identical(raw$study_plan$id, plan$id)
  back <- plan_from_text(tree, text, read = rep_engine("read_study_plan"))
  expect_identical(back$id, plan$id)
  expect_identical(back$name, plan$name)
  expect_identical(back$replication$fields$labs_finding, "Priming slows walking")
  expect_identical(plan_content(back), plan_content(plan))
  expect_identical(back$saved_how, "file")
  expect_true(nzchar(plan_browser_record(plan, write = rep_engine("write_study_plan"))))
})

test_that("a file from the Labs replication planner opens as a new replication plan", {
  file <- tempfile(fileext = ".json")
  jsonlite::write_json(replication_file(list(rep_study = "Old study", rep_effect = "0.3", rep_n = "80", rep_design = "paired"), "0.65.0"), file, auto_unbox = TRUE)
  plan <- plan_from_text(tree, paste(readLines(file), collapse = "\n"), now = as.POSIXct("2026-11-14 10:00:00", tz = "UTC"))
  expect_match(plan$name, "^Replication plan, ")
  expect_true(plan_is_replication(plan))
  expect_identical(plan$replication$fields$rep_design, "paired")
  expect_length(plan$entries, 0)
})

test_that("a replication plan with its original's analysis keeps the record in the study-plan file", {
  skip_if(is.null(rep_engine("run_spec")), "no engine")
  values <- form_examples[["E2"]]
  spec <- build_spec(forms, "E2", form_fields(form_groups(forms, "E2")), values)
  calc <- run_calculation(spec, rep_engine("run_spec"), seed = 3L)
  calc$route <- list(app = "routing-prototype", route = "choose", endpoint = "E2", came_from = "node", ctx = list(), history = list(), form_k = 2L, form_values = values)
  plan <- plan_set_replication(new_replication_plan(), fields = list(rep_study = "Smith (2020)"), endpoint = "E2")
  plan <- plan_add_entry(plan, plan_entry(tree, "E2", calc, calc$route))
  text <- plan_to_text(plan, write = rep_engine("write_study_plan"))
  expect_identical(jsonlite::parse_json(text)$format, "powerkit-study-plan")
  back <- plan_from_text(tree, text, read = rep_engine("read_study_plan"))
  expect_identical(back$replication$endpoint, "E2")
  expect_identical(back$replication$fields$rep_study, "Smith (2020)")
  expect_identical(back$entries[[1]]$role, "primary")
  expect_identical(plan_content(back), plan_content(plan))
})

test_that("on a replication's card, each effect field says it takes the original's effect", {
  plain <- form_groups(forms, "E2", 2L, list())
  groups <- replication_effect_labels(plain)
  fields <- unlist(lapply(groups, `[[`, "fields"), recursive = FALSE)
  before <- unlist(lapply(plain, `[[`, "fields"), recursive = FALSE)
  effects <- which(vapply(fields, function(f) isTRUE(f$effect), logical(1)))
  expect_gt(length(effects), 0)
  for (i in effects) expect_match(fields[[i]]$label, ", as the original study reported it$")
  # Every other field keeps its label.
  for (i in setdiff(seq_along(fields), effects)) expect_identical(fields[[i]]$label, before[[i]]$label)
  # Labelled once, however often it is applied.
  twice <- replication_effect_labels(groups)
  expect_identical(twice, groups)
})

test_that("the plan's page holds the workspace, and says where the original's analysis stands", {
  plan <- new_replication_plan("Smith replication")
  page <- as.character(plan_page_ui(plan))
  expect_match(page, "Replication plan", fixed = TRUE)
  expect_no_match(page, "Add an analysis", fixed = TRUE)
  expect_match(page, "download_plan_bundle", fixed = TRUE)
  html <- as.character(replication_workspace_ui(tree))
  for (id in c("rep_section", "labs_finding", "rep_effect", "rep_card_status")) expect_match(html, id, fixed = TRUE)
  expect_match(as.character(replication_card_status_ui(tree, plan)), "rep_find_design", fixed = TRUE)
  carded <- plan_set_replication(plan, endpoint = "E2")
  status <- as.character(replication_card_status_ui(tree, carded))
  expect_match(status, tree$endpoints$E2$plain_name, fixed = TRUE)
  expect_match(status, "Plan it on its card", fixed = TRUE)
  expect_match(as.character(plans_list_ui(setNames(list(plan), plan$id))), "plans_new_replication", fixed = TRUE)
})

test_that("a replication plan's write-up comes from its record, and Download everything includes it", {
  plan <- plan_set_replication(new_replication_plan("Smith replication"), fields = list(labs_finding = "Priming slows walking", rep_study = "Smith (2020)"))
  report <- paste(replication_plan_report(plan, tree, forms, engine = function(name) NULL), collapse = "\n")
  expect_match(report, "Smith replication", fixed = TRUE)
  expect_match(report, "Priming slows walking", fixed = TRUE)
  expect_match(report, "Written with powerkit's replication plan", fixed = TRUE)
  skip_if(is.null(rep_engine("write_study_plan")), "no engine")
  zip <- tempfile(fileext = ".zip")
  write_plan_bundle(plan, zip, tree, forms, engine = rep_engine)
  files <- utils::unzip(zip, list = TRUE)$Name
  expect_true(any(grepl("replication-plan\\.md$", files)))
  expect_true(any(grepl("\\.powerkit\\.json$", files)))
})
