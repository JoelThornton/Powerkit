# app/ — Shiny front end

**Status: prototype for the 2x2 between and 2x2 mixed designs.** Built ahead
of build phase 5 as a demo; it is not the phase 5 app and is not for use in
real studies. The app builds design specs and calls the engine
(`run_spec()`); it never computes power itself (see CLAUDE.md and
docs/build-guide.md section 7).

## Run the demo

The demo needs these R packages:

| Package | For | In `renv.lock` already? |
| --- | --- | --- |
| shiny | the app | no |
| bslib | the app's theme | yes |
| pkgload | loading the engine from `engine/` | yes |
| digest, jsonlite, jsonvalidate, Superpower | the engine (`engine/DESCRIPTION`) | yes |

Install them once, from the project (RStudio: open `Powerkit.Rproj`):

```r
install.packages(c("shiny", "bslib", "pkgload", "digest", "jsonlite", "jsonvalidate", "Superpower"))
```

Then start the app with `source("run_app.R")`, or open `app/app.R` and
click **Run App**. `run_app.R` installs nothing: if a package is missing it
stops and prints the line above. `renv.lock` is deliberately not updated
for the demo; record shiny there after the phase 3 work is merged.

The app loads the engine from `engine/` in this checkout with
`pkgload::load_all()`, falling back to an installed powerkit.

## Screens

1. **Design**: 2x2 between or 2x2 mixed; factor, level and outcome names;
   four cell means, SD, correlation (mixed), effect to detect, alpha, target
   power and an effect-size justification. **Load example** fills in the
   Superpower vignette crossover example (between: means 1, 0, 0, 1, SD 2;
   mixed: means -0.25, 0.25, 0.25, -0.25, SD 1, r .5). Problems are the
   engine validator's own messages, with field names rewritten as the
   form's labels.
2. **Confirm**: interaction plot and the design in plain words. Nothing runs
   until the user confirms.
3. **Results**: required total N (exact method), power curve (every point is
   a `run_spec()` call with goal type "power"), a draft APA-style methods
   paragraph built only from the spec and the result object (the paragraph
   checks the spec against the hash the result recorded), the run's
   provenance and check run, and downloads: a standalone R script that
   reproduces the required N with Superpower directly, and the spec as JSON.

**How we check this** lists the published benchmarks the 2x2 engine
reproduces (transcribed from `engine/tests/testthat/test-validation-anova-2x2-*.R`)
and can re-run them through the engine.

## Files

- `app.R`: UI and server.
- `engine-bridge.R`: loads the engine; turns engine conditions into plain
  English (validator messages, advice warnings; never stack traces).
- `forms/form_2x2.R`: screen 1 and form values -> spec.
- `confirm/confirm_2x2.R`: screen 2 (interaction plot, plain words).
- `results/results_2x2.R`: screen 3 (power curve, methods paragraph, R script).
- `checks/benchmarks.R`: the "How we check this" benchmarks.
- `tests/`: tests for the helpers, including running the generated R script.
  Run with `testthat::test_dir("app/tests/testthat")` (about 30 seconds).
- `builder/`: full-model builder (later).
