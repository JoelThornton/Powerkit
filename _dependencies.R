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
library(manymome)  # the whole-study simulation's implied indirect effects
library(power4mome)
library(powertools)
library(Spower)
library(Superpower)

# Tests
library(pwr)
library(pwrss)   # pwrss and simsem: the mediation_crosscheck validation chunk
library(simsem)
library(testthat)

# Routing prototype (app/routing/; no engine calls). All three are in
# renv.lock.
library(bslib)
library(callr)   # E9's calculation runs in a background R process
library(curl)    # the Feedback tab's Send button
library(shiny)
library(yaml)
