# Generate a source inventory, not a second evidence registry.
# From the repository root: Rscript scripts/release-support.R [--check]
release_support <- function(root = ".") {
  app <- new.env(parent = globalenv())
  # Locale collation differs for forms.R versus forms_ui.R across systems.
  paths <- sort(list.files(file.path(root, "app/routing/R"), pattern = "[.]R$", full.names = TRUE), method = "radix")
  for (path in paths) sys.source(path, envir = app)
  tree <- yaml::read_yaml(file.path(root, "app/routing/tree.yaml"))
  forms <- yaml::read_yaml(file.path(root, "app/routing/forms.yaml"))
  how <- app$about_endpoint_how(forms)
  ids <- names(tree$endpoints)
  ids <- ids[order(suppressWarnings(as.integer(sub("E", "", ids))), ids, na.last = TRUE, method = "radix")]
  cards <- lapply(ids, function(id) {
    ep <- tree$endpoints[[id]]
    form <- forms$forms[[id]]
    # Generated mediation fields depend on mediator count. Two is the initial
    # screen, not an assertion that all allowed mediator counts were enumerated.
    fields <- if (is.null(form)) list() else app$form_fields(app$form_groups(forms, id))
    choices <- Filter(function(f) identical(f$type, "select"), fields)
    selectors <- lapply(choices, function(f) {
      out <- f[intersect(c("id", "path", "default", "shown_if", "choices_shown_if", "sets"), names(f))]
      out$choices <- names(f$choices)
      out
    })
    route <- unname(how[id])
    list(id = id, name = ep$doc_name, technical_name = ep$technical_name, card_status = ep$status,
      access = if (length(route) == 1 && !is.na(route)) route else "guidance",
      declared_template = ep$template, base_design = form$base$design, base_template = form$base$template,
      declared_backend = ep$backend, scope_note = form$scope_note,
      validation_note = ep$validation, selectors = selectors,
      input_bounds = lapply(Filter(function(f) any(c("min", "max", "min_exclusive", "max_exclusive") %in% names(f)), fields),
        function(f) f[intersect(c("id", "path", "min", "max", "min_exclusive", "max_exclusive", "shown_if"), names(f))]))
  })
  sources <- c("app/routing/tree.yaml", "app/routing/forms.yaml",
    "engine/inst/evidence/records.json", "scripts/release-support.R",
    substring(paths, nchar(root) + 2))
  # Hash normalized text so Windows and Linux checkouts have the same inventory.
  hashes <- vapply(sources, function(path) {
    tmp <- tempfile()
    on.exit(unlink(tmp), add = TRUE)
    writeBin(charToRaw(paste(readLines(file.path(root, path), warn = FALSE, encoding = "UTF-8"), collapse = "\n")), tmp)
    unname(tools::md5sum(tmp))
  }, "")
  list(format_version = 1, sources_md5 = as.list(hashes),
    evidence_registry = "engine/inst/evidence/records.json",
    limits = c("Discovery metadata only; no calculation or new validation is performed.",
      "Selectors are individual choices, not valid Cartesian products.",
      "Shared closing fields are included; generated mediation inputs use two mediators.",
      "Engine constraints, dynamic UI logic and all generated model sizes still need case-level audit.",
      "Card status is historical; use analysis_evidence() on a complete selected spec.",
      "No empirical percentage of research designs is established by this inventory."),
    cards = cards)
}

release_support_text <- function(root = ".") {
  inventory <- release_support(root)
  cards <- vapply(inventory$cards, function(card) as.character(jsonlite::toJSON(card,
    auto_unbox = TRUE, null = "null", na = "null")), "")
  inventory$cards <- NULL
  header <- as.character(jsonlite::toJSON(inventory, auto_unbox = TRUE, pretty = TRUE))
  paste0(substr(header, 1, nchar(header) - 1), ',\n  "cards": [\n',
    paste0("    ", cards, collapse = ",\n"), "\n  ]\n}\n")
}
if (sys.nframe() == 0) {
  output <- file.path("docs", "release-support-inventory.json")
  text <- release_support_text()
  if ("--check" %in% commandArgs(TRUE)) {
    old <- paste0(paste(readLines(output, warn = FALSE, encoding = "UTF-8"), collapse = "\n"), "\n")
    # JSON data is the contract; encoders on different systems can use
    # different escaping/whitespace for the same text.
    parse <- function(x) jsonlite::fromJSON(x, simplifyVector = FALSE)
    if (!identical(parse(old), parse(text))) stop("Release inventory is stale; run Rscript scripts/release-support.R")
    message("Release inventory matches source.")
  } else {
    writeBin(charToRaw(text), output)
    message("Wrote ", output)
  }
}
