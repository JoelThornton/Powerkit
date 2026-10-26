# What to work on next

*26 October 2026. The ordered answer to "work on the next thing". One
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
| 1 | **Two dependent correlations in the app**: its own card and input screen | Comparing two correlations in one sample is common and G\*Power's version is hard to drive | M | Ready |
| 2 | **The two variance tests in the app**: cards, input screen, and a finder question ("is your hypothesis about how much scores vary?") | Last of the five designs the engine can run but nobody can reach. Needs a route in the finder, not just a listing | M | Ready |
| 3 | **Let the app's own checks run in CI**: set `NOT_CRAN: true` in `routing-prototype-tests.yaml` and fix what it catches | Six tests skip in CI today, including the one that checks the app's result equals the engine's and that the downloaded script reproduces it. The most valuable test in the suite has never run | S | Ready |
| 4 | **Make CI fast and independent of CRAN**: cache the apt packages and run on an image with the locked R version already installed | On 26 October every job spent about 28 of its 35 minutes downloading R and system libraries before any code ran, and three checks failed outright on `curl: (28)` to cran.r-project.org. Our package cache is fine (17 seconds); it is R itself and apt that crawl | M | Ready |
| 5 | **Labs tool 2: a map of the method space**, generated from `tree.yaml`, grouped by the research question being asked, each node opening a page about that test with charts and its status | Psychologists can't look up a design they don't know exists, and a flat list of 52 cards doesn't show the landscape or the gaps. Generated, it can't rot; in Labs, it risks nothing on the fast path. SAGE's Methods Map is the nearest thing and is paywalled and doesn't compute anything | L | Needs a decision: the shape (grouped grid first, pan and zoom only if it earns the dependency), and whether a sourced reading list per test is wanted later |
| 6 | **Whole-study plan: the combined sample size** | "Plan my whole study" promises it and shows "Coming soon". Once each analysis on the plan opens its input screen, the plan can collect the N each main analysis needs and report the largest, naming the analysis that sets it (the rule recorded in `decisions.md`, 22 October 2026). Without it the user does this by hand | M | Ready |
| 7 | **Whole-study plan: consistency between analyses** | The plan already lists relationships two analyses share (for example, the effect of X on the outcome is the total effect in a mediation), but nothing checks that the values entered for them agree; entered on separate forms they can contradict each other and the plan's N is then right for no single study ([`decision-tree.md`](decision-tree.md) 4.2) | M | Needs a decision: open question 12 (setting `consistency_approach`): a check across per-analysis forms (recommended: it keeps each backend's established method), whole-study simulation from one model, or both |
| 8 | **Effect size in the measure's own units** | The last piece of the effect-size help: let a user say "4.5 against 3.8 on a 1-7 scale, SD 1.2" and have the engine convert. The commonest way a power analysis goes wrong is a number the researcher can't justify | M | Ready |
| 9 | **A power curve with three lines**: optimistic, expected, conservative | One number hides how sensitive the answer is to being wrong about the effect; three lines show it at a glance | M | Ready |
| 10 | **Safeguard power for a pilot-derived effect** | Offer the lower confidence bound when an effect size comes from a pilot or a single study, so a noisy estimate doesn't produce an underpowered study. Read Perugini et al. before building | M | Ready (read the method first) |
| 11 | **Welch's one-way ANOVA** | Three or more groups with unequal variances. powerkit has Welch's t-test but only the equal-variance F for k groups, and unequal variances are the norm | M | Needs a decision: which package, and whether it is a departure from A23's omnibus F |
| 12 | **Pitman-Morgan test: variances in a paired design** | The sibling of the two variance tests just built; a pre-post design asking whether responses became more consistent has nowhere to go | M | Needs a decision: no foundation package covers it, so the method and package come first |
| 13 | **Equivalence and non-inferiority (TOST)** | Psychologists cannot currently show an effect is absent, and p > .05 does not do it. G\*Power has nothing; the screening question already routes to E36, which says "not in powerkit yet" | L | Needs a decision: TOSTER or another package, and which tests first (independent, paired, one-sample, correlations) |
| 14 | **Repeated measures, within factors with three or more levels** (A27, A28) | The standard cognitive-psychology design. E8 covers 2 x 2 mixed only | L | Needs a decision: Superpower's within-factor route, and whether to report the MANOVA approach alongside the ANOVA one |
| 15 | **Repeated measures, within-between interactions beyond 2 x 2** (A29, A30) | The classic randomised trial test, Group x Time, with more than two timepoints | L | Needs a decision: as above, plus how the sphericity correction is asked for |
| 16 | **Spearman's rho and Kendall's tau** | Rank correlations are used constantly for skewed or ordinal measures, and powerkit offers only Pearson's r | M | Needs a decision: method (asymptotic relative efficiency, or simulation) and package |
| 17 | **Multilevel and clustered designs: the method decision** | Where psychologists most often give up and guess: pupils in classes, patients in clinics, trials within participants. The decision needs a statistician, so it is its own step | L | Needs a decision: closed-form design effect or simulation (simr), and who checks it |
| 18 | **Multilevel: build the two-level clustered design** | The first design from that decision, with the intraclass correlation and cluster size asked for in plain words | L | Blocked by 17 |
| 19 | **Download a synthetic data set with the R script** | Registered reports: write and pre-register the analysis code against simulated data before recruiting. The engine already generates one data set per run for its check run | M | Needs a decision: how it is labelled as simulated, and the wording that stops it reading as a substitute for the analysis plan |
| 20 | **SEM, CFA and measurement invariance: the decision and the first design** | Scale development and latent models are a fifth of modern psychology and G\*Power cannot touch them | L | Needs a decision: semPower, and which of fit, invariance or a latent path comes first |
| 21 | **Validation catch-up** | Everything added since 22 October has validation files with placeholders. Transcribe, run the full validation, update the log, and move card statuses from "validation in progress" to validated where they pass | M | Needs the maintainer: the published values and the full run are theirs |

## The direction behind item 5

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
