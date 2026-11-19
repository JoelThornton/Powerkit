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
  # Alpha and power start empty, with buttons, as on the cards; variation
  # between studies starts at Small (P-04, 15 November 2026).
  expect_identical(v$rep_alpha, "")
  expect_identical(v$rep_power, "")
  expect_identical(v$rep_tau, "0.05")
  expect_identical(v$rep_published, "unknown")
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
  expect_match(page, "Study plan \u00b7 Replication", fixed = TRUE)
  expect_no_match(page, "Add an analysis", fixed = TRUE)
  expect_match(page, "download_plan_bundle", fixed = TRUE)
  html <- as.character(replication_workspace_ui(tree))
  for (id in c("rep_section", "labs_finding", "rep_effect", "rep_card_status")) expect_match(html, id, fixed = TRUE)
  # The list of analyses first, the design finder's questions second (queue item 28).
  first <- as.character(replication_card_status_ui(tree, plan))
  expect_match(first, "rep_pick_design", fixed = TRUE)
  expect_match(first, "rep_find_design", fixed = TRUE)
  expect_lt(regexpr("rep_pick_design", first, fixed = TRUE), regexpr("rep_find_design", first, fixed = TRUE))
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

test_that("choosing the original's card starts the planner on its design and effect", {
  fields <- replication_fields_for_card(list(), forms, "E27")
  expect_identical(fields$rep_design, "generic")
  expect_identical(fields$rep_scale, "log")
  expect_match(fields$rep_effect_name, "odds ratio", fixed = TRUE)
  expect_identical(replication_fields_for_card(list(), forms, "E3")$rep_design, "paired")
  # A test of several degrees of freedom: another design, its effect to be
  # named (an ANOVA card starts on An ANOVA effect instead: test-replication-bucss.R).
  multi <- replication_fields_for_card(list(), forms, "E6")
  expect_identical(multi$rep_design, "generic")
  expect_identical(multi$rep_effect_name, "")
  # A card with no replication goals leaves the fields alone.
  expect_identical(replication_fields_for_card(list(rep_study = "x"), forms, "E61"), list(rep_study = "x"))
  # Once an original effect is entered, the researcher's choices stay.
  kept <- list(rep_design = "two_groups", rep_effect = "0.5")
  expect_identical(replication_fields_for_card(kept, forms, "E27"), kept)
  # The plan's page says what the card gives the goals.
  plan <- plan_set_replication(new_replication_plan("Logistic replication"), endpoint = "E27")
  expect_match(as.character(replication_card_status_ui(tree, plan, forms)), "odds ratio of the predictor", fixed = TRUE)
  code <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(code, "replication_fields_for_card(plan$replication$fields, forms, ep)", fixed = TRUE)
  expect_match(code, "replication_card_status_ui(tree, plan, forms)", fixed = TRUE)
})

test_that("the plan warns when the design entered and the original's card disagree", {
  plan <- plan_set_replication(new_replication_plan(), fields = list(rep_design = "two_groups", rep_effect = "0.5"), endpoint = "E4")
  status <- as.character(replication_card_status_ui(tree, plan, forms))
  expect_match(status, "rep-design-mismatch", fixed = TRUE)
  expect_match(status, "Two separate groups compared on a score", fixed = TRUE)
  expect_match(status, "Two scores and how they are related", fixed = TRUE)
  # Matching designs, and a card whose effect goes under Another design, don't warn.
  same <- plan_set_replication(new_replication_plan(), fields = list(rep_design = "correlation"), endpoint = "E4")
  expect_null(replication_design_mismatch(same, forms))
  generic <- plan_set_replication(new_replication_plan(), fields = list(rep_design = "generic"), endpoint = "E8")
  expect_null(replication_design_mismatch(generic, forms))
  # An ANOVA card goes under An ANOVA effect (BUCSS) or as its one contrast under Another design.
  expect_identical(replication_card_planner_design(forms, "E8"), c("anova", "generic"))
  anova <- plan_set_replication(new_replication_plan(), fields = list(rep_design = "anova"), endpoint = "E8")
  expect_null(replication_design_mismatch(anova, forms))
  expect_identical(replication_card_planner_design(forms, "E27"), "generic")
})

