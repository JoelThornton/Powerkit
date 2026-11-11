# The engine's optional packages, which the online app installs.
#
# Packages that only some designs need are in the engine's Suggests, not its
# Imports, so installing powerkit doesn't install every backend. Connect
# Cloud installs what rsconnect::writeManifest() finds the app using: the
# engine's Imports, and every package named in the app's files. This file
# names the engine's Suggests so the online app has them all. It is never
# run (Shiny sources only app.R and what app.R sources).
# test-repo-consistency.R checks it matches engine/DESCRIPTION's Suggests,
# leaving out testthat and withr, which only the tests use.

if (FALSE) {
  library(ARTool)
  library(BayesRepDesign)
  library(brunnermunzel)
  library(boot)
  library(GPArotation)
  library(gsl)
  library(hypergeo)
  library(ICC.Sample.Size)
  library(irtpwr)
  library(JustifyAlpha)
  library(kappaSize)
  library(lavaan)
  library(longpower)
  library(lmhelprs)
  library(MASS)
  library(Matrix)
  library(MBESS)
  library(mclust)
  library(metafor)
  library(metapower)
  library(mirt)
  library(nnet)
  library(pbkrtest)
  library(PITS)
  library(PMCMRplus)
  library(POMADE)
  library(powerSurvEpi)
  library(powRICLPM)
  library(presize)
  library(pscl)
  library(PUMP)
  library(quantreg)
  library(semPower)
  library(simsem)
  library(statpsych)
  library(survival)
  library(TOSTER)
  library(vegan)
  library(WebPower)
}
