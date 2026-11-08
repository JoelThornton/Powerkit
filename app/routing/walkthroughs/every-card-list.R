# Writes the card list every-card.js works through: every card in
# tree.yaml, whether it has an input screen and calculates, and the app
# suite's example values for it (tests/testthat/helper-forms.R).
#
# Run from the repository root:
#   Rscript app/routing/walkthroughs/every-card-list.R [cards.json]
suppressMessages({
  library(yaml)
  library(jsonlite)
})
out <- commandArgs(TRUE)[1]
if (is.na(out)) out <- file.path(tempdir(), "cards.json")
routing <- "app/routing"
if (!file.exists(file.path(routing, "tree.yaml"))) stop("Run this from the repository root.", call. = FALSE)
source(file.path(routing, "tests", "testthat", "helper-forms.R"))
tree <- read_yaml(file.path(routing, "tree.yaml"))
forms <- read_yaml(file.path(routing, "forms.yaml"))
cards <- lapply(names(tree$endpoints), function(id) {
  card <- tree$endpoints[[id]]
  list(
    id = id,
    title = card$title %||% card$name %||% "",
    has_form = id %in% names(forms$forms),
    calculates = id %in% forms$calculates,
    simulation = id %in% names(forms$simulations$endpoints),
    example = form_examples[[id]]
  )
})
writeLines(toJSON(cards, auto_unbox = TRUE, null = "null"), out)
without <- vapply(cards, function(x) x$has_form && is.null(x$example), logical(1))
cat(sprintf("%d cards, %d with an input screen, %d with example values; written to %s\n",
  length(cards), sum(vapply(cards, `[[`, logical(1), "has_form")), sum(!vapply(cards, function(x) is.null(x$example), logical(1))), out))
if (any(without)) cat("Input screens without example values:", paste(names(tree$endpoints)[without], collapse = " "), "\n")
