# Named study plans (R/study-plans.R): several plans, each with a name,
# description, roles and notes, kept in the browser and saved as files
# (docs/saving-projects.md, "Study plans").

run <- engine_function("run_spec", file.path(repo_dir, "engine"))
skip_without_engine_plans <- function() {
  if (is.null(run) && identical(Sys.getenv("POWERKIT_APP_TESTS_NEED_ENGINE"), "true")) {
    fail("powerkit's engine couldn't be loaded, but this run needs it (POWERKIT_APP_TESTS_NEED_ENGINE).")
  }
  skip_if(is.null(run), "powerkit's engine isn't available here")
}

entry_with_hash <- function(label, n, hash) {
  list(endpoint = "E2", label = label, headline = paste("You need", n), goal = "sample_size", n = n,
    sample = list(unit = "participants", note = "N counts participants.", compatibility_key = "same"),
    result = list(provenance = list(spec_hash = hash)))
}
t0 <- as.POSIXct("2026-11-13 10:00:00", tz = "UTC")

test_that("a new plan has a dated default name and a fresh id", {
  expect_identical(plan_default_name(as.Date("2026-11-03")), "Study plan, 3 Nov 2026")
  expect_identical(plan_default_name(as.Date("2026-11-13"), prefix = "Whole-study plan"), "Whole-study plan, 13 Nov 2026")
  a <- new_plan(now = t0)
  b <- new_plan(now = t0)
  expect_match(a$id, "^[0-9a-f]{16}$")
  expect_false(identical(a$id, b$id))
  expect_identical(new_plan("Thesis", now = t0)$name, "Thesis")
  expect_length(a$entries, 0)
  expect_true(plan_unsaved(a))
})

test_that("the first analysis is primary, later ones secondary, and a result is added once", {
  p <- new_plan(now = t0)
  p <- plan_add_entry(p, entry_with_hash("A", 128, "h1"), now = t0)
  p <- plan_add_entry(p, entry_with_hash("B", 90, "h2"), now = t0)
  expect_identical(vapply(p$entries, `[[`, "", "role"), c("primary", "secondary"))
  expect_true(all(grepl("^[0-9a-f]{12}$", vapply(p$entries, `[[`, "", "key"))))
  expect_true(plan_has_result(p, "h1"))
  expect_false(plan_has_result(p, "h3"))
  expect_length(plan_add_entry(p, entry_with_hash("A again", 128, "h1"), now = t0)$entries, 2)
})

test_that("updating keeps the analysis's key, role and note; removing goes by key", {
  p <- plan_add_entry(new_plan(now = t0), entry_with_hash("A", 128, "h1"), now = t0)
  key <- p$entries[[1]]$key
  p <- plan_edit_entry(p, key, role = "check", note = "Manipulation check", now = t0)
  p <- plan_update_entry(p, key, entry_with_hash("A changed", 150, "h9"), now = t0)
  expect_identical(p$entries[[1]]$key, key)
  expect_identical(p$entries[[1]]$role, "check")
  expect_identical(p$entries[[1]]$note, "Manipulation check")
  expect_identical(p$entries[[1]]$n, 150)
  expect_identical(plan_edit_entry(p, key, role = "tertiary", now = t0)$entries[[1]]$role, "check")
  expect_length(plan_remove_entry(p, key, now = t0)$entries, 0)
  expect_length(plan_remove_entry(p, "nosuchkey", now = t0)$entries, 1)
})

test_that("names and descriptions are trimmed and limited; an empty name keeps the old one", {
  p <- plan_edit(new_plan("Old", now = t0), name = paste(rep("x", 200), collapse = ""), now = t0)
  expect_identical(nchar(p$name), 120L)
  expect_identical(plan_edit(p, name = "   ", now = t0)$name, p$name)
  expect_identical(plan_edit(p, name = "  Thesis  ", now = t0)$name, "Thesis")
  long <- paste(rep("y", 2500), collapse = "")
  expect_identical(nchar(plan_edit(p, description = long, now = t0)$description), 2000L)
  note <- paste(rep("z", 1200), collapse = "")
  q <- plan_add_entry(p, entry_with_hash("A", 1, "h"), now = t0)
  expect_identical(nchar(plan_edit_entry(q, q$entries[[1]]$key, note = note, now = t0)$entries[[1]]$note), 1000L)
})

