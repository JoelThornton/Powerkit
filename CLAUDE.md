# powerkit — project rules

## What this is
A unified power analysis tool for psychology. One design specification format,
routed to validated R backends (Spower, power4mome, Superpower, InteractionPoweR),
with a Shiny front end (design finder, design forms, full-model builder,
confirmation screen, results and exports). An optional AI assistant comes last.
Full plan: docs/build-guide.md. Product background: docs/strategy.md (if present).

## What to work on
docs/next.md is the ordered queue: take the first item marked Ready (with
any closely related items, as one group of work: see "Working process"),
and delete its row when it lands. An item marked "Needs a decision" is
not yours to start — say what the decision is and move on, or ask. Check the
top item still makes sense before starting: the page is dated, and the
maintainer's priorities beat it.

## Adding a power analysis
Follow docs/adding-a-test.md, start to finish, in the same PR. A test is added when a
researcher can run it and see that it exists: engine, validation placeholders,
card, input screen, a plain-words "What's new" entry, the version (see
Non-negotiables) and the status update all land together. For a design whose power must be simulated,
"run it" can mean the R script the app hands them to run themselves (as E10-E14
do) — say which route they are on. Never leave a design the engine can compute
with a card that says powerkit cannot.
Split a big batch by design, never by layer: splitting by layer is what left
five designs in the engine that no researcher could reach.
Every design is reachable from the design finder, rare ones most of all (a
researcher who needs a multilevel model can't look it up by name); only a design
that can't be identified from a description of a study, such as the generic
tests, is listed in "I know my analysis" alone.
app/routing/tests/testthat/test-repo-consistency.R refuses an engine template
that is neither named by a card nor listed in forms.yaml's engine_only, so an
engine-side change alone will fail the app suite.

## Non-negotiables
- Never write new statistical maths when a backend package already does it; adapt the spec.
- Never edit expected values in tests/testthat/test-validation-*. They are transcribed
  from published sources by the maintainer. If a test fails, report why.
- Validation tests may contain `TODO_PUBLISHED_VALUE` placeholders; leave them for the maintainer.
- Every result records: spec hash, seed, backend, R and package versions.
- The Shiny app never computes power; it builds specs and calls the engine.
- Citations come only from inst/citations/refs.bib or a package's own citation().
  Never invent references or write one from memory.
- Plain-English errors for users; no stack traces in the UI.
- powerkit follows the established tools' conventions by default, so that users
  comparing tools are never surprised silently. Any departure must be recorded
  in docs/conventions.md, shown to the user on the results screen, stated in the
  methods paragraph, and covered by a test showing the size of the difference.
  Following by default is about not diverging silently, not about treating the
  usual tools as correct: G*Power is the benchmark for what researchers expect
  to enter and see, not for what is right, and the packages powerkit calls have
  their own faults (docs/upstream-questions.md). Where the literature says a
  method is better, prefer it and record the departure — that machinery exists
  so powerkit can be right and honest at once. Which method is right is the
  maintainer's call, with the literature behind it; never the thread's quiet
  decision, and never settled by what is already installed.
- Work one build phase at a time (docs/build-guide.md section 8). Stop at the end of
  a phase and summarise what was done, what's untested, and open questions.
- engine/DESCRIPTION's Version is powerkit's version, shown to users and in
  every export, as major.minor.patch. Patch (last): bug fixes and very small
  changes. Minor (middle): one batch of new features, the work merged
  together from one thread or round, so a batch raises it by one however
  many PRs it holds (0.9 is followed by 0.10). Major (first): a big shift,
  such as leaving prototype (1.0.0) or changing what the site runs on; the
  maintainer's call. The first PR of a batch sets the next number; the rest
  of the batch keep it and add under the same NEWS.md heading. Never claim
  a number for a PR that isn't in the current batch. Keep CITATION.cff
  (repository root) and engine/NEWS.md in step. Rules and history:
  docs/adding-a-test.md, "Version numbers".

## Conventions
- R package in engine/ with roxygen2 docs, testthat 3rd edition, renv for versions.
- tidyverse style guide; small, pure functions where possible.
- Design specs are JSON validated against engine/inst/schema/design.schema.json.
- High-replication validation tests are skipped by default (skip unless
  env var POWERKIT_FULL_VALIDATION=true). A PR that adds or changes a
  design runs that design's chunk of scripts/run-validation.R before it
  merges, and says which. GitHub runs the short chunks and the changed
  long chunks every night the engine changed, and every chunk every
  Sunday (scripts/validation-plan.R). A full local run is the
  maintainer's choice, and comes before a release.

## Working process (maintainer, 18 October 2026)
The maintainer is the only reviewer and decider, so keep what they have
to read small.
- Judgement calls: give a recommendation and a one-line reason, not only
  neutral options. The maintainer accepts or overrules it. When a call is decided, move
  its entry to docs/archive/judgement-calls-decided.md and record it in
  docs/decisions.md.
- docs/status.md is current state only: replace old entries, don't append
  history (git, NEWS.md and docs/archive/ hold that).
- Prefer updating an existing doc to adding a new one.
- Read CLAUDE.md, docs/next.md and docs/status.md in full. docs/decisions.md,
  docs/conventions.md, engine/NEWS.md and the YAML files are long records
  (hundreds of KB): search them for the design, date or package in hand
  rather than reading them whole.
- One PR per group of related work: one queue item, a design with its
  follow-ups, or a set of fixes from one review. The test is whether the
  PR can be described in a sentence; unrelated changes go in separate PRs.
  The docs that describe a change go in the same PR as the change. When a
  group is too big to review comfortably, split it by design or by fix,
  never by layer, and say in the description what each part does.
- Public content: the repository is public and must read as a professional
  software project. Commit messages, PR titles and descriptions, comments
  and repo files say what a change does, why it is needed (in terms of the
  software, its users or the published literature) and how it does it.
  Never summarise project chats, private emails or correspondence, or who
  said what in a discussion; cite published sources, not conversations.
  Personal and discussion notes stay outside the repository.
- One thread per area at a time (engine, app, docs). Before editing a
  shared page (handover.md, status.md), check open PRs for edits to it.
- Local R in a cloud session: scripts/setup-cloud-session.sh, set as the
  environment's setup script, so a session starts with R and the packages
  ready. Check `Rscript -e 'library(power4mome)'` before installing
  anything; if that fails, run `bash scripts/setup-cloud-session.sh
  --build-from-source`.

## Before finishing any task
- Run the engine's tests and R CMD check in engine/, as CI does; both must
  pass: `testthat::test_local()` and
  `rcmdcheck::rcmdcheck(args = "--no-manual", error_on = "warning")`
  (devtools isn't in the CI image that cloud sessions copy; where it is
  installed, devtools::test() and devtools::check() do the same). After
  changing roxygen comments, regenerate man/ with roxygen2 at the version
  in engine/DESCRIPTION (also not in the image: install it into a scratch
  library) rather than editing .Rd files by hand.
- Run the app's suite too when anything outside engine/ changed:
  testthat::test_dir("tests/testthat") in app/routing/, after installing
  the engine (`R CMD INSTALL engine`), since the suite tests the installed
  one. The cross-checks that tie the engine, the docs and the app together
  live there, so an engine-only run will not see them. test-results.R takes
  about two thirds of its time; CI runs it beside the rest (`filter =
  "^results$"`, with `invert = TRUE` for the rest), and two R sessions can
  do the same locally.
  (validation tests with TODO placeholders may be skipped, not deleted).
- Update NEWS.md with user-visible changes, and add a plain-words entry to
  app/routing/whats-new.yaml (the app's "What's new" tab) for any change users see.
- Update docs/status.md (where the project is and what's next) in every PR.
