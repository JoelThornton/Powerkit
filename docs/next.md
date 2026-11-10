# What to work on next

*10 November 2026: broad first-release support, case-level evidence and a measured coverage benchmark now lead the queue. Implementation does not imply validation; the current state is in [status.md](status.md).*

**How a thread uses this page**

1. Take the first item marked Ready in the queue.
2. If an item says *Needs a decision*, it is not yours to start: say what
   the decision is and move to the next Ready item, or ask the maintainer.
3. Follow [`adding-a-test.md`](adding-a-test.md) for anything that adds a
   power analysis. One item, or a group of closely related ones, per PR
   (`CLAUDE.md`, "Working process").
4. When an item lands, delete its row and say so in `status.md`.
5. **Check the top item still makes sense before starting.** This page is
   dated; a queue written three weeks ago can be stale, and the
   maintainer's priorities beat it.

The 10 November default review made between-study variation an explicit
optional scenario and added power at the actual analysed N to smaller-effect
comparisons (open PR; saved values retained). Next, continue the departure
audit for analysis mismatches: mediation ML/Monte Carlo versus PROCESS
OLS/bootstrap, continuity-corrected proportions tests, fixed/random
predictors and family-level claims. This is part of the selected-variant
audit below; none is resolved merely by changing labels. The open PR now
adds a selectable OLS/casewise-percentile-bootstrap route, paired regression
checks and a dedicated null-calibration job. Finish and archive its results
and the direct PROCESS-software comparison before claiming equivalence.

## The queue

