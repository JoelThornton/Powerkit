# Map of the docs

*18 October 2026.* Which document to read for what. Start with the first
three; the rest are reference. Pages marked "history" are kept for their
reasoning and are not current instructions.

## Start here

- [`status.md`](status.md): where the project is and what comes next, in
  priority order. Current state only.
- [`handover.md`](handover.md): the working rules and where things live,
  for whoever picks the project up next.
- [`decisions.md`](decisions.md): every decision the maintainer has made,
  dated, newest last. "2026-10-18 · The new design" is the current
  direction.
- The project rules are in [`../CLAUDE.md`](../CLAUDE.md); user-visible
  changes are in [`../engine/NEWS.md`](../engine/NEWS.md).

## Open questions for the maintainer

- [`judgement-session.md`](judgement-session.md): the open calls that
  change what users see, one page each, in order of impact.
- [`judgement-calls.md`](judgement-calls.md): every open question in
  full. Decided ones move to
  [`archive/judgement-calls-decided.md`](archive/judgement-calls-decided.md).
- [`routing-design-options.md`](routing-design-options.md): question tree
  or design profile, and how the start screen leads into it.
- [`inference-question-design.md`](inference-question-design.md): options
  for asking what users will conclude (options only).
- [`phase-3b-questions.md`](phase-3b-questions.md): decisions needed
  before binary X or W is coded.
- [`hosting-options.md`](hosting-options.md): how other people could use
  the app (options only; prices unchecked).
- [`upstream-questions.md`](upstream-questions.md): open technical
  questions about the backend packages (not yet raised).

## Statistics: conventions and validation

- [`conventions.md`](conventions.md): what each backend does by default,
  every departure (1–11) and known difference (1–2), and where each is
  shown.
- [`validation-log.md`](validation-log.md): every full validation run,
  and what "validated" means.
- [`gpower-parity.md`](gpower-parity.md): what a user can enter and get
  for each design, compared with G\*Power.
- [`coverage.md`](coverage.md) and
  [`coverage-roadmap.md`](coverage-roadmap.md): what the backend tools
  can do, and the master list of everything powerkit might cover
  (including the 49 G\*Power tests).

## The app: routing, cards and wording

- [`routing-prototype.md`](routing-prototype.md): how the app is put
  together and how to run it for development.
- [`decision-tree.md`](decision-tree.md) and
  [`design-finder.md`](design-finder.md): the question tree and the
  design finder's wording (the basis of `app/routing/tree.yaml`).
- [`card-sources.md`](card-sources.md): the source of every factual
  claim on the end-point cards.
- [`glossary.md`](glossary.md): the plain-English hints and their
  sources.
- [`routing-audit.md`](routing-audit.md) and
  [`walkthroughs.md`](walkthroughs.md): designs powerkit doesn't cover,
  and example studies through every route (pictures in `figures/`).
- [`phase5-simulations.md`](phase5-simulations.md): how the
  simulation-heavy designs (E9–E14) run in the app (decided 17 October
  2026).

## Users and testing

- [`run-it-yourself.md`](run-it-yourself.md): how a colleague installs
  and runs the app on their own computer.
- [`user-testing.md`](user-testing.md): the plan for testing with
  psychologists.
- [`test-cases.md`](test-cases.md): problems testers found, each turned
  into a test.

## History

- [`build-guide.md`](build-guide.md): the original plan, architecture and
  spec format. Its build phases (section 8) were followed up to phase 5;
  since 18 October 2026 the build order is the one in `status.md`.
- [`saving-projects.md`](saving-projects.md): the options before project
  files were built (option (a), 18 October 2026).
- [`archive/status-history.md`](archive/status-history.md): the status
  page's entries up to 18 October 2026.
- `upstream/spower-one-sided-tests.R`: the example reported to Spower's
  author about one-sided tests (`decisions.md`, 13 October 2026).
