# Adding a test to powerkit

*26 October 2026. The one page to follow when powerkit gains a power
analysis it couldn't do before. It replaces working it out from
[`build-guide.md`](build-guide.md), [`conventions.md`](conventions.md) and
the git history each time.*

**The rule: a test is added when a researcher can run it and see that it
exists.** Engine code alone is not an added test. Everything in "What
'added' means" below happens in the same pull request, so the app is never
behind the engine.

`CLAUDE.md` also asks for one design per PR and a few hundred lines where
possible. If a batch is too big, **split it by design, never by layer**:
two complete designs in two PRs, not one PR of engine code and another of
cards. Splitting by layer is what left five designs in the engine with no
way to reach them. Where the two rules pull against each other,
completeness wins and the PR is a little longer.

"Run it" does not always mean "in the browser". For a design whose power
has to be simulated, the honest answer is often a short R script the
researcher runs on their own computer, and the app should encourage that
rather than hide it: E10–E14 (mediation) work this way today — a quick
preview on the screen, then the full analysis as a one-line script to
download, or in the background where it is quick enough. A design is
finished when the researcher gets their answer by whichever of those
routes suits it, and the card and input screen say which route they are
on.

## What "added" means

Every box ticked, in one PR:

1. The engine computes it, routed to a validated backend package.
2. Its example spec is in `engine/inst/specs/` and its unit tests pass.
3. A validation file exists, with `TODO_PUBLISHED_VALUE` placeholders for
   the maintainer, and a chunk in `scripts/run-validation.R` and in
   `.github/workflows/full-validation.yaml` (a long chunk also needs its
   backend file in `scripts/validation-plan.R`). The PR runs that chunk
   before it merges and says so.
4. It has a card in `app/routing/tree.yaml`, and a row in
   [`decision-tree.md`](decision-tree.md) and
   [`card-sources.md`](card-sources.md) — *tests check these two*
   (`test-docs-match.R`).
5. It has an input screen in `app/routing/forms.yaml`, so the result
   screen, the write-up, the R script and the saved project all work.
   The screen takes the effect in a form researchers have: the effect
   size papers usually report for that analysis (as G\*Power asks for it),
   or a published statistic converted into it, besides any more detailed
   input the backend needs. If that isn't possible, the card says why.
6. A plain-words entry is in `app/routing/whats-new.yaml` — no internal
   codes, name the analysis. `test-whats-new.R` checks the shape of
   entries (date, title, text, newest first, no codes) but **cannot tell
   that you wrote one**: that box is on the author, so say in the PR
   description which entry you added.
7. `engine/DESCRIPTION` has the batch's version ("Version numbers" below)
   and `engine/NEWS.md` has its entry (*test:* the version agreement test).
