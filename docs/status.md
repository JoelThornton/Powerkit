# Project status

*Last updated: 18 November 2026.*

*Where the project is
now, one short paragraph per area; replace a paragraph rather than adding
to it. What to do next is [`next.md`](next.md). History is in git,
[`engine/NEWS.md`](../engine/NEWS.md) and
[`archive/status-history.md`](archive/status-history.md), which holds this
page as it stood before each rewrite.*

powerkit is in development and **not ready for use**: results are not yet
fully validated ([`validation-log.md`](validation-log.md)). The working
rules are in `CLAUDE.md`. There is no AI assistant: it was dropped from
the plan (`decisions.md`, 13 November 2026).

## Now

Colleague testing began on 16 November 2026. What testers report, and
what the 15 November reviews left for later (the whole-study step bar,
the reliability-left-empty wording on the moderation cards and the
smaller items), is `next.md` item 25 and comes first while testing runs;
with it, item 27 audits every card that runs for a check independent of
the package it wraps, and the method choices each card makes for the
researcher (so far E18, E23, E26, E33 and the other mixed models, E53
and E54 offer the alternatives researchers commonly run; McNemar's card
offers the chi-square test with or without the continuity correction,
and the two-variance card Levene's and the Brown-Forsythe test, the Brown-Forsythe test preselected; both cards' tests are found by name in the search). The input screen's headings and labels are the
same with explanations on or off, and a line names the boxes the effect
size goes in (17 November 2026).

Added since 13 November 2026, each with validation in progress (its
simulation chunk passes; published examples await transcription): the
repeated-measures correlation (E76), prediction models (E77), Cochran's
Q (E78), repeated counts, yes/no answers and ordered categories (E75),
mediation with X in three or more groups (E42) or a yes/no or
ordered-category mediator (E39), count, multinomial and yes/no outcomes on E32, within-person
moderation (E41), Yuen's trimmed-means t-tests (E2, E3), the
Bland-Altman limits of agreement (E69), and Bayes factor versions of
regression (E24), ANCOVA (E23) and the three-factor ANOVA (E56). The
multinomial test (E48) and JASP's A/B test (E5) are decided and queued
(`next.md` item 2). Still uncovered: mediation of a categorical outcome
and within-person mediation.

Moderated mediation with a yes/no X tests slightly liberally (5.38% at alpha .05 in 20,000 studies, `validation-log.md`); its card note says so.

The release-readiness and first-release reviews keep their own open
items: [`release-readiness-review.md`](release-readiness-review.md) and
[`v1-support-plan.md`](v1-support-plan.md).

