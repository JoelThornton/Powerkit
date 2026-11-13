# Project status

*Last updated: 13 November 2026 (repeated-measures correlation, card E76; several named study plans with a page of their own; JASP's analyses reviewed against the cards and the queue reordered; every change on main now gets a version number, and 0.63.0 numbers the waiting notes; specialist maths review fixes; share links for projects, plans and drafts; a clearer save area on the result screen; the AI assistant is dropped from the plan; CLAUDE.md's facts brought up to date; version 0.62.0 closes the pre-tester fix batch; faster results; replication planner gives its simple answer first; small wording fixes; keyboard focus and contrast fixes, accessibility audit script runs again; one line of help per field; a calmer result screen; regression takes Cohen's f-squared; the goal and direction as buttons on the form; choosing an analysis takes fewer screens; MANOVA takes Pillai's V; tables of means, SDs and proportions entered in a labelled grid; moderated regression result screen fixed; replication from the design finder; cards say what they can't do; critical effect beside the smallest effect; sphericity correction default and exact correlation method; pre-tester review fixes; start screen layout; count-search safeguards merged in PR #372; compact guidance follow-up; live rollout unconfirmed). Where the project is
now, one short paragraph per area; replace a paragraph rather than adding
to it. What to do next is [`next.md`](next.md). History is in git,
[`engine/NEWS.md`](../engine/NEWS.md) and
[`archive/status-history.md`](archive/status-history.md), which holds this
page as it stood before each rewrite.*

powerkit is in development and **not ready for use**: results are not yet
fully validated ([`validation-log.md`](validation-log.md)). The working
rules are in `CLAUDE.md`. There is no AI assistant: it was dropped from
the plan (`decisions.md`, 13 November 2026).

JASP's analyses were reviewed against powerkit's cards (13 November
2026; `coverage-roadmap.md`, "JASP's analyses"). Those powerkit already
plans under other names (CFA, MIMIC, latent growth, mixed models, the
binomial and A/B tests, contingency tables, Cochrane meta-analysis) are
now found by those names in "I know my analysis". The rest lead the
queue in the maintainer's order: three small designs, then every card
that says powerkit can't calculate it yet, then a Bayes factor version
of every design that can have one, then the remaining JASP analyses.

A repeated-measures (within-person) correlation is planned on a new card,
E76 (13 November 2026): rmcorr's documented method, a Pearson
correlation's exact power at the effective sample size N(k − 1) + 1
(Bakdash and Marusich, 2017), reached from the design finder's new
question R2 and by search. Validation in progress: the simulation chunk
`rmcorr` passes; the published example awaits transcription. Next in the
queue: Yuen's trimmed-means t-tests, then Bland-Altman limits of
agreement.

The cross-lagged panel card runs with a reliability below 1 (13
November 2026): its check run compares the specified lagged effects with
those recovered from error-free scores, since measurement error
attenuates them by design (specialist maths review, M-11).

Tables of means, SDs and proportions (two-factor, mixed and repeated
measures ANOVA, ANCOVA, MANOVA, chi-square and logistic factorial cards)
are entered in a grid whose rows and columns are named from the levels
typed above it, with an example and a line on why powerkit asks for
means; the text box stays for pasting, and a link beside the grid
switches to Cohen's w or partial eta-squared where the card takes one
(`decisions.md`, 12 November 2026). MANOVA also takes Pillai's V, as in
G*Power, computed by G*Power's published formula (Faul et al., 2007) and
checked against simulation, and the regression card takes Cohen's
f-squared, as G*Power does, converted by the engine; the within-participants and logistic
factorial cards still take only their tables.

Results come sooner (12 November 2026): the spare R process prepares
the spec checker and Superpower before a calculation needs them, and an
ANOVA's sample size is shown before its 80/90/95% comparison table,
which fills in after it. Welch's ANOVA, the one-way default, is worked
out by Levy's approximation as Jan and Shieh (2014) recommend (13
November 2026), so its answer is instant; the simulation stays as an
option on the card (`decisions.md`, 13 November 2026).

