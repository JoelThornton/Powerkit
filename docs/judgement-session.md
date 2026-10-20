# Judgement session: the open calls that change what users see

*Prepared 18 October 2026 for the maintainer's judgement session;
updated the same day after the maintainer approved the new design
([`decisions.md`](decisions.md), "The new design").*

This is an agenda, not a decision record. Item 1 (added 18 October
2026) ends with Claude's recommendation; the other items give options
only, in the order of their source entries. Each call fits on about a
page; the full evidence, quotations and page numbers are in the linked
entries of [`judgement-calls.md`](judgement-calls.md) and the other
documents named.

**Order.** By impact: how many users and results the call touches. Calls
that change every route or every result come first; calls that affect
one kind of user or one kind of card come last.

**How sources are marked** (as in `judgement-calls.md`): *opened* (the
source was read), *verified, maintainer* (the maintainer checked the full
text), *second-hand* (seen quoted elsewhere, to verify), *candidate* (not
checked). "Who might disagree" is reasoning about positions, not reports
of what named people said.

**What the 18 October decisions removed or shrank.**
- Removed: alpha and tails (G8, B4) and sensitivity (G9) are decided,
  and so is the default correction (G7). They are in
  [`archive/judgement-calls-decided.md`](archive/judgement-calls-decided.md).
