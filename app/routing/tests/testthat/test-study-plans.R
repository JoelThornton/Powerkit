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
