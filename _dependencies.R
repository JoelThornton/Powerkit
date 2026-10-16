# Declares the project's R packages for renv (see renv::dependencies()).
# This file is never run. engine/DESCRIPTION is the source of truth for the
# engine package; keep this list in step with it. The Shiny app (build
# phase 5) will add its own packages here.

# Engine
library(digest)
library(jsonlite)
library(jsonvalidate)

# Backends
library(InteractionPoweR)
library(lavaan)
library(power4mome)
library(Spower)
library(Superpower)

# Tests
library(pwr)
library(testthat)

# Routing prototype (app/routing/; no engine calls). All three are in
# renv.lock.
library(bslib)
library(shiny)
library(yaml)