8. [`status.md`](status.md) and [`coverage-roadmap.md`](coverage-roadmap.md)
   say where it now stands (*test:* `test-repo-consistency.R` keeps the
   roadmap's summary counts honest).

The About page needs nothing: it lists whatever the app calculates
(`about_endpoint_lines()` reads `forms.yaml`).

**If a design truly cannot be finished** — it is waiting on a decision, or
on a statistician — then it does not get merged half-built and silently.
Its card says what is true: that powerkit can compute it but not yet on
this screen, and how to reach it meanwhile. A test refuses a design the
engine can run whose card claims powerkit cannot.

This page is the *how*. [`build-guide.md`](build-guide.md) section 8 is
the *when*: which phase of the build a group of designs belongs to. Where
they disagree about process, this page is current.

## 1. Pick the batch

The queue is [`next.md`](next.md): take its first item marked Ready,
unless the maintainer says otherwise.

Within a batch, the lens is **what researchers realistically need**:

- A design psychologists actually run beats one that only appears in
  textbooks.
- A design they would otherwise give up on, or do badly in another tool,
  is worth more than one G\*Power already does well. Complex and rare
  designs are the point of powerkit, not a side quest.
- A design whose power no established package computes waits for the
  maintainer and a statistician. Never write the maths in powerkit
  (`CLAUDE.md`).

## 2. Agree the method, then the package

powerkit never computes power itself: it translates a spec and calls a
package. That does **not** mean the packages already installed decide what
powerkit can do, or how it does it. Two rules:

**The method comes first, the package second.** Ask what the right way to
compute power for this design is, from the literature, and then find
something that implements it. Never fit the design to whatever is
convenient. If nothing available does it properly, the honest outcomes are
a better package (the maintainer's decision) or the design staying
uncovered with the reason recorded — never a worse approximation presented
as though it were the answer.

**Being familiar is not being right.** G\*Power is the benchmark for what
researchers expect to type and see, not for what is correct: it is
criticised in the methods literature, and where it does something badly
powerkit should not copy it for familiarity's sake. The same goes for the
packages powerkit already calls — this project has found and reported
three faults in Spower's `p_var.test()` alone, and one in its `p_r()`
([`upstream-questions.md`](upstream-questions.md)) — so a package's
default is a claim to check, not an instruction. powerkit already
overrides defaults that are wrong for the design (Yates' correction off,
`k.covariates = 0` for a contrast, the unpooled Steiger test, the
direction of a one-sided variance test), each recorded as a departure.

Before writing any engine code, bring the maintainer a shortlist. This is
their decision, not the thread's:

| What to bring | Why |
| --- | --- |
| What the right method is, and who says so | The design decides the method, not the toolbox |
| Which function in which package implements it, and what it computes | The design must match, not merely sound similar |
| Its version, licence and whether it is on CRAN | Anything not installable is not a candidate |
| How it is criticised, in the literature or in its own issues | A known weakness is a reason to prefer another, or to say so plainly |
| What G\*Power does for the same test, and whether that is sound | Differences become a departure or a known difference; "G\*Power does it" is not a justification |
| A second package or a published example to check it against | Agreement is what makes it trustworthy |
| What it cannot do | The spec checks must refuse those cases plainly |

The five foundation packages (Spower, power4mome, Superpower,
InteractionPoweR, pwr) and pwrss cover much of the queue, and reusing one
keeps the dependency list and the citations short — but say so because it
is the best fit, not because it is already there. A new package is a
bigger decision: say what it adds and what it costs.

**When the right tool is wrong in part**, the playbook this project has
used works: override the bad default and record the departure; report the
fault upstream with a reproducible example in `docs/upstream/`; and refuse
plainly, in the spec checks, whatever cannot be done properly (as the
two-variance test refuses unequal groups). A question of *which method is
right* goes to the maintainer with the literature behind it, and some need
a statistician — the thread does not settle it quietly.

Record the choice in [`decisions.md`](decisions.md) and the package's
conventions in [`conventions.md`](conventions.md), with any departure or
known difference.

## 3. The engine

The files a design touches, in the order it is easiest to work in. The two
variance tests (PR #109) are a recent, complete example to copy.

| File | What it gains |
| --- | --- |
| `engine/inst/schema/design.schema.json` | the template: its variables, population fields and target test, and the `allOf` branch that selects it |
| `engine/R/route.R` | the `design/template` key routed to its backend |
| `engine/R/backend-*.R` | the adapter: the arguments the package takes, the check run that recovers the population values from generated data, and the packages recorded in the provenance |
| `engine/R/spec-checks.R` | plain-English refusals: a zero effect, the minimum n, group splits, which `method` and `alternative` it allows |
| `engine/R/recruitment.R` | the group split, so attrition gives the right number to recruit |
| `engine/R/export-script.R`, `engine/R/export-script-pwrss.R` | the design's one-line description, inputs, arguments and derived lines in the exported script |
| `engine/R/export-citations.R` | a package only this design calls, cited from its own `citation()` |
| `engine/inst/specs/<template>.json` | a complete, realistic example spec |
| `engine/tests/testthat/test-backend-*.R` | translation, the check run, refusals, and the exported script reproducing the run |

Then regenerate `man/` if any roxygen comment changed (`roxygen2::roxygenise()`
in `engine/`, with the roxygen2 version in `engine/DESCRIPTION`).

## 4. Validation

Write `engine/tests/testthat/test-validation-<design>.R` with:

- the published example(s), every input and output as
  `TODO_PUBLISHED_VALUE` with a comment naming the field in the source,
  and the source's section and page;
- a direct call to the backend package with the arguments written out by
  hand, to check powerkit's translation;
- a Type I error check (no effect, so power should sit near alpha).

Never fill in a published value: the maintainer transcribes them
(`CLAUDE.md`). Add the chunk to `scripts/run-validation.R` (with a rough
time per test) and to the workflow's chunk list;
`test-repo-consistency.R` fails if you forget either.

## 5. The app

**The card** (`app/routing/tree.yaml`): plain name, the document name, its
status, what the user would enter, the packages behind it, and its
validation note. A design whose published values are still
`TODO_PUBLISHED_VALUE` takes the status
`runs_validation_in_progress`, never `runs_validated`: the card must not
claim a check the maintainer hasn't made. Say in the validation note what
has been checked (agreement with the package called directly, Type I
error) and what hasn't. Add the matching rows to
[`decision-tree.md`](decision-tree.md) (table 2.3) and
[`card-sources.md`](card-sources.md), or the docs tests fail.

**Where it sits in the routing.** The default is that **every design is
reachable from the design finder**, and a rare design more urgently than a
common one: someone who needs a multilevel model and doesn't know it
cannot look it up by name, and a finder that only leads to familiar
designs would send exactly that person to a t-test. The tree is already
built this way — the four screening questions alone lead to clustered
data (E34), counts (E28), ordered categories (E29), survival (E43), pairs
(E44), many stimuli per person (E33), equivalence (E36) and planning for
precision (E46).

What keeps a simple design simple is not leaving rare ones out; it is
where the questions sit. The screening asks four questions of everyone,
and anything a rare design needs to know is asked only of people whose
earlier answers imply it. Someone comparing two groups on a score should
never be asked about nesting or exposure time.

The one exception is a design that **cannot be identified from a
description of a study, only by name**: the generic tests (E50), where a
researcher has to know already that they have a noncentrality parameter.
Those are listed in "I know my analysis" and left out of the finder,
because no honest question about a study would lead to them. Rarity is not
the test; identifiability is.

Either way the design is in the list, because the list is every card.

**The input screen** (`app/routing/forms.yaml`): the fields, their help,
the goal types it supports, and — for a simulated design — the preview and
full-run or script route (`simulations > endpoints`). Add it to
`calculates` only when the app really computes it.

**The result screen**: if the design has a departure or known difference,
give its key in the card's `departures` or `known_differences` so the
result screen and the methods paragraph say so.

## 6. Tell the user

- `app/routing/whats-new.yaml`: one entry, newest first, in the words a
  psychologist would use. No E-numbers, no "Departure 6".
- `engine/DESCRIPTION`: the batch's version (see below: the first pull
  request of a batch raises it, the rest keep it), and `CITATION.cff` (at
  the repository root, not in `engine/`) with it.
- `engine/NEWS.md`: the developer-facing entry.
- [`status.md`](status.md): where the project now is, replacing the old
  entry rather than adding to it.

## 7. Before you finish

- The engine's tests and R CMD check in `engine/`: both clean (the
  commands are in `CLAUDE.md`, "Before finishing any task").
- The app's suite: `testthat::test_dir("tests/testthat")` in
  `app/routing/`.
- Read the eight boxes again. The tests catch a missed card, a missed
  "What's new" entry, a stale roadmap count and a version out of step —
  but not a card that says the wrong thing.

## Version numbers

`engine/DESCRIPTION`'s `Version` is the single source. It shows on the
About page, in exported R scripts and in every result's provenance, so a
number somebody quotes can be traced.

The number is major.minor.patch, and each part means something:

- **Patch (last number): bug fixes and very small changes**, such as a
  wording fix or a corrected default. 0.9.0 becomes 0.9.1.
- **Minor (middle number): one batch of new features.** A batch is the
  work built and merged together, usually by one thread or in one round of
  the queue, and it raises the number by one however many pull requests it
  holds. 0.9 is followed by 0.10, so a high middle number does not mean
  powerkit is nearly finished.
- **Major (first number): a big shift**, such as leaving prototype (1.0.0,
  the release: validated, published values transcribed, and the designs
  the maintainer wants in it) or changing what the site runs on. This is
  the maintainer's call.

In practice: the first pull request of a batch sets the next number in
`engine/DESCRIPTION`, `CITATION.cff` and a new `engine/NEWS.md` heading;
the rest of the batch keep that number and add their entries under the
same heading. Never reserve a number ahead for a pull request that isn't
in the current batch: parallel pull requests that each took their own
number are how 0.4.0 became 0.8.0 in about a day. The "What's new" tab is
dated rather than numbered, so users still see each change as it lands.

Shipped so far: 0.1.0 the first working prototype (17 October 2026),
0.2.0 the four-screen design and the app going online (18 October), 0.3.0
the tests by formula (18 to 20 October), 0.4.0 the shorter input screen,
Labs, feedback and browser history (22 October). 0.5.0 to 0.8.0 (26 to 27
October) were raised once per feature under the earlier rule. 0.9.0 is the
methods map, the three-effect curves, safeguard power and the share
button (27 October).

## What to add next

[`next.md`](next.md) is the one queue: take its first item marked Ready.
The roadmap ([`coverage-roadmap.md`](coverage-roadmap.md)) gives every
design a status and a candidate package; a row marked "no ready-made tool"
or "unknown" is a question for the maintainer first, not a batch.
