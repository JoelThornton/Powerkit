# Load the routing helpers and the data file. Paths are relative to
# app/routing/tests/testthat.
routing_dir <- normalizePath(file.path("..", ".."))
repo_dir <- normalizePath(file.path(routing_dir, "..", ".."))
library(shiny)
source(file.path(routing_dir, "R", "tree.R"), local = FALSE)
source(file.path(routing_dir, "R", "ui.R"), local = FALSE)
source(file.path(routing_dir, "R", "forms.R"), local = FALSE)
source(file.path(routing_dir, "R", "forms_ui.R"), local = FALSE)
source(file.path(routing_dir, "R", "feedback.R"), local = FALSE)
source(file.path(routing_dir, "R", "results.R"), local = FALSE)
source(file.path(routing_dir, "R", "simulations.R"), local = FALSE)
source(file.path(routing_dir, "R", "project.R"), local = FALSE)
source(file.path(routing_dir, "R", "about.R"), local = FALSE)
tree <- load_tree(file.path(routing_dir, "tree.yaml"))
forms <- load_forms(file.path(routing_dir, "forms.yaml"))
# As in app.R: cards for end points that calculate.
tree$calculates <- c(unlist(forms$calculates), names(forms$simulations$endpoints))
options(powerkit.routing_dir = routing_dir)
