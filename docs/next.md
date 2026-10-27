# What to work on next

*27 October 2026. The ordered answer to "work on the next thing". One
queue, newest decisions folded in; [`status.md`](status.md) says where the
project is, this says what to do.*

**How a thread uses this page**

1. Read the top of the queue. Take the **first item marked Ready**.
2. If an item says *Needs a decision*, it is not yours to start: say what
   the decision is and move to the next Ready item, or ask the maintainer.
3. Follow [`adding-a-test.md`](adding-a-test.md) for anything that adds a
   power analysis. One item per PR.
4. When an item lands, delete its row and say so in `status.md`.
5. **Check the top item still makes sense before starting.** This page is
   dated; a queue written three weeks ago can be stale, and the
   maintainer's priorities beat it.

## The queue

| # | What | Why it matters | Size | State |
| --- | --- | --- | --- | --- |
| 1 | **Whole-study simulation, as an option** | One model for the whole study, simulated by an existing package, gives power for every main analysis from the same data and one N, and gets "every result must be significant" exactly. New, so it is recorded as a departure and checked by a statistician before it is offered (decided 26 October 2026) | L | Needs a decision: a statistician's check of the method, and which package covers the plan's combinations (power4mome is the candidate), and a check of the method |
| 2 | **Safeguard power for a pilot-derived effect** | Offer the lower confidence bound when an effect size comes from a pilot or a single study, so a noisy estimate doesn't produce an underpowered study. Read Perugini et al. before building | M | Ready (read the method first) |
| 3 | **Welch's one-way ANOVA** | Three or more groups with unequal variances. powerkit has Welch's t-test but only the equal-variance F for k groups, and unequal variances are the norm | M | Needs a decision: which package, and whether it is a departure from A23's omnibus F |
| 4 | **Pitman-Morgan test: variances in a paired design** | The sibling of the two variance tests just built; a pre-post design asking whether responses became more consistent has nowhere to go | M | Needs a decision: no foundation package covers it, so the method and package come first |
| 5 | **Equivalence and non-inferiority (TOST)** | Psychologists cannot currently show an effect is absent, and p > .05 does not do it. G\*Power has nothing; the screening question already routes to E36, which says "not in powerkit yet" | L | Needs a decision: TOSTER or another package, and which tests first (independent, paired, one-sample, correlations) |
| 6 | **Repeated measures, within factors with three or more levels** (A27, A28) | The standard cognitive-psychology design. E8 covers 2 x 2 mixed only | L | Needs a decision: Superpower's within-factor route, and whether to report the MANOVA approach alongside the ANOVA one |
| 7 | **Repeated measures, within-between interactions beyond 2 x 2** (A29, A30) | The classic randomised trial test, Group x Time, with more than two timepoints | L | Needs a decision: as above, plus how the sphericity correction is asked for |
| 8 | **Spearman's rho and Kendall's tau** | Rank correlations are used constantly for skewed or ordinal measures, and powerkit offers only Pearson's r | M | Needs a decision: method (asymptotic relative efficiency, or simulation) and package |
| 9 | **Multilevel and clustered designs: the method decision** | Where psychologists most often give up and guess: pupils in classes, patients in clinics, trials within participants. The decision needs a statistician, so it is its own step | L | Needs a decision: closed-form design effect or simulation (simr), and who checks it |
| 10 | **Multilevel: build the two-level clustered design** | The first design from that decision, with the intraclass correlation and cluster size asked for in plain words | L | Blocked by 9 |
| 11 | **Download a synthetic data set with the R script** | Registered reports: write and pre-register the analysis code against simulated data before recruiting. The engine already generates one data set per run for its check run | M | Needs a decision: how it is labelled as simulated, and the wording that stops it reading as a substitute for the analysis plan |
| 12 | **SEM, CFA and measurement invariance: the decision and the first design** | Scale development and latent models are a fifth of modern psychology and G\*Power cannot touch them | L | Needs a decision: semPower, and which of fit, invariance or a latent path comes first |
| 13 | **Validation catch-up** | Everything added since 22 October has validation files with placeholders. Transcribe, run the full validation, update the log, and move card statuses from "validation in progress" to validated where they pass | M | Needs the maintainer: the published values and the full run are theirs |

## The direction behind the methods map

The map is the first step towards something larger the maintainer wants:
showing researchers the different ways a question could be answered, not
only the test that fits the design they have already chosen. Later nodes
need not compute anything. Row D1 (qualitative sample size) is marked out
of scope today because there is "no statistical test or estimate to plan
for", which is right for a calculator and wrong for a map: Malterud,
Siersma and Guassora's information power (Qualitative Health Research,
2016) justifies a qualitative sample size at the design stage through five
dimensions and explicitly is not a formula — exactly the kind of framework
powerkit could present honestly without inventing any maths. **D1 is
therefore a question for the maintainer again, not a settled no.** Its
reference has to go through `refs.bib` before it is quoted anywhere.

The first version (a pan-and-zoom diagram, `decisions.md`, 27 October
2026) is in Labs. Still to come there: charts on each analysis's page,
whether to add a sourced reading list per analysis (the maintainer's
call), and nodes for approaches powerkit doesn't compute.

## Fold into whichever PR touches the area

- Delete a design's row from `forms.yaml`'s `engine_only` when its card and
  input screen land (a test will fail if you forget).
- [`build-guide.md`](build-guide.md) section 8's phase table still reads as
  though phases 0-2 are the frontier; refresh it when next in that file.
- Raise the Spower faults upstream: the reproducible example is ready at
  `docs/upstream/spower-var-test.R`
  ([`upstream-questions.md`](upstream-questions.md)).

## Waiting on the maintainer, not a PR

- **Published values** (`TODO_PUBLISHED_VALUE`) for every validation file,
  and the full validation run on your own machine.
- **Six roadmap rows that need G\*Power itself** (A22, A38, A42, A46, A48,
  A49): the manual has no example for them.
- **The logistic R-squared question** (Known difference 3): whether
  powerkit's reading of "R² other X" matches G\*Power's.
- **Which batch comes after 1**, if the order above is wrong.
