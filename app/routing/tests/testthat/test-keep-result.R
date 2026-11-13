# "Keep this result" and "Documents for your study" (R/keep-result.R).

test_that("the box under the answer holds the three ways to come back", {
  html <- as.character(keep_result_ui(TRUE))
  expect_match(html, "Keep this result", fixed = TRUE)
  expect_match(html, 'id="download_project"', fixed = TRUE)
  expect_match(html, "Save project file", fixed = TRUE)
  expect_match(html, 'id="share_project"', fixed = TRUE)
  expect_match(html, 'id="study_plan_bar"', fixed = TRUE)
  expect_match(html, 'data-kept="no"', fixed = TRUE)
  expect_match(html, "Not saved yet", fixed = TRUE)
  expect_null(keep_result_ui(FALSE))
  expect_false(grepl("study_plan_bar", as.character(keep_result_ui(TRUE, plan = FALSE))))
  reopened <- as.character(keep_result_ui(TRUE, kept = TRUE))
  expect_match(reopened, 'data-kept="yes"', fixed = TRUE)
  expect_match(reopened, "Opened from a saved file", fixed = TRUE)
})

test_that("the documents say they don't reopen, and the project file moved out of them", {
  html <- as.character(documents_ui(TRUE, "pwrss", span("menu")))
  expect_match(html, "Documents for your study", fixed = TRUE)
  expect_match(html, "These don't reopen in powerkit", fixed = TRUE)
  expect_match(html, 'id="download_bundle"', fixed = TRUE)
  expect_match(html, 'id="download_script"', fixed = TRUE)
  expect_false(grepl("download_project", html, fixed = TRUE))
  expect_false(grepl("btn-primary\"", html, fixed = TRUE))
  locked <- as.character(documents_ui(FALSE, "pwrss", span("menu")))
  expect_false(grepl("download_bundle", locked, fixed = TRUE))
  expect_match(locked, 'id="download_citations"', fixed = TRUE)
})

test_that("each result panel uses the box once and has no second Save project", {
  results <- paste(readLines(file.path(routing_dir, "R", "results.R")), collapse = "\n")
  expect_identical(lengths(regmatches(results, gregexpr("keep_result_ui(can_export", results, fixed = TRUE))), 2L)
  expect_identical(lengths(regmatches(results, gregexpr("documents_ui(", results, fixed = TRUE))), 2L)
  expect_false(grepl('download_button("download_project"', results, fixed = TRUE))
  expect_false(grepl('uiOutput("study_plan_bar")', results, fixed = TRUE))
})

make_zip <- function(files) {
  dir <- tempfile(); dir.create(dir)
  for (name in names(files)) {
    dir.create(dirname(file.path(dir, name)), showWarnings = FALSE, recursive = TRUE)
    writeLines(files[[name]], file.path(dir, name))
  }
  out <- tempfile(fileext = ".zip")
  zip::zip(out, files = names(files), root = dir, mode = "mirror")
  out
}

test_that("Open takes the zip from Download everything", {
  plain <- tempfile(fileext = ".powerkit.json")
  writeLines("{}", plain)
  expect_null(zip_project_file(plain))
  good <- make_zip(list(`README.txt` = "notes", `powerkit-E2-project.powerkit.json` = "{\"format\": \"powerkit-project\"}"))
  inside <- zip_project_file(good)
  expect_type(inside, "character")
  expect_false(inherits(inside, "zip_problem"))
  expect_identical(readLines(inside), "{\"format\": \"powerkit-project\"}")
  none <- make_zip(list(`README.txt` = "notes"))
  expect_s3_class(zip_project_file(none), "zip_problem")
  two <- make_zip(list(`a.powerkit.json` = "{}", `b.powerkit.json` = "{}"))
  expect_s3_class(zip_project_file(two), "zip_problem")
})

test_that("a project file in a subfolder of the zip is extracted into the temporary folder only", {
  nested <- make_zip(list(`deep/folder/plan.powerkit.json` = "{}"))
  inside <- zip_project_file(nested)
  expect_identical(basename(inside), "plan.powerkit.json")
  expect_identical(normalizePath(dirname(dirname(inside))), normalizePath(tempdir()))
})

test_that("the result kept in the browser comes back only with the same answers", {
  values <- list(d = "0.4", power = "0.8")
  project <- jsonlite::toJSON(list(format = "powerkit-project",
    route = list(app = "routing-prototype", endpoint = "E2", form_values = values)), auto_unbox = TRUE)
  draft <- list(route = list(endpoint = "E2", form_values = values))
  expect_true(last_result_matches_draft(as.character(project), draft))
  draft$route$form_values$d <- "0.5"
  expect_false(last_result_matches_draft(as.character(project), draft))
  expect_false(last_result_matches_draft(as.character(project), list(route = list(endpoint = "E3", form_values = values))))
  expect_false(last_result_matches_draft("", draft))
  expect_false(last_result_matches_draft("{not json", draft))
})

test_that("the zip's notes name every file and how to reopen it", {
  notes <- bundle_readme("E2", c(project = "/x/powerkit-E2-project.powerkit.json", script = "/x/powerkit-E2-script.R",
    data = "/x/SIMULATED-not-real-data-E2.csv"))
  expect_true(any(grepl("powerkit-E2-project.powerkit.json", notes, fixed = TRUE)))
  expect_true(any(grepl("Open a saved or shared project", notes, fixed = TRUE)))
  expect_true(any(grepl("SIMULATED, NOT REAL DATA", notes, fixed = TRUE)))
})

test_that("Open shows a plain message for a zip without a project file", {
  none <- make_zip(list(`README.txt` = "notes"))
  shiny::testServer(routing_dir, {
    session$setInputs(open_project = data.frame(name = "x.zip", size = file.info(none)$size,
      type = "application/zip", datapath = none))
    expect_match(output$open_project_message$html, "no powerkit project file", fixed = TRUE)
  })
})

test_that("a result brought back from the browser says it still needs keeping", {
  project <- list(saved = "2026-11-13 10:00:00 UTC", powerkit_version = "0.62.0", result = list())
  back <- as.character(project_opened_ui(project, shown = TRUE, from_browser = TRUE))
  expect_match(back, "Your last result is back", fixed = TRUE)
  expect_match(back, "kept in this browser only", fixed = TRUE)
  expect_false(grepl("Project opened", back, fixed = TRUE))
  expect_match(as.character(project_opened_ui(project, shown = TRUE)), "Project opened", fixed = TRUE)
})
