# Judgement session: the open calls that change what users see

*Prepared 18 October 2026 for the maintainer's judgement session.*

This is an agenda, not a decision record. **Nothing here is decided, and
nothing is recommended.** The order of options is the order in the
source entry, not a preference. Each call fits on about a page; the full
evidence, quotations and page numbers are in the linked entries of
[`judgement-calls.md`](judgement-calls.md) and the other documents named.

**Order.** By impact: how many users and results the call touches. Calls
that change every route or every result come first; calls that affect
one kind of user or one kind of card come last.

**How sources are marked** (as in `judgement-calls.md`): *opened* (the
source was read), *verified, maintainer* (the maintainer checked the full
text), *second-hand* (seen quoted elsewhere, to verify), *candidate* (not
checked). "Who might disagree" is reasoning about positions, not reports
of what named people said.

| # | Call | Touches | Detail |
| --- | --- | --- | --- |
| 1 | Routing: question tree or design profile | every user, every route | `routing-design-options.md`; D1, D2 |
| 2 | Effect sizes: empty and justified, suggested, or sensitivity instead | every result | B10, B2, G9 |
| 3 | Alpha and tails: defaults or required inputs with a reason | every result | G8, B3, B4 |
| 4 | Several hypotheses: the inference question and corrections | every study with more than one test | B6, G7, D6 |
| 5 | What the methods paragraph must report | every write-up | G4 |
| 6 | Hosting (and saving projects) | whether, and how, others can use the app | `hosting-options.md` (draft PR #49); `saving-projects.md` |
| 7 | Scope for the G\*Power tests powerkit doesn't run | users coming from G\*Power | G1; `coverage-roadmap.md` |
| 8 | Naming other tools on cards | users whose design isn't covered | A1, A2, A4 |
| 9 | Bayesian planning: where it enters | Bayesian users | G2, D3 |

---

## 1. Routing: question tree or design profile

**The question.** Should users reach their card through a branching
question tree (as now), or through the same short set of profile
questions every time (outcome, what is compared, grouping, measurements,
goal, framework), with a table that maps answers to cards?

**Options** (from [`routing-design-options.md`](routing-design-options.md)):
- A. Keep the question tree (four screening questions, then branches).
- B. Design profile, all six questions on one screen.
- C. Design profile, one question at a time, with the list of cards that
  still fit shrinking after each answer.
- D. Profile plus follow-ups: B or C, then card-specific follow-ups where
  the profile leaves several cards (the source notes B and C need this
  step for E1–E14, so in practice they are D).
- Within B to D: unmatched answers go to the safety net (exact matching),
  or to the nearest row (first match, as the guided route does now).

**Evidence.** 28 misroutes or route conflicts are recorded. Judged from the
recorded paths ("likely", not tested):

| | Prevented | Partly | Not prevented |
| --- | --- | --- | --- |
| Current tree, after three rounds of fixes | 15 | 3 | 10 |
| Design profile with exact matching (likely) | 19 | 2 | 7 |

12 of the tree's 15 fixes came from the screening, which is already a
partial profile. Neither approach prevents M12, M13, M19, M20, M21, M26 or
M28 without another dimension (shape of effect, latent variables,
covariates, number of outcomes, interim looks) or better wording.

**What established tools and sources do.** UCLA OARC's test-selection table uses a profile of the number and kind
of outcomes and predictors (opened, as recorded in `routing-audit.md`). G\*Power asks for the
test family and test directly, with no routing (opened, `decision-tree.md`
section 1). No reviewed power tool routes users by questions.

**Who might disagree.** People who like being led one question at a time
may find a six-question screen dense; people who know their design may
find a branching tree slow. Maintainers of the current tests and the 183
recorded walkthrough paths bear the cost of moving.

**Knock-on effects.** Scaling: the roadmap's 49 currently unreachable
rows need roughly 50 to 100 more tree answers, or roughly 100 to 150
table rows in total (both inferred). A profile identifies the design,
not the analysis, so about 25 rows need a "which analysis will you run?"
step (where C10 and C11 sit). Frequentist or Bayesian as a profile
question is call 9.

---

## 2. Effect sizes: empty and justified, suggested values, or sensitivity instead

**The question.** The input screens start with effect sizes empty and
require a value and a justification. Should they offer suggested values
(for example small, medium, large)? And when a user can't justify any
effect size, should powerkit offer a sensitivity analysis (the smallest
effect detectable at the N they can get) instead of asking for a number?

**Options** (B10, B2, G9):
- empty and required with a justification (as built);
- suggested values the user can change, still with a justification;
- benchmarks shown as context only, never filled in (B2);
- sensitivity offered for every end point, alongside the sample size;
- sensitivity as the route when no effect size can be justified;
- both of the last two.

**What established tools and sources do.**
- G\*Power shows Cohen's conventions as tooltips and warns they "may have
  different meanings for different tests" (opened). power4mome's quick
  functions accept "s", "m" and "l" labels (opened).
- The build guide rules out "medium effect" defaults; the spec's
  `effect_justification` exists to prevent them (opened).
- Lakens (2022), "Sample Size Justification": a sensitivity analysis
  "should be compared against a smallest effect size of interest, or a
  range of effect sizes that are expected" (revised manuscript, opened;
  published version's abstract opened).
- Rubin (2024) lists running an a priori analysis "when there is no clear
  basis for an effect size estimate and a sensitivity power analysis is
  more appropriate" as a ritual habit (verified, maintainer).
- Mikael Rubin (2025): power analyses "should be reported as ranges of
  effect sizes, power and sample sizes" (opened).
- G\*Power offers sensitivity as one of its analysis types (opened).

**Who might disagree.** Suggested values help users with no starting
point but anchor them. Sensitivity as the default could let users skip
finding a smallest effect of interest. Users asked by an ethics board or
funder for "the N I need" want that number first.

**Knock-on effects.** Sensitivity runs only for E7 and E8 now; every
other end point needs engine work and validation. A "can't justify one"
option is a schema change (`effect_justification.type`). Result wording
(B11) and a power curve (B13) follow.

---

## 3. Alpha and tails: defaults, or required inputs with a reason

**The question.** Should alpha and one- or two-sided stay pre-filled
(.05, two-sided, labelled as the wrapped tool's default), or be inputs
the user must set with a short reason, as the effect size has?

**Options** (G8, B3, B4):
- pre-filled from the wrapped tool, labelled with its source (as now);
- pre-filled, with a required reason whether kept or changed;
- blank and required, with a required reason;
- required, with an optional reason that goes into the methods paragraph
  when given;
- for target power: blank, .80, .80 with a reason, or .90 (B4).

**What established tools and sources do.**
- pwr, Spower, Superpower and InteractionPoweR all default alpha to .05
  (read from installed signatures). G\*Power asks for the number of tails
  (opened); its alpha is pre-filled (to confirm from screenshots).
- Lakens et al. (2018), "Justify your alpha": *candidate* (not opened;
  described the same way by Uttley, 2019, opened, and Rubin, 2024,
  verified, maintainer).
- Rubin (2021) separates "alpha specification" from alpha adjustment
  (verified, maintainer). Rubin (2024) lists using a two-sided test "when
  a one-sided test is more consistent with one's statistical inference"
  as a ritual habit (verified, maintainer).
- Uttley (2019): one-tailed tests were rarely justified; power 0.15
  one-tailed against 0.09 two-tailed in one example (opened).
- The .80 convention: Cohen (1988) second-hand; reported by Perugini et
  al. (opened).

**Who might disagree.** A required reason slows the many users whose
reason is "convention". The "justify, don't default" view sees a
pre-filled .05 as a nudge to stop thinking. Some would ask for a reason
only when departing from .05 and two-sided.

**Knock-on effects.** A schema change (reason fields for alpha and
tails); the forms; the methods paragraph (call 5); call 4, since an
"any one is enough" claim changes alpha.

---

## 4. Several hypotheses: the inference question, and corrections

**The question.** When a study tests several hypotheses, should powerkit
ask what the user will conclude from them (each on its own, all of them
together, or any one), and set alpha and power to match? Should it ever
correct alpha by default?

**Options** (B6, G7):
- don't ask; each analysis at the alpha entered (as now);
- ask in the single-analysis routes and point to the guided route;
- ask only in the guided route, using Rubin's three cases (individual,
  conjunction, disjunction), worded as in
  [`inference-question-design.md`](inference-question-design.md);
- on corrections: none by default and offered only for "any one is
  enough"; none by default but always show what one would do to N; a
  correction by default whenever there is more than one primary test,
  which the user can turn off with a reason; no prompt.

**What established tools and sources do.**
- Rubin (2021, 2024; verified, maintainer): alpha adjustment is
  appropriate only for disjunction testing; conjunction testing needs no
  adjustment but lowers joint power (.80 × .80 = .64); a correction
  without a union claim is "an inconsistent correction".
- Frane (2019), "Misguided opposition to multiplicity adjustment remains
  a problem": the opposing view by its title (verified, maintainer: the
  reference only; the text was not read).
