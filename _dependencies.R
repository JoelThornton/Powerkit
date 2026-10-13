# Declares the project's R packages for renv (see renv::dependencies()).
# This file is never run. engine/DESCRIPTION is the source of truth for the
# engine package; keep this list in step with it.

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

# Shiny app (app/; prototype ahead of build phase 5)
library(bslib)
library(pkgload)
library(shiny)

# Tests
library(pwr)
library(testthat)