test_that("an extension added to a replication plan isn't reported as the original's analysis", {
  entry <- function(ep, label, n) list(endpoint = ep, label = label, n = n)
  plan <- plan_set_replication(new_replication_plan(), endpoint = "E8")
  plan$entries <- list(entry("E56", "The extension's three-way interaction", 400), entry("E8", "The original's interaction", 84))
  expect_identical(replication_original_index(plan), 2L)
  lines <- paste(replication_analysis_lines(plan, tree, forms), collapse = "\n")
  expect_lt(regexpr("The original's interaction", lines, fixed = TRUE)[1], regexpr("## Other analyses in this plan", lines, fixed = TRUE)[1])
  expect_gt(regexpr("The extension's three-way interaction", lines, fixed = TRUE)[1], regexpr("## Other analyses in this plan", lines, fixed = TRUE)[1])
  status <- as.character(replication_card_status_ui(tree, plan, forms))
  expect_match(status, "N = 84", fixed = TRUE)
  # One analysis: no second heading.
  plan$entries <- plan$entries[2]
  expect_no_match(paste(replication_analysis_lines(plan, tree, forms), collapse = "\n"), "Other analyses", fixed = TRUE)
})

test_that("the replication plan's steps are numbered, each with a button to the next (queue item 28)", {
  html <- as.character(replication_workspace_ui(tree))
  expect_match(html, "replication-steps", fixed = TRUE)
  nexts <- as.character(replication_next_step_ui())
  ids <- unname(replication_sections)
  for (i in seq_len(length(ids) - 1L)) {
    expect_match(nexts, sprintf("Next: %s", names(replication_sections)[[i + 1L]]), fixed = TRUE)
    expect_match(nexts, sprintf("value=%s]", ids[[i + 1L]]), fixed = TRUE)
  }
  # The last step has no next.
  expect_no_match(nexts, sprintf("input.rep_section == '%s'", ids[[length(ids)]]), fixed = TRUE)
})

test_that("the list of analyses, opened from a replication plan, says what to choose and where it is kept", {
  plan <- new_replication_plan("Smith replication")
  note <- as.character(replication_known_note(plan))
  expect_match(note, "the original study used", fixed = TRUE)
  expect_match(note, "Smith replication", fixed = TRUE)
  expect_match(as.character(known_ui(tree, note = replication_known_note(plan))), "replication-known-note", fixed = TRUE)
  expect_no_match(as.character(known_ui(tree)), "replication-known-note", fixed = TRUE)
})

test_that("a replication plan asks what the replication keeps, and each answer leads somewhere (queue item 28)", {
  html <- as.character(replication_workspace_ui(tree))
  expect_match(html, "rep_keeps", fixed = TRUE)
  for (k in unname(replication_keeps_ui)) expect_match(html, sprintf("value=\"%s\"", k), fixed = TRUE)
  for (id in c("rep_add_extension", "rep_use_conceptual", "rep_start_study_plan", "rep_diff_checks", "rep-changes-note"))
    expect_match(html, id, fixed = TRUE)
  expect_true(all(c("rep_keeps", "rep_diff_checks") %in% replication_plan_field_ids))
  # The write-up says what it keeps, and the checks for a changed replication.
  plan <- plan_set_replication(new_replication_plan("Smith replication"),
    fields = list(rep_keeps = "conceptual", rep_diff_checks = "A manipulation check after the prime"))
  report <- paste(replication_plan_report(plan, tree, forms, engine = function(name) NULL), collapse = "\n")
  expect_match(report, "What it keeps: a conceptual replication", fixed = TRUE)
  expect_match(report, "A manipulation check after the prime", fixed = TRUE)
  close <- plan_set_replication(new_replication_plan("Close"), fields = list(rep_keeps = "close"))
  expect_no_match(paste(replication_plan_report(close, tree, forms, engine = function(name) NULL), collapse = "\n"),
    "still tests the same thing", fixed = TRUE)
})

test_that("a conceptual replication is planned from the shrunk belief with more variation between studies", {
  expect_identical(replication_conceptual_settings(list(rep_design = "two_groups", rep_tau = "0.05")),
    list(rep_prior = "shrunk", rep_tau = "0.125"))
  expect_identical(replication_conceptual_settings(list(rep_design = "paired", rep_tau = "0.125"))$rep_tau, "0.2")
  expect_identical(replication_conceptual_settings(list(rep_design = "two_groups", rep_tau = "0.2"))$rep_tau, "0.2")
  expect_identical(replication_conceptual_settings(list(rep_design = "correlation", rep_tau_r = "0.025"))$rep_tau_r, "0.075")
  # A generic effect's variation is on its own scale: left to the researcher.
  expect_identical(replication_conceptual_settings(list(rep_design = "generic")), list(rep_prior = "shrunk"))
})

