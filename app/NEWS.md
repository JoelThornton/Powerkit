# powerkit app (development)

* Prototype Shiny app for 2x2 between and 2x2 mixed designs (demo; not for
  real studies). Three screens (design, confirm, results) and a "How we
  check this" panel with the published 2x2 benchmarks. The app builds a spec
  and calls `run_spec()` with the exact method; it never computes power
  itself. Results include the required total N, a power curve, a draft
  APA-style methods paragraph, a downloadable R script that reproduces the
  result with Superpower alone, and the spec as JSON. Start it with
  `source("run_app.R")` from the project.
