# Keeping a result, and the documents made from it (13 November 2026).
#
# The result screen used to offer six equal download buttons at the foot
# of a long page, with "Save project" (the only file that reopens in
# powerkit) styled like "Citations", so a visitor could download the
# planning PDF, think the work was saved, and lose it. The screen now
# separates the two jobs:
#
# * "Keep this result", right under the answer: Save project file, Copy a
#   link and Add to my study plan, the three ways to come back to it, with
#   a line that says whether the result has been kept yet.
# * "Documents for your study", in "Write it up and save it": the
#   planning document, the R script, citations and "Download everything
#   (.zip)", said plainly not to reopen in powerkit. The zip holds the
#   project file too, and "Open a saved or shared project" opens the zip
#   itself (zip_project_file()).
#
# Two safety nets: the last current result is kept in this browser
# (localStorage, as unfinished answers already are) so a closed tab can
# bring it back, and the browser asks before leaving a result that hasn't
# been kept (keep_result_js).

last_result_key <- "powerkit-last-result"

# The box under the answer. NULL when the result can't be exported (its
# effect-size source changed since it was calculated).
keep_result_ui <- function(can_export, plan = TRUE, kept = FALSE) {
  if (!can_export) return(NULL)
  div(class = "keep-result", role = "region", `aria-labelledby` = "keep_result_title",
    div(class = "keep-result-head",
      h4(id = "keep_result_title", class = "h6 mb-0", "Keep this result"),
      tags$span(id = "keep-status", class = "keep-status", role = "status", `aria-live` = "polite",
        `data-kept` = if (kept) "yes" else "no", if (kept) "Opened from a saved file" else "Not saved yet")),
    div(class = "keep-result-actions",
      download_button("download_project", "Save project file", class = "btn btn-primary"),
      share_link_ui("project"),
      if (plan) uiOutput("study_plan_bar", inline = TRUE)),
    p(class = "small mb-0", "Opens again in powerkit with your answers and result. The documents further down are for reading, running and citing; they don't reopen here."))
}

# The documents, in "Write it up and save it".
documents_ui <- function(can_export, backend, planning_menu) {
  tagList(
    h4(class = "h6 mt-3", "Documents for your study"),
    p(class = "small", "These don't reopen in powerkit. To come back to this result, use “Keep this result” under the answer, or download everything: the zip holds the project file too."),
    div(class = "nav-buttons result-downloads",
      if (can_export) planning_menu,
      if (can_export) download_button("download_script", "R script", class = "btn btn-outline-primary"),
      download_button("download_citations", "Citations", class = "btn btn-outline-primary"),
      if (can_export) download_button("download_bundle", "Download everything (.zip)", class = "btn btn-outline-primary")),
    tags$ul(class = "result-downloads-notes small",
      if (can_export) tags$li(tags$strong("Planning document: "), "the plan, its reasoning and the methods paragraph, for an ethics application, a preregistration or a supervisor."),
      if (can_export) tags$li(tags$strong("R script: "), "reproduces this result with ", backend, " alone; powerkit isn't needed."),
      tags$li(tags$strong("Citations: "), "the package's own citation(), its method paper and the software used."),
      if (can_export) tags$li(tags$strong("Download everything: "), "all of these with the project file and, where there is one, the simulated data set, in one zip. Open the zip itself from the start screen to carry on.")))
}