| # | What | Why it matters | Size | State |
| --- | --- | --- | --- | --- |
| 1 | **Audit first-release support at the selected-variant level** | The goal is over 99% of primary quantitative psychology analyses in a representative benchmark, including complex designs; no percentage is established yet. The generated source inventory and 18 complex-design briefs are in [v1-support-plan.md](v1-support-plan.md) | M | Ready: complete P0 case specifications and code/evidence audits first; extend the existing registry only from recorded results, then prioritise missing variants |
| 2 | **Investigate the two scientific validation failures** | The last completed nightly run (42570428222, 9 November) failed mixed-ANOVA GG and model-7 binary-X null checks; the 10 November run (42772650889) also failed these chunks | M | Ready: the GG independent reference and fixed-epsilon experiment are recorded (10 November); finish its approximation audit and current-version reproduction. Next run the paired binary-X calibration comparison and prepare author-review dossiers; preserve expected values and tolerances |
| 3 | **Build the representative coverage benchmark and archive protocol** | Cards and a synthetic design catalogue cannot establish population coverage. Independent paper selection, two-coder extraction, holdout assessment, uncertainty and durable evidence are required | M | Ready: prepare sampling/extraction protocol and data template; independent reviewers and paper extraction remain necessary before any 99% claim |
| 4 | **Joint power for study plans that mix designs** | The whole-study simulation covers people measured once or twice, measured or two-group X (randomised or not), mediation and moderated mediation, factorial experiments, dyadic moderation of the actor effects and several outcomes of one trial. Left, in this order (decided 7 November 2026): covariates in every analysis's model; fully within-people designs (three or more conditions per person, three or more waves, the moderator's main effect); yes/no and other outcomes, and mixed outcome types; nested data (people in groups, repeated trials); pairs beyond the actor-partner model | L | Ready (decided 31 October 2026): one design at a time, marked Experimental, checked by a statistician later (below the queue), not before |
| 5 | **Bayes factors: informed priors** | Fifteen designs have Bayes factor versions with JASP's default priors. Left: informed priors, which wait on a bfpwr fault or the maintainer's decision on an exact calculation in the engine (`bayes-planning.md`) | M | Ready (decided 31 October and 4 November 2026). The binomial preprint the maintainer supplied (Kelter and Pawel, arXiv 2502.02914) asks not to be cited without the authors' permission, so it stays out of `refs.bib` until it is published |
| 6 | **Longitudinal: experience sampling** | Growth curves (E35) and random-intercept cross-lagged panels (E74) calculate. Left: experience sampling (roadmap B42); verify the current PowerAnalysisIL distribution and methods before choosing a backend | M | Ready (decided 4 November 2026): backend availability and method fit must be verified before implementation |
| 7 | **Designs that need a custom simulation: dyadic and mediation (E39, E42, E65)** | Non-score outcomes or mediators in mediation, a condition with three or more groups in mediation, and dyadic designs other than actor and partner effects. Each card points to Spower with a model the user writes | L | Ready (decided 4 November 2026): one PR per design |
| 8 | **Psychometric models still without a method** | Krippendorff's alpha, two-way ICCs and McDonald's omega (no package or published sample-size method found yet); further IRT presets in irtpwr if researchers ask | M | Ready (decided 4 November 2026): only once a package with a sample-size or power method is found |
| 9 | **The smallest detectable effect for every design that calculates** | Sensitivity at a fixed n is a goal on the t-tests, the correlation, proportions, the ANOVAs, regression, E9 and the clustered design. Every other design offers only power at an n and the n for a power, so a researcher whose sample size is fixed has to search effect sizes by hand | L | Ready (decided 18 October 2026, judgement call G9: sensitivity is a first-class route for every end point; mediation goes to the R script). Closed-form designs first, from each package's own solve-for-effect or by searching the effect with its power function; then the simulated designs by the preview and R script route. One PR per family, each with the sensitivity curve |
| 10 | **Input screen and result page follow-ups** | Regression's effect boxes stay hidden until "What you want to test" is chosen, which leaves that section looking empty; the result page is long. Both are what a first-time user meets on the commonest cards | S | Ready: a one-line prompt in the empty section until the choice is made; fold the result page's secondary sections (technical details, simulated data, citations) behind headings, keeping the answer, its conditions and the methods paragraph in view |
| 11 | **Hosting for real users (build guide phase 8)** | Phase 8's check is "stable under 20 concurrent runs" with a queue and limits; none of it is done. Long simulations end with the visitor's session, and the online app runs on a plan with 100 usage credits a month | M | Needs a decision: which host serves real users (`hosting-options.md`). Recommendation: measure two weeks of use on Connect Cloud's usage page first, then load-test the chosen host at 20 concurrent runs, with a per-visitor limit on simultaneous simulations; the durable job queue only once long simulations are a measured share of use |
| 12 | **Triage the open judgement calls** | `judgement-calls.md` (last updated 18 October 2026) lists 44 open entries, and several have since been overtaken by later work (for example C14, several outcomes, which the MANOVA card E59 now answers). Stale entries hide the few that still need the maintainer | S | Ready: move each entry later work or a later decision settled to the archive with a link to that decision; give each one that stays a current recommendation; put the remainder in `judgement-session.md` order |
| 13 | **Designs nobody has decided on yet** | Roadmap rows whose next step is "Decide": group-sequential designs with interim analyses (B57), broader assurance beyond existing design-prior routes (B60), diagnostic accuracy (B63), prediction model development (B64), single-case designs (B65), prevalence estimation (B66) and network models (B53). Several are common outside psychology's usual designs, and powerkit is for research studies generally (`decisions.md`, 5 November 2026) | M | Needs a decision: which to offer. Recommendation: diagnostic accuracy and prevalence extensions first, auditing the existing E46 proportion route before adding anything; prediction models with pmsampsize; group-sequential designs with rpact; assurance as an option beside power; single-case designs and network models later. Each package's methods to be checked against its help files before a card is built |
| 14 | **Extend the existing variant-by-variant evidence register** | `engine/inst/evidence/records.json` and `analysis_evidence()` already capture selected historical cases, and results/projects preserve the snapshot. New defaults and routes added since 5 November still need linked, release-specific evidence; card-level status is broader than selected-variant coverage | M | Ready: extend this register from validation results and `forms.yaml`, preserving source/versions, failures and unknown coverage; show it on About beside the capability table. Do not build a second register |
| 15 | **A crossover (AB/BA) card** | The paired and mixed ANOVA cards say how to plan a crossover, but no card asks for the period effect or the carry-over assumption, and the design finder can only send a crossover to the paired card (roadmap B33) | M | Ready: a card that takes the treatment effect, the period effect and the correlation between periods, with the test of the treatment effect adjusted for period, from a package that implements it (Superpower's 2b*2w design is the candidate to check); routed from "the same people in both conditions" when the order is counterbalanced |
| 16 | **Counts and ratings measured more than once** | A count, or ordered categories, measured twice or more on the same people (before and after, or in two conditions) is common: the design finder now sends it to a card (E75) that says powerkit doesn't calculate it and names simr and mixpower. The same card takes groups measured twice on a yes/no outcome | M | Needs a decision: which method to build. Recommendation: a Poisson or negative binomial mixed model with a random intercept for each person, simulated with simr, as E33 already does for yes/no trials, with ordered categories (a cumulative link mixed model, ordinal's `clmm()` in a Spower simulation) as a second PR; the conditional binomial test of paired counts is a closed-form alternative for two conditions only, if a package implements it |
| 17 | **Bayes mode: goals without a threshold** | Bayes mode (8 November 2026) opens every card on its Bayes factor version and plans with a design prior by default, and the Bayes factor write-ups are worded as design analyses (8 November 2026). Still missing: goals that are not a Bayes factor threshold (how narrow the posterior interval is likely to be, or the chance it falls inside a region of practical equivalence) | M | Needs a decision: which package plans them (none checked yet); the maintainer asked to leave it for now (8 November 2026) |
| 18 | **Submit the engine to CRAN** | Every package the engine uses is on CRAN, and the engine has been prepared (`status.md`, "CRAN"). A CRAN release lets researchers install powerkit with `install.packages("powerkit")` and cite a fixed version | S | Needs a decision: when to submit. Recommendation: with the 1.0.0 release that leaves prototype. Linux R release/devel quick CRAN checks with current hard dependencies passed for v0.60.0 (run 42735853076). Remaining before submission: a clean `R CMD check --as-cran` with tests on R release and devel (win-builder), the tests run once against the newest CRAN versions of every backend (bfpwr 0.3 in particular, which `renv.lock` pins at 0.1.6), a `cran-comments.md`, and afterwards distinguish the minimal CRAN engine install from optional backends and the full-app installation |

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
- Split a very large file, or move a single-card package to Suggests, only
  as part of a PR that already touches it (`CLAUDE.md`, "Conventions";
  `routing-prototype.md`, "Splitting the large files").