The second specialist mathematics review (13 November 2026) is finished
and its fixes, apart from the cross-lagged panel check run (merged in PR #395),
are in: clustered yes/no outcomes show powertools' unsourced factor 1.2
as Known difference 16, the three-way interaction's fixed-model formula
shows its gap from simulated studies as Known difference 17, the SEM
test of fit has no preselected test (not-close fit listed first), the
cross-lagged panel card asks whether to enter the reliability or assume no measurement error (then the result says power is optimistic), and a simulated
meta-analysis's number of studies shows its interval. Mediation and
PROCESS simulations test each simulated study 3 to 7 times faster with
identical results: the Monte Carlo interval is computed directly from
manymome's draws (`fast-mediation-test.R`). Whether to change
the clustered yes/no and three-way methods is a queue item for the
maintainer (`next.md`).

The moderated regression cards' result screen, which stopped with an
error for the sample size and power since 10 November, shows its result
again (fixed 12 November, with a test).

"Help me choose" reaches the t-test, one-way ANOVA and MANOVA one
question sooner (the number of groups is asked with the number of
factors), the aim screen leads with "Test a prediction", and the
analysis list shows its groups in two columns and finds the names
researchers use, such as Cohen's f or mixed ANOVA. On the form, the
goal and the test's direction are rows of buttons, the bar names the
answers still needed, and the effect section uses the same white cards
as the rest; each field shows one line of help, with the rest behind an
info button beside its label. The result says the answer once, with the sample size at
other powers and significance levels in a small table, and keeps the
records for checking it under one "Technical records" fold
(`decisions.md`, 12 November 2026).

Every route through the design finder now ends on a card that can hold
the user's answers or says at the top what it can't do (the equivalence
aim, a non-score outcome, Bayes factors on "Plan my whole study") and
where to go instead (`decisions.md`, 12 November 2026). The
smallest-effect result gives the critical effect beside it, Welch's
t-test included when groups are equal, and the ANCOVA result shows how
Shieh's method differs from G*Power's (Known difference 15).

A pre-tester review on 11 November corrected three calculations: decimal
group-size ratios are planned as the simplest matching whole split
(`docs/conventions.md`, "Group sizes given as a ratio"), non-inferiority
t-tests use the one-sided t-test against the margin, and a search whose
power cannot rise says so. Precision planning for one group and paired
data accepts assurance. In the app, exports no longer wait for a written
effect-size reason, the run button is "Calculate", Welch's t-test has the
explore panels, and partial eta-squared with Welch's ANOVA is caught on the
input screen. The study plan is reachable from every screen and kept in
the browser; a result is reused when only free-text answers change; a
conventional effect size can be recorded as one. The non-inferiority and allocation unit tests and the
non-inferiority validation chunk were run; no full validation run is
claimed. Minimum-effect tests now use the same shifted t-test (12
November; the equivalence validation chunk was run). The rounded-group-size
search is queued.

Simple mediation (E10, E16) starts on a quick estimate by formula (the
joint-significance test, pwrss), marked as an estimate on the result, with
the simulated methods for the number to report (12 November).

The claim (how many tests a conclusion rests on) is asked in view on every
input screen, with a Bonferroni choice for related tests (12 November).

Results now help users compare with the tools they know (12 November):
Student's answer beside Welch's, the cost of a stricter alpha, Cohen's f
named on the ANOVA screens, and plainer wording in the checks panel and
the advice on effect sizes.

The correlation card plans by the exact distribution of r, as G*Power (12
November; Departure 10 retired), with Fisher's z as a choice.

Repeated measures with SDs or correlations that differ now default to the
Greenhouse-Geisser corrected F test (12 November, Departure 26); the
uncorrected test stays as a choice with a warning.

The input screens were shortened (11 November): the two-group t-test
screen shows about 670 words at first sight, from about 1,200, with the
spread ratio and between-study variation folded. Wording only.

The start screen was laid out again before colleagues try the app
(11 November): a title and one-sentence introduction, the three routes
with more room, and saved projects and the local download in one row
under a divider. Presentation only; no method, default or evidence
claim changes.

The [R checklist](release-readiness-review.md#fix-checklist) now records checked
subtasks directly under each open/partial R14–R36 item, with the remaining
acceptance work beside it. Parent boxes close only when the full requirement
is met; this tracking correction adds no implementation or validation claim.

The [release-readiness review](release-readiness-review.md) safeguards merged
in PR #369 (0.61.1): early analysis limitations, clearer power/paired-input help,
eleven common analysis-translation checks and a phone action-bar correction.
Required gates, full app/browser checks, clean Windows/macOS first/repeat
starts and CRAN-release compatibility passed. Scientific validation gaps
remain open; these checks do not establish broad mathematical validation.

The publishing correction merged in PR #370. Its isolated-index publisher
preserves checked source, prior deployment ancestry and temporary build files.
[Publication run 42927530578](https://github.com/JoelThornton/Powerkit/actions/runs/42927530578)
succeeded: deployment commit 300b53d967df contains checked main bdbdfb6cc7e3
plus the pinned manifest. The host's normal rollout is left to complete;
a new live version is not claimed verified. The public download page and
sitemap body were checked in a browser, including the download-page entry.
CRAN-development job outcomes were still unrecorded at the 11 November
00:03 UTC handoff; CRAN readiness and first-release evidence remain open.

The [first-release support plan](v1-support-plan.md) sets a broad coverage
target, a representative benchmark and complex-design audit briefs. Its
[source inventory](release-support-inventory.json) is generated from current
expanded forms and access routes, with a freshness check. It is discovery
metadata, not new scientific evidence or a measured 99% result. Audit P0
cases and investigate the two recurring failures before further claims.

Local installation recovery merged in PR #368: bounded per-file TLS/download
retries, alternate downloader/mirrors, bootstrap recovery and an engine
completion stamp written only after a successful matching install.
An isolated three-package binary restore on Windows passed with renv 1.0.3
and an unchanged lockfile. Full clean Windows/macOS first/repeat starts passed
on that PR's final head. No fix is claimed for every network.

The [default review and checklist](variation-default-review.md) records the
maintainer's approval of ordinary t-test and Pearson correlation plans starting
without between-study variation (10 November). Explicit variation scenarios
retain the existing engine and saved values, and explain averaged significance
rather than power at the average effect. The smaller-effect comparison now
shows power at the exact analysed sample size. These source changes are not a claim about the deployed app or new scientific validation.

This release batch adds [PROCESS-style mediation planning](process-style-planning.md):
OLS plus casewise percentile bootstrap, alongside the existing ML Monte
Carlo and ML bootstrap methods. All nine applicable forms expose the
method/count; bootstrap plans run through a local script that saves an
app project for viewing the result without rerunning it. Results and exports
record the choice, and same-data
regression/interval checks cover the supported model families. The PR validation completed the two selected null checks (2,000 studies and
1,000 resamples each): .0495 for simple mediation and .0585 for binary-X
model 7, with a direct-reference TODO skip. Results and frozen settings are
archived; the 5,000-resample default and other cases remain outside that
recorded run. A direct archived
PROCESS-software comparison remains pending; no evidence badge is upgraded
and the existing ML/Monte-Carlo binary-X failure remains open.

The five safeguards merged in PR #368 are recorded in the
[review checklist](release-readiness-review.md#five-priority-safeguards-10-november):
visible corrected-ANOVA limitations, a new unknown-dependence default that
preserves historical plans, matched interaction-sensitivity verification,
four independent corrected-count fitted-N checks with honest uncertainty,
and selected-setting evidence on input screens. The balanced-proportion
reference found .79547 power at a nominal .8 fitted target; the smooth curve's
interval missed that finite-reference value. The count-search fix merged in PR #372 and
uses that curve only as a proposal: fresh checks at each candidate require a
one-sided binomial lower bound above the target, with a 1% error budget across
at most ten checks. It increases N when needed or refuses a recommendation.
This is a checked N under the specified model, not a minimum-N guarantee or
protection against optimistic population assumptions. Historical saved results
retain the old warning. Independent case checks and hosted gates are recorded
in the count-test checklist; the ANOVA/mediation failures and broader evidence
requirements remain open. Attrition input/results/methods now distinguish a
recruitment buffer from missing-data modelling. Pilot guidance describes
uncertainty and selection without asserting inflation or automatic halving.

The compact-guidance follow-up makes explanations-off fold routine field
help, defaults and group notes behind native info controls, with concise
common labels. Selected methods, units, errors and scientific limitations
stay visible. Explanations-on keeps guidance inline. Target power remains
blank, with equally styled 80/90/95% examples and consequence/cost guidance
rather than a preferred 80% shortcut. This changes presentation, not methods,
effect values or numerical defaults. Desktop/phone interaction, keyboard
and automated accessibility checks passed locally for the exercised routes.

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

- **What calculates:** 70 of the 76 analyses run in the app, as the About
  page says (77 cards, counting the "none of these fit" card; `tree.yaml`'s
  statuses); the other seven say powerkit can't plan them yet and point
  elsewhere. 55 calculate in the app directly (`forms.yaml`'s
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
  adjustment; effects that vary between studies on the three t-test
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
  proportions, the ANOVAs (Welch's F by formula), regression and the
  clustered design (the rest is `next.md` item 9). Results show the critical effect size for the
  t-tests (Student's) and the correlation.

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
  been saved to a file, since the browser's copy can be cleared. "Download
  everything" for a plan and "Plan my whole study" starting a plan are
  next ([`saving-projects.md`](saving-projects.md), "Study plans").

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
  the designs still to add are in `next.md` item 4.

- **Experimental: Labs.** The pre-replication notes, the replication
  planner, the methods map, the effect-size converter, the power
  visualiser, the repeated-studies tool and Bayesian planning (fixed and
  sequential), all on the cards' engine code and one chart style. The
  replication planner (8 November 2026) follows the notes: for an
  original t-test or correlation finding, the sample size for each
  replication goal (Anderson & Maxwell, 2016) under three beliefs about
  the true effect, with BayesRepDesign (Pawel, Consonni & Held, 2026)
  and the small-telescopes card's own calculation, how the replication
  differs, and a write-up with an R script, in sections saved to a file.
  The design finder's "Replicate a published finding" asks the original
  study's design (12 November 2026): the planner's four designs link to
  it from their card, and every other design plans the replication on
  its own card. The planner gives its simple answer first (12 November
  2026): a button at the end of section 1, and one sentence with the
  sample size for a significant result again, as reported and shrunk,
  above the table. The replication plan that wraps any card is queued
  (`next.md` items 21 to 23).

PR #368 added selectable continuity-corrected two-proportion and
2 by 2 contingency tests, leaving existing defaults intact. Inputs/results
name the correction and sampling plan; corrected tests simulate the actual
R analysis and report failed studies. Direction/allocation/replay checks and
the selected high-replication comparisons passed locally and on GitHub.
Four independent returned-N checks are archived, including small target
shortfalls and a reference outside the smooth curve interval; fresh final-N
confirmation is implemented in PR #372. Published references, broader parameter coverage
and minimum-N efficiency remain open. See the
[count-test checklist](count-test-review.md).

The wording pass merged in PR #368 corrects the equal-group Welch/Student
overstatement, scopes the interaction comparison to its recorded cases,
labels interaction sensitivity as a formula approximation, and distinguishes
one-test power from any/all-test success. The regression form now explains
why its two input routes need not agree. This is the first pass of the
full wording audit in release-readiness-review.md, not every-screen sign-off;
statistical engines are unchanged; new all-required-test plans now use the
existing unknown-dependence bound while saved choices are preserved. Three
fresh sensitivity checks (10,000 simulated studies each) are archived; all
99% power intervals included the 80% target. They use the same backend and
do not establish universal agreement or an independent-package validation.

Compact-mode naming has been audited across all 77 analysis entries and
14 families. Curated conventional names replace explanatory title suffixes
in the analysis list, cards, input headings, recent entries and the methods
map's standard-name field. Common method selectors are shorter; detailed
analysis assumptions and validation warnings remain separate and visible.
This is display metadata, not a change of method, defaults or evidence.
R22's crossover scope correction is also implemented: ordinary paired
analysis is no longer presented as a general adjusted-crossover approximation;
card/input guidance and copied methods state the limitation. The dedicated
crossover model remains a separate capability/evidence gap.

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
The [10 November run 42772650889](https://github.com/JoelThornton/Powerkit/actions/runs/42772650889)
also completed with failures in the ANOVA and binary-X chunks; this does not
resolve either scientific issue. The latest completed nightly inspected,
[11 November run 42968983200](https://github.com/JoelThornton/Powerkit/actions/runs/42968983200),
at fbbd237 (0.61.1), again failed only these two partitions: GG .2130
versus .2313 and binary-X ML/Monte-Carlo null .0750 versus the unchanged
.0707 limit. The two recurring failures concern the
mixed-design Greenhouse-Geisser check: a new independent 20,000-study
reference gives .21805 (MCSE .00292), with same-data p-values matching afex
to 1.9e-15. Fixing epsilon gives .2196, so that alone does not explain
Superpower's .2313. Investigation and specialist review remain open, and moderated mediation's Type I error with a
yes/no X (7.5% of 1,000 studies), a question for power4mome's author.

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
- With a yes/no X and no moderation, power4mome's moderated mediation has
  a Type I error of about 6.7%, stated on the results screen pending investigation and author review (`upstream-questions.md`).
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