keep_result_css <- "
  .keep-result { margin-top: 1rem; padding: 0.9rem 1rem; border: 2px solid var(--pk-blue, #0a5a8c); border-radius: 10px; background: #f3f8fc; }
  .keep-result-head { display: flex; flex-wrap: wrap; align-items: baseline; gap: 0.75rem; margin-bottom: 0.6rem; }
  .keep-result-actions { display: flex; flex-wrap: wrap; align-items: center; gap: 0.5rem; margin-bottom: 0.5rem; }
  .keep-result-actions .study-plan-bar { margin-top: 0 !important; }
  .keep-status { font-size: 0.85rem; font-weight: 600; padding: 0.1rem 0.55rem; border-radius: 999px; background: #fff3cd; color: #664d03; }
  .keep-status[data-kept='yes'] { background: #d1e7dd; color: #0f5132; }
"

keep_result_js <- sprintf("
(function() {
  var KEY = '%s';
  // Whether the result on screen has been kept (saved, linked or added to
  // the plan) since it appeared. A new result panel starts unkept.
  var unkept = false;
  function mark(how) {
    unkept = false;
    var s = document.getElementById('keep-status');
    if (s) { s.textContent = how; s.setAttribute('data-kept', 'yes'); }
  }
  $(document).on('shiny:value', function(e) {
    if (e.name !== 'form_result') return;
    setTimeout(function() { var s = document.getElementById('keep-status'); unkept = !!s && s.getAttribute('data-kept') === 'no'; }, 0);
  });
  document.addEventListener('click', function(e) {
    var t = e.target && e.target.closest ? e.target.closest('#download_project, #download_bundle, #plan_add') : null;
    if (!t || t.classList.contains('disabled')) return;
    mark(t.id === 'plan_add' ? 'In your study plan' : 'Saved as a file');
  }, true);
  // A link copied for this result counts as kept.
  $(document).on('pk:share-link', function(e, kind) { if (kind === 'project') mark('Link made'); });
  // An answer changed after calculating: the result on screen is no longer
  // the one to keep, so nothing to warn about until Calculate again.
  $(document).on('pk:calculation-current', function(e, current) { if (!current) unkept = false; });
  window.addEventListener('beforeunload', function(e) {
    if (!unkept || !window.Shiny || !Shiny.shinyapp || !Shiny.shinyapp.isConnected()) return;
    e.preventDefault(); e.returnValue = '';
  });
  // The last current result, kept in this browser for the next visit.
  Shiny.addCustomMessageHandler('pk_last_result', function(text) {
    try { if (text) window.localStorage.setItem(KEY, text); else window.localStorage.removeItem(KEY); } catch (e) {}
  });
  $(document).on('shiny:connected', function() {
    var saved = null;
    try { saved = window.localStorage.getItem(KEY); } catch (e) {}
    if (saved) Shiny.setInputValue('pk_saved_result', saved, {priority: 'event'});
  });
})();
", last_result_key)

# The last result in the browser: the project file's text, or "" when it
# is too large to keep there (browsers allow about 5 MB a site, shared
# with the draft and the study plan).
last_result_for_browser <- function(calc, write = engine_function("write_project")) {
  if (is.null(calc) || !identical(calc$status, "ok") || is.null(write)) return("")
  text <- tryCatch(write(calc$spec, calc$result, route = calc$route), error = function(e) "")
  if (nchar(text) > 1.5e6) "" else text
}

# Whether the result kept in the browser is for the same answers as the
# draft kept beside it (the draft is rewritten after every change, so it
# says where the visitor left off). Then reopening brings the result back
# rather than only the answers.
last_result_matches_draft <- function(text, draft_record) {
  if (!is.character(text) || length(text) != 1 || !nzchar(text) || !is.list(draft_record)) return(FALSE)
  project <- tryCatch(jsonlite::fromJSON(text, simplifyVector = FALSE), error = function(e) NULL)
  route <- project$route
  if (!is.list(route) || !identical(route$endpoint, draft_record$route$endpoint)) return(FALSE)
  calculation_matches_values(list(status = "ok", route = route), draft_record$route$form_values %||% list())
}

# For a zip from "Download everything": the one project file inside it,
# extracted, so "Open" reads it as if it had been chosen on its own. NULL
# when the file isn't a zip; a plain-English problem (a string, classed
# "zip_problem") when it is a zip without exactly one project file.
zip_project_file <- function(path) {
  if (!file.exists(path)) return(NULL)
  con <- file(path, "rb")
  magic <- tryCatch(readBin(con, "raw", 4), finally = close(con))
  if (!identical(magic, as.raw(c(0x50, 0x4b, 0x03, 0x04)))) return(NULL)
  problem <- structure(zip_without_project, class = "zip_problem")
  if (file.info(path)$size > 50e6) return(problem)
  listing <- tryCatch(zip::zip_list(path), error = function(e) NULL)
  if (is.null(listing)) return(problem)
  inside <- listing$filename[grepl("\\.powerkit\\.json$", listing$filename) & listing$uncompressed_size <= 5e6]
  if (length(inside) != 1) return(problem)
  dir <- tempfile("powerkit-zip-")
  dir.create(dir)
  # Extract that one entry under its own base name: a crafted path inside
  # the zip can't write outside the temporary folder.
  ok <- tryCatch({ zip::unzip(path, files = inside, exdir = dir, junkpaths = TRUE); TRUE }, error = function(e) FALSE)
  out <- file.path(dir, basename(inside))
  if (ok && file.exists(out)) out else problem
}

zip_without_project <- "This zip has no powerkit project file in it. Open the zip saved with “Download everything”, or the .powerkit.json file on its own."

# What "Download everything" puts in the zip, with a note on each file.
bundle_readme <- function(endpoint, files) {
  about <- c(
    project = "Opens again in powerkit: on the start screen choose \"Open a saved or shared project\" and pick this file, or this zip.",
    planning_md = "The planning document as Markdown, to paste into a preregistration or edit.",
    planning_docx = "The planning document as an editable Word document.",
    script = "Reproduces the result in R with the backend package alone.",
    citations = "The references to cite for this calculation.",
    data = "SIMULATED, NOT REAL DATA: a made-up data set of the planned size for checking analysis code.")
  lines <- vapply(names(files), function(k) sprintf("%s\n  %s", basename(files[[k]]), about[[k]]), character(1))
  c(sprintf("powerkit: everything for %s, saved %s", endpoint, format(Sys.time(), "%d %B %Y at %H:%M UTC", tz = "UTC")), "",
    lines, "", "The planning document as a PDF is made from the result screen (Planning document), using your browser's print dialog.")
}

# "Download everything": the zip. The project file is written first and
# without a fallback, and the finished zip is checked for it, so a zip that
# can't be reopened is never handed over: if the project file can't be
# written the download fails instead. The documents are each skipped if
# they can't be made, and the README lists what is there.
write_bundle <- function(calc, ep, file, tree, forms, engine = engine_function) {
  dir <- tempfile("powerkit-bundle-")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE))
  files <- c(project = file.path(dir, project_file_name(ep)))
  engine("write_project")(calc$spec, calc$result, route = calc$route, file = files[["project"]])
  if (!file.exists(files[["project"]]) || !file.size(files[["project"]])) stop("The project file couldn't be written.")
  attempt <- function(key, path, make) {
    if (inherits(try(make(path), silent = TRUE), "try-error") || !file.exists(path)) return(files)
    c(files, stats::setNames(path, key))
  }
  if (!isTRUE(calc$route$form_values$source_stale)) {
    doc <- tryCatch(planning_document(tree, forms, calc), error = function(e) NULL)
    if (!is.null(doc)) {
      files <- attempt("planning_md", file.path(dir, "powerkit-study-planning.md"), function(p) writeLines(doc, p, useBytes = TRUE))
      files <- attempt("planning_docx", file.path(dir, "powerkit-study-planning.docx"), function(p) docx_document(doc, p, powerkit_version()))
    }
  }
  files <- attempt("script", file.path(dir, sprintf("powerkit-%s-script.R", ep)),
    function(p) engine("export_script")(calc$spec, calc$result, file = p))
  files <- attempt("citations", file.path(dir, sprintf("powerkit-%s-citations.txt", ep)),
    function(p) engine("export_citations")(calc$result, format = "text", file = p))
  n <- simulated_data_n_for(calc$spec, calc$result)
  if (!is.na(n) && isTRUE(tryCatch(engine("simulated_data_available")(calc$spec), error = function(e) FALSE))) {
    files <- attempt("data", file.path(dir, sprintf("SIMULATED-not-real-data-%s.csv", ep)),
      function(p) engine("simulated_data")(calc$spec, n, seed = calc$result$provenance$seed %||% 1, file = p))
  }
  writeLines(bundle_readme(ep, files), file.path(dir, "README.txt"))
  zip::zip(file, files = c("README.txt", basename(files)), root = dir, mode = "mirror")
  if (!basename(files[["project"]]) %in% zip::zip_list(file)$filename) stop("The zip is missing the project file.")
  invisible(basename(files))
}
