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
peer-reviewed R packages:
[Superpower](https://cran.r-project.org/package=Superpower),
[Spower](https://cran.r-project.org/package=Spower),
[power4mome](https://cran.r-project.org/package=power4mome) and
[InteractionPoweR](https://cran.r-project.org/package=InteractionPoweR),
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

A point-and-click app, a design finder, a methods paragraph (write-up)
export, and an optional AI assistant are planned.

## Status

> **powerkit is in early development. Do not use it to plan real studies
> yet.** Every design below except moderated mediation has passed its full
> validation run against direct calls to its backend package and Type I
> error (moderated mediation is being rerun), but most published-value
> checks are still to come, and the interface may change.

| Design | Status |
| --- | --- |
| 2 x 2 between-participants ANOVA | **Working** (via Superpower) |
| 2 x 2 mixed ANOVA (one factor between, one within) | **Working** (via Superpower) |
| Basic tests (t-tests, correlation, proportions, chi-square) | **Working** (via Spower); validated against analytic results, direct Spower calls and Type I error; checks against G*Power's published examples to come |
| Regression interactions | **Working** (via InteractionPoweR); validated against analytic results, direct InteractionPoweR calls and Type I error, with and without measurement error; checks against the InteractionPoweR tutorial's published examples to come |
| Simple, parallel and serial mediation (PROCESS 4, 6) | **Working** (via power4mome); validated against direct power4mome calls and Type I error (parallel and serial: with two mediators; three or more not yet tested); checks against published examples to come |
| Moderated mediation (PROCESS 7, 14) | **Working** (via power4mome); validation in progress: its full run passed on 16 October 2026, but a fix to how power4mome calls are seeded changed its results slightly, so it will be rerun; checks against published examples to come |
| Shiny app and design finder | Planned |

What "validated" means is defined at the top of the
[validation log](docs/validation-log.md). Not available yet for these
designs: binary X or W, measurement error in
mediation designs, and the smallest detectable effect.

powerkit can:

- compute power at a given sample size;
- find the sample size that reaches a target power;
- for the 2 x 2 designs, find the smallest detectable effect.

Power is computed exactly by default for the 2 x 2 designs (or by
simulation on request), and by simulation for every other design.

## Install the engine

The engine is an R package in the `engine/` folder of this repository.
Install it from GitHub with:

```r
# install.packages("remotes")
remotes::install_github("JoelThornton/Powerkit", subdir = "engine")
```

This also installs its dependencies, including the backend packages
Superpower, Spower, InteractionPoweR and power4mome.

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

- [Status](docs/status.md): where the project is and what's next.
- [Validation log](docs/validation-log.md): every full validation run.
- [Build guide](docs/build-guide.md): the plan, architecture, spec format,
  engine design and validation targets.
- [Decisions log](docs/decisions.md): why things are the way they are.
- [Design finder](docs/design-finder.md): the question tree for the app's
  "find my design" route.
- [Conventions](docs/conventions.md): what the established tools do by
  default, what powerkit does, and every departure.
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
