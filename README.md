# powerkit

A power analysis tool for psychology. You describe your study once, in plain
terms, and powerkit routes it to a validated R package to work out the power,
the sample size you need, or the smallest effect you could detect.

powerkit does not reimplement the statistics. It builds on established,
peer-reviewed R packages:
[Superpower](https://cran.r-project.org/package=Superpower),
[Spower](https://cran.r-project.org/package=Spower),
[power4mome](https://cran.r-project.org/package=power4mome) and
[InteractionPoweR](https://cran.r-project.org/package=InteractionPoweR).
It adds what those packages don't have:

- one specification format for every design;
- checks that the population you describe is possible;
- validation against published results;
- a record of exactly how each result was produced (spec hash, seed,
  package versions).

A point-and-click app, a design finder, script and write-up exports, and an
optional AI assistant are planned.

## Status

> **powerkit is in early development. Do not use it to plan real studies
> yet.** Results have been validated for 2 x 2 designs only, and the
> interface may change.

| Design | Status |
| --- | --- |
| 2 x 2 between-participants ANOVA | **Working** (via Superpower) |
| 2 x 2 mixed ANOVA (one factor between, one within) | **Working** (via Superpower) |
| Basic tests (t-tests, correlation, proportions, chi-square) | In progress |
| Regression interactions | In progress |
| Simple, parallel and serial mediation (PROCESS 4, 6) | In progress |
| Moderated mediation (PROCESS 7, 14) | In progress |
| Shiny app and design finder | Planned |

For the 2 x 2 designs, powerkit can:

- compute power at a given sample size;
- find the sample size that reaches a target power;
- find the smallest detectable effect.

Power is computed exactly by default, or by simulation on request.

## Install the engine

The engine is an R package in the `engine/` folder of this repository.
Install it from GitHub with:

```r
# install.packages("remotes")
remotes::install_github("JoelThornton/Powerkit", subdir = "engine")
```

This also installs its dependencies, including Superpower. The other backend
packages are optional until their designs are ready:

```r
install.packages(c("Spower", "power4mome", "InteractionPoweR", "lavaan"))
```

If the repository is private, set a GitHub personal access token in the
`GITHUB_PAT` environment variable first.

## Try it

```r
library(powerkit)

# An example spec: a 2 x 2 mixed design (therapy vs waitlist, measured
# before and after), with the interaction as the effect of interest.
spec <- read_spec(system.file("specs", "anova_2x2_mixed.json", package = "powerkit"))
spec

result <- run_spec(spec)
result
```

A spec is a JSON file. `read_spec()` checks it and explains any problem in
plain English. Example specs for every design are in
[`engine/inst/specs/`](engine/inst/specs/). The format is defined by
[`engine/inst/schema/design.schema.json`](engine/inst/schema/design.schema.json).

## Documentation

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

High-replication validation tests are skipped by default. Set
`POWERKIT_FULL_VALIDATION=true` to run them; they run nightly on GitHub
Actions. Package versions for development are pinned with
[renv](https://rstudio.github.io/renv/) (`renv.lock` at the repository root).

## Licence

The engine is free software, licensed under the GNU General Public License,
version 3 or later (GPL (>= 3)). See [`engine/LICENSE`](engine/LICENSE).
