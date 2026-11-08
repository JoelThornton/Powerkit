# Project status

*Last updated: 8 November 2026 (powerkit 0.48.1). Where the project is
now, one short paragraph per area; replace a paragraph rather than adding
to it. What to do next is [`next.md`](next.md). History is in git,
[`engine/NEWS.md`](../engine/NEWS.md) and
[`archive/status-history.md`](archive/status-history.md), which holds this
page as it stood before each rewrite.*

powerkit is in development and **not ready for use**: results are not yet
fully validated ([`validation-log.md`](validation-log.md)). The working
rules are in `CLAUDE.md`.

## Where things are

- **Review fixes (7 November 2026):** a review of the whole project found
  no wrong number and nothing critical, and grouped 21 serious problems
  and about 110 smaller ones into fourteen fix batches, all done by
  8 November: validation runs that finish and report, what the app says,
  design-finder routes, the draft box and page structure, effect-size
  guidance, speed, whole-study planning, input screens, Labs, docs and
  start-up reading, change notes that no longer need catch-up merges
  (each pull request writes its own note files; `scripts/close-batch.R`
  sets the version when a batch closes), Welch's tests by default
  (Welch's t-test on the two-group card, by formula, Departure 21;
  Welch's F on the one-way ANOVA card, simulated, Departure 22), small
  telescopes for replications (0.47.2: d33 at the original study's own
  significance level, the power if the true effect is small but not
  zero, and wording that says what a result below d33 does and doesn't
  show), and the review's own checks kept for
  each release: property checks over every example spec and a run of
  every card in a browser (`repository-protection.md`, "Checks before a
  release"). A check of every review finding against what merged
  (8 November) found a few left: the small ones are fixed, and the
  larger ones are `next.md` items 15 to 20. Effects that vary between
  studies are on the t-test cards (8 November). Next: the queue in
  `next.md`, and a Bayes mode (item 21, waiting on a decision).

- **What calculates:** 70 of the 77 cards run in the app (`tree.yaml`'s
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
  cards (Kenny & Judd, 2019, through pwr; optional, empty by default);
  precision planning (a confidence interval's width, by MBESS
  and presize) as a goal beside power. Bayes factor versions exist for
  fifteen designs, with JASP's default priors; p-value results of the
  exact ones offer "Add a Bayes factor?", and Bayes factor t-test results
  show three prior widths, a sequential plan and an uncertain effect.
  Informed priors wait on a bfpwr fault (`upstream-questions.md`).

- **Effect sizes:** the commonest cards take what researchers have: a
  published t, F, r, d or odds ratio, partial eta-squared, Cohen's w, the
  R-squared change; safeguard power for an effect from one study or a
  pilot, or small telescopes for a replication (Simonsohn, 2015); the
  smallest detectable effect on the t-tests, the correlation,
  proportions, the ANOVAs (Welch's F by simulation), regression and the
  clustered design (the rest is `next.md` item 6). Results show the critical effect size for the
  t-tests (Student's) and the correlation.

- **Results and documents:** a result opens with the answer and what it
  assumes, then "How sure can you be?", the write-up with a methods
  paragraph, and downloads: a project file, an R script that reproduces
  it with the backend alone, citations and, for most designs, a simulated
  data set. Every result records its spec hash, seed, backend, and R and
  package versions. The pre-replication notes and the study-planning
  document save as PDF, Word and Markdown. Results link to the Labs tool
  that explains them.

- **Experimental: whole-study planning.** The guided plan simulates
  several analyses of one study together, so the chance all succeed is
  counted rather than assumed: measured predictors or two groups
  (randomised or not), people measured once or twice, mediation and
  moderated mediation (power4mome), factorial experiments (Superpower),
  and a pair-level moderator in dyadic studies. Joint power for several
  outcomes of one randomised trial uses PUMP. It waits for a
  statistician's check ([`whole-study-method.md`](whole-study-method.md));
  the designs still to add are in `next.md` item 1.

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
  It opens from the start screen's "Replicate a published finding".

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
need attention. The full run of 8 November took 4 hours 13
minutes (389 pass, 2 fail, 110 skipped). Its two failures are known: the
mixed-design Greenhouse-Geisser check, which fails with new seeds too and
waits for the statistician, and moderated mediation's Type I error with a
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
  a Type I error of about 6.7%, stated on the results screen until its
  author answers (`upstream-questions.md`).
- Long simulations end with the visitor's session; no durable job queue
  (`hosting-options.md`, `next.md` item 8).
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
([`repository-protection.md`](repository-protection.md)). Still to do
once, by the maintainer: turn on GitHub Pages and add the site to Search
Console.

## Working environment

- **CI:** R CMD check and the engine's tests in three parts when the
  engine, `renv.lock` or the CI setup changed; the app's suite in two
  parts and the browser checks on every pull request; the Windows and
  macOS install test when the launcher or lockfile changes, and weekly;
  all in a prebuilt image with R and the locked packages.
- **Cloud sessions:** `scripts/setup-cloud-session.sh`, as the
  environment's setup script, copies R and the packages from the CI image.
  roxygen2 isn't in the image; `CLAUDE.md` says what to do instead.
- **Open PRs:** GitHub is the list; this page doesn't duplicate it.
