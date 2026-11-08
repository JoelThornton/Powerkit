# What to work on next

*8 November 2026: rows trimmed to what is left; what landed is in `status.md` and `engine/NEWS.md`. 7 November 2026: "Review fixes first" added from a review of the whole project; those rows come before the queue. The ordered answer to "work on the next thing": [`status.md`](status.md) says where the project is, this says what to do.*

**How a thread uses this page**

1. Take the first Ready item in **Review fixes first** below, while any
   remain; then the first item marked Ready in the queue.
2. If an item says *Needs a decision*, it is not yours to start: say what
   the decision is and move to the next Ready item, or ask the maintainer.
3. Follow [`adding-a-test.md`](adding-a-test.md) for anything that adds a
   power analysis. One item, or a group of closely related ones, per PR
   (`CLAUDE.md`, "Working process").
4. When an item lands, delete its row and say so in `status.md`.
5. **Check the top item still makes sense before starting.** This page is
   dated; a queue written three weeks ago can be stale, and the
   maintainer's priorities beat it.

## Review fixes first (7 November 2026)

A review of the whole project on 7 November 2026 (powerkit 0.35.0) found no
wrong number and nothing critical, but 21 serious problems and about 110
smaller ones. They are grouped below into pull requests by area of the app,
in the order to take them; two or three can run at once when they touch
different areas. The maintainer decided the choices marked "decided".

| Order | What | Includes | Size | State |
| --- | --- | --- | --- | --- |
| R12b | **Welch's F by default** | Welch's F as the one-way ANOVA's default, the classical F test as a choice, recorded as a departure in all four places; the two-group card's Welch default landed on 8 November 2026 (decided 8 November 2026: best practice) | M | Ready |
| R13 | **Small telescopes for replications** | Offer Simonsohn's (2015) small-telescopes sample size beside safeguard power on the t-test and correlation cards, if a package implements it; source through `refs.bib` (decided) | M | Ready |
| R14 | **Keep the review's scripts** | The property checks over every example spec and the every-card browser run, added so they can be rerun before each release (decided) | S | Ready |

## The queue

