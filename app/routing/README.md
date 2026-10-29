# app/routing — the powerkit app

The Shiny app: the design finder (the routes in `docs/decision-tree.md`),
an input screen for each design powerkit runs, and the result screen with
its exports. The app never computes power itself: it builds a design spec,
checks it with the engine's `validate_spec()` and passes it to the
engine's `run_spec()`. How to run it, record decisions and run the tests:
[`docs/routing-prototype.md`](../../docs/routing-prototype.md).

- `tree.yaml`: the single source of truth for routes, questions, end points,
  the guided route and the undecided settings.
- `forms.yaml`: the input screens, and which end points calculate.
- `whats-new.yaml`: the "What's new" tab.
- `app.R`: the Shiny app (reads the three files above).
- `R/tree.R`: helpers for the routing data (reachability, guided-route rules).
- `R/ui.R`: screen builders for the design finder and the cards.
- `R/forms.R`, `R/forms_ui.R`: the input screens.
- `R/results.R`: the result screen and its exports.
- `R/simulations.R`: mediation and moderated mediation, which run in the
  background or as an R script.
- `R/whole-study.R`: the whole-study simulation (experimental).
- `R/project.R`: saving and opening a project file.
- `R/about.R`, `R/feedback.R`, `R/labs.R`, `R/map.R`: the About, Feedback
  and Labs tabs, and the methods map in Labs.
- `www/vendor/`: the JavaScript libraries the methods map draws with
  (licences in `LICENSES.txt`).
- `walkthroughs/`: scripted walkthroughs and screenshots
  ([`docs/walkthroughs.md`](../../docs/walkthroughs.md)).
- `tests/`: testthat tests (`testthat::test_dir("app/routing/tests/testthat")`).
- `manifest.json`: for the online app on Posit Connect Cloud; updated by
  the `online-app-manifest` workflow, not by hand.
