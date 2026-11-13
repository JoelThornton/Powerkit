# powerkit

> **⚠️ In development: not ready for use.** powerkit is still being built.
> Its results are not yet fully validated, so please don't use it to plan
> real studies yet. See [`docs/validation-log.md`](docs/validation-log.md)
> for the current validation status, and [`docs/status.md`](docs/status.md)
> for where the project is.

A power analysis tool for research studies. You describe your study once, in plain
terms, and powerkit routes it to established R packages and documented methods to work out the power,
the sample size you need, or the smallest effect you could detect.

Powerkit mainly adapts established R packages. Where it implements a formula
or simulation itself, the method, source and checks are documented. Its packages include
[pwr](https://cran.r-project.org/package=pwr),
[pwrss](https://cran.r-project.org/package=pwrss),
[Superpower](https://cran.r-project.org/package=Superpower),
[Spower](https://cran.r-project.org/package=Spower),
[power4mome](https://cran.r-project.org/package=power4mome),
[InteractionPoweR](https://cran.r-project.org/package=InteractionPoweR),
[powertools](https://cran.r-project.org/package=powertools),
[TOSTER](https://cran.r-project.org/package=TOSTER),
[semPower](https://cran.r-project.org/package=semPower) and
[bfpwr](https://cran.r-project.org/package=bfpwr),
and it is grateful to their authors. Every result records its backend,
method and software versions. On top of those packages, powerkit adds:

- one specification format for every design;
- checks that the population you describe is possible;
- validation against direct calls to those packages, analytic results
  and Type I error, with checks against published results added as they
  are transcribed;
- a record of exactly how each result was produced (spec hash, seed,
  package versions);
- an R script for each result that reproduces it with the backend package
  alone, and the citations for that package and its method paper.

A prototype point-and-click app is in `app/routing/` (how to run it:
[`docs/run-it-yourself.md`](docs/run-it-yourself.md)). It follows a
four-screen design (decided 18 October 2026, `docs/decisions.md`):

1. **Start:** choose the analysis list, guided questions or a whole-study
   plan. The input screen then asks the goal, whether the sample is fixed,
   and how several tests support the claim when applicable.
2. **Find your design:** a few plain questions route you to the right
   analysis.
3. **Inputs:** the effect size is at the centre. You say where it comes
   from in your own words, or that you can't justify one, which leads to
   the smallest effect you could detect.
4. **Result:** a plain reading that keeps the condition ("if the true
   effect is the one you entered, about 8 in 10 studies like this would
   get a significant result"), 80% and 95% power side by side, what power
   can't tell you, an explore panel, and a write-up (a short methods paragraph
   and a full version).

## Status

> **powerkit is in early development. Do not use it to plan real studies
> yet.** Most published-value checks are still to come, and the interface
> may change.

The app lists every analysis it knows: 70 that run and a few that are
not in powerkit yet (those cards point to the tools that do the job). An
analysis that runs is marked either **validated** or **validation in
progress**. Validated has one meaning, the one defined at the top of the
[validation log](docs/validation-log.md): a recorded full run of its checks
agrees with the package that computes it and with analytic results, and
keeps the Type I error rate. Published examples are added as they are
transcribed, so a validated analysis may not have one yet. The analyses
that run, and the packages they use:

| Family | Analyses | Packages |
| --- | --- | --- |
| t-tests | one sample, paired, two groups (Student's or Welch's), with the rank-based, Bayes factor and minimum-effect versions | pwr, pwrss, Spower, bfpwr |
| Correlations and proportions | Pearson's r and the rank correlations; two independent or two dependent correlations; one or two proportions, Fisher's exact test, McNemar's test; chi-square tests of independence and goodness of fit; a trend in proportions | pwr, pwrss, Spower, BayesFactor |
| Variances | one variance against a value, two groups' variances (by formula, as the G\*Power manual gives them), paired variances | base R, Spower |
| ANOVA | one-way (between or within; Welch's F, the Kruskal-Wallis and Jonckheere-Terpstra tests and the Bayes factor as options), factorial designs with two or three factors (between, within or mixed, with the aligned rank transform), planned contrasts, ANCOVA, MANOVA and Hotelling's T-squared | Superpower, pwrss, Spower |
| Regression | multiple regression, logistic, multinomial, ordinal, Poisson, negative binomial and zero-inflated regression; interactions between scores or with groups, and three-way interactions | pwrss, InteractionPoweR, powertools, Spower |
| Mediation | simple, parallel and serial mediation; moderated mediation (PROCESS models 7, 14, 58, 59 and more); X or W as two groups; pairs of people (the actor-partner model) | power4mome |
| Multilevel and longitudinal | cluster-randomised and multisite trials; people in groups, and groups in larger groups; many items or stimuli per person; growth curves; cross-lagged panels; interrupted time series | powertools, simr, longpower, powRICLPM, PITS |
| Equivalence and non-inferiority | two one-sided tests for means, a correlation and two proportions; non-inferiority | TOSTER, pwrss |
| Latent variables and measurement | structural equation models (model fit, measurement invariance, factor correlations and paths), exploratory factor analysis, latent profiles, differential item functioning, reliability and rater agreement, signal detection (d') | semPower, WebPower, psych, mclust, irtpwr, ICC.Sample.Size, statpsych, kappaSize |
| Other designs | time-to-event outcomes (log-rank test, Cox regression), meta-analysis, precision planning for a confidence-interval width | Hmisc, powerSurvEpi, metafor, metapower, MBESS, presize |
| Generic tests | t, F, chi-square and z from a noncentrality parameter | pwrss |

Each card names the exact functions it calls. Where each design stands,
and what comes next, is in [`docs/status.md`](docs/status.md).

For each design except the generic tests, powerkit can find the sample
size that reaches a target power, or the power at a given sample size;
most can also find the smallest effect you could detect at a given sample
size, including every ANOVA and regression. Power is computed by formula
where one exists, and by simulation otherwise or on request. A
whole-study planner simulates several analyses of one study together.

## Try the app (no R experience needed)

Open <https://joelthornton-powerkit.share.connect.posit.cloud> in a
browser: nothing to install. It is a prototype; its results are not yet
fully validated, so don't use them for real studies.

To run it on your own computer instead, follow [`docs/run-it-yourself.md`](docs/run-it-yourself.md): install R,
download this repository as a ZIP, and run one line,
`source("run_powerkit.R")`, which installs what powerkit needs and opens
the prototype in your browser.

## Install the engine

The engine is an R package in the `engine/` folder of this repository.
Install it from GitHub with:

```r
# install.packages("remotes")
remotes::install_github("JoelThornton/Powerkit", subdir = "engine", dependencies = TRUE)
```

`dependencies = TRUE` also installs the backend packages that only some
designs use (the engine's Suggests). Without it, powerkit installs the
packages most designs need, and a design whose backend is missing stops
with a message naming the package to install.

## Try it

```r
library(powerkit)

# An example spec: a 2 x 2 mixed design (therapy vs waitlist, measured
# before and after), with the interaction as the effect of interest.
spec <- read_spec(system.file("specs", "anova_2x2_mixed.json", package = "powerkit"))
spec

result <- run_spec(spec)
result

# A standalone script that reproduces the result with Superpower alone,
# and what to cite.
export_script(spec, result, "reproduce.R")
cat(export_citations(result))
```

A spec is a JSON file. `read_spec()` checks it and explains any problem in
plain English. Example specs for every design are in
[`engine/inst/specs/`](engine/inst/specs/). The format is defined by
[`engine/inst/schema/design.schema.json`](engine/inst/schema/design.schema.json).

## Documentation

- [Map of the docs](docs/README.md): which document to read for what,
  and which are history.
- [Status](docs/status.md): where the project is and what's next.
- [First-release support plan](docs/v1-support-plan.md): coverage target,
  representative benchmark, complex-design audits and evidence gates.
- [Handover](docs/handover.md): the working rules, for whoever picks the
  project up next.
- [Validation log](docs/validation-log.md): every full validation run.
- [Build guide](docs/build-guide.md): the plan, architecture, spec format,
  engine design and validation targets.
- [Decisions log](docs/decisions.md): why things are the way they are.
- [Design finder](docs/design-finder.md): the question tree for the app's
  "find my design" route.
- [Conventions](docs/conventions.md): what the established tools do by
  default, what powerkit does, and every departure.
- [Phase 3b questions](docs/phase-3b-questions.md): the statistical
  decisions a binary X or W needs before it is coded.
- [Upstream questions](docs/upstream-questions.md): open technical
  questions about the packages powerkit builds on.
- [Engine news](engine/NEWS.md): user-visible changes.
- [CLAUDE.md](CLAUDE.md): project rules for contributors and coding
  assistants.

## Development

```r
# from the engine/ folder
devtools::test()   # unit tests
devtools::check()  # R CMD check
```

High-replication validation tests are skipped by default. On GitHub
Actions they run every night that the engine changed (the short chunks,
and the long chunks whose code changed) and in full every Sunday
(`scripts/validation-plan.R`). They also run on demand, on a local machine, with
`scripts/run-validation.R` (see the instructions at the top of that file);
it can be stopped and resumed, and run one design at a time. Package versions for development are pinned with
[renv](https://rstudio.github.io/renv/) (`renv.lock` at the repository root).

## Licence

The engine is free software, licensed under the GNU General Public License,
version 3 or later (GPL (>= 3)). See [`LICENSE`](LICENSE).

<meta name="google-site-verification" content="7-BujXKugl-RpJ5nQE4NepC5vJQ-oAmUHs3EkopTuW0" />