- Tools: power4mome's `rejection_rates(collapse = )` gives "all_sig" and
  "at_least_one_sig"; Superpower's `ANOVA_power(p_adjust = )` corrects but
  reports power per effect; powertools has co-primary and alternative
  primary functions (all opened).

**Who might disagree.** Those who correct by default see "no correction"
as too lenient; Rubin argues the reverse. Users may not know in advance
which claim they will make. How to plan N for each case is powerkit's
extension of Rubin's framework, not his.

**Knock-on effects.** The guided route's study-level result (D4, D6);
disjunction raises N (alpha divided by the number of tests); conjunction
needs joint power, which needs a whole-study simulation when tests are
correlated; the methods paragraph states the case chosen.

---

## 5. What the methods paragraph must report

**The question.** The methods paragraph (still a placeholder) is what
users paste into papers and preregistrations. Which of a result's outputs
must it state?

**Options (each separately):** the test and its tails; alpha; target
power; the effect size, its format and its source; the N (total, per
group, after attrition); the actual power at the reported N; the backend,
its function and version; the method (formula or simulation, with
replications, seed and Monte Carlo interval); any departures; the
noncentrality parameter, critical value and degrees of freedom where the
backend returns them.

**What established tools and sources do.** CLAUDE.md requires the spec
hash, seed, backend and versions to be recorded, and every departure to
be stated in the methods paragraph (opened). None of powerkit's backends
returns a noncentrality parameter or critical value for E1–E6 or E9–E14
([`gpower-parity.md`](gpower-parity.md)). What G\*Power's output shows
needs the maintainer's screenshots (*candidate* until then). Reporting
guidance for power analyses in psychology journals: *candidate* (not
checked).

