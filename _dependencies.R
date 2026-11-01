# Declares the project's R packages for renv (see renv::dependencies()).
# This file is never run. engine/DESCRIPTION is the source of truth for the
# engine package; keep this list in step with it (a test in the app's suite,
# test-repo-consistency.R, checks that every package it imports is here).
# scripts/setup-cloud-session-apt.sh installs exactly this list.

# Engine
library(digest)
library(effectsize) # converting a published effect size into the one a card uses
library(jsonlite)
library(jsonvalidate)
library(psych)     # safeguard power's confidence interval

# Backends
library(BayesFactor) # the correlation Bayes factor (correlationBF())
library(bfpwr)
library(car)
library(InteractionPoweR)
library(JustifyAlpha) # a justified alpha (optimal_alpha())
library(lavaan)
library(lme4)      # E33's mixed model (with simr)
library(lmerTest)  # E33's Satterthwaite test (simr's method "sa")
library(manymome)  # the whole-study simulation's implied indirect effects
library(MBESS)     # precision planning for Cohen's d (ss.aipe.smd(), ss.aipe.sm())
library(gsl) # MBESS's ss.aipe.reg.coef() (precision for a regression coefficient)
library(metafor)   # E61's Hartung-Knapp test (rma(test = "knha")), simulated
library(metapower) # E61's planned meta-analysis
library(power4mome)
library(powertools)
library(PUMP)      # joint power for several outcomes in the study plan
library(PMCMRplus) # the Jonckheere-Terpstra test (jonckheereTest())
library(presize)   # precision planning for a correlation and a proportion
library(pwr)
library(pwrss)     # also the mediation_crosscheck validation chunk, with simsem
library(semPower)
library(simr)
library(SimDesign) # MANOVA's multivariate normal scores (rmvnorm())
library(Spower)
library(SuppDists) # the distribution of a sample correlation (pPearson())
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
