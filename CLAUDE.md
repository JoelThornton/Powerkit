# powerkit — project rules

## What this is
A unified power analysis tool for research studies (built with psychology's
designs in mind, but not only for psychology: never describe it to users as
a psychology tool; docs/decisions.md, 5 November 2026). One design specification format,
routed to established R backends (Spower, power4mome, Superpower, InteractionPoweR
and the others in engine/DESCRIPTION's Imports and Suggests),
with a Shiny front end (design finder, design forms, full-model builder,
confirmation screen, results and exports).
Full plan: docs/build-guide.md.

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
card, input screen, a plain-words Updates entry, the version (see
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
  Where no package does it, a closed-form result from a published source (a
  textbook, a paper or the G*Power manual) may be written in the engine, with
  the source cited and checked against an independent simulation and, where
  G*Power has the test, its answers. Don't simulate only because no package
  has a formula: a simulation is slower and carries random error.
- Never edit expected values in engine/tests/testthat/test-validation-*. They are transcribed
  from published sources by the maintainer. If a test fails, report why.
- Validation tests may contain `TODO_PUBLISHED_VALUE` placeholders; leave them for the maintainer
  (a test with a placeholder may be skipped, not deleted).
- Every result records: spec hash, seed, backend, R and package versions.
- The Shiny app never computes power; it builds specs and calls the engine.
- Citations come only from engine/inst/citations/refs.bib or a package's own citation().
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
  so powerkit can be right and honest at once. powerkit exists to break
  rituals: where a method is clearly better, make it the default and keep the
  conventional one as an option where researchers commonly use it. Which method is right is the
  maintainer's call, with the literature behind it; never the thread's quiet
  decision, and never settled by what is already installed.
- Work from docs/next.md, one queue item or group of related items at a
  time (see "What to work on"); the build guide's phases are history, and
  its remaining phase (hosting) is a queue item.
- engine/DESCRIPTION's Version is powerkit's version, shown to users and in
  every export, as major.minor.patch. Patch (last): bug fixes and very small
  changes. Minor (middle): one batch of new features, the work merged
  together from one thread or round, so a batch raises it by one however
  many PRs it holds (0.9 is followed by 0.10). Major (first): a big shift,
  such as leaving prototype (1.0.0) or changing what the site runs on; the
  maintainer's call. Each PR writes its change notes as files of its own
  (engine/news.d/<topic>.md, app/routing/whats-new.d/<topic>.yaml), and
  only the PR that finishes a batch sets the number, by running
  scripts/close-batch.R, which also keeps CITATION.cff and engine/NEWS.md
  in step (decided 7 November 2026). Never claim a number for work that
  isn't in the current batch. Rules: docs/adding-a-test.md, "Change notes
  and version numbers".

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
- Grow the code in place, not by rewrites (decided 7 November 2026): a
  very large file (app.R's server, results.R, export-script.R,
  spec-checks.R, backend-spower.R) is split only when a pull request
  already touches it, by moving that design's or screen's code to its own
  file (the target layout is in docs/routing-prototype.md, "Splitting the
  large files"). A backend used by one card only moves from Imports to
  Suggests, with a `requireNamespace()` guard and a plain message, when a
  pull request touches that card (docs/dependency-footprint.md).
- Before starting work, read the last scheduled run of nightly-validation
  (Actions tab): its summary page lists every test that failed, erred or
  did not run. Add a row to docs/next.md for any failure that has none.

## Working process (maintainer, 18 October 2026)
The maintainer is the only reviewer and decider, so keep what they have
to read small.
- Judgement calls: give a recommendation and a one-line reason, not only
  neutral options. The maintainer accepts or overrules it. When a call is decided, move
  its entry to docs/archive/judgement-calls-decided.md and record it in
  docs/decisions.md.
- A statistician reviews powerkit's methods at the end, not along the
  way. Until then, make the best method decision the literature supports,
  as if no later review were coming: never defer, simplify or skip a
  design, a method question or a validation because a statistician will
  check it later. "Validated" has one meaning, the validation log's
  (docs/validation-log.md, "What 'validated' means"): a card says
  "validation in progress" until a recorded full run of its design meets
  that definition, because that is what users need to know. Published
  examples are added as the maintainer transcribes them.
- Build each design properly the first time when that saves coming back
  to it (every variant researchers commonly need, with its validation),
  rather than a small first version; split it into several PRs by
  design only when one would be too big to review.
- docs/status.md is current state only: replace old entries, don't append
  history (git, NEWS.md and docs/archive/ hold that).
- Prefer updating an existing doc to adding a new one.
- Read docs/next.md and docs/status.md in full. docs/decisions.md,
  docs/conventions.md, engine/NEWS.md and the YAML files are long records
  (hundreds of KB): search them for the design, date or package in hand
  rather than reading them whole. Decisions from October 2026 are in
  docs/archive/decisions-2026-10.md, indexed at the top of decisions.md.
- One PR per group of related work: one queue item, a design with its
  follow-ups, or a set of fixes from one review. The test is whether the
  PR can be described in a sentence; unrelated changes go in separate PRs.
  The docs that describe a change go in the same PR as the change. When a
  group is too big to review comfortably, split it by design or by fix,
  never by layer, and say in the description what each part does.
- Open the pull request yourself when the work is ready, and merge it once
  its checks pass. Leave it open for the maintainer to merge when you're
  uncertain about something (a method choice, a result you can't explain,
  a check you couldn't run), and say what in the description.
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
- Test locally what you changed, and let the required checks on the pull
  request be the gate (decided 7 November 2026): run the test files for
  the code you changed (`testthat::test_local(filter = ...)` in engine/,
  `testthat::test_dir("tests/testthat", filter = ...)` in app/routing/)
  plus app/routing/tests/testthat/test-repo-consistency.R, which ties the
  engine, the docs and the app together. The app's suite tests the
  installed engine, so run `R CMD INSTALL engine` first when the engine
  changed. Don't run the full suites or R CMD check locally: CI runs both
  (the engine's tests and `rcmdcheck::rcmdcheck(args = "--no-manual",
  error_on = "warning")`, and the app's suite in two parts). Report only
  failures, and check CI once at the end.
- After changing roxygen comments, regenerate man/ with roxygen2 at the
  version in engine/DESCRIPTION (not in the CI image that cloud sessions
  copy: install it into a scratch library) rather than editing .Rd files
  by hand.
- Write the change notes as new files: engine/news.d/<topic>.md for the
  developer notes, and app/routing/whats-new.d/<topic>.yaml (the app's
  Updates tab, in plain words) for any change users see. Don't edit
  engine/NEWS.md, whats-new.yaml or the version except through
  scripts/close-batch.R.
- Update docs/status.md (where the project is and what's next) in every PR.
