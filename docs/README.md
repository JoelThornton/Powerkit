# Map of the docs

*8 November 2026.* Which document to read for what. Start with the first
three; the rest are reference. Pages under "History" are kept for their
reasoning and are not current instructions. Every page in `docs/` is
listed here (a test checks).

## Start here

- [`next.md`](next.md): the ordered queue, the answer to "work on the
  next thing". Take the first item marked Ready.
- [`status.md`](status.md): where the project is now, area by area.
  Current state only.
- [`adding-a-test.md`](adding-a-test.md): the one page to follow when
  powerkit gains a power analysis: what "added" means, how the backend
  package is chosen and every file it touches.
- [`handover.md`](handover.md): where things live, for whoever picks the
  project up next. The working rules are in
  [`../CLAUDE.md`](../CLAUDE.md) only; user-visible changes are in
  [`../engine/NEWS.md`](../engine/NEWS.md).
- [`decisions.md`](decisions.md): every decision the maintainer has made,
  dated, newest last. A long record: search it rather than reading it
  whole.

## For the statistician

- [`conventions.md`](conventions.md): what each backend does by default,
  every departure (1-21) and known difference (1-13), and where each is
  shown.
- [`validation-log.md`](validation-log.md): every full validation run,
  and what "validated" means; [`validation/`](validation/) holds the raw
  record of a run where one was kept.
- [`whole-study-method.md`](whole-study-method.md): the whole-study
  simulation's method and the questions it needs a statistician to settle.
- [`upstream-questions.md`](upstream-questions.md): faults and open
  questions in the packages powerkit calls, with the evidence (the
  reproducible examples are in `upstream/`).
- [`method-coverage-review.md`](method-coverage-review.md): which methods
  were chosen for each design and what remains.
- [`bayes-planning.md`](bayes-planning.md): planning a Bayes factor study
  (analysis and design priors, the three outcomes, sequential designs).
- [`gpower-parity.md`](gpower-parity.md): what a user can enter and get
  for each design, compared with G\*Power.
- [`coverage.md`](coverage.md) and
  [`coverage-roadmap.md`](coverage-roadmap.md): what the backend tools
  can do, and the master list of everything powerkit might cover
  (including the 49 G\*Power tests).

## Open questions for the maintainer

- [`judgement-session.md`](judgement-session.md): the open calls that
  change what users see, one page each, in order of impact.
- [`judgement-calls.md`](judgement-calls.md): every open question in
  full. Decided ones move to
  [`archive/judgement-calls-decided.md`](archive/judgement-calls-decided.md).
- [`hosting-options.md`](hosting-options.md): where the app runs, what it
  costs, and the options for real users.

## The app: routing, cards and wording

- [`routing-prototype.md`](routing-prototype.md): how the app is put
  together, how to run it for development, and how the largest files are
  to be split.
- [`accessibility-review.md`](accessibility-review.md): what the
  accessibility checks cover, and the visual style new screens follow.
- [`decision-tree.md`](decision-tree.md) and
  [`design-finder.md`](design-finder.md): the question tree and the
  design finder's wording (the basis of `app/routing/tree.yaml`).
- [`card-sources.md`](card-sources.md): the source of every factual
  claim on the cards.
- [`glossary.md`](glossary.md): the plain-English hints and their
  sources.
- [`routing-audit.md`](routing-audit.md) and
  [`walkthroughs.md`](walkthroughs.md): designs powerkit doesn't cover,
  and example studies through every route (pictures in `figures/`).

## The repository

- [`repository-protection.md`](repository-protection.md): what main
  requires, how releases are tagged and how the online app is published.
- [`dependency-footprint.md`](dependency-footprint.md): how many packages
  the engine and the app depend on, and the rule for moving single-card
  packages to Suggests.

## Users and testing

- [`run-it-yourself.md`](run-it-yourself.md): how a colleague installs
  and runs the app on their own computer.
- [`user-testing.md`](user-testing.md): the plan for testing with
  researchers, and [`usability-session-pack.md`](usability-session-pack.md)
  the observer's protocol and key for those sessions.
- [`test-cases.md`](test-cases.md): problems testers found, each turned
  into a test.

## History

- [`build-guide.md`](build-guide.md): the original plan, architecture and
  spec format. Its build phases (section 8) were followed up to phase 5;
  since 18 October 2026 the work comes from `next.md`.
- [`routing-design-options.md`](routing-design-options.md),
  [`inference-question-design.md`](inference-question-design.md),
  [`phase-3b-questions.md`](phase-3b-questions.md),
  [`phase5-simulations.md`](phase5-simulations.md) and
  [`saving-projects.md`](saving-projects.md): the options weighed before
  the start screen, the inference question, yes/no X or W, the simulated
  designs and project files were built (each decided in `decisions.md`).
- [`archive/status-history.md`](archive/status-history.md): the status
  page as it stood before each rewrite.
- `upstream/spower-one-sided-tests.R`: the example reported to Spower's
  author about one-sided tests (`decisions.md`, 13 October 2026).