test_that("a plan is unsaved until saved, and again after a later change", {
  p <- plan_mark_saved(new_plan(now = t0), "file", now = t0 + 1)
  expect_false(plan_unsaved(p))
  expect_identical(p$saved_how, "file")
  expect_true(plan_unsaved(plan_edit(p, description = "New", now = t0 + 5)))
  expect_identical(plan_mark_saved(p, "link", now = t0 + 2)$saved_how, "link")
})

test_that("opening a plan never overwrites one in the browser", {
  mine <- plan_add_entry(new_plan("Thesis", now = t0), entry_with_hash("A", 128, "h1"), now = t0)
  plans <- list(); plans[[mine$id]] <- mine
  # A plan not yet in the browser is added.
  other <- new_plan("Other", now = t0)
  out <- plans_open(plans, other, now = t0)
  expect_length(out$plans, 2); expect_identical(out$id, other$id); expect_null(out$message)
  # The same plan, unchanged, opens the one already there.
  same <- mine; same$saved_at <- t0 + 100
  out <- plans_open(plans, same, now = t0)
  expect_length(out$plans, 1); expect_identical(out$id, mine$id); expect_null(out$message)
  # A different version of it is kept as well, under its own id and name.
  changed <- plan_edit(mine, description = "Edited elsewhere", now = t0 + 50)
  out <- plans_open(plans, changed, now = as.POSIXct("2026-11-14 09:00:00", tz = "UTC"))
  expect_length(out$plans, 2)
  expect_false(identical(out$id, mine$id))
  expect_identical(out$plans[[out$id]]$name, "Thesis (opened 14 Nov 2026)")
  expect_identical(out$plans[[mine$id]]$description, "")
  expect_match(out$message, "both are kept", fixed = TRUE)
})

test_that("a plan round-trips through its file text, names untouched", {
  skip_without_engine_plans()
  spec <- build_spec(forms, "E2", form_fields(form_groups(forms, "E2")), form_examples[["E2"]])
  spec$goal <- list(type = "sample_size", power = 0.8)
  spec$options$seed <- 5L
  calc <- run_calculation(spec, run, seed = 5L)
  p <- new_plan("<b>O'Brien's</b> study", now = t0)
  p <- plan_edit(p, description = "Line one", now = t0)
  p <- plan_add_entry(p, plan_entry(tree, "E2", calc, list(app = "routing-prototype", endpoint = "E2")), now = t0)
  p <- plan_edit_entry(p, p$entries[[1]]$key, role = "check", note = "Note", now = t0)
  text <- plan_to_text(p)
  expect_true(nzchar(text))
  back <- plan_from_text(tree, text, now = t0)
  expect_identical(back$id, p$id)
  expect_identical(back$name, "<b>O'Brien's</b> study")
  expect_identical(back$description, "Line one")
  expect_identical(back$entries[[1]]$role, "check")
  expect_identical(back$entries[[1]]$note, "Note")
  expect_equal(back$entries[[1]]$n, p$entries[[1]]$n)
  expect_false(plan_unsaved(back))
  expect_identical(back$saved_how, "file")
  # A file saved before plans had names: a fresh id, a dated name, roles defaulted.
  bare <- lapply(c(p$entries, p$entries), function(e) { e$role <- NULL; e$note <- NULL; e })
  old <- engine_function("write_study_plan")(plan_analyses(bare))
  old_plan <- plan_from_text(tree, old, now = t0)
  expect_match(old_plan$id, "^[0-9a-f]{16}$")
  expect_match(old_plan$name, "^Study plan, [0-9]{1,2} [A-Z][a-z]{2} [0-9]{4}$")
  expect_identical(vapply(old_plan$entries, `[[`, "", "role"), c("primary", "secondary"))
  # The old single browser plan becomes "My study plan", not yet saved to a file.
  migrated <- plans_migrate_legacy(tree, old, now = t0)
  expect_identical(migrated$name, "My study plan")
  expect_true(plan_unsaved(migrated))
  expect_null(plan_from_text(tree, "{not json", now = t0))
  expect_identical(plan_to_text(new_plan(now = t0)), "")
})