- Small extras from the 7 November review, for a PR that touches the
  area: a "longer than usual, still running" note once a simulation passes
  its usual time; one automatic retry, with more runs, for a sample-size
  search that fails by chance; a smaller About page (its HTML is about
  1.6 MB); and check that the sticky "answers still needed" bar doesn't
  cover the alpha help at 1100 px.
- Raise the Spower faults upstream: the reproducible example is ready at
  `docs/upstream/spower-var-test.R`
  ([`upstream-questions.md`](upstream-questions.md)).

## Waiting on the maintainer, not a PR

- **Whole-study simulation: the statistician's check** of the method note
  and its cross-checks (`whole-study-method.md`), before it is offered as
  more than experimental.
- **Validation catch-up:** the one-way ANOVA, multiple regression R², one
  proportion, McNemar, ANCOVA, Poisson regression, goodness of fit and two
  independent correlations each need a published example in their
  validation file and a full run.
- **Published values** (`TODO_PUBLISHED_VALUE`) for every validation file,
  and the full validation run on your own machine.
- **Six roadmap rows that need G\*Power itself** (A22, A38, A42, A46, A48,
  A49): the manual has no example for them.
- **The logistic R-squared question** (Known difference 3): whether
  powerkit's reading of "R² other X" matches G\*Power's.
- **Usability sessions with researchers**: build guide phase 5's check
  ("five PhD students complete a task unaided") needs people;
  `usability-session-pack.md` has the protocol and key. No ease-of-use
  result is claimed until then.
- **Raise the upstream questions** with each package's authors (an issue
  on its repository): besides Spower (below), longpower, irtpwr,
  metapower, power4mome, powertools and bfpwr each have an open question
  in [`upstream-questions.md`](upstream-questions.md), with the evidence
  ready.
- **The AI assistant** (build guide phase 7: words or a diagram to a
  suggested design, always confirmed by the user): whether and when to
  start it. It comes last by design (`CLAUDE.md`).
- **Scientific sign-off on the two recurring validation failures** (investigation is Ready above) (`validation-log.md`, 7
  and 8 November 2026): the mixed design's Greenhouse-Geisser check
  (an independent 20,000-study reference agrees with the fitted analysis;
  fixing epsilon alone does not explain the exact-data discrepancy, see
  the 10 November investigation in validation-log.md), and moderated mediation's Type I error with a yes/no
  X (power4mome's question 6 in `upstream-questions.md`). Original expected values remain unchanged; investigation and independent checks proceed before external sign-off.
- **Which queue item comes next**, if the order above is wrong.
