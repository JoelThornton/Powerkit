# powerkit

> **⚠️ In development: not ready for use.** powerkit is still being built.
> Its results are not yet fully validated, so please don't use it to plan
> real studies yet. See [`docs/validation-log.md`](docs/validation-log.md)
> for the current validation status, and [`docs/status.md`](docs/status.md)
> for where the project is.

A power analysis tool for psychology. You describe your study once, in plain
terms, and powerkit routes it to a validated R package to work out the power,
the sample size you need, or the smallest effect you could detect.

powerkit does not reimplement the statistics. It builds on established,
peer-reviewed R packages, among them
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
and is grateful to their authors. Every result records which package
computed it. On top of those packages, powerkit adds:

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

1. **Start:** can you choose your sample size or is it fixed; are you
   testing a prediction or estimating something; does your claim rest on
   one test or several.
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

An optional AI assistant may come last.

## Status

> **powerkit is in early development. Do not use it to plan real studies
> yet.** Most published-value checks are still to come, and the interface
> may change.

The app lists every analysis it knows, about 60, from **runs in powerkit
(validated)** and **runs, validation in progress** to **coming soon** and
**not in powerkit yet** (those cards point to the tools that do the job).
The ones that run, and the package each one uses:

| Family | Analyses | Package |
| --- | --- | --- |
| t-tests | one sample, paired, two groups (Student's or Welch's), with the rank-based and Bayes factor versions | pwr, pwrss, Spower, bfpwr |
| Correlations and proportions | Pearson's r; two independent or two dependent correlations; one or two proportions, Fisher's exact test, McNemar's test; chi-square tests of independence and goodness of fit | pwr, pwrss |
| Variances | one variance against a value, two groups' variances | Spower (simulation) |
| ANOVA | one-way (between or within; Welch's F and the Kruskal-Wallis test as options), 2 x 2 and larger factorial designs (between, within or mixed, with the MANOVA approach beside the F), three factors, planned contrasts, ANCOVA | Superpower, pwrss, Spower |
| Regression | multiple regression R², logistic and Poisson regression, interactions between two scores | pwrss, InteractionPoweR |
| Mediation | simple, parallel and serial mediation; first- and second-stage moderated mediation (PROCESS models 4, 6, 7 and 14) | power4mome (simulation) |
| Clustered designs | cluster-randomised and multisite trials, score or yes/no outcome | powertools |
| Equivalence and non-inferiority | equivalence (TOST) for two groups, paired, one sample, a correlation, two proportions; non-inferiority for two groups, paired, one sample, two proportions | TOSTER, pwrss |
| Structural equation models | model fit (RMSEA), measurement invariance (across groups or over time), factor correlations, latent regression | semPower |
| Generic tests | t, F, chi-square and z from a noncentrality parameter | pwrss |

What "validated" means is defined at the top of the
[validation log](docs/validation-log.md); where each design stands, and
what comes next, is in [`docs/status.md`](docs/status.md).

For each design except the generic tests, powerkit can find the sample
size that reaches a target power, or the power at a given sample size. For the t-tests, Pearson's r,
two proportions, the chi-square test of independence, the 2 x 2 ANOVAs,
regression interactions and clustered designs it can also find the
smallest effect you could detect at a given sample size. Power is computed
by formula where one exists, and by simulation otherwise (mediation, the
variance tests, the rank-based tests and Welch's F) or on request.

## Try the app (no R experience needed)

Open <https://joelthornton-powerkit.share.connect.posit.cloud> in a
browser: nothing to install. It is a prototype; results are not yet
validated, so don't use them for real studies.

To run it on your own computer instead, follow [`docs/run-it-yourself.md`](docs/run-it-yourself.md): install R,
download this repository as a ZIP, and run one line,
`source("run_powerkit.R")`, which installs what powerkit needs and opens
the prototype in your browser.

## Install the engine

The engine is an R package in the `engine/` folder of this repository.
Install it from GitHub with:

```r
# install.packages("remotes")
remotes::install_github("JoelThornton/Powerkit", subdir = "engine")
```

This also installs its dependencies, including the backend packages
listed above.

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

High-replication validation tests are skipped by default. A fast subset
(basic tests and regression interactions) runs nightly on GitHub Actions.
The full validation runs on demand, on a local machine, with
`scripts/run-validation.R` (see the instructions at the top of that file);
it can be stopped and resumed, and run one design at a time. Package versions for development are pinned with
[renv](https://rstudio.github.io/renv/) (`renv.lock` at the repository root).

## Licence

The engine is free software, licensed under the GNU General Public License,
version 3 or later (GPL (>= 3)). See [`LICENSE`](LICENSE).