**Who might disagree.** Reviewers used to G\*Power reports look for the
noncentrality parameter and critical value. A long paragraph is copied
less faithfully; a short one can drop the effect-size justification.

**Knock-on effects.** The result object may need new outputs; the methods
text and `export_script()`; calls 2 to 4 each add a line (the effect-size
source, the reason for alpha and tails, the inference case).

---

## 6. Hosting, and saving projects

**The question.** How will people other than the maintainer use the app,
and where are their inputs and results kept?

**Options** (from [`hosting-options.md`](hosting-options.md), draft PR #49,
and [`saving-projects.md`](saving-projects.md)):
- run it yourself (the guide and one-line launcher in PR #49);
- shinyapps.io; Posit Connect (self-hosted) or Connect Cloud; a
  university server with Shiny Server; a container service; in the
  browser with webR or Shinylive; a bundled desktop app;
- for saving: a project file the user keeps; autosave in the browser;
  share links; private result links for background jobs; accounts with
  stored projects.

**What established tools and sources do.** G\*Power is a desktop download;
Superpower, InteractionPoweR and power4mome offer R packages, and some
have hosted Shiny apps (*candidate*: which, and where hosted, not
checked). Prices and limits in `hosting-options.md` come from search
results and are marked to check.

**Who might disagree.** A university's data protection officer may prefer
on-premises hosting; users want a link that works without installing R;
the maintainer bears the running cost and upkeep.

**Knock-on effects.** Long simulations block other users on
single-process hosts; webR runs everything on the user's machine but
needs every package available for it (the spike's results are in
`hosting-options.md`); any stored data brings UK GDPR duties; the About
panel and the "Something doesn't fit?" link may need changing for a
hosted version.

---

## 7. Scope for the G\*Power tests powerkit doesn't run

**The question.** For a G\*Power test powerkit doesn't run, what does the
user see?

**Options** (G1): a card saying "G\*Power covers this"; add the tests in
waves (first those a foundation tool already does); out of scope with no
card.

**Evidence.** Of G\*Power's 49 tests, powerkit runs 10, 4 were planned, 23
a foundation tool can do, 11 none covers, and 1 needs checking
([`coverage-roadmap.md`](coverage-roadmap.md), Part A). Wave 2 engine
groundwork (one-way ANOVA, R² against 0 and increase, one proportion,
McNemar, Welch by formula) is in a draft PR, not wired into the app.

**What established tools and sources do.** `coverage.md` proposes "not
planned" for the generic tests and variance tests (opened). The build
guide says basic tests are for "G\*Power parity" (opened).

**Who might disagree.** Users who come from G\*Power expect every test.
Naming G\*Power on a card is naming another tool (call 8). Waves keep
scope small but leave gaps users meet first.

**Knock-on effects.** Cards or none; validation work per test (G\*Power
screenshots for each); call 8.

---

## 8. Naming other tools on cards

**The question.** Should cards for designs powerkit doesn't cover name
other established tools (for example simr, apimpower, PITS), or say only
that established tools exist?

**Options** (A1): name the tools, as `coverage.md` does; the neutral
sentence only, on every "not covered" card.

**What established tools and sources do.** G\*Power, Spower, Superpower,
InteractionPoweR and PAMLj don't point users to other tools (opened,
`decision-tree.md` section 1). The tools themselves are documented
(opened, `card-sources.md`).