- Shrunk: effect sizes (B10 mostly decided; B2's benchmarks remain);
  several hypotheses (B6: the start screen's four claim options are
  decided; power for "all of several" and the guided route remain);
  naming other tools (A1: decided for E36 and E46).
- Moved: whether to ask "Do you predict a direction?" (B18, with B3) is
  handled separately, not in this session.
- New: item 1 replaces the old routing item. It now starts from screen A.

| # | Call | Touches | Detail |
| --- | --- | --- | --- |
| 1 | Routing: screen A as the start of the profile; tree or profile for screen B | every user, every route | `routing-design-options.md`; D1, D2 |
| 2 | Effect-size benchmarks as context | every result | B2 |
| 3 | Several hypotheses: what the claim options leave open | every study with more than one test | B6, D4, D6 |
| 4 | What the methods paragraph must report (decided 18 October 2026) | every write-up | G4 |
| 5 | Hosting (and saving projects) | whether, and how, others can use the app | `hosting-options.md`; `saving-projects.md` |
| 6 | Scope for the G\*Power tests powerkit doesn't run | users coming from G\*Power | G1; `coverage-roadmap.md` |
| 7 | Naming other tools on cards | users whose design isn't covered | A1, A2, A4 |
| 8 | Bayesian planning: where it enters | Bayesian users | G2, D3 |

---

## 1. Routing: screen A as the start of the profile, then tree or profile

**The question.** Screen A (Start) asks the situation (N fixed or not),
the aim (test a prediction, estimate, show no meaningful effect) and the
claim (one test, several each on its own, any of several, all of
several). Today the routing asks the same things in other places: S4
(goal), Q1's "absent" option, and the closing questions Q-goal and
Q-multi. How do screen A and the design finder (screen B) fit together
without asking twice or contradicting each other? And once they do,
should screen B stay a question tree or become a design profile? The
maintainer asked that screen B not stay "unchanged for now"
indefinitely.

**Options** (from [`routing-design-options.md`](routing-design-options.md),
"Screen A as the start of the profile"):
- for screen A: its answers as the first part of the profile, stored
  once, with S4, Q1's "absent" option, Q-goal and Q-multi removed from
  screen B; or screen A on top of the tree, with the old questions
  pre-filled but still shown;
- for screen B: A. keep the question tree; B. profile, all questions on
  one screen; C. profile, one question at a time; D. profile plus
  follow-ups (B or C in practice need this for E1–E14);
- within B to D: unmatched answers go to the safety net (exact matching)
  or to the nearest row.

**Evidence.** 28 misroutes or route conflicts are recorded. Judged from
the recorded paths ("likely", not tested): the current tree, after three
rounds of fixes, prevents 15, partly 3, not 10; a profile with exact
matching would likely prevent 19, partly 2, not 7. 12 of the tree's 15
fixes came from the screening, which is already a partial profile. With
screen A in place the profile has five questions, not six (screen A's
aim is the old goal question).

**What established tools and sources do.** UCLA OARC's test-selection
table uses a profile of the number and kind of outcomes and predictors
(opened, as recorded in `routing-audit.md`). G\*Power asks for the test
family and test directly, with no routing (opened, `decision-tree.md`
section 1). No reviewed power tool routes users by questions. PAMLj asks
its "aim" first (opened, D2).

**Who might disagree.** People who like being led one question at a time
may find a screen of questions dense; people who know their design may
find a branching tree slow. Maintainers of the current tests and the 183
recorded walkthrough paths bear the cost of moving.

**Knock-on effects.** Build step 4 (screen A and the fixed-N route) puts
screen A on top of the current tree, hiding S4, Q-goal and Q-multi and
filling them from screen A, so nothing clashes in the meantime. The
roadmap's 49 currently unreachable rows need roughly 50 to 100 more tree
answers, or roughly 100 to 150 table rows in total (both inferred). A
profile identifies the design, not the analysis, so about 25 rows need a
"which analysis will you run?" step. Frequentist or Bayesian as a
profile question is item 8.

**Recommendation:** screen A's answers as the first part of the profile,
and D (profile plus follow-ups) for screen B, with exact matching, one
question at a time, built after build step 7 and before the first round
of user testing. Reason: screen A already makes the start a profile,
one table stops the routes disagreeing, and the recorded misroutes
favour it.

---

## 2. Effect-size benchmarks as context

**Decided 18 October 2026:** effect-size fields stay empty, with a source
and a short rationale required to save or export; "I can't justify one"
leads to the smallest detectable effect; a published-study source warns
that published effects tend to be inflated and points to BUCSS (B10, G9,
B2 in part). What remains is below.

**The question.** Should small, medium and large benchmarks be shown at
all, even as context and never filled in?

**Options** (B2): don't show benchmarks; show them as context only,
never as defaults.

**What established tools and sources do.**
- G\*Power shows Cohen's conventions as tooltips and warns they "may have
  different meanings for different tests" (opened). power4mome's quick
  functions accept "s", "m" and "l" labels (opened).
- The build guide rules out "medium effect" defaults; the spec's
  `effect_justification` exists to prevent them (opened).

**Who might disagree.** Benchmarks as context still anchor users. Users
with no starting point guess worse without them.

**Knock-on effects.** Hints must keep explaining meaning, not values (a
test checks this); setting `effect_size_benchmarks`.

---

## 3. Several hypotheses: what the claim options leave open

**Decided 18 October 2026:** screen A asks every user what the main
claim rests on: one test; several claims, each standing on its own (no
correction); any of several (Bonferroni; the claim is about the set);
all of several (guidance only: the chance all succeed is lower than any
one test's power, and with tests on the same people the product is
roughly a floor). No correction by default (G7). What remains is below.

**The question.** For "all of several", is guidance enough, or should
powerkit compute joint power where a backend can? And how does the
guided route ("plan my whole study") report a study with several tests?

**Options** (B6, D4, D6): guidance only (v1, as decided); joint power
where a backend gives it (power4mome's `rejection_rates(collapse =
"all_sig")`, powertools' co-primary functions); a whole-study simulation
in the guided route.

**What established tools and sources do.**
- Rubin (2021; verified, maintainer): conjunction testing needs no alpha
  adjustment but lowers joint power (.80 × .80 = .64, p. 7). Neither of
  his papers sets out how to plan N for each case; that is powerkit's
  extension, still to be reviewed.
- Tools: power4mome's `rejection_rates(collapse = )` gives "all_sig" and
  "at_least_one_sig"; powertools has co-primary and alternative primary
  functions (opened).

**Who might disagree.** Users may not know in advance which claim they
will make. Joint power computed by powerkit itself, without a backend,
would be new maths (CLAUDE.md).

**Knock-on effects.** The guided route's study-level result (D4, D6);
the write-up states the claim chosen; the option wording is still to be
reviewed.

---

## 4. What the methods paragraph must report

Decided 18 October 2026 ([`decisions.md`](decisions.md)); the write-up is on the result screen. Kept here so the numbering stays the same.

## 5. Hosting, and saving projects

**The question.** How will people other than the maintainer use the app,
and where are their inputs and results kept?

**Options** (from [`hosting-options.md`](hosting-options.md),
and [`saving-projects.md`](saving-projects.md)):
- run it yourself (the guide and one-line launcher, merged in PR #49);
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

## 6. Scope for the G\*Power tests powerkit doesn't run

**The question.** For a G\*Power test powerkit doesn't run, what does the
user see?

**Options** (G1): a card saying "G\*Power covers this"; add the tests in
waves (first those a foundation tool already does); out of scope with no
card.

**Evidence.** Of G\*Power's 49 tests, powerkit runs 10, 4 were planned, 23
a foundation tool can do, 11 none covers, and 1 needs checking
([`coverage-roadmap.md`](coverage-roadmap.md), Part A). Wave 2 engine
groundwork (one-way ANOVA, R² against 0 and increase, one proportion,
McNemar, Welch by formula) is in the engine (PR #51), not yet in the
app.

**What established tools and sources do.** `coverage.md` proposes "not
planned" for the generic tests and variance tests (opened). The build
guide says basic tests are for "G\*Power parity" (opened).

**Who might disagree.** Users who come from G\*Power expect every test.
Naming G\*Power on a card is naming another tool (item 7). Waves keep
scope small but leave gaps users meet first.

**Knock-on effects.** Cards or none; validation work per test (G\*Power
screenshots for each); item 7.

---

## 7. Naming other tools on cards

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
item 6 if G\*Power is named.

---

## 8. Bayesian planning: where it enters

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
Bayesian version; item 1 if it becomes a profile question.
