# A study plan's overview, its study-wide planning document and its
# "Download everything" zip (docs/saving-projects.md, "Study plans").
# Nothing here calculates: every number is one an analysis's card found,
# or joint power the engine calculated on the plan's page.

# "3 analyses: 1 primary, 1 secondary, 1 check".
plan_role_counts_text <- function(entries) {
  k <- length(entries)
  if (!k) return("No analyses yet")
  roles <- vapply(entries, function(e) e$role %||% "secondary", character(1))
  counts <- vapply(names(plan_roles), function(r) sum(roles == r), integer(1))
  counts <- counts[counts > 0]
  sprintf("%s: %s", if (k == 1) "1 analysis" else sprintf("%d analyses", k),
    paste(sprintf("%d %s", counts, tolower(plan_roles[names(counts)])), collapse = ", "))
}

# The entries in the order the document uses: primary, secondary, then
# checks, each in the plan's own order.
plan_entries_by_role <- function(entries) {
  rank <- match(vapply(entries, function(e) e$role %||% "secondary", character(1)), names(plan_roles))
  entries[order(rank, seq_along(entries))]
}

# An analysis in a plan as the calculation its card made, for the
# functions that build a result's documents.
plan_entry_calc <- function(entry) {
  p <- entry$project %||% list(spec = entry$spec, result = entry$result, route = entry$route)
  list(status = "ok", spec = p$spec, result = p$result, route = p$route %||% list(), form_consistent = TRUE)
}

# The plan's analyses, by spec hash and in order: joint power calculated
# for the plan is used in its document only while these stay the same.
plan_analysis_hashes <- function(plan) {
  vapply(plan$entries, function(e) plan_entry_calc(e)$result$provenance$spec_hash %||% "", character(1))
}

# What the analysis aimed for, in the words its card uses.
plan_entry_target <- function(spec) {
  goal <- spec$goal %||% list()
  if (identical(spec$design, "precision")) return(paste0("interval width ", format(goal$width),
    if (!is.null(goal$assurance)) paste0(", assurance ", format(goal$assurance))))
  if (!is.null(goal$power)) return(paste("power", format(goal$power)))
  gsub("_", " ", goal$type %||% "")
}

# The merged references from several analyses' citation texts
# (export_citations(format = "text")): each reference once, with the line
# that says where it comes from. Only what the results' own citations
# hold, so nothing is written from memory.
plan_merge_citations <- function(texts) {
  blocks <- unlist(lapply(texts, function(t) strsplit(t, "\n[[:space:]]*\n")[[1]]))
  refs <- character()
  for (b in blocks) {
    lines <- strsplit(b, "\n", fixed = TRUE)[[1]]
    if (length(lines) < 2 || !grepl(":$", lines[[1]]) || !all(grepl("^\\s", lines[-1]))) next
    if (grepl("^Methods paragraph", lines[[1]])) next
    body <- paste(trimws(lines[-1]), collapse = " ")
    if (!body %in% names(refs)) refs[[body]] <- paste(c(lines[[1]], lines[-1]), collapse = "\n")
  }
  unname(refs)
}

plan_citation_texts <- function(entries, engine = engine_function) {
  cite <- engine("export_citations")
  if (is.null(cite)) return(character())
  unlist(lapply(entries, function(e) tryCatch(cite(plan_entry_calc(e)$result, format = "text"), error = function(err) NULL)))
}

# A Markdown table cell: one line, no column breaks.
md_cell <- function(x) gsub("|", "\\|", gsub("[\r\n]+", " ", as.character(x %||% "")), fixed = TRUE)

# The study-wide planning document, as Markdown. `joint` is joint power
# (joint_power()) calculated on the plan's page for these analyses, or NULL.
plan_planning_document <- function(plan, tree, forms, joint = NULL, engine = engine_function) {
  entries <- plan_entries_by_role(plan$entries)
  largest <- plan_largest_entry(plan$entries)
  version <- powerkit_version()
  row <- function(e) {
    calc <- plan_entry_calc(e)
    sprintf("| %s | %s | %s | %s | %s | %s |", md_cell(e$label), plan_roles[[e$role %||% "secondary"]],
      if (is.numeric(e$n) && length(e$n) == 1 && is.finite(e$n)) whole(e$n) else "not a sample size result",
      md_cell(plan_entry_sample(e)$unit %||% ""), md_cell(plan_entry_target(calc$spec)),
      md_cell(calc$result$provenance$backend %||% ""))
  }
  methods <- unlist(lapply(seq_along(entries), function(i) {
    e <- entries[[i]]
    text <- tryCatch(planning_methods_text(tree, forms, plan_entry_calc(e)), error = function(err) NULL)
    c(sprintf("### %d. %s (%s)", i, e$label, tolower(plan_roles[[e$role %||% "secondary"]])),
      if (nzchar(e$note %||% "")) paste("Note:", e$note),
      text %||% "The methods paragraph for this analysis couldn't be made; it is in the analysis's own planning document.", "")
  }))
  requirement <- if (!is.null(largest)) c(
    sprintf("The largest comparable requirement is N = %s, for %s.", whole(largest$n), largest$label),
    plan_common_recruitment_caveat) else if (length(entries) > 1) plan_incomparable_note else
    "The plan has one analysis: its requirement is the plan's."
  refs <- plan_merge_citations(plan_citation_texts(entries, engine))
  c(sprintf("# %s", plan$name), "",
    sprintf("Study planning document for review, made with powerkit %s. It restates the analyses in this study plan as each card calculated them; it does not register a preregistration or guarantee the assumptions are correct.", version), "",
    if (nzchar(plan$description %||% "")) c("## About this study", plan$description, ""),
    "## Analyses", plan_role_counts_text(entries), "",
    "| Analysis | Role | N needed | Unit | Target | Backend |", "|---|---|---|---|---|---|",
    vapply(entries, row, ""), "",
    "Roles label and order the analyses; they change no number.", "",
    "## Sample size across the study", requirement, "",
    if (!is.null(joint)) {
      words <- joint_power_sentence(joint, plan$entries)
      c("## The chance that every analysis is significant", unname(words[["headline"]]), unname(words[["detail"]]), "")
    },
    "## Methods, analysis by analysis", "", methods,
    "## References", if (length(refs)) unlist(lapply(refs, function(r) c(r, ""))) else c("No references could be gathered from these results.", ""),
    "Each analysis's own files (its project file, planning document, R script and citations) are in the analyses folder of “Download everything”. The study plan file opens every analysis again in powerkit.")
}