test_that("plans come back from the browser, a broken copy dropped and the old single plan moved in", {
  skip_without_engine_plans()
  spec <- build_spec(forms, "E2", form_fields(form_groups(forms, "E2")), form_examples[["E2"]])
  spec$goal <- list(type = "sample_size", power = 0.8)
  spec$options$seed <- 5L
  calc <- run_calculation(spec, run, seed = 5L)
  entry <- plan_entry(tree, "E2", calc, list(app = "routing-prototype", endpoint = "E2"))
  a <- plan_add_entry(new_plan("A", now = t0), entry, now = t0)
  b <- plan_mark_saved(plan_add_entry(new_plan("B", now = t0), entry, now = t0), "link", now = t0 + 3)
  records <- list(); records[[a$id]] <- plan_browser_record(a); records[[b$id]] <- plan_browser_record(b)
  records[["0123456789abcdef"]] <- "{broken"
  saved <- list(index = list(current = b$id, ids = list(a$id, b$id, "0123456789abcdef")), records = records)
  out <- plans_from_browser(tree, saved, now = t0 + 10)
  expect_identical(names(out$plans), c(a$id, b$id))
  expect_identical(out$current, b$id)
  expect_identical(out$plans[[a$id]]$name, "A")
  expect_true(plan_unsaved(out$plans[[a$id]]))
  expect_false(plan_unsaved(out$plans[[b$id]]))
  expect_identical(out$plans[[b$id]]$saved_how, "link")
  # The old single plan, alone: it becomes "My study plan".
  legacy <- engine_function("write_study_plan")(plan_analyses(list(entry)))
  out <- plans_from_browser(tree, list(legacy = legacy), now = t0)
  expect_length(out$plans, 1)
  expect_identical(out$plans[[1]]$name, "My study plan")
  expect_identical(out$current, names(out$plans))
  # ...unless a plan already holds the same analyses.
  same <- plan_add_entry(new_plan("My study plan", now = t0), entry, now = t0)
  recs <- list(); recs[[same$id]] <- plan_browser_record(same)
  out <- plans_from_browser(tree, list(index = list(current = same$id, ids = list(same$id)), records = recs, legacy = legacy), now = t0)
  expect_length(out$plans, 1)
  expect_identical(plans_from_browser(tree, NULL)$plans, list())
})

test_that("an empty plan keeps its name and description in the browser", {
  p <- plan_edit(new_plan("Thesis study 3", now = t0), description = "Not started", now = t0)
  rec <- plan_browser_record(p)
  expect_true(nzchar(rec))
  back <- plans_from_browser(tree, list(index = list(current = p$id, ids = list(p$id)), records = setNames(list(rec), p$id)), now = t0)
  expect_identical(back$plans[[p$id]]$name, "Thesis study 3")
  expect_identical(back$plans[[p$id]]$description, "Not started")
  expect_length(back$plans[[p$id]]$entries, 0)
  expect_null(back$migrated)
})

