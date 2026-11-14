# What to work on next

*14 November 2026: Bland-Altman limits of agreement landed on E69, finishing item 1. 13 November 2026: the analyses JASP offers that powerkit doesn't plan yet lead the queue, in the maintainer's order (`coverage-roadmap.md`, "JASP's analyses"); broad first-release support, case-level evidence and a measured coverage benchmark follow. Implementation does not imply validation; the current state is in [status.md](status.md).*

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
comparisons (merged in PR #368; saved values retained). Next, continue the departure
audit for analysis mismatches: mediation ML/Monte Carlo versus PROCESS
OLS/bootstrap, continuity-corrected proportions tests, fixed/random
predictors and family-level claims. This is part of the selected-variant
audit below; none is resolved merely by changing labels. PR #368 adds a selectable OLS/casewise-percentile-bootstrap route, paired regression
checks and a completed selected null-calibration job (two passes, one direct
reference TODO skip; archived). Direct PROCESS-software comparison, broader
model/null settings and the 5,000-resample default remain before equivalence
or broad calibration claims.
The same PR now adds explicit continuity-corrected count-test choices, with
independent finite-enumeration/simulation checks. Four selected returned-N checks are now independently archived, including
small target shortfalls. Published references and a discretisation-aware or
independently verified final-N search remain required. Next audit fixed
versus random predictors and whether the selected claim is one effect,
any effect, or all required effects; do not replace these with a single
blanket power claim. The first wording pass now scopes interaction benchmarks,
explains the two regression input routes before calculation, and distinguishes
individual-test power from a family success probability. Formula-based
interaction sensitivity has three archived matched-route checks and
offers a matched fixed-N verification step; broader parameter checks remain.
New all-required-test plans use unknown dependence and the existing sufficient
bound, with explicit historical saved choices preserved. Selected-setting
evidence is visible on complete input screens. Compact-mode
test/family labels are now audited for all 77 entries and 14 groups, with
short common test selectors and no duplicate plain-language subtitles.
The compact-guidance follow-up now folds routine input/default/group help
behind info controls with explanations off, shortens common labels and keeps
errors, captured methods and scientific warnings visible. Power offers equal
80/90/95% examples without a default and explains the trade-off.
Continue the remaining wording checklist and the unresolved scientific
items above; concise labels do not complete their evidence requirements.

The 0.61.1 pre-sharing safeguards merged in PR #369 and the deployment
handoff correction in PR #370. Common analysis identities and exercised
desktop/mobile/keyboard journeys pass their checks. Publication run
42927530578 succeeded; leave the normal host rollout to finish and confirm
the live version later. R14's scientific failures and R17's discrete-count
search accuracy remain priorities. The completed interface safeguards do
not close those mathematical requirements. The follow-on corrected-count fix
requires a fresh, selection-adjusted lower-power check at the returned N.
Four independent checks passed; required hosted gates must pass before merge. This addresses
the known smooth-search shortfall risk, not the ANOVA/mediation failures or
a minimum-N guarantee.

## The queue

| # | What | Why it matters | Size | State |
| --- | --- | --- | --- | --- |
| 1 | **Every card that says powerkit can't calculate it yet** | Researchers who find these in "I know my analysis" are told powerkit can't help: relationships within people or in nested data (E41: within-person moderation and mediation; the correlation is E76); two groups measured more than once on a count, yes/no or ordered categories (E75; counts, yes/no and ordered categories for the same people are done, 14 November 2026); mediation with a mediator that isn't a score (E39) or a condition with three or more groups (E42); other dyadic designs (E65); Cochran's Q (named on E26); count and categorical outcomes in moderation and mediation (named on E32). Two-way ICCs, omega and Krippendorff's alpha (named on E69) still need a published method first | L | Ready (maintainer's priority, 13 November 2026): one PR per design. E75 next: the group-by-time interaction on the same `repeated_glmm` template; the conditional binomial test of paired counts is a closed-form alternative for two conditions only, if a package implements it |
| 2 | **A Bayes factor version of every design that can have one** | Fifteen designs have one. Candidates next, each with JASP's default priors: regression coefficients and R² (BayesFactor's `regressionBF()`/`lmBF()`), ANCOVA, the remaining ANOVAs, the multinomial test (E48), JASP's A/B test prior on E5 (abtest) and the informed multinomial and multi-binomial tests (multibridge). Designs where JASP reports posteriors rather than Bayes factors (mixed models) wait on item 18 (goals without a threshold) | L | Ready (maintainer's priority, 13 November 2026): audit which cards can have one, then one PR per design |
| 3 | **The rest of the JASP review** | In this order: prediction model performance (pmsampsize, pmvalsampsize; roadmap B64), network analysis (powerly; B53; needs libjpeg in the image), PCA as an option on E73, log-linear models, Bayesian informative hypotheses (bain), publication-bias methods within E61 (PET-PEESE, WAAP-WLS, selection models), cluster analyses beside E58, PLS-SEM (Kock and Hadaya's inverse square root method) and circular statistics. Time series (stationarity, ARIMA, spectral), machine learning, Bayesian mixed models and reliability, and JAGS have no planning method: the methods map should say why | L | Ready: one PR per design; the methods-map notes as one PR |
| 4 | **Audit first-release support at the selected-variant level** | The goal is over 99% of primary quantitative psychology analyses in a representative benchmark, including complex designs; no percentage is established yet. The generated source inventory and 18 complex-design briefs are in [v1-support-plan.md](v1-support-plan.md) | M | Ready: complete P0 case specifications and code/evidence audits first; extend the existing registry only from recorded results, then prioritise missing variants |
| 5 | **Investigate the scientific validation failures and discrete-count search accuracy** | The latest completed nightly inspected (42968983200, 11 November, fbbd237) again failed only mixed-ANOVA GG and model-7 binary-X null partitions | M | Ready: the GG independent reference and fixed-epsilon experiment are recorded (10 November); finish its approximation audit and current-version reproduction. Next run the paired binary-X calibration comparison and prepare author-review dossiers; preserve expected values and tolerances. Four corrected-count fitted-N checks also show small target shortfalls and a finite reference outside the fitted power interval; fresh final-N confirmation and four independent checks are implemented in PR #372; extend parameter coverage and assess minimum-N efficiency before stronger claims |
| 6 | **Build the representative coverage benchmark and archive protocol** | Cards and a synthetic design catalogue cannot establish population coverage. Independent paper selection, two-coder extraction, holdout assessment, uncertainty and durable evidence are required | M | Ready: prepare sampling/extraction protocol and data template; independent reviewers and paper extraction remain necessary before any 99% claim |
| 7 | **Joint power for study plans that mix designs** | The whole-study simulation covers people measured once or twice, measured or two-group X (randomised or not), mediation and moderated mediation, factorial experiments, dyadic moderation of the actor effects and several outcomes of one trial. Left, in this order (decided 7 November 2026): covariates in every analysis's model; fully within-people designs (three or more conditions per person, three or more waves, the moderator's main effect); yes/no and other outcomes, and mixed outcome types; nested data (people in groups, repeated trials); pairs beyond the actor-partner model | L | Ready (decided 31 October 2026): one design at a time, marked Experimental, checked by a statistician later (below the queue), not before |
| 8 | **Bayes factors: informed priors** | Fifteen designs have Bayes factor versions with JASP's default priors. Left: informed priors, which wait on a bfpwr fault or the maintainer's decision on an exact calculation in the engine (`bayes-planning.md`) | M | Ready (decided 31 October and 4 November 2026). The binomial preprint the maintainer supplied (Kelter and Pawel, arXiv 2502.02914) asks not to be cited without the authors' permission, so it stays out of `refs.bib` until it is published |
| 9 | **Longitudinal: experience sampling** | Growth curves (E35) and random-intercept cross-lagged panels (E74) calculate. Left: experience sampling (roadmap B42); verify the current PowerAnalysisIL distribution and methods before choosing a backend | M | Ready (decided 4 November 2026): backend availability and method fit must be verified before implementation |
| 10 | **Psychometric models still without a method** | Krippendorff's alpha, two-way ICCs and McDonald's omega (no package or published sample-size method found yet); further IRT presets in irtpwr if researchers ask | M | Ready (decided 4 November 2026): only once a package with a sample-size or power method is found |
| 11 | **The smallest detectable effect for every design that calculates** | Sensitivity at a fixed n is a goal on the t-tests, the correlation, proportions, the ANOVAs, regression, E9 and the clustered design. Every other design offers only power at an n and the n for a power, so a researcher whose sample size is fixed has to search effect sizes by hand | L | Ready (decided 18 October 2026, judgement call G9: sensitivity is a first-class route for every end point; mediation goes to the R script). Closed-form designs first, from each package's own solve-for-effect or by searching the effect with its power function; then the simulated designs by the preview and R script route. One PR per family, each with the sensitivity curve |
| 12 | **Input screen, result page and complete wording review** | Audit every user-facing screen and export for statistical accuracy, clear assumptions, familiar terms and concise wording; keep necessary detail behind help. Initial targeted corrections cover Welch/Student, regression methods and individual versus joint power, not a full wording sign-off. Regression's existing prerequisite prompt is under browser verification; result warning placement and the remaining long-page sections still need review | M | Ready: work through the wording checklist in release-readiness-review.md across finder/cards, forms/errors, results/methods, Labs, About/glossary, installation/static site and downloads; verify each scientific claim against code and scoped evidence. Verify prerequisite prompts and fold secondary result details |
| 13 | **Hosting for real users (build guide phase 8)** | Phase 8's check is "stable under 20 concurrent runs" with a queue and limits; none of it is done. Long simulations end with the visitor's session, and the online app runs on a plan with 100 usage credits a month | M | Needs a decision: which host serves real users (`hosting-options.md`). Recommendation: measure two weeks of use on Connect Cloud's usage page first, then load-test the chosen host at 20 concurrent runs, with a per-visitor limit on simultaneous simulations; the durable job queue only once long simulations are a measured share of use |
| 14 | **Triage the open judgement calls** | `judgement-calls.md` (last updated 18 October 2026) lists 44 open entries, and several have since been overtaken by later work (for example C14, several outcomes, which the MANOVA card E59 now answers). Stale entries hide the few that still need the maintainer | S | Ready: move each entry later work or a later decision settled to the archive with a link to that decision; give each one that stays a current recommendation; put the remainder in `judgement-session.md` order |
| 15 | **Designs nobody has decided on yet** | Roadmap rows whose next step is "Decide": group-sequential designs with interim analyses (B57), broader assurance beyond existing design-prior routes (B60), diagnostic accuracy (B63), prediction model development (B64), single-case designs (B65), prevalence estimation (B66) and network models (B53). Several are common outside psychology's usual designs, and powerkit is for research studies generally (`decisions.md`, 5 November 2026) | M | Needs a decision: which to offer. Recommendation: diagnostic accuracy and prevalence extensions first, auditing the existing E46 proportion route before adding anything; prediction models with pmsampsize; group-sequential designs with rpact; assurance as an option beside power; single-case designs and network models later. Each package's methods to be checked against its help files before a card is built |
| 16 | **Extend the existing variant-by-variant evidence register** | `engine/inst/evidence/records.json` and `analysis_evidence()` already capture selected historical cases, and results/projects preserve the snapshot. New defaults and routes added since 5 November still need linked, release-specific evidence; card-level status is broader than selected-variant coverage | M | Ready: extend this register from validation results and `forms.yaml`, preserving source/versions, failures and unknown coverage; show it on About beside the capability table. Do not build a second register |
| 17 | **A crossover (AB/BA) card** | The paired and mixed cards now state their restricted scope instead of claiming a general crossover approximation (R22). No dedicated card yet asks for period, sequence or carry-over assumptions; the finder still needs a matching crossover route (roadmap B33) | M | Ready: a card that takes the treatment effect, the period effect and the correlation between periods, with the test of the treatment effect adjusted for period, from a package that implements it (Superpower's 2b*2w design is the candidate to check); routed from "the same people in both conditions" when the order is counterbalanced |
| 18 | **Bayes mode: goals without a threshold** | Bayes mode (8 November 2026) opens every card on its Bayes factor version and plans with a design prior by default, and the Bayes factor write-ups are worded as design analyses (8 November 2026). Still missing: goals that are not a Bayes factor threshold (how narrow the posterior interval is likely to be, or the chance it falls inside a region of practical equivalence) | M | Needs a decision: which package plans them (none checked yet); the maintainer asked to leave it for now (8 November 2026) |
| 19 | **Submit the engine to CRAN** | Every package the engine uses is on CRAN, and the engine has been prepared (`status.md`, "CRAN"). A CRAN release lets researchers install powerkit with `install.packages("powerkit")` and cite a fixed version | S | Needs a decision: when to submit. Recommendation: with the 1.0.0 release that leaves prototype. Linux R release/devel quick CRAN checks with current hard dependencies passed for v0.60.0 (run 42735853076). Remaining before submission: a clean `R CMD check --as-cran` with tests on R release and devel (win-builder), the tests run once against the newest CRAN versions of every backend (bfpwr 0.3 in particular, which `renv.lock` pins at 0.1.6), a `cran-comments.md`, and afterwards distinguish the minimal CRAN engine install from optional backends and the full-app installation |
| 20 | **Search rounded group sizes at every total for unequal allocation** | A decimal ratio is now planned as the simplest whole split that rounds to it, which can still return up to about four people more than the smallest total whose rounded groups reach the target. Evaluate power at each total with the groups rounded as a researcher would recruit them, state the achieved ratio, and compare with G\*Power's answers for the same ratios | S | Ready |
| 21 | **Minimum-effect validation: simulate the test now planned** | Since 12 November 2026 minimum-effect tests are planned as `t.test(mu = margin)`, a central t shifted by the margin. `test-validation-minimum-effect.R` still simulates the earlier test (the t statistic against a noncentral t at the margin) and passes only because the difference (under a point of power) is inside its tolerance | S | Needs a decision: the maintainer owns that file's expected values and simulation; a simulation of the shifted test is in `test-backend-minimum-effect.R` meanwhile |
| 22 | **Replication plan: goals for any one-number effect** | The goals table (BayesRepDesign) for any design whose focal effect is one number: an "another design's effect" route taking the estimate with its standard error, interval or test statistic and the original's sample size; the replication's standard error scaled by the square root of the sample-size ratio, with a test that the four exact designs give the same table; a `replication_effect` field per card in forms.yaml; and a one-sentence message for multi-df tests suggesting the focal contrast | M | Ready (after 22) |
| 23 | **Replication plan: an original analysed with Bayes factors** | "How was it analysed?" routes for a Bayes factor (BF and n converted to t with BayesFactor's `ttest.tstat()`, with a round-trip test) and a posterior (used only for a vague or default prior). Goals: hide small telescopes and the original's significance level; add "repeat the original's Bayes factor test" with bfpwr's default-prior `powertbf01` under the three beliefs; keep the replication and sceptical Bayes factors; add evidence for no effect (`ssdBF01`, after checking its help); point the sequential Bayes factor tool at the replication if `bayes_sequential()` accepts a design prior. The references Verhagen and Wagenmakers (2014) and Ly et al. (2019) are to be added to refs.bib from the papers first | M | Ready (after 23) |
| 24 | **Precision planning: assurance for a raw mean difference** | Assurance (a stated chance that the interval is narrow enough, Departure 25) is the default for Cohen's d, a standardised mean and a regression coefficient, but a mean difference in the measure's own units, a correlation, a proportion, an odds ratio and an ICC are planned for the width at the assumed values, which about half of studies miss; the result says the width is met on average. Add assurance for the raw mean difference first (the usual choice), from a package's method where one exists, checked by simulation | M | Ready |
| 25 | **Clustered yes/no outcomes: drop powertools' factor 1.2, or simulate by default** | powertools multiplies the variance by 1.2 with no published source; a `glmer()` simulation reaches 80% with 24 groups where powerkit asks for 28 (Known difference 16). Groups are the costliest unit in these trials | S | Needs a decision: which method is the default. Recommendation: the `glmer()` simulation through simr (which E33 already uses) as the default for the cluster-randomised and multisite yes/no routes, keeping powertools' formula as the quick option, and ask powertools' authors for the factor's source (`upstream-questions.md`) |
| 26 | **Three-way interactions: simulate studies, as two-way ones are** | The fixed-model formula gives about 4 points more power than simulated studies at its own N (853 against about 940 needed in the example; Known difference 17). InteractionPoweR has no three-way simulation | M | Needs a decision: which method is the default. Recommendation: a Spower experiment with random predictors and `lm()`, built from the same true-score correlations, as the default, the formula kept as the quick option and for the search's bracket |
| 27 | **How much does the answer depend on my assumptions?** | A required N rests on several uncertain numbers besides the effect: an ICC, a correlation between measurements, an SD, attrition. Researchers need to see which one the answer depends on most, not only power at a smaller or larger effect (the comparison that exists, decisions.md 10 November 2026). Release-readiness R25 asks for plausible ranges and "a small coherent scenario table". Build: (a) one at a time, a low and a high plausible value for each uncertain input, the required N (or power at the planned N) at each, drawn as a tornado chart in order of influence; (b) a two-way grid of the effect against one chosen input (for example effect × ICC), as a heatmap. Instant for formula designs; simulated designs get a coarse grid or the R-script route. Named so it isn't confused with the "smallest detectable effect" goal, which G*Power calls sensitivity. Not global (Sobol or Morris) sensitivity analysis: it needs a distribution for every input, which researchers rarely have; the planning literature's equivalent is assurance over the uncertain inputs (O'Hagan, Stevens and Campbell, 2005), which item 9 and Bayes mode extend | M | Ready (maintainer, 13 November 2026): take after item 1 |
| 28 | **A permutation test on Welch's t, as a test version on E2** | De Winter (2026, *Quality & Quantity*, doi:10.1007/s11135-026-02909-5) shows that with skewed scores and unequal groups both Student's and Welch's t-tests can lose control of the false-positive rate, and that a permutation test on Welch's statistic keeps it. Welch stays the default (Departure 21) | S | Ready (maintainer, 14 November 2026): simulated with Spower, the permutation from a package (check `MKinfer::perm.t.test()` or `coin`; none chosen yet), validated against a by-hand permutation; a note on the Welch result when the groups are unequal and the score shape is skewed; the paper added to `refs.bib` from the PDF the maintainer holds |

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
- **Scientific sign-off on the two recurring validation failures** (investigation is Ready above) (`validation-log.md`, 7
  and 8 November 2026): the mixed design's Greenhouse-Geisser check
  (an independent 20,000-study reference agrees with the fitted analysis;
  fixing epsilon alone does not explain the exact-data discrepancy, see
  the 10 November investigation in validation-log.md), and moderated mediation's Type I error with a yes/no
  X (power4mome's question 6 in `upstream-questions.md`). Original expected values remain unchanged; investigation and independent checks proceed before external sign-off.
- **Which queue item comes next**, if the order above is wrong.