Since 18 November 2026 pull requests don't number themselves: the
after-merge workflow gives each merge its version, joins the decision
entries waiting in `decisions.d/`, dates this page and regenerates the
release inventory (`adding-a-test.md`, "Change notes and version
numbers").

The page as it stood before this rewrite, with the dated history of
each area, is at the end of
[`archive/status-history.md`](archive/status-history.md).

## Where things are

- **Review fixes (7 November 2026):** the earlier project review grouped 21 serious problems
  and about 110 smaller ones into fourteen fix batches, all done by
  8 November: validation runs that finish and report, what the app says,
  design-finder routes, the draft box and page structure, effect-size
  guidance, speed, whole-study planning, input screens, Labs, docs and
  start-up reading, change notes that no longer need catch-up merges
  (each pull request writes its own note files and sets the version with
  `scripts/close-batch.R` before it merges, so every change on main has
  a number: `decisions.md`, 13 November 2026), Welch's tests by default
  (Welch's t-test on the two-group card, by formula, Departure 21;
  Welch's F on the one-way ANOVA card, by Levy's approximation as Jan
  and Shieh, 2014, recommend, simulated on request, Departure 22), small
  telescopes for replications (0.47.2: d33 at the original study's own
  significance level, the power if the true effect is small but not
  zero, and wording that says what a result below d33 does and doesn't
  show), and the review's own checks kept for
  each release: property checks over every example spec and a run of
  every card in a browser (`repository-protection.md`, "Checks before a
  release"). A check of every review finding against what merged
  (8 November) found a few left: the small ones are fixed, and the
  larger ones are in `next.md`; two proportions now take a published
  odds ratio or risk ratio, mediation with two groups takes X's
  effects as Cohen's d, the card for people in groups offers joint
  power for several effects, precision planning by MBESS asks for a
  chance (assurance) that the interval is narrow enough, and mediation
  results say that the planned Monte Carlo interval differs from
  PROCESS's percentile bootstrap, and the significance level and the
  Bayes factor threshold start empty, as target power does, with the
  usual value one click away and an optional reason (9 November).
  Decisions from October are archived (`archive/decisions-2026-10.md`,
  indexed at the top of `decisions.md`), and closing a batch moves Updates
  entries over a month old to `whats-new-archive.yaml`, which the Updates
  tab still shows. Each document's downloads are one PDF button with a menu
  for Word and Markdown, and the pre-replication notes in Labs are worded
  as a tool rather than as a summary of their source paper. Effects that vary between
  studies are on the t-test and correlation cards, with a table of the
  answer at no, small, medium and large variation, and an opt-in Bayes
  mode is on the start screen, with Bayes factor write-ups worded as
  design analyses and a write-up for plans that report a p-value and a
  Bayes factor together (8 November). Next: the queue in `next.md`; the rest of
  Bayes mode (item 17) waits on a decision.

- **What calculates:** 77 of the 78 analyses run in the app (80 cards,
  counting the "none of these fit" and Bayes factor guide cards;
  `tree.yaml`'s statuses); the other dyadic designs card is a guide to the
  pair cards. 59 calculate in the app directly (`forms.yaml`'s
  `calculates`), by a package's formula where one exists, otherwise by
  simulation with Spower, Superpower, simr, power4mome, metafor or PITS.
  The rest are simulations too slow for the app: a preview in the app,
  then a full run or an R script the researcher runs themselves
  (mediation and moderated mediation, participants and items, multilevel
  models, Bayes factors of repeated-measures effects). Every design but the
  generic tests is reached from the design finder, and "I know my
  analysis" lists all of them by family with a search. No answer leads to
  "No matching design" unless the user chooses it, apart from a short list
  of known gaps that two tests in `test-misroutes.R` hold fixed: a new
  gap fails them (8 November 2026, after counts and ratings measured twice
  had reached it).

- **Test versions researchers commonly need:** rank tests for skewed or
  heavy-tailed scores; robust standard errors and quantile regression;
  negative binomial and zero-inflated counts; minimum-effect and
  equivalence tests; a justified alpha; pairwise comparisons with Holm's
  adjustment, including rank comparisons of pairs after the Kruskal-Wallis
  and Friedman tests (separate tests of each pair, or Dunn's or Conover's
  test, as the researcher chooses); effects that vary between studies on the three t-test
  cards (Kenny & Judd, 2019, through pwr; an SD of 0.05 in d to start
  with, Departure 23) and the correlation card (McShane & Böckenholt,
  2014, through pwr; 0.025 on Fisher's z, Departure 24), each result
  showing the answer at no, small, medium and large variation;
  precision planning (a confidence interval's width, by MBESS
  and presize) as a goal beside power. Bayes factor versions exist for
  fifteen designs, with JASP's default priors; p-value results of the
  exact ones offer "Add a Bayes factor?", and Bayes factor t-test results
  show three prior widths, a sequential plan and an uncertain effect.
  An opt-in switch, "I'll analyse with Bayes factors", at the top of
  "I know my analysis" (where it narrows the list to the 15 designs with
  a Bayes factor version) and of "Help me choose" (12 November; it was a
  "Bayes mode" on the start screen), opens every card on its Bayes factor
  version and asks how unsure the user is about the effect instead of
  assuming 0.
  Informed priors wait on a bfpwr fault (`upstream-questions.md`).

- **Effect sizes:** the commonest cards take what researchers have: a
  published t, F, r, d or odds ratio, partial eta-squared, Cohen's w, the
  R-squared change; safeguard power for an effect from one study or a
  pilot, or small telescopes for a replication (Simonsohn, 2015); the
  smallest detectable effect on the t-tests, the correlation,
  proportions, the ANOVAs (Welch's F by formula; by partial eta-squared
  too), multiple, logistic and Poisson regression, moderated regression,
  one proportion, McNemar's test, two independent correlations, goodness
  of fit, planned contrasts, ANCOVA and the clustered design (16 November
  2026: pwrss's power searched over the effect, checked against G*Power's
  F test, pwr, WebPower, stats and a simulation), and since 17 November
  2026 the dependent correlations, one and two variances, Hotelling's
  T-squared, MANOVA by Pillai's V or with two groups, and equivalence
  tests, where the answer is the narrowest bounds the sample could show,
  the meta-analysis's average effect (metapower's z test, and the
  Hartung-Knapp test by simulation) and structural equation models (the
  RMSEA for exact, close and not-close fit, a factor correlation, a latent
  slope), two groups on an ordinal outcome, the log-rank test and a Cox
  predictor, growth curves, and the ICC, Cronbach's alpha and kappa (each
  backend's power searched, checked against simulations of the tests and
  the packages' own solvers), and, by a simulated search with a 95%
  interval, two paired variances, a trend in proportions, d' in two
  conditions the Jonckheere-Terpstra trend test and
  the factorial logistic regression's main effects and interaction and
  moderation by three or more groups, the interrupted time series,
  moderation of a yes/no or count outcome, an outcome in unordered
  categories, moderated regression with a yes/no X or W, latent
  profiles (the separation) and factor recovery (the loading), and by
  InteractionPoweR's formula the three-way interaction; and the mediation
  cards' smallest indirect effect or index of moderated mediation, by the
  same search through the R script they hand out (the rest is `next.md`
  item 11). Results show the critical effect size for the
  t-tests (Student's) and the correlation. The "If the effect were
  different" and "What if the true effect is smaller?" panels work on the
  basic tests and, since 16 November 2026, on the formula cards whose
  effect is one number: multiple regression (R-squared, partial R-squared
  or the R-squared increase), logistic and Poisson regression (the odds
  or rate ratio, weaker meaning closer to 1), the ANOVAs from partial
  eta-squared, the interaction's R-squared change, one proportion, two
  proportions and two correlations. Not yet: an ANOVA or ANCOVA given by
  its means (a pattern, not one number) and the simulated designs.

- **Results and documents:** a result opens with the answer and what it
  assumes, then "How sure can you be?", the write-up with a methods
  paragraph, and downloads: a project file, an R script that reproduces
  it with the backend alone, citations and, for most designs, a simulated
  data set. A "Keep this result" box under the answer holds Save project
  file, Copy a link and Add to my study plan, with a "Not saved yet"
  status, a warning before leaving and browser recovery of the last
  result; the documents sit apart, with a "Download everything" zip that
  the Open button also reads. "Copy a link" beside each save button puts the same file
  inside a link's fragment, so a project, study plan or draft opens on
  any computer with nothing stored and no account
  ([`saving-projects.md`](saving-projects.md); not yet tried inside
  Connect Cloud's frame). Every result records its spec hash, seed,
  backend, and R and package versions. The pre-replication notes and the study-planning
  document save as PDF, Word and Markdown. Results link to the Labs tool
  that explains them.

- **Study plans:** several named plans, each with a description, kept
  in the browser and saved as a file or a link that opens on any
  computer. "Study plans" in the top bar opens a page of its own
  (`?page=plans`) listing them; each plan's page gives the largest
  comparable N, joint power where it can be calculated, and each analysis
  with a role (primary, secondary, check), a note, and Open, which brings
  back its card, answers and saved result. Each plan says whether it has
  been saved to a file, since the browser's copy can be cleared. Each plan
  has an overview (its analyses by role) and "Download everything": one
  zip with the plan file, a study-wide planning document (Markdown and
  Word, with a Registered Report study design table: question,
  hypothesis, sampling plan, analysis plan, what sets the sensitivity,
  interpretation of each outcome, theory at stake; also on its own from
  the plan's Planning report button), the merged references and each analysis's own files; the zip
  opens again as the plan. "Plan my whole study" makes or fills a study
  plan that keeps the guided plan, its analyses (with the roles the
  guided plan gives them) and the last whole-study result, and reopens
  the guided screens from the plan's page. A plan's significance level
  and target power are set once on its page and start each analysis
  added from it, and "Help me choose an analysis" and "I know my
  analysis" both add to it
  ([`saving-projects.md`](saving-projects.md), "Study plans").

- **Experimental: whole-study planning.** The guided plan simulates
  several analyses of one study together, so the chance all succeed is
  counted rather than assumed: measured predictors or two groups
  (randomised or not), people measured once or twice, mediation and
  moderated mediation (power4mome), factorial experiments (Superpower),
  and a pair-level moderator in dyadic studies. Joint power for several
  outcomes of one randomised trial uses PUMP. Its result gives a
  planning document (PDF, Word or Markdown) with every analysis and its
  role, the claim, the population assumed, the joint and separate powers
  and the R script that reproduces them, marked experimental on its first
  page. It waits for a statistician's check ([`whole-study-method.md`](whole-study-method.md));
  the designs still to add are in `next.md` item 7.

- **Replication plans** (14 November 2026). A replication plan is a kind
  of study plan, started from "New replication plan" on the Study plans
  page, from Labs or from the input screen's signpost for an effect from
  an earlier study. Its page holds the sections that were Labs' tools:
  the pre-replication notes (whether to replicate), the original study,
  the goals table for an original t-test or correlation finding
  (Anderson & Maxwell, 2016; BayesRepDesign, Pawel, Consonni & Held,
  2026; the small-telescopes card's calculation) under three beliefs
  about the true effect, how the replication differs, and one write-up.
  The original's analysis is chosen from the searchable list of analyses
  (the design finder's questions as a second way); its card, with each
  effect field labelled as the original's, plans the replication and
  keeps the result in the plan. The plan saves, shares
  and downloads like any study plan. Since 15 November 2026 the goals
  table covers any card whose focal effect is one number: the original's
  estimate with its standard error, interval or test statistic, ratios on
  the log scale and correlations on Fisher's z (each card's effect is in
  `forms.yaml`, `replication_effects`); the four keep their exact routes.
  An original analysed with Bayes factors (15 November 2026) is read
  from its Bayes factor (a t-test, inverted with BayesFactor's
  `ttest.tstat()`; Ly et al., 2018) or from a posterior with a vague or
  default prior; small telescopes is left out, and the goals add the
  original's Bayes factor test repeated and evidence for no effect
  (bfpwr), with a way on to a sequential Bayes factor design in Labs.
  After the colleague-testing review (15 November 2026) the notes show
  one box per part, the references are listed once at the foot, the
  Bayes factor goals use the cards' "Evidence threshold" wording,
  variation between studies starts at Small (0.05; docs/conventions.md),
  and the replication's alpha and power start empty with buttons. Each
  study plan can be deleted from its row on the Study plans list. A
  review on 17 November 2026 fixed what gave wrong or misleading output:
  a goal met by any replication (the pooled goal after a strong
  original) said "not reachable"; variation between studies was applied
  in d to a correlation's Fisher's z and to another design's own scale;
  the plan accepted a card for a different design from the one entered,
  and kept the "None of these fit" card as the original's design; an
  extension added to the plan was written up as the original's analysis;
  and the write-up cited every method. A paired original can now be
  entered as its t or as d_rm or d_av with the correlation (Lakens,
  2013), and another design's uncertainty as an F with one numerator df.
  Validation (17 November 2026, `validation-log.md`): every goal's
  chance agrees with a separate simulation of the method's model, and the
  classical goal and small telescopes with t-tests on simulated people;
  the published examples are placeholders, so the plan says "Validation
  in progress". A replication or sceptical Bayes factor counts as a
  success only in the original's direction (Departure 31; BayesRepDesign
  counts either side by default). Since 17 November 2026 the
  Goals section asks the purpose first (confirm the effect, settle it
  either way, or test its absence) and gives one sample size, from one
  main criterion under one belief, with each criterion under "Also
  report" as its chance at that size; a criterion that can show absence
  starts ticked (Departure 30), the default Bayes factor t-test is
  offered for p-value originals, d33 is the equivalence bound when none
  is entered, and the table of every criterion folds under the answer.
  Since 19 November 2026 the criteria fit every kind of original: the
  list is grouped into frequentist and Bayesian criteria with those the
  original can't give greyed out, only the settings the chosen criteria
  use are asked for, the absence criterion is always one planned for no
  effect (the Bayes factor t-test for no effect, else the equivalence
  test), a bound the plan can't default is asked for before the run,
  "settle it either way" warns when a null result at the planned
  size would have too little chance of showing absence, an expected
  dropout gives the number to recruit (the cards' rule), and a
  two-group replication can have unequal groups (the cards' allocation
  ratio).
  The write-up adds the study design table Registered Reports ask for,
  the R script runs only the chosen criteria under the chosen belief,
  and the significance test can be one-sided. The page's five sections
  are numbered steps with a "Next" button under each, and the original's
  card starts on the sample-size question with the plan's significance
  level, chance of success and, for the four exact designs, the
  original's effect. The plan asks what the replication keeps: an
  extension's analyses join it as extensions, never as the original's; a
  conceptual replication is planned from the shrunk belief with more
  variation between studies; and a new study is offered an ordinary
  study plan. An original reported as an F or a partial eta-squared from
  a between, within or mixed ANOVA goes through every goal when its
  effect has one degree of freedom (a factor with two levels or a 2 x 2
  interaction: F = t², planned as the two-mean comparison it is), with
  BUCSS's corrected sample size beside them; an effect with several
  degrees of freedom is planned with BUCSS at a chosen assurance and,
  beside it, from the researcher's smallest partial eta-squared by the
  ANOVA card's own F test. t-test and correlation originals also show
  BUCSS's corrected sample sizes beside their goals (validation in
  progress: a published example is still to be transcribed). The design
  list says where ANCOVA and MANOVA originals go. An original can be entered as analysed with both a
  significance test and a Bayes factor (the effect from the test, the
  Bayes factor's prior for repeating its test). "Not worth replicating"
  goes straight to the write-up, a negative pre-replication report, and
  the planning steps say they aren't needed. The pages' guidance follows
  the "Show explanations" switch: one sentence in view and the rest under
  a labelled fold, with even that sentence folded when explanations are
  off; a field's help sits under its box. The plan
  asks whether the original was published because it was significant
  (if not, as for a Registered Report, BUCSS corrects for uncertainty
  only, `alpha_prior = 1`), explains BUCSS's large numbers as a finding
  about the original, and offers the other routes beside them (the
  smallest effect that matters, what resources allow, a sequential
  design, several originals); results from earlier answers are marked
  out of date. The planner looks like the input screens: numbered step
  titles, titled cards, tile choices, number-sized boxes, ticked steps
  and one "Still needed" bar beside the button. Still to come: the rest
  of item 28 (the three-factor ANOVA, several originals, unequal
  allocation, reliability, claims resting on several tests).

- **Experimental: Labs.** The methods map, the effect-size converter,
  the power visualiser, the repeated-studies tool and Bayesian planning
  (fixed and sequential), all on the cards' engine code and one chart
  style. The replication tools moved to replication plans.


## Validation

Most designs are checked against the package each one calls, plus their
Type I error; independent checks exist for the basic tests (G\*Power), for
mediation (pwrss and simsem), for the two-group MANOVA and for several
simulations (a separately written simulation each). 17 published examples
are transcribed and pass; the rest keep `TODO_PUBLISHED_VALUE` for the
maintainer. 20 of the 70 cards that run are validated in the validation
log's sense; the other 50 say "validation in progress". Validation runs
for a design before its PR merges, every night the engine changed, and in
full every Sunday from 00:05 UTC (`scripts/validation-plan.R`), with
tests dealt to parts by their recorded times so each part ends within
GitHub's six hours, and one list at the end of each run of the tests that
need attention. The recorded full run of 8 November took 4 hours 13
minutes (389 pass, 2 fail, 110 skipped; skips include partitioning and
published placeholders). An earlier inspected nightly,
[9 November run 42570428222](https://github.com/JoelThornton/Powerkit/actions/runs/42570428222),
also failed the ANOVA and binary-X checks (the latter .077 in 1,000).
The latest completed nightly inspected,
[11 November run 42968983200](https://github.com/JoelThornton/Powerkit/actions/runs/42968983200),
at fbbd237 (0.61.1), failed only the two recurring partitions: GG .2130
versus .2313, and binary-X ML/Monte-Carlo null .0750 versus a .0707 limit.
Both are explained (14 November, `validation-log.md`). The GG reference
.2313 is Superpower's epsilon-scaled approximation; the corrected test's
power is .217. Such tests are now simulated by default (Departure 28).
With the maintainer's approval, the chunk's three corrected-test checks
now compare the simulated default with independent references (.4658,
.2169 and .0971), and bound the exact dataset's approximation at 4 points. The binary-X null rate is 5.38% in
20,000 studies, consistent with 5%; seed 1703 drew a 1-in-80 sample every
night. The maintainer chose seed 1500 for that check (`decisions.md`, 14
November 2026), which gives .051.

## Known gaps on cards that run

- Simulated data sets are missing for the three-way regression
  interaction, the meta-analysis, SEM, McNemar's test and the generic
  tests.
- MANOVA with three or more groups is simulated (no formula in a package
  or the G\*Power manual).
- SEM doesn't cover invariance with more than two groups of unequal size,
  or with only some factors differing in their own items.
- Technical details (df, critical value, noncentrality) are missing where
  the package reports none (TOSTER, powertools) and for Bayes factors.
- With a yes/no X and no moderated mediation, power4mome's Monte Carlo
  interval rejected in 5.38% of 20,000 studies (likely about 0.4 points
  above 5%); the results screen states it (`validation-log.md`,
  14 November 2026; `upstream-questions.md`).
- Long simulations end with the visitor's session; no durable job queue
  (`hosting-options.md`, `next.md` item 11).
- No usability sessions with researchers yet
  ([`usability-session-pack.md`](usability-session-pack.md)); no
  ease-of-use result is claimed.

## The online app and releases

The app is online at
<https://joelthornton-powerkit.share.connect.posit.cloud>, published at
most once a day from the `connect-cloud` branch (at 04:23 UTC, with a
second look at 16:23 in case GitHub skips the first), which the
`online-app-manifest` workflow writes with the manifest Connect Cloud
installs from ([`hosting-options.md`](hosting-options.md)). "Copy page
link" gives the open tab, the Labs tool or the open card (`?card=E8`,
which opens that card as the list of every analysis does). The pages
search engines index are static, in `site/`, on GitHub Pages. Main
requires a pull request with passing checks; each finished version is
tagged and published as a GitHub pre-release
([`repository-protection.md`](repository-protection.md)). Verify the static site, download page and indexing configuration against
the actual deployment; Search Console registration alone does not prove
that every page is indexed.

**CRAN (11 November 2026):** every package the engine uses is on CRAN,
and the engine has been prepared for submission: the backends only some
designs use are in Suggests (25 non-base Imports remain, and installing
the engine alone brings 228 locked packages rather than 300,
[`dependency-footprint.md`](dependency-footprint.md)), a run whose
backend is missing says which package to install, every exported
function has an example, and on CRAN a quick set of 23 test files runs
(`engine/tests/testthat.R`). The online app still installs every
backend (`app/routing/optional-packages.R`). The v0.60.0 Linux current-dependency
quick CRAN suite passed on R release and devel with NOT_CRAN=false.
The 0.61.1 release job also passed; the development-job outcome was not yet
recorded at the handoff. This is compatibility evidence, not scientific
validation or CRAN acceptance. Other platforms, optional-backend
coverage and submission checks remain. Submitting is a queue item
in [`next.md`](next.md).

## Working environment

- **Claude Code sessions:** `.claude/settings.json` caps the context
  window before compaction at 400,000 tokens (`autoCompactWindow`), for
  every Claude Code session on this repository.
- **CI:** R CMD check and the engine's tests in three parts when the
  engine, `renv.lock` or the CI setup changed; the app's suite in two
  parts and the browser checks on every pull request; the Windows and
  macOS install test when the launcher or lockfile changes, and weekly;
  all in a prebuilt image with R and the locked packages.
- **Cloud sessions:** `scripts/setup-cloud-session.sh`, as the
  environment's setup script, copies R and the packages from the CI image.
  roxygen2 isn't in the image; `CLAUDE.md` says what to do instead.
- **Open PRs:** GitHub is the list; this page doesn't duplicate it.
- **Upstream reports:** the questions in `upstream-questions.md` were
  rerun on 13 November 2026 for longpower 1.0.27, irtpwr 1.0.3 and
  semPower 2.2.0; all three still reproduce, and none has been sent yet.