test_that("the Study plans page lists every plan, names escaped, and says how to start with none", {
  empty <- as.character(plans_list_ui(list()))
  expect_match(empty, "You have no study plans yet.", fixed = TRUE)
  expect_match(empty, "Open a saved plan", fixed = TRUE)
  expect_match(empty, "can be cleared without warning", fixed = TRUE)
  expect_no_match(empty, "plans_forget_all", fixed = TRUE)
  a <- plan_add_entry(new_plan("<b>Bold</b>", now = t0), entry_with_hash("A", 128, "h1"), now = t0)
  b <- plan_mark_saved(plan_add_entry(new_plan("O'Brien's study", now = t0), entry_with_hash("B", 90, "h2"), now = t0), "file", now = t0 + 1)
  html <- as.character(plans_list_ui(setNames(list(a, b), c(a$id, b$id)), current = a$id))
  expect_match(html, "&lt;b&gt;Bold&lt;/b&gt;", fixed = TRUE)
  expect_no_match(html, "<b>Bold</b>", fixed = TRUE)
  expect_match(html, ">O'Brien's study</button>", fixed = TRUE)
  expect_match(html, "largest comparable N = 128", fixed = TRUE)
  expect_match(html, "Only in this browser", fixed = TRUE)
  expect_match(html, "Saved to a file", fixed = TRUE)
  expect_match(html, "1 plan has not been saved to a file", fixed = TRUE)
})

test_that("a plan's page shows each role, the save status, and confirms with any name", {
  p <- plan_add_entry(new_plan("O'Brien's \"study\"", now = t0), entry_with_hash("A", 128, "h1"), now = t0)
  p <- plan_add_entry(p, entry_with_hash("B", 90, "h2"), now = t0)
  p <- plan_edit_entry(p, p$entries[[2]]$key, role = "check", note = "Manipulation check", now = t0)
  html <- as.character(plan_page_ui(p))
  expect_match(html, '<option value="check" selected>Check</option>', fixed = TRUE)
  expect_match(html, '<option value="primary" selected>Primary</option>', fixed = TRUE)
  expect_match(html, "Manipulation check", fixed = TRUE)
  expect_match(as.character(plan_status_ui(p)), "plan-status-unsaved", fixed = TRUE)
  expect_match(html, 'class="[^"]*btn btn-primary"[^>]*id="download_study_plan"')
  # The name sits inside a JSON string in the confirm: its quotes are escaped.
  expect_match(html, "Delete “O&#39;Brien&#39;s \\&quot;study\\&quot;” from this browser?", fixed = TRUE)
  big <- p; big$too_large <- TRUE
  expect_match(as.character(plan_status_ui(big)), "too large to keep in this browser", fixed = TRUE)
  saved <- as.character(plan_status_ui(plan_mark_saved(p, "link", now = t0 + 1)))
  expect_match(saved, "Copied as a link", fixed = TRUE)
  expect_identical(plan_file_name(p), "powerkit-o-brien-s-study.powerkit.json")
  expect_identical(plan_file_name(new_plan("!!!", now = t0)), "powerkit-study-plan.powerkit.json")
})

test_that("with several plans the bar asks which; a changed result from a plan offers update or add", {
  a <- new_plan("A", now = t0); b <- new_plan("B", now = t0)
  plans <- setNames(list(a, b), c(a$id, b$id))
  html <- as.character(study_plan_bar_ui(plans, b$id, "h9"))
  expect_match(html, 'id="plan_target"', fixed = TRUE)
  expect_match(html, "A new plan", fixed = TRUE)
  expect_lt(regexpr(paste0('value="', b$id), html), regexpr(paste0('value="', a$id), html))
  a <- plan_add_entry(a, entry_with_hash("X", 100, "h1"), now = t0)
  plans[[a$id]] <- a
  origin <- list(plan = a$id, key = a$entries[[1]]$key, endpoint = "E2", hash = "h1")
  changed <- as.character(study_plan_bar_ui(plans, a$id, "h2", origin = origin))
  expect_match(changed, "Update it in the plan", fixed = TRUE)
  expect_match(changed, "Add it as a new analysis", fixed = TRUE)
  expect_match(as.character(study_plan_bar_ui(plans, a$id, "h1", origin = origin)), "From your plan “A”.", fixed = TRUE)
})

