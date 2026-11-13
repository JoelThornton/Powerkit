# "Plan my whole study" joins a study plan: the guided plan's record kept
# inside the plan, roles from the guided plan, the whole-study result on
# the plan's page, and old guided-plan files opening as study plans.

guided_engine <- function(name) engine_function(name, file.path(repo_dir, "engine"))
guided_ids <- vapply(tree$guided$analyses, `[[`, "", "id")

guided_state <- function() {
  list(route = "plan", start = list(aim = "plan"), ctx = list(), history = list(),
    answers = list(), ticked = guided_ids[1:2], primary = guided_ids[2], asks = list(), rule = "each",
    plan_values = list(), plan_shared = list(), plan_results = list(), ws_values = list(n = "200"),
    ws_names = list(), ws_spec = NULL, ws_result = NULL)
}

guided_entry <- function(id, n = 100) {
  list(label = paste("Analysis", id), n = n, plan_id = id,
    route = list(endpoint = "E2", guided_analysis = id))
}

ws_calc <- function(rule = "all") {
  list(status = "ok", result = list(n = 128, alpha = 0.05, claim = rule,
    joint = if (rule != "each") list(rule = rule, power = 0.74, lower = 0.71, upper = 0.77),
    analyses = data.frame(label = c("Total effect", "Indirect effect"), role = c("main", "extra"),
      power = c(0.81, 0.62), lower = c(0.78, 0.59), upper = c(0.84, 0.65)),
    provenance = list(nrep = 1000, spec_hash = "abc")))
}

test_that("the guided record is the one Save this plan writes, with the whole-study summary", {
  state <- guided_state()
  record <- guided_plan_record(state, now = as.POSIXct("2026-11-13 10:00:00", tz = "UTC"))
  expect_identical(record$format, "powerkit-guided-plan")
  expect_identical(record$plan$primary, state$primary)
  expect_true("ws_result" %in% guided_plan_fields)
  file <- tempfile(fileext = ".powerkit.json")
  write_guided_plan(state, file)
  expect_identical(read_guided_plan_record(file)$plan$ticked, as.list(state$ticked))
})

test_that("a whole-study run is summarised in words the plan page can show", {
  s <- whole_study_summary(ws_calc("all"), now = as.POSIXct("2026-11-13 10:00:00", tz = "UTC"))
  expect_identical(s$n, 128)
  expect_identical(s$joint$power, 0.74)
  expect_match(whole_study_summary_text(s), "74% chance that every main analysis is significant", fixed = TRUE)
  expect_match(whole_study_summary_text(s), "N = 128", fixed = TRUE)
  each <- whole_study_summary(ws_calc("each"))
  expect_null(each$joint)
  expect_match(whole_study_summary_text(each), "Total effect 81%", fixed = TRUE)
  expect_null(whole_study_summary(list(status = "error", message = "no")))
})

test_that("setting the guided record gives the guided analyses their roles, and marks the plan changed only on a change", {
  t0 <- as.POSIXct("2026-11-13 10:00:00", tz = "UTC")
  plan <- plan_with(list(guided_entry(guided_ids[1]), guided_entry(guided_ids[2]), list(label = "Other", n = 50)))
  plan$changed <- t0
  state <- guided_state()
  record <- guided_plan_record(state, now = t0)
  plan <- plan_set_guided(plan, record, state$primary, now = t0 + 60)
  roles <- vapply(plan$entries, `[[`, "", "role")
  expect_identical(roles[1:2], c("secondary", "primary"))
  expect_identical(plan$changed, t0 + 60)
  # The same record again (saved at another time) changes nothing.
  again <- plan_set_guided(plan, guided_plan_record(state, now = t0 + 300), state$primary, now = t0 + 600)
  expect_identical(again$changed, t0 + 60)
  # A check the researcher set on a guided analysis stays a check.
  plan <- plan_edit_entry(plan, plan$entries[[1]]$key, role = "check")
  plan <- plan_set_guided(plan, record, state$primary, now = t0 + 900)
  expect_identical(plan$entries[[1]]$role, "check")
  # The analysis that isn't from the guided plan keeps its role.
  expect_identical(plan$entries[[3]]$role, "secondary")
})

test_that("a plan's guided record changes what counts as the same plan", {
  a <- plan_with(list(guided_entry(guided_ids[1])))
  b <- a
  b$guided <- guided_plan_record(guided_state())
  expect_false(identical(plan_content(a), plan_content(b)))
  c <- b
  c$guided$saved_at <- "another time"
  expect_identical(plan_content(b), plan_content(c))
})