**Who might disagree.** Naming tools helps users act, but powerkit hasn't
checked them and a name reads as an endorsement. The neutral sentence can
read as unhelpful or as hiding names that are easy to find.

**Knock-on effects.** Names must be kept current (PITS appeared after E45
was written, A2); every named tool needs a source in `card-sources.md`;
call 7 if G\*Power is named.

---

## 9. Bayesian planning: where it enters

**The question.** Does the screening ask whether the analysis is
frequentist or Bayesian, and where does Bayesian planning sit?

**Options** (G2, D3): a screening or profile question; after Q1; among the
closing questions (as the prototype shows now); only in the shortcut
list; Bayesian planning as its own route.

**What established tools and sources do.** None of the reviewed tools
routes between p-values and Bayes factors (opened). The build guide puts
Bayesian design analysis at "Later", with Spower and BFDA as likely
backends (opened). Spower documents expected power over a prior and
user-written Bayes factor and ROPE experiments (opened, roadmap
B58–B62).

**Who might disagree.** Bayesian users want to say so early; most users
plan with p-values and an extra question adds a step. Expected power over
a prior also suits frequentist users, so it may not belong behind a
Bayesian question.

**Knock-on effects.** The screening (C1); which end points need a
Bayesian version; call 1 if it becomes a profile question.