plan_bundle_file_name <- function(plan) sub("\\.powerkit\\.json$", "-everything.zip", plan_file_name(plan))

# A folder name for an analysis: its place in the plan and its card.
plan_analysis_folder <- function(i, entry) {
  slug <- tolower(gsub("[^A-Za-z0-9]+", "-", entry$label %||% "analysis"))
  slug <- substr(gsub("^-+|-+$", "", slug), 1L, 40L)
  sprintf("%02d-%s", i, gsub("-+$", "", slug))
}

plan_bundle_readme <- function(plan, plan_file, docs, analyses, skipped) {
  about <- c(
    sprintf("%s\n  Opens the whole plan again in powerkit: on the Study plans page choose \"Open a saved plan\" and pick this file, or this zip.", plan_file),
    if ("md" %in% docs) "study-plan.md\n  The study-wide planning document as Markdown, to paste into a preregistration or edit.",
    if ("docx" %in% docs) "study-plan.docx\n  The study-wide planning document as an editable Word document.",
    if ("refs" %in% docs) "references.txt\n  Every analysis's references, each once.",
    if (length(analyses)) "analyses/\n  One folder per analysis, with its own \"Download everything\": project file, planning document, R script, citations and, where offered, SIMULATED (not real) data.")
  c(sprintf("powerkit: everything for the study plan \"%s\", saved %s", plan$name, format(Sys.time(), "%d %B %Y at %H:%M UTC", tz = "UTC")), "",
    about, "",
    if (length(skipped)) c("Couldn't be made, so not included:", paste0("  ", skipped), ""),
    "Opening the zip in powerkit opens the plan file, not an analysis's own project file.")
}

# "Download everything" for a plan. The plan file is written first, without
# a fallback, and the finished zip is checked for it, as for one result
# (write_bundle()). Each analysis's files come from write_bundle() on its
# saved spec, result and route, so nothing is recalculated; anything else
# that can't be made is skipped and the README says so.
write_plan_bundle <- function(plan, file, tree, forms, joint = NULL, engine = engine_function) {
  dir <- tempfile("powerkit-plan-bundle-")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE))
  plan_file <- plan_file_name(plan)
  text <- plan_to_text(plan, write = engine("write_study_plan"))
  if (!nzchar(text)) stop("The plan file couldn't be written.")
  writeLines(text, file.path(dir, plan_file), useBytes = TRUE)
  docs <- character(); skipped <- character()
  doc <- tryCatch(plan_planning_document(plan, tree, forms, joint = joint, engine = engine), error = function(e) NULL)
  if (!is.null(doc)) {
    if (!inherits(try(writeLines(doc, file.path(dir, "study-plan.md"), useBytes = TRUE), silent = TRUE), "try-error")) docs <- c(docs, "md")
    if (!inherits(try(docx_document(doc, file.path(dir, "study-plan.docx"), powerkit_version()), silent = TRUE), "try-error") &&
      file.exists(file.path(dir, "study-plan.docx"))) docs <- c(docs, "docx")
  } else skipped <- c(skipped, "the study-wide planning document")
  refs <- plan_merge_citations(plan_citation_texts(plan$entries, engine))
  if (length(refs)) {
    writeLines(c(sprintf("References for the study plan \"%s\"", plan$name), "", paste0(refs, "\n")), file.path(dir, "references.txt"), useBytes = TRUE)
    docs <- c(docs, "refs")
  }
  dir.create(file.path(dir, "analyses"))
  analyses <- character()
  for (i in seq_along(plan$entries)) {
    e <- plan$entries[[i]]
    folder <- plan_analysis_folder(i, e)
    calc <- plan_entry_calc(e)
    inner <- tempfile(fileext = ".zip")
    ok <- !inherits(try(write_bundle(calc, calc$route$endpoint %||% e$endpoint, inner, tree, forms, engine = engine), silent = TRUE), "try-error")
    if (ok && file.exists(inner)) {
      dir.create(file.path(dir, "analyses", folder))
      zip::unzip(inner, exdir = file.path(dir, "analyses", folder), junkpaths = TRUE)
      analyses <- c(analyses, folder)
    } else skipped <- c(skipped, sprintf("the files for analysis %d (%s)", i, e$label))
    unlink(inner)
  }
  writeLines(plan_bundle_readme(plan, plan_file, docs, analyses, skipped), file.path(dir, "README.txt"))
  top <- c("README.txt", plan_file, c(md = "study-plan.md", docx = "study-plan.docx", refs = "references.txt")[docs])
  inside <- c(top, if (length(analyses)) "analyses")
  zip::zip(file, files = unname(inside), root = dir, mode = "mirror")
  if (!plan_file %in% zip::zip_list(file)$filename) stop("The zip is missing the plan file.")
  invisible(zip::zip_list(file)$filename)
}