test_that("an analysis added as an extension is never taken for the original's", {
  entry <- function(ep, label, n, ext = FALSE) c(list(endpoint = ep, label = label, n = n), if (ext) list(extension = TRUE))
  # Added before the original's card was chosen: still not the original's.
  plan <- new_replication_plan()
  plan$entries <- list(entry("E2", "The added condition", 300, ext = TRUE))
  expect_true(is.na(replication_original_index(plan)))
  lines <- paste(replication_analysis_lines(plan, tree, forms), collapse = "\n")
  expect_match(lines, "Not planned yet", fixed = TRUE)
  expect_match(lines, "## Other analyses in this plan", fixed = TRUE)
  expect_no_match(as.character(replication_card_status_ui(tree, plan_set_replication(plan, endpoint = "E2"), forms)), "N = 300", fixed = TRUE)
  # The same card as the original's: the one not added as an extension is.
  plan$entries <- c(plan$entries, list(entry("E2", "The original comparison", 128)))
  plan <- plan_set_replication(plan, endpoint = "E2")
  expect_identical(replication_original_index(plan), 2L)
  # Replacing an extension's result keeps it an extension.
  keyed <- plan_add_entry(new_replication_plan(), entry("E7", "Added", 90, ext = TRUE))
  updated <- plan_update_entry(keyed, keyed$entries[[1]]$key, entry("E7", "Added", 120))
  expect_true(isTRUE(updated$entries[[1]]$extension))
})

test_that("the list and the card say when an extension is being chosen, and the card status says why the sample sizes can differ", {
  plan <- new_replication_plan("Smith replication")
  expect_match(as.character(replication_extension_note(plan)), "what the replication adds", fixed = TRUE)
  expect_match(as.character(replication_extension_note(plan, card = TRUE)), "no original estimate", fixed = TRUE)
  status <- as.character(replication_card_status_ui(tree, plan_set_replication(plan, endpoint = "E2"), forms))
  expect_match(status, "The card and the Goals can give different sample sizes", fixed = TRUE)
})

test_that("legacy replication plans keep their filter and migrate the posterior mean", {
  legacy <- list(format = replication_plan_format, version = 1L,
    fields = list(rep_analysis = "posterior", rep_effect = "-0.15", rep_post_sd = "0.2"))
  restored <- replication_values(legacy)
  expect_identical(restored$rep_post_mean, "-0.15")
  expect_identical(restored$rep_effect, "")
  expect_identical(restored$rep_published, "significant")
  expect_identical(replication_values(replication_record(list(rep_published = "any")))$rep_published, "any")

  plan <- plan_set_replication(new_replication_plan(), fields = list(rep_analysis = "posterior",
    rep_effect = "0.5", rep_post_mean = "-0.15", rep_published = "unknown"))
  back <- plan_from_replication_text(plan_replication_only_text(plan))
  expect_identical(replication_values(back$replication), replication_values(plan$replication))
})

test_that("conceptual sensitivity reports the precise change and when a setting is already at its maximum", {
  before <- list(rep_design = "two_groups", rep_tau = "0.05", rep_prior = "uncertain")
  message <- replication_conceptual_summary(before, replication_conceptual_settings(before))
  expect_match(message, "Belief changed from With its uncertainty to Shrunk towards zero.", fixed = TRUE)
  expect_match(message, "Between-study SD changed from 0.05 to 0.125.", fixed = TRUE)
  before$rep_tau <- "0.2"
  expect_match(replication_conceptual_summary(before, replication_conceptual_settings(before)),
    "Between-study SD stays at 0.2.", fixed = TRUE)
})

test_that("every field's starting value on screen is the one a new plan records", {
  # A plan starts saving the screen's fields only once they match what it
  # recorded, so a field drawn with a starting value the record lacks
  # would stop a new replication plan from ever being saved.
  html <- as.character(replication_workspace_ui(tree))
  recorded <- replication_values(replication_record())
  for (id in replication_plan_field_ids) {
    checked <- regmatches(html, regexpr(sprintf('<input[^>]*name="%s"[^>]*value="[^"]*"[^>]*checked="checked"', id), html))
    text <- regmatches(html, regexpr(sprintf('<input id="%s"[^>]*>', id), html))
    select <- regmatches(html, regexpr(sprintf('<select id="%s"[^>]*>.*?</select>', id), html, perl = TRUE))
    shown <- if (length(checked)) sub('.*value="([^"]*)".*', "\\1", checked)
      else if (length(text)) (if (grepl('value="', text)) sub('.*value="([^"]*)".*', "\\1", text) else "")
      else if (length(select)) {
        option <- regmatches(select, regexpr('<option value="[^"]*" selected>', select))
        if (length(option)) sub('.*value="([^"]*)".*', "\\1", option)
      }
    if (!is.null(shown)) expect_identical(shown, recorded[[id]], label = id)
  }
})
