# Scoped method expansion and remaining priorities

This records feature selection, not a promise to implement every possible
model or a blanket validation claim. The maintainer's decisions and ordered
queue in `next.md` take precedence over suggestions from a review.

The original review's candidate gaps now have initial, specified routes on
main: multinomial and zero-inflated outcomes, growth curves with three or
more occasions (now including scheduled dropout/unequal groups), selected
IRT/DIF, moderation with more groups or a binary outcome, and signal-detection
sensitivity. Their forms specify the population and analysis; the generated
About catalogue is the current inventory, rather than another copied list.

This review round adds completed independent checks of the existing
zero-inflated route: the declared count distributions, normal score predictor
and count/joint analysis cases in `test-validation-zero-inflated.R`.
The likelihood is maximised separately from pscl for the reference. Three
blocks passed; the published-example block remains skipped. Details, exact
source and numeric comparisons are in `validation-log.md` and its linked
summary. These checks do not establish arbitrary missingness, extra predictors,
binary X, every analysis variant or complete release validation.

Random-intercept cross-lagged panels (E74), interrupted time series (E45),
latent profiles (E58) and factor recovery (E73) now have scoped calculation
routes; their presence does not settle their scientific validity or cover
all models in those families. Further dyadic/mediation variants remain in
the queue. The [first-release plan](v1-support-plan.md) now defines the
coverage benchmark, complex-design audits and case-specific evidence gates. Frequentist
group-sequential designs remain distinct from existing Bayesian sequential
planning. Each addition needs its specified data-generating population,
actual analysis, route/card/form, reproducible exports, independent numerical
checks and honest limitations through `adding-a-test.md`. An unsupported
method must not be advertised as handled by a generic simulation button.

Prioritisation and an initial scoped expansion are delivered. The remaining
feature programme and untranscribed published examples are not declared done.
