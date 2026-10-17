# Routing design options: question tree or design profile

*Last updated: 17 October 2026.*

Options and evidence only. **Nothing here is decided or recommended**; the
maintainer decides. Counts of prevented misroutes are judgements made for
this page from the recorded paths, marked "likely", not tests.

Sources: [`routing-audit.md`](routing-audit.md) (29 designs and the 32
UCLA OARC rows), [`walkthroughs.md`](walkthroughs.md) (flags F1–F15),
[`coverage-roadmap.md`](coverage-roadmap.md) (118 tests and designs),
`app/routing/tree.yaml` and `app/routing/R/tree.R` on `main`.

## The approaches

### A. The current question tree

Every route starts with four screening questions: S1 outcome, S2 how data
are grouped, S3 measurements per person, S4 goal (with T1 for repeated
measurements, and O5a for a rating item). Then:

- **Help me choose** asks a branching tree: Q1 "What do you want your
  study to show?" (difference, relationship, moderation, mediation,
  both, absence, model fit), then branch-specific questions;
- **I know my analysis** is the list of end points, filtered by the
  screening answers;
- **Plan my whole study** (guided) asks about variables (X, outcome,
  mediators, moderator, covariates) and maps them to an end point with
  ordered rules in `tree.yaml` (`guided: analyses: rules`; the first rule
  whose `when` matches wins).

Size today: 48 question nodes with 108 answers, 49 end cards (E1–E47,
E-unsure, E-bayes), and a separate rule list for the guided route.

