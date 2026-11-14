# A study plan's overview, its study-wide planning document and its
# "Download everything" zip (R/plan-bundle.R).

bundle_engine <- function(name) engine_function(name, file.path(repo_dir, "engine"))

# A calculated analysis from a card's example answers, as the result screen
# keeps it, turned into a plan entry.
calculated_entry <- function(ep, seed = 11L) {
  values <- form_examples[[ep]]
  spec <- build_spec(forms, ep, form_fields(form_groups(forms, ep)), values)
  calc <- run_calculation(spec, bundle_engine("run_spec"), seed = seed)
  calc$route <- list(app = "routing-prototype", route = "choose", endpoint = ep, came_from = "node",
    ctx = list(), history = list(), form_k = 2L, form_values = values)
  plan_entry(tree, ep, calc, calc$route)
}

skip_without_engine <- function() {
  skip_if(is.null(bundle_engine("write_project")) || is.null(bundle_engine("run_spec")), "no engine with project files")
}

test_that("the overview counts the analyses by role", {
  entry <- function(n) list(label = "An analysis", n = n)
  plan <- plan_with(list(entry(100), entry(80), entry(60)))
  plan <- plan_edit_entry(plan, plan$entries[[3]]$key, role = "check")
  expect_identical(plan_role_counts_text(plan$entries), "3 analyses: 1 primary, 1 secondary, 1 check")
  expect_identical(plan_role_counts_text(plan$entries[1]), "1 analysis: 1 primary")
  expect_identical(plan_role_counts_text(list()), "No analyses yet")
  html <- as.character(plan_page_ui(plan))
  expect_match(html, "Overview", fixed = TRUE)
  expect_match(html, "3 analyses: 1 primary, 1 secondary, 1 check", fixed = TRUE)
})

test_that("the plan page offers Download everything once the plan has an analysis", {
  expect_no_match(as.character(plan_page_ui(new_plan("Empty"))), "download_plan_bundle", fixed = TRUE)
  html <- as.character(plan_page_ui(plan_with(list(list(label = "An analysis", n = 10)))))
  expect_match(html, "download_plan_bundle", fixed = TRUE)
  expect_match(html, "Download everything (.zip)", fixed = TRUE)
})

test_that("the zip's name comes from the plan's name", {
  expect_identical(plan_bundle_file_name(new_plan("Thesis study 2: attention")), "powerkit-thesis-study-2-attention-everything.zip")
})

test_that("references from several analyses are merged, each once", {
  one <- "Citations for this power analysis\n(powerkit 0.65.0)\n\npwr, the package (from citation(\"pwr\")):\n  Champely S (2020). pwr.\n\nR, in which the analysis ran (from citation(\"base\")):\n  R Core Team (2026). R.\n\nMethods paragraph:\n  The write-up is on the result screen."
  two <- "Citations for this power analysis\n(powerkit 0.65.0)\n\nSpower, the package (from citation(\"Spower\")):\n  Chalmers P (2025). Spower.\n\nR, in which the analysis ran (from citation(\"base\")):\n  R Core Team (2026). R."
  refs <- plan_merge_citations(c(one, two))
  expect_length(refs, 3)
  expect_identical(sum(grepl("R Core Team", refs)), 1L)
  expect_false(any(grepl("Methods paragraph|write-up", refs)))
  expect_true(any(grepl("citation(\"Spower\")", refs, fixed = TRUE)))
})

test_that("the study-wide document restates each analysis, ordered by role, without new numbers", {
  skip_without_engine()
  a <- calculated_entry("E2")
  b <- calculated_entry("E1")
  plan <- plan_with(list(a, b), name = "Attention <training> study")
  plan <- plan_edit(plan, description = "Does a 4-week attention training help?")
  plan <- plan_edit_entry(plan, plan$entries[[1]]$key, role = "secondary")
  plan <- plan_edit_entry(plan, plan$entries[[2]]$key, role = "primary", note = "The main claim.")
  doc <- plan_planning_document(plan, tree, forms, engine = bundle_engine)
  text <- paste(doc, collapse = "\n")
  expect_match(text, "# Attention <training> study", fixed = TRUE)
  expect_match(text, "Does a 4-week attention training help?", fixed = TRUE)
  expect_match(text, "The main claim.", fixed = TRUE)
  # The primary analysis comes first in the table and the methods.
  expect_lt(regexpr(plan$entries[[2]]$label, text, fixed = TRUE), regexpr(plan$entries[[1]]$label, text, fixed = TRUE))
  # Each analysis's N is the one its card found.
  for (e in plan$entries) expect_match(text, whole(e$n), fixed = TRUE)
  expect_match(text, "| Analysis | Role | N needed |", fixed = TRUE)
  expect_match(text, "pwr", fixed = TRUE)
  expect_match(text, "## References", fixed = TRUE)
  expect_identical(sum(grepl("R Core Team", doc, fixed = TRUE)), 1L)
  # The two cards' own methods paragraphs are in it.
  for (e in plan$entries) {
    calc <- plan_entry_calc(e)
    expect_match(text, substr(planning_methods_text(tree, forms, calc), 1, 60), fixed = TRUE)
  }
})

