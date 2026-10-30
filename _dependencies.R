# Declares the project's R packages for renv (see renv::dependencies()).
# This file is never run. engine/DESCRIPTION is the source of truth for the
# engine package; keep this list in step with it (a test in the app's suite,
# test-repo-consistency.R, checks that every package it imports is here).
# scripts/setup-cloud-session-apt.sh installs exactly this list.

# Engine
library(digest)
library(jsonlite)
library(jsonvalidate)
library(psych)     # safeguard power's confidence interval

# Backends
library(bfpwr)
library(InteractionPoweR)
library(lavaan)
library(lme4)      # E33's mixed model (with simr)
library(lmerTest)  # E33's Satterthwaite test (simr's method "sa")
library(manymome)  # the whole-study simulation's implied indirect effects
library(power4mome)
library(powertools)
library(pwr)
library(pwrss)     # also the mediation_crosscheck validation chunk, with simsem
library(semPower)
library(simr)
library(Spower)
library(Superpower)
library(TOSTER)

# Tests
library(simsem)
library(testthat)

# The app (app/routing/; it calls the engine above). All are in
# renv.lock.
library(bslib)
library(callr)   # E9's calculation runs in a background R process
library(curl)    # the Feedback tab's Send button
library(pkgload) # loads the engine from engine/ when it isn't installed
library(shiny)
library(yaml)