The screening (added after the audit, PR #18) is already four of the six
profile questions below, and the guided route is already a rule table.
So the choice is less "tree or table" than how far to go in that
direction.

### B. Design profile, all questions on one screen

The same six questions every time, in every route, and a rule table that
maps each combination of answers to a card:

1. **Outcome type:** a score; yes/no; one of several categories; a count;
   ordered categories; time until an event.
2. **What's compared or predicted:** one group against a fixed value; two
   groups of different people; two conditions with the same people;
   three or more groups or conditions; two crossed factors; a
   relationship between two measured variables; an effect that depends
   on a third variable (moderation); an effect through a go-between
   (mediation); mediation with a moderated path; a model's fit or a
   latent structure.
3. **How data are grouped:** independent people (or one person or unit);
   people within groups; pairs; many trials or stimuli per person.
4. **Measurements per person:** once; twice; three or more conditions;
   many over time.
5. **Goal:** detect an effect; show there is no meaningful effect
   (equivalence or non-inferiority); estimate an effect precisely.
6. **Frequentist or Bayesian:** p-values; Bayes factors or posterior
   probabilities (judgement call G2).

Every question keeps "None of these fit / I'm not sure". The rule table is
in the spirit of the UCLA OARC table, whose dimensions are the number and
kind of outcomes and the number and kind of predictors (the audit's
cross-check). Its table isn't reproduced here.

**Exact matching.** For the table to prevent misroutes rather than move
them, a combination with no row should go to the safety net, not to the
nearest row. The guided route's rules today are first-match with broad
last rules (for example, a measured X with any score outcome reaches E4),
which is how a curvilinear relationship still reaches E4 there.

### C. Design profile, one question at a time

The same six questions and rule table as B, shown one per screen, with
the list of cards that still fit shrinking after each answer (the
end-point list already does this for the screening answers, flag F5).
Answers that leave no card can be greyed out or lead to the safety net
straight away. This is closest to how the screening works today.

### D. Profile plus follow-ups (a hybrid)

Either B or C for the six questions, then card-specific follow-ups where
the profile leaves several cards (for example the number of mediators,
which path a moderator acts on, 2 x 2 or larger, a yes/no X). Today's Q2
and Q3 questions would become these follow-ups. Any profile approach
needs this step for E1–E14 (see the rule table below), so B and C in
practice are D.

## Past misroutes, and which approach would likely have prevented them

28 misroutes or route conflicts recorded in the audit (before and after
PR #18), the UCLA OARC cross-check and the walkthrough flags. "Now" is the
current tree after the fixes in PRs #18, #21 and #22. "Profile" asks
whether a profile approach with exact matching, designed from the start,
would likely have avoided it.

| # | Misroute (source) | Now | Profile | Why |
| --- | --- | --- | --- | --- |
| M1 | Segmented regression to E3, E2 or E4 (audit) | Fixed (S3, T1) | Likely yes | Measurements = many over time, and "compared" = a change in trend |
| M2 | Nested data with a yes/no outcome to E5; guided to E2 (audit) | Fixed (S2) | Likely yes | Grouping is asked for every outcome |
| M3 | Crossed trials with a yes/no outcome to E26; relationship to E4 (audit) | Fixed (S2) | Likely yes | Grouping |
| M4 | Cluster-randomised answered "different people" to E2 or E5 (audit) | Fixed (S2 wording) | Partly | Depends on S2's wording, as now |
| M5 | Dyads to E4 or E2 (audit) | Fixed (S2) | Likely yes | Grouping = pairs |
| M6 | Growth curves in the guided route to E23 or E8 (audit) | Fixed (S3) | Likely yes | Measurements |
| M7 | Diary/EMA in the guided route to E23 or E8 (audit) | Fixed (S3) | Likely yes | Measurements |
| M8 | Time series in the guided route to E2 or E4 (audit) | Fixed (S3, T1) | Likely yes | Measurements |
| M9 | Time-to-event to E2 or E4 (audit) | Fixed (S1) | Likely yes | Outcome type |
| M10 | Equivalence in the guided route planned as detection (audit) | Fixed (S4) | Likely yes | Goal |
| M11 | Precision to E2 or E4 (audit) | Fixed (S4) | Likely yes | Goal |
| M12 | Curvilinear effect to E4 (audit) | Open | No | No dimension for the shape of an effect |
| M13 | Latent-variable path entered as mediation to E10 (audit) | Partly (Q1 wording) | No | No dimension for latent variables |
| M14 | Factorial logistic regression to E5 (UCLA) | Fixed (E47) | Likely yes | Outcome × two crossed factors has its own row |
| M15 | Chi-square goodness-of-fit to E25 or E6 (UCLA) | Open | Likely yes | Categories × one group against fixed values: no row, so the safety net |
| M16 | Guided route ignored "Twice" (F1) | Fixed | Likely yes | One table for every route |
| M17 | Guided route had no several-category outcome (F2) | Fixed | Likely yes | One outcome question for every route |
| M18 | Factorial logistic regression: opposite advice by route (F3) | Partly (E32 through Q1's moderation answer, C7) | Likely yes | One table, so routes can't disagree |
| M19 | Non-baseline covariate in a two-group comparison to E2 (F4) | Open | No | Covariates aren't one of the six |
| M20 | Rank-based tests and MANOVA to parametric or single-outcome cards (F6) | Open | No | Same profile as the parametric test; number of outcomes isn't asked |
| M21 | SEM in the guided route to E4 (F8) | Open | No | No latent dimension |
| M22 | Diary within-person relationship to E35 rather than E41 (F12) | Open | Likely yes | "Compared" = a relationship is asked whatever the timing |
| M23 | Test–retest reliability to E41 or E4 (F11; audit) | Open | Partly | Goal = precision catches a CI-width plan; a reliability coefficient isn't a profile value |
| M24 | Several categories measured twice to E26 (audit item 12) | Open | Likely yes | No row, so the safety net |
| M25 | Two groups, yes/no, measured twice to E26 in "Help me choose" (audit item 13) | Partly (guided gives the safety net) | Likely yes | No row, so the safety net |
| M26 | Sequential designs reach fixed-sample cards (audit item 4) | Open | No | Interim looks aren't one of the six |
| M27 | Counts in the relationship path to E4 (audit) | Fixed (S1) | Likely yes | Outcome type |
| M28 | Matched pairs answered "Pairs" to E44 (audit item 8) | Open | No | A wording problem in either approach |

**Totals.**

| | Prevented | Partly | Not prevented |
| --- | --- | --- | --- |
| Current tree, after three rounds of fixes | 15 | 3 | 10 |
| Design profile with exact matching (likely) | 19 | 2 | 7 |

Most of the current tree's 15 fixes came from adding the screening, which
is a partial profile: 12 of the 15 were fixed by S1–S4 or T1. The profile
would likely add M15, M18 (fully), M22, M24 and M25, all through one table
for every route or "no row means the safety net". Neither approach
prevents M12, M13, M19, M20, M21, M26 or M28 without a further dimension
(shape of the effect, latent variables, covariates, number of outcomes,
interim looks) or better wording. Whether C (one at a time) prevents more
than B can't be told from these records: they record paths, not whether
users misread a question shown alongside others.

## How each approach scales to the roadmap

The [roadmap](coverage-roadmap.md) has 118 tests and designs in Parts A
and B; 69 reach a card for their own analysis today, and 49 can't be
reached as themselves.

**Current tree (A).** Each new card needs a branch in "Help me choose", a
rule in the guided route, an entry in the list, and tests that the three
agree (the walkthroughs found six conflicts between routes in 61
examples, F1–F6). At today's ratio of about 2.2 answers per card, the 49
unreachable rows would need roughly 50–100 more answers (inferred), spread
across the branches, and most branches would need to ask about things the
screening already asked. The audit's open items show the pattern: each
needs a new question in one branch (C5, C6, C7, C12, C15).

**Design profile (B, C, D).** The six questions stay fixed; growth is in
rows of the table and in follow-ups. From the roadmap (inferred):

- about 25 rows share a profile with another row and differ only in the
  analysis chosen (for example, t-test, Welch, Wilcoxon and permutation
  tests for two groups; Fisher's exact, the unconditional exact test and
  the z test; the ANOVA and MANOVA approaches to repeated measures; fixed
  and random predictors in regression). A profile identifies the design,
  not the analysis, so these need an "which analysis will you run?" step
  after the table, which is where judgement calls 3.7–3.9 sit;
- about 20 rows need a value or dimension the six don't have: number of
  outcomes (MANOVA, Hotelling's T²), latent variables (SEM, CFA,
  invariance, latent interactions and mediation), comparing correlations
  (A4–A6), covariates, shape of the effect, interim looks, a prior
  (Bayesian rows), and the applied designs in roadmap B63–B66 (diagnostic
  accuracy, prediction models, single-case, prevalence);
- the rest map to a row of the six.

A table for the whole roadmap would have roughly 100–150 rows (inferred),
each testable on its own: every row can be checked against the roadmap
and the walkthroughs automatically, and the routes can't disagree because
they share it.

**Costs of moving.** The routing prototype, its tests (`test-tree.R`,
`test-misroutes.R`, `test-walkthroughs.R`, `test-walkthrough-fixes.R`) and
the 183 recorded walkthrough paths are built on the tree. The screening and
the guided route's rule format could be kept; Q1 and the branch questions
would become follow-ups or go.

## Draft rule table for E1–E14

Columns are the six profile questions, then any follow-up the card needs.
Unless a row says otherwise: grouping = independent people, goal = detect,
framework = frequentist. "Any" means the row doesn't depend on that
answer. Rows are matched exactly; anything without a row goes to E-unsure.

| Rule | Outcome | Compared or predicted | Measurements | Follow-up | Card |
| --- | --- | --- | --- | --- | --- |
| R1 | Score | One group against a fixed value | Once | — | E1 |
| R2 | Score | Two groups of different people | Once | Student or Welch (closing question) | E2 |
| R3 | Score | Two conditions, same people | Twice | — | E3 |
| R4 | Score | A relationship between two measured variables | Once | — | E4 |
| R5 | Yes/no | Two groups of different people | Once | — | E5 |
| R6 | Yes/no or several categories | Two or more groups of different people, or a relationship between two categorical variables | Once | — | E6 |
| R7 | Score | Two crossed factors | Once | Each factor two levels, both between people | E7 |
| R8 | Score | Two crossed factors | Twice | One factor between, one within, each two levels | E8 |
| R8b | Score | Two groups of different people | Twice | "Which analysis?" (today's PP2: ANCOVA, E23, or the group × time interaction, E8) | E8 or E23 |
| R9 | Score | Moderation | Once | X and W both measured scores | E9 |
| R10 | Score | Mediation | Once | One mediator (a score); X a score | E10 |
| R11 | Score | Mediation | Once | Two or more mediators, side by side | E11 |
| R12 | Score | Mediation | Once | Two or more mediators, in sequence | E12 |
| R13 | Score | Mediation with a moderated path | Once | The moderator acts on X → M | E13 |
| R14 | Score | Mediation with a moderated path | Once | The moderator acts on M → Y | E14 |

Exits that apply before these rows (as the screening does today):

| Rule | Answer | Card |
| --- | --- | --- |
| X1 | Grouping: people within groups | E34 |
| X2 | Grouping: pairs | E44 |
| X3 | Grouping: many trials or stimuli per person | E33 |
| X4 | Measurements: many over time | E35 or E45 (today's T1) |
| X5 | Goal: no meaningful effect | E36 |
| X6 | Goal: estimate precisely | E46 |
| X7 | Outcome: a count | E28 |
| X8 | Outcome: time until an event | E43 |
| X9 | Outcome: ordered categories | O5a, then the score rows or E29 |
| X10 | Framework: Bayesian | E-bayes |
| X11 | No row matches | E-unsure |

What the draft shows:

- E1–E6 are fully determined by the profile; E7–E14 need one follow-up
  each, and E2, E8 and E23 need a "which analysis?" step;
- a yes/no X or W (E15–E17) is a follow-up on R9–R14, not a profile value;
- R2/R3 depend on separating "two groups of different people" from "two
  conditions, same people" in question 2 rather than inferring it from
  question 4: a pre–post study with two groups (R8b) answers "twice" too.

## Open points for the maintainer

- Which approach, A to D, and whether to keep the guided route's rule
  format as the shared table.
- Whether unmatched combinations go to the safety net (exact matching)
  or the nearest row (first-match, as the guided route does now).
- Whether question 6 (frequentist or Bayesian) is asked of everyone
  (judgement call G2).
- Which extra dimensions, if any, to add for the misroutes neither
  approach prevents (M12, M13, M19, M20, M21, M26).