test_that("the plan page shows the guided plan, its last whole-study result and Open the guided plan", {
  plan <- plan_with(list(guided_entry(guided_ids[1])))
  expect_no_match(as.character(plan_page_ui(plan)), "plan_open_guided", fixed = TRUE)
  state <- guided_state()
  state$ws_result <- whole_study_summary(ws_calc("all"), now = as.POSIXct("2026-11-13 10:00:00", tz = "UTC"))
  plan$guided <- guided_plan_record(state)
  html <- as.character(plan_page_ui(plan))
  expect_match(html, "plan_open_guided", fixed = TRUE)
  expect_match(html, "74% chance that every main analysis is significant", fixed = TRUE)
  expect_match(html, "13 Nov 2026", fixed = TRUE)
  # A guided plan with no analyses calculated yet still has a page worth showing.
  empty <- new_plan("Whole-study plan, 13 Nov 2026")
  empty$guided <- guided_plan_record(guided_state())
  html <- as.character(plan_page_ui(empty))
  expect_match(html, "plan_open_guided", fixed = TRUE)
  expect_match(html, "download_study_plan", fixed = TRUE)
})

test_that("a plan with a guided record round-trips through its file, its browser copy and an old version", {
  skip_if(is.null(guided_engine("write_study_plan")), "no engine")
  plan <- new_plan("Whole-study plan, 13 Nov 2026")
  state <- guided_state()
  plan$guided <- guided_plan_record(state)
  # No analyses yet: saved as a guided-plan file carrying the plan's name,
  # which the version before this one opens as a guided plan.
  text <- plan_to_text(plan, write = guided_engine("write_study_plan"))
  expect_true(nzchar(text))
  raw <- jsonlite::parse_json(text)
  expect_identical(raw$format, "powerkit-guided-plan")
  expect_identical(raw$study_plan$id, plan$id)
  back <- plan_from_text(tree, text, read = guided_engine("read_study_plan"))
  expect_identical(back$id, plan$id)
  expect_identical(back$name, plan$name)
  expect_identical(unlist(back$guided$plan$primary), state$primary)
  expect_true(nzchar(plan_browser_record(plan, write = guided_engine("write_study_plan"))))
})

test_that("an old guided-plan file opens as a new whole-study plan", {
  file <- tempfile(fileext = ".powerkit.json")
  write_guided_plan(guided_state(), file)
  text <- paste(readLines(file), collapse = "\n")
  plan <- plan_from_text(tree, text, read = guided_engine("read_study_plan"), now = as.POSIXct("2026-11-14 09:00:00", tz = "UTC"))
  expect_match(plan$name, "^Whole-study plan, ")
  expect_length(plan$entries, 0)
  expect_identical(plan$guided$format, "powerkit-guided-plan")
  expect_identical(plan$saved_how, "file")
})

test_that("a guided analysis read back from a plan file is still the guided plan's analysis", {
  project <- list(route = list(endpoint = "E2", guided_analysis = guided_ids[1]), result = list(goal_type = "sample_size"), spec = list())
  expect_identical(plan_entry_from_project(tree, project)$plan_id, guided_ids[1])
  expect_null(plan_entry_from_project(tree, list(route = list(endpoint = "E2"), result = list(), spec = list()))$plan_id)
})

test_that("Save this plan on the guided screens saves the whole study plan", {
  expect_match(as.character(guided_plan_save_ui(2, "Whole-study plan, 13 Nov 2026")), "Whole-study plan, 13 Nov 2026", fixed = TRUE)
  expect_match(as.character(guided_plan_save_ui(0, "Whole-study plan, 13 Nov 2026")), "plan_view", fixed = TRUE)
})

test_that("a guided plan read back from its file is the same plan as the one in the browser", {
  state <- guided_state()
  state$plan_results <- list(a = list(endpoint = "E2", goal = "sample_size", n = 264))
  plan <- plan_set_guided(new_plan("Whole-study plan, 13 Nov 2026"), guided_plan_record(state), state$primary)
  back <- plan_from_text(tree, plan_to_text(plan), read = guided_engine("read_study_plan"))
  expect_identical(plan_content(back), plan_content(plan))
  opened <- plans_open(setNames(list(plan), plan$id), back)
  expect_length(opened$plans, 1)
  expect_null(opened$message)
})