test_that("the document says when the analyses have no single study-wide N", {
  skip_without_engine()
  a <- calculated_entry("E2")
  b <- a
  b$sample <- list(unit = "pairs", note = "Pairs.", compatibility_key = "pairs")
  doc <- paste(plan_planning_document(plan_with(list(a, b)), tree, forms, engine = bundle_engine), collapse = "\n")
  expect_match(doc, "no single study-wide sample size", fixed = TRUE)
})

test_that("the document includes joint power only when it was calculated for the plan as it stands", {
  skip_without_engine()
  a <- calculated_entry("E2")
  plan <- plan_with(list(a, a))
  joint <- list(n = 128, rho = 0.3, complete = 0.71, each = list(0.8, 0.8), design = "d1.1_m2fc", provenance = list(packages = list(PUMP = "1.0.3"), tnum = 10000, seed = 1))
  with_joint <- paste(plan_planning_document(plan, tree, forms, joint = joint, engine = bundle_engine), collapse = "\n")
  expect_match(with_joint, "71%", fixed = TRUE)
  expect_no_match(paste(plan_planning_document(plan, tree, forms, engine = bundle_engine), collapse = "\n"), "71%", fixed = TRUE)
})

test_that("Download everything for a plan holds the plan file, the documents and each analysis, and reopens", {
  skip_without_engine()
  plan <- plan_with(list(calculated_entry("E2"), calculated_entry("E1")), name = "Two analyses")
  zipfile <- tempfile(fileext = ".zip")
  write_plan_bundle(plan, zipfile, tree, forms, engine = bundle_engine)
  listed <- zip::zip_list(zipfile)$filename
  expect_true(all(c("README.txt", "powerkit-two-analyses.powerkit.json", "study-plan.md", "study-plan.docx", "references.txt") %in% listed))
  first <- grep("^analyses/01-", listed, value = TRUE)
  expect_true(any(grepl("project\\.powerkit\\.json$", first)))
  expect_true(any(grepl("script\\.R$", first)))
  expect_true(any(grepl("^analyses/02-", listed)))
  readme <- readLines(unz(zipfile, "README.txt"))
  expect_true(any(grepl("powerkit-two-analyses.powerkit.json", readme, fixed = TRUE)))
  # Open reads the plan file in it, not one of the analyses' project files.
  inside <- zip_project_file(zipfile)
  expect_false(inherits(inside, "zip_problem"))
  back <- plan_from_text(tree, paste(readLines(inside, warn = FALSE), collapse = "\n"), read = bundle_engine("read_study_plan"))
  expect_identical(back$id, plan$id)
  expect_identical(length(back$entries), 2L)
})

test_that("Download everything for a plan fails rather than hand over a zip without the plan file", {
  plan <- plan_with(list(list(label = "An analysis", n = 10)))
  zipfile <- tempfile(fileext = ".zip")
  expect_error(write_plan_bundle(plan, zipfile, tree, forms, engine = function(name) function(...) stop("no")))
  expect_false(file.exists(zipfile))
})

test_that("the zip reader prefers the plan file at the top of a plan's zip", {
  zipped <- make_zip(list(`README.txt` = "notes", `my-plan.powerkit.json` = "{\"format\": \"powerkit-study-plan\"}",
    `analyses/01-a/powerkit-E2-project.powerkit.json` = "{}", `analyses/02-b/powerkit-E1-project.powerkit.json` = "{}"))
  inside <- zip_project_file(zipped)
  expect_false(inherits(inside, "zip_problem"))
  expect_identical(basename(inside), "my-plan.powerkit.json")
  # Two files at the top is still a problem: nothing says which to open.
  two <- make_zip(list(`a.powerkit.json` = "{}", `b.powerkit.json` = "{}", `analyses/x.powerkit.json` = "{}"))
  expect_s3_class(zip_project_file(two), "zip_problem")
})