| # | What | Why it matters | Size | State |
| --- | --- | --- | --- | --- |
| 1 | **Joint power for study plans that mix designs** | The whole-study simulation covers people measured once or twice, measured or two-group X (randomised or not), mediation and moderated mediation, factorial experiments, dyadic moderation of the actor effects and several outcomes of one trial. Left, in this order (decided 7 November 2026): covariates in every analysis's model; fully within-people designs (three or more conditions per person, three or more waves, the moderator's main effect); yes/no and other outcomes, and mixed outcome types; nested data (people in groups, repeated trials); pairs beyond the actor-partner model | L | Ready (decided 31 October 2026): one design at a time, marked Experimental, checked by a statistician later (below the queue), not before |
| 2 | **Bayes factors: informed priors** | Fifteen designs have Bayes factor versions with JASP's default priors. Left: informed priors, which wait on a bfpwr fault or the maintainer's decision on an exact calculation in the engine (`bayes-planning.md`) | M | Ready (decided 31 October and 4 November 2026). The binomial preprint the maintainer supplied (Kelter and Pawel, arXiv 2502.02914) asks not to be cited without the authors' permission, so it stays out of `refs.bib` until it is published |
| 3 | **Longitudinal: experience sampling** | Growth curves (E35) and random-intercept cross-lagged panels (E74) calculate. Left: experience sampling, which waits for PowerAnalysisIL on CRAN (roadmap B43) | M | Ready (decided 4 November 2026): starts once PowerAnalysisIL is on CRAN |
| 4 | **Designs that need a custom simulation: dyadic and mediation (E39, E42, E65)** | Non-score outcomes or mediators in mediation, a condition with three or more groups in mediation, and dyadic designs other than actor and partner effects. Each card points to Spower with a model the user writes | L | Ready (decided 4 November 2026): one PR per design |
| 5 | **Psychometric models still without a method** | Krippendorff's alpha, two-way ICCs and McDonald's omega (no package or published sample-size method found yet); further IRT presets in irtpwr if researchers ask | M | Ready (decided 4 November 2026): only once a package with a sample-size or power method is found |
| 6 | **The smallest detectable effect for every design that calculates** | Sensitivity at a fixed n is a goal on the t-tests, the correlation, proportions, the ANOVAs, regression, E9 and the clustered design. Every other design offers only power at an n and the n for a power, so a researcher whose sample size is fixed has to search effect sizes by hand | L | Ready (decided 18 October 2026, judgement call G9: sensitivity is a first-class route for every end point; mediation goes to the R script). Closed-form designs first, from each package's own solve-for-effect or by searching the effect with its power function; then the simulated designs by the preview and R script route. One PR per family, each with the sensitivity curve |
| 7 | **Input screen and result page follow-ups** | Regression's effect boxes stay hidden until "What you want to test" is chosen, which leaves that section looking empty; the result page is long. Both are what a first-time user meets on the commonest cards | S | Ready: a one-line prompt in the empty section until the choice is made; fold the result page's secondary sections (technical details, simulated data, citations) behind headings, keeping the answer, its conditions and the methods paragraph in view |
| 8 | **Hosting for real users (build guide phase 8)** | Phase 8's check is "stable under 20 concurrent runs" with a queue and limits; none of it is done. Long simulations end with the visitor's session, and the online app runs on a plan with 100 usage credits a month | M | Needs a decision: which host serves real users (`hosting-options.md`). Recommendation: measure two weeks of use on Connect Cloud's usage page first, then load-test the chosen host at 20 concurrent runs, with a per-visitor limit on simultaneous simulations; the durable job queue only once long simulations are a measured share of use |
| 9 | **Triage the open judgement calls** | `judgement-calls.md` (last updated 18 October 2026) lists 44 open entries, and several have since been overtaken by later work (for example C14, several outcomes, which the MANOVA card E59 now answers). Stale entries hide the few that still need the maintainer | S | Ready: move each entry later work or a later decision settled to the archive with a link to that decision; give each one that stays a current recommendation; put the remainder in `judgement-session.md` order |
| 10 | **Bring the coverage roadmap up to date** | Rows lag the app: B49 and B52 still say no tool, though both calculate (E58, E73); A34 points to a MANOVA queue item that no longer exists | S | Ready: one pass over every row's status, end point and next step against `forms.yaml`'s `calculates` list; each design PR keeps its row current after that (`adding-a-test.md`) |
| 11 | **Designs nobody has decided on yet** | Roadmap rows whose next step is "Decide": group-sequential designs with interim analyses (B57), assurance, or power averaged over a prior for the effect (B60), diagnostic accuracy (B63), prediction model development (B64), single-case designs (B65), prevalence estimation (B66) and network models (B53). Several are common outside psychology's usual designs, and powerkit is for research studies generally (`decisions.md`, 5 November 2026) | M | Needs a decision: which to offer. Recommendation: diagnostic accuracy and prevalence first, as precision planning with presize, which powerkit already uses; prediction models with pmsampsize; group-sequential designs with rpact; assurance as an option beside power; single-case designs and network models later. Each package's methods to be checked against its help files before a card is built |
| 12 | **A variant-by-variant evidence register** | No single register says, for each test version on each card, which checks it has (package agreement, Type I error, published example, independent simulation) | M | Ready: generate it from the validation files and `forms.yaml`, as the capability table is, so it cannot drift; show it on About beside the capability table |
| 13 | **A crossover (AB/BA) card** | The paired and mixed ANOVA cards say how to plan a crossover, but no card asks for the period effect or the carry-over assumption, and the design finder can only send a crossover to the paired card (roadmap B33) | M | Ready: a card that takes the treatment effect, the period effect and the correlation between periods, with the test of the treatment effect adjusted for period, from a package that implements it (Superpower's 2b*2w design is the candidate to check); routed from "the same people in both conditions" when the order is counterbalanced |

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
- Split a very large file, or move a single-card package to Suggests, only
  as part of a PR that already touches it (`CLAUDE.md`, "Conventions";
  `routing-prototype.md`, "Splitting the large files").
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
- **Two validation checks that fail every run** (`validation-log.md`, 7
  and 8 November 2026): the mixed design's Greenhouse-Geisser check
  (Superpower's exact route applies the population's epsilon, a simulated
  study estimates its own; which describes the planned analysis is for
  the statistician), and moderated mediation's Type I error with a yes/no
  X (power4mome's question 6 in `upstream-questions.md`). Neither test is
  changed until then.
- **Which batch comes next**, if the order above is wrong.