test_that("an analysis in a plan opens as a project, from a file or from a fresh result", {
  skip_without_engine_plans()
  spec <- build_spec(forms, "E2", form_fields(form_groups(forms, "E2")), form_examples[["E2"]])
  spec$options$seed <- 5L
  calc <- run_calculation(spec, run, seed = 5L)
  entry <- plan_entry(tree, "E2", calc, list(app = "routing-prototype", endpoint = "E2", form_values = form_examples[["E2"]]))
  project <- plan_entry_project(entry)
  expect_s3_class(project, "powerkit_project")
  expect_identical(project$result$provenance$spec_hash, calc$result$provenance$spec_hash)
  expect_identical(project$route$endpoint, "E2")
  expect_false(is.character(restore_from_project(project$route, tree, forms)))
  expect_identical(plan_entry_project(list(project = project)), project)
})

test_that("opening the same plan again never piles up copies, with or without an id", {
  mine <- plan_add_entry(new_plan("Thesis", now = t0), entry_with_hash("A", 128, "h1"), now = t0)
  file_copy <- mine
  edited <- plan_edit(mine, description = "Edited here", now = t0 + 5)
  plans <- setNames(list(edited), edited$id)
  once <- plans_open(plans, file_copy, now = t0)
  twice <- plans_open(once$plans, file_copy, now = t0)
  expect_length(once$plans, 2)
  expect_length(twice$plans, 2)
  expect_identical(twice$id, once$id)
  # A file with no id gets a new one each time it is read: still one copy.
  no_id <- file_copy; no_id$id <- plan_new_id()
  again <- plans_open(twice$plans, no_id, now = t0)
  expect_length(again$plans, 2)
})

test_that("every plan kept in the browser loads, listed in the index or not", {
  a <- new_plan("A", now = t0); b <- new_plan("B", now = t0)
  recs <- setNames(list(plan_browser_record(a), plan_browser_record(b)), c(a$id, b$id))
  out <- plans_from_browser(tree, list(index = list(current = a$id, ids = list(a$id)), records = recs), now = t0)
  expect_setequal(names(out$plans), c(a$id, b$id))
  expect_identical(names(out$plans)[[1]], a$id)
  out <- plans_from_browser(tree, list(index = list(current = NULL, ids = list()), records = recs), now = t0)
  expect_length(out$plans, 2)
})

test_that("a kept plan that fails while being read is left out, not fatal", {
  p <- plan_add_entry(new_plan("A", now = t0), entry_with_hash("A", 128, "h1"), now = t0)
  rec <- as.character(jsonlite::toJSON(list(format = "powerkit-plan-in-browser", version = 1L, id = p$id,
    name = "Broken", changed = 1, file = "{\"format\": \"powerkit-study-plan\"}"), auto_unbox = TRUE))
  stub <- function(text) list(analyses = list("not a project"), roles = NA_character_, notes = NA_character_)
  good <- plan_browser_record(new_plan("Good", now = t0))
  ids <- c(p$id, "0123456789abcdef")
  out <- plans_from_browser(tree, list(records = setNames(list(rec, good), ids)), read = stub, now = t0)
  expect_identical(vapply(out$plans, `[[`, "", "name"), setNames("Good", names(out$plans)))
})

test_that("a plan's save status has its own output, so saving doesn't redraw the page", {
  html <- as.character(plan_page_ui(plan_add_entry(new_plan("A", now = t0), entry_with_hash("A", 1, "h"), now = t0)))
  expect_match(html, 'id="plan_status"', fixed = TRUE)
})

test_that("every browser message handler takes its message, as Shiny requires", {
  # Shiny refuses a handler with no argument, and the refusal stops the rest
  # of its script: the plans index and the draft autosave were never set up.
  files <- c(list.files(file.path(routing_dir, "R"), pattern = "[.]R$", full.names = TRUE), file.path(routing_dir, "app.R"))
  text <- unlist(lapply(files, readLines, warn = FALSE))
  expect_identical(grep("addCustomMessageHandler\\([^,]+,\\s*(async\\s+)?function\\s*\\(\\s*\\)", text, value = TRUE), character())
})
