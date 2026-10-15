# Power Analysis Tool — Build Guide

Oct 12, 2026

One R simulation engine, three front doors (design forms, full-model builder, optional AI assistant), validated against published results before anything ships. This guide is written to hand to Claude Code.

**Goal (the maintainer's).** powerkit aims to give psychologists one place to run the power analyses offered by Superpower, Spower, power4mome, InteractionPoweR and G\*Power. It is built on those tools and credits them, and it is validated against them. For the rare cases no form covers, the route is the full-model builder and the R script export. What each tool offers, and where powerkit stands on each capability, is in [`coverage.md`](coverage.md).

## 1. Prior art: the tools powerkit builds on

The statistics powerkit needs already exist in well-tested, peer-reviewed R packages. Two packages from 2025–26, Spower and power4mome, shaped the build plan: powerkit adds a front end and write-up layer on top of them rather than reimplementing the maths.

| Tool | What it covers | Interface | Notes |
| --- | --- | --- | --- |
| [Spower](https://cran.r-project.org/web/packages/Spower/index.html) (Chalmers, 2025; v0.6.4 June 2026) | General-purpose Monte Carlo power engine; simulation versions of all G\*Power tests, mediation, Bayesian power; a priori, sensitivity, compromise and criterion analyses with MC uncertainty | R code | Very flexible: users can supply their own generate/analyse functions for non-standard designs |
| [power4mome](https://cloud.r-project.org/web/packages/power4mome/index.html) (Cheung et al., v0.2.1 March 2026) | Moderation, mediation, moderated mediation, latent mediation, via lavaan or regression; sample size search; power curves | R code | Models are written in lavaan syntax |
| [pwrss](https://www.rdocumentation.org/packages/pwrss/versions/1.3.1/topics/power.z.mediation) | Broad analytic coverage incl. ANOVA/ANCOVA, regression, logistic, Poisson, indirect effects (Monte Carlo test) | R + Shiny apps | Formula-based (analytic) calculations |
| [Superpower](https://journals.sagepub.com/doi/10.1177/2515245920951503) | Factorial ANOVA up to three factors, between/within/mixed | R + Shiny | Specialised in factorial ANOVA |
| InteractionPoweR | 2- and 3-way regression interactions with reliability | R + Shiny | Specialised in regression interactions |
| pwrSEM, semPower | SEM parameter and fit power | Shiny / R | Specialised in SEM |
| PowerGPT, N-Power AI | LLM + engine for clinical trial tests | Web / prototype | Focused on clinical trial designs |

**Where powerkit fits:** we did not find a single interface that takes a psychology design, routes it to one of these engines, confirms the model with the user, and returns a power curve, reproducible script and APA paragraph. powerkit aims to be that layer, built on the packages above and crediting them in every result.

**What this changes in the plan**

- **Wrap, don't reimplement.** Use Spower and power4mome (plus Superpower and InteractionPoweR for their specialities) as engine backends. They are peer-reviewed and maintained, which cuts your validation burden and gives reviewers names they already trust.
- **powerkit's contribution is a layer on top of them:** the unified specification, the design forms and model builder, the confirmation screen, the write-up and citation generator, and the optional AI assistant.
- **Contact the authors early** (Phil Chalmers for Spower; Shu Fai Cheung for power4mome): share the plan, ask for their advice, and report anything found while wrapping their packages. powerkit depends on their work and should credit it clearly.
- **Your own validation still matters:** test that your specification-to-engine translation is right, by checking your results equal what each package gives when called directly, and match published examples.

## 2. Coverage: what psychologists need power for

So far we had covered interactions and mediation/moderation. The biggest gaps were repeated measures, mixed models with participants and stimuli, longitudinal designs, equivalence tests and non-normal outcomes. All of them fit the same engine; they differ only in the data generator and the analysis.

| Family | Examples | Why it matters | Tier | Likely backend |
| --- | --- | --- | --- | --- |
| Basic tests | t-tests, correlations, chi-square, proportions | Baseline users and teaching; G\*Power parity | MVP | Spower |
| Factorial ANOVA | 2x2 between, 2x2 mixed, 2x2x2, ANCOVA | Most common experimental design | MVP | Superpower / Spower |
| Interactions in regression | Continuous × continuous, continuous × binary, three-way, reliability | Moderation hypotheses | MVP | InteractionPoweR / power4mome |
| Mediation | Simple, parallel, serial (PROCESS 4, 6) | Very common in psychology | MVP | power4mome |
| Moderated mediation | PROCESS 7, 8, 14, 58, 59; index of moderated mediation | A core focus for powerkit | MVP (7, 14), v2 (rest) | power4mome |
| Equivalence and smallest effect of interest | TOST, minimum-effect tests | Increasingly required by Registered Reports | v2 | Spower |
| Generalised linear models | Logistic, Poisson, ordinal / Likert outcomes | Binary and count outcomes are common | v2 | Spower / pwrss |
| Mixed-effects models | Crossed participants × stimuli, nested designs | Reviewers increasingly expect this for experiments with items | v2 | simr / faux |
| Within-subject and multilevel mediation | Repeated measures mediation, 2-1-1 designs | Common in experience-sampling work | Later | Custom |
| Longitudinal | Growth curves, cross-lagged panel, intensive longitudinal / EMA | Panel and diary studies | Later | lavaan / PowerAnalysisIL |
| SEM and measurement | CFA, latent mediation, measurement invariance, model fit (RMSEA) | Scale development and latent models | Later | pwrSEM / semPower |
| Bayesian design analysis | Bayes factor design analysis, posterior precision | Growing minority | Later | Spower / BFDA |
| Sequential designs | Group-sequential, interim analyses | Efficient sampling, RR friendly | Later | rpact |
| Precision (AIPE) | n for a target confidence interval width | Alternative to power for estimation-focused work | v2 | Custom |

The capability-by-capability inventory of the five tools powerkit builds on, with powerkit's status, proposed tier and validation for each row, is in [`coverage.md`](coverage.md).

**Cross-cutting options every design needs:** attrition and missing data, unequal group sizes, measurement reliability, multiple-comparison correction, non-normal data, and a sensitivity analysis (smallest detectable effect at a fixed n).

**Out of scope:** power for qualitative or purely computational text studies (e.g., topic models) has no agreed framework; leave it out rather than invent one.

## 3. Architecture and repository layout

One repository, three parts: an R package that turns a specification into a power result, a Shiny app that builds specifications, and (later) a small AI service that only suggests specifications.

```
powerkit/                      # working name
├── engine/                    # R package
│   ├── R/
│   │   ├── spec.R             # read + validate a design spec (JSON schema)
│   │   ├── route.R            # pick the backend for a spec
│   │   ├── backends/          # one adapter per backend
│   │   │   ├── spower.R
│   │   │   ├── power4mome.R
│   │   │   ├── superpower.R
│   │   │   └── interactionpower.R
│   │   ├── search_n.R         # sample size search + power curve
│   │   ├── export_script.R    # write a standalone R script for the run
│   │   └── writeup.R          # templated APA paragraph + citations
│   ├── inst/schema/design.schema.json
│   ├── inst/citations/refs.bib
│   └── tests/testthat/        # validation targets (section 6)
├── app/                       # Shiny front end
│   ├── forms/                 # one module per design form
│   ├── builder/               # full-model builder
│   ├── confirm/               # diagram + equations confirmation
│   └── results/
├── assistant/                 # later: AI suggestion service
├── docs/                      # this guide, decisions log
├── renv.lock                  # pinned package versions
└── CLAUDE.md
```

**Rules that hold across the repo**

- The app never computes power itself; it only builds specs and calls the engine.
- Every backend adapter takes a spec and returns the same result object (power, MC standard error, n, settings, versions, seed).
- Package versions are pinned with renv; every result records them.
- Long runs go through a job runner (future + mirai, or a queue when hosted) so the app stays responsive.

## 4. The design specification

The specification is the heart of the product: every front door writes one, the engine reads only this, and it is saved with every result. Design it before any other code.

Example for a first-stage moderated mediation (PROCESS Model 7):

```json
{
  "spec_version": "0.1",
  "design": "moderated_mediation",
  "template": "process_7",
  "variables": {
    "X": {"type": "binary", "label": "Condition"},
    "W": {"type": "continuous", "label": "Group identification", "reliability": 0.85},
    "M": {"type": "continuous", "label": "Perceived threat"},
    "Y": {"type": "continuous", "label": "Support for policy"}
  },
  "population": {
    "metric": "standardised",
    "paths": {"X->M": 0.20, "W->M": 0.10, "XW->M": 0.15, "M->Y": 0.30, "X->Y": 0.05}
  },
  "effect_justification": {"type": "meta_analysis", "source": "Author (Year), k = 24", "adjustment": "halved for bias"},
  "target_test": {"effect": "index_of_moderated_mediation", "method": "monte_carlo_ci", "alpha": 0.05},
  "goal": {"type": "sample_size", "power": 0.90},
  "options": {"attrition": 0.10, "nrep": 1000, "seed": 20261012}
}
```

**Design rules**

- `design` + `template` decide the backend; the rest is design-specific and validated by the JSON schema.
- `goal.type` is one of: `sample_size`, `power` (at a fixed n), `sensitivity` (smallest detectable effect).
- `effect_justification` is required, not optional. It feeds the write-up and stops "medium effect" defaults.
- Labels are the user's own variable names, so the confirmation screen and write-up read naturally.
- Version the schema from day one; old saved specs must keep running.

## 5. Engine design

The engine validates the spec, routes it to a backend, searches for the sample size, and returns one standard result object. Speed comes from method choices, not language.

**The run, step by step**

1. **Validate** the spec against the schema; check the implied population is possible (e.g., correlation matrix positive definite, R² below 1). Fail with a plain-English message.
2. **Route** by `design` + `template` to a backend adapter.
3. **Check run:** simulate one large data set (e.g., n = 100,000) and confirm the fitted estimates recover the specified population values. This catches translation errors before spending compute.
4. **Search n:** coarse pass with few replications to bracket the answer, then refine near the target with more replications (power4mome's `n_region_from_power` and Spower's criterion search already do this).
5. **Report:** power curve, required n with a confidence interval, Monte Carlo standard error, sensitivity curve, settings, seed, package versions.

**Speed rules**

- Use Monte Carlo confidence intervals for indirect effects inside the loop, not bootstrapping.
- Use the fastest valid estimator: `lm`-based fits for observed-variable regression models; lavaan only where needed.
- Run replications in parallel; cache results by a hash of the spec so identical requests are free.
- Default precision: enough replications that the power estimate's 95% interval is about ±.03 near the target; let users increase it for final reports.

**Result object.** `run_spec()` always returns one result object, whatever the goal type:

| Field | Contents |
| --- | --- |
| `goal_type` | The spec's goal type: `sample_size`, `power` or `sensitivity` |
| `curve` | Data frame of `n`, `power` and `mcse` (Monte Carlo standard error) for each n simulated; a single row for a fixed-n (`power`) goal |
| `n_required` | List of `n`, `lower`, `upper`: smallest n reaching the target power, with its uncertainty interval; `NA` unless the goal is `sample_size` |
| `sensitivity` | Smallest detectable effect at the chosen n; `NA` unless the goal is `sensitivity` |
| `check_run` | Population values versus recovered estimates |
| `provenance` | Spec hash, seed, backend, R and package versions, run time |

## 6. Validation targets

Write these tests before the engine code, and treat them as your work rather than Claude's: you choose the published numbers and check they are transcribed correctly. If the engine passes them, the engine can be trusted.

**Four kinds of test**

1. **Analytic agreement.** For designs with exact formulas (t-tests, correlations, simple regression, ANOVA main effects), simulated power must match G\*Power or `pwr` within Monte Carlo error.
2. **Published-example agreement.** Reproduce worked examples from the method papers and vignettes, within Monte Carlo error. The table lists where to take them from.
3. **Direct-call agreement.** For each backend, your spec-to-backend translation must give the same answer as calling the package directly with equivalent inputs. This tests your code, not theirs.
4. **Type I error.** With the target effect set to zero, rejection rates must sit near alpha (e.g., between .04 and .06 at α = .05 with enough replications).

| Design | Benchmark source to transcribe | Test type |
| --- | --- | --- |
| Basic tests | G\*Power 3.1 / `pwr` outputs; Spower's G\*Power subroutines | Analytic |
| 2x2 between and mixed ANOVA | [Superpower paper](https://journals.sagepub.com/doi/10.1177/2515245920951503) and Superpower book examples | Published, direct call |
| 2x2 interaction shapes | Sommet, Weissman, Cheutin & Elliot (2023), AMPPS, Table 2 (primary) | Published |
| Regression interactions | [InteractionPoweR tutorial](https://www.psychologicalscience.org/journals/ampps/25152459231187531/) examples (analytic and simulated) | Published, direct call |
| Simple, parallel, serial mediation | Schoemann, Boulton & Short (2017) examples; pwrss `power.z.mediation` | Published, direct call |
| Moderated mediation | [power4mome vignettes](https://sfcheung.r-universe.dev/power4mome/doc/power4mome.html); Donnelly, Jorgensen et al. (2023), Behavior Research Methods, 55(7), 3892–3909, doi:10.3758/s13428-022-01996-0 | Published, direct call |
| All designs | Effect set to zero | Type I error |

**Tolerance rule:** a test passes if the published value lies inside the 99.9% Monte Carlo interval of your estimate. (At 95%, a correct engine would fail roughly one test in twenty by chance, so a suite of fifty would almost never be all green.) Run validation tests at 10,000 replications, not on every commit: a fast subset nightly on CI, and the full set on demand before merges and releases, on the maintainer's machine, with `scripts/run-validation.R` (the mediation tests alone take about a day of CPU time). That count keeps a real error of .03 in power failing even at the wider interval: at power .5 the interval half-width is about .016 against a published value and .023 between two simulations (direct-call tests).

**Open items**

- Simulation versions of the 2x2 ANOVA Type I error tests. The current ones use the exact method (`ANOVA_exact()`), so they give exactly .05 by construction: they confirm powerkit translates "no effect" correctly but are not an empirical check of the simulation's Type I error rate (`docs/validation-log.md`, 14 October 2026).

Full validation runs are recorded in `docs/validation-log.md`.

**Bonus:** these tests, plus a comparison table, are most of a validation paper for *Behavior Research Methods* or *AMPPS*.

## 7. Front end and outputs

The Shiny app is a four-screen flow: Choose → Specify → Confirm → Results. Mock these up in Claude Design first and show them to a few PhD students before building.

**Screens**

1. **Choose a design.** Plain-language cards ("Two conditions crossed with two conditions", "X affects Y through M", "…and that depends on W"), plus "Build my own model" and, later, "Describe it in words".
2. **Specify.** The design's short form, with an effect-size helper that converts reported t, F, r or means/SDs, and a required justification picker (smallest effect of interest, meta-analysis, prior study with bias correction, pilot with warning).
3. **Confirm.** The model drawn as a path diagram or interaction plot, the equations, and hypotheses in plain words using the user's labels. Nothing runs until the user confirms.
4. **Results.** Required n, power curve, sensitivity curve, check-run table, warnings in plain English, and the export buttons.

**Design finder (the simple route)**

For users who don't know what design they have, the Choose screen offers a guided question tree. It is deterministic (no AI), each question is answered by clicking a plain-language card with a small picture, and every answer can be changed later.

1. **What do you want to show?** A difference between groups or conditions · A relationship between variables · An effect that works through something else (mediation) · An effect that depends on something else (moderation) · Both of the last two · That an effect is absent or negligible (equivalence) · That a model or scale fits.
2. **What is your outcome like?** A score or scale · Yes/no · A count · A rating on a few points (Likert).
3. **Who gives the data?** Different people per condition · The same people in every condition · People respond to many items or stimuli · People nested in groups (classes, teams) · The same people over time.
4. **Design details,** asked only when needed: number of factors and levels; whether the moderator is a category or a continuous score; for a 2x2, which picture matches your prediction (lines cross, one effect shrinks, one effect disappears).
5. **Shortcut:** "I already know my analysis" jumps straight to a form, e.g., "PROCESS Model 7" or "2x2 mixed ANOVA".

The finder ends on one design form, shows the path taken ("Different people · score outcome · effect depends on W"), and names the analysis in standard terms so users learn the vocabulary. "Not sure" is always an option and opens a short explanation with an example from psychology. The optional AI assistant can fill in the same answers from a typed description, but the tree works without it.

**Exports**

| Export | Contents |
| --- | --- |
| Methods paragraph | APA style; design, effect size and justification, alpha, target power, method and replications, n, software and versions; editable before copy |
| R script | Standalone script that calls the backend package directly, with seed and `sessionInfo()`; runs without your tool |
| Spec file | The JSON spec, re-uploadable to reproduce the run |
| Citations | APA and BibTeX for the method and packages, from the curated `refs.bib` only |
| Preregistration text | Sample size section for OSF or AsPredicted |
| Report PDF | All of the above plus plots, with the spec hash |

**UX rules:** form-first, chat optional; plain English, no error codes; every number shown with its uncertainty; runs over a few seconds show progress and can be left running.

## 8. Build plan for Claude Code

Work in small phases, each ending with passing tests. Give Claude Code this guide and the CLAUDE.md below, then one phase prompt at a time.

| Phase | Goal | Done when |
| --- | --- | --- |
| 0. Set-up | Repo, renv, package skeleton, CI; email the Spower and power4mome authors | CI runs an empty test suite |
| 1. Spec + tests | JSON schema, spec validator, all MVP validation tests written (failing) | Tests exist and fail for the right reason |
| 2. First backend | 2x2 between and mixed via Superpower/Spower; sample size search; result object | 2x2 tests pass, Type I check passes |
| 3. Mediation backends | Models 4, 6, 7, 14 and regression interactions via power4mome / InteractionPoweR | All MVP validation tests pass |
| 3b. Binary X and W | A yes/no (binary) X or W in regression interactions and mediation (see below) | Its validation tests pass |
| 4. Exports | Script export, write-up, citations, prereg text | Exported scripts rerun and match in a clean R session |
| 5. Shiny app | Four-screen flow for MVP designs | Five PhD students complete a task unaided |
| 6. v2 designs | Equivalence, GLMs, mixed-effects, AIPE | Their validation tests pass |
| 7. AI assistant | Words/diagram → suggested spec, user confirms | Suggestions never bypass the confirm screen |
| 8. Hosting | Public deploy with queue and limits | Stable under 20 concurrent runs |

**Next phase (not started, no code yet): binary X and W**

*Timing (maintainer's decision, `docs/decisions.md`, 15 October 2026):* this phase comes next, after phase 3 closes and before phase 4, because phase 4's methods paragraphs and scripts need to cover binary variables.

Section 2 lists continuous × binary interactions as MVP, and the example PROCESS model 7 spec in section 4 has a binary X, but the engine refuses a binary X or W in regression interactions and mediation designs ("not available yet"; treating the variable as continuous may give an inaccurate power estimate). This phase would add them, in three steps, each reviewed before the next.

*a. Check backend support first (findings from the package sources, October 2026).*

- **InteractionPoweR 0.2.4** makes a variable binary with `k.x1 = 2` / `k.x2 = 2` in `power_interaction()` and `generate_interaction()` (simulation only). It draws a normal variable, splits it into two equal groups and standardises the result; with `adjust.correlations = TRUE` (the default) the input correlations are adjusted so the observed binary data have the specified correlations. The group split is fixed at 50/50 (no option for unequal groups). The analytic `power_interaction_r2()` is documented as valid only for continuous, normally distributed variables, so it can't give the power for a binary X or W; powerkit uses it only to bracket N before simulating, and that use would need checking for binary variables.
- **power4mome 0.2.1: backend convention.** power4mome supports a binary X or W through `power4test()`'s `x_fun` argument with `rbinary_rs()`: a 0/1 variable (probability `p1` of a 1) rescaled to population mean 0 and SD 1, so effects in `pop_es` are fully standardised. This is the convention powerkit follows for mediation and moderated mediation. Limits from its documentation: a variable generated with `x_fun` must have zero covariance with the other exogenous variables, and `x_fun` on an endogenous variable sets its error term, so a binary M or Y is not covered. manymome's conditional effects accept a dichotomous moderator. Remaining questions for Shu Fai Cheung (they don't block the convention):
  1. Is there a supported way to have a binary X correlated with W (for example, a non-randomised group variable)?
  2. Has power4mome's Monte Carlo CI test been checked with a binary X?

*b. Decisions (the maintainer's, `docs/decisions.md`, 15 October 2026).*

- **Effect sizes.** v1 uses fully standardised paths, following both backends: InteractionPoweR standardises binary variables after the split, and power4mome's `rbinary_rs()` rescales a 0/1 variable to mean 0 and SD 1. A "standardised path" from a 0/1 X therefore means per SD of X. Entering a condition effect as Cohen's d (Y standardised, X left as 0/1) comes later. It will be a departure, so it goes in `docs/conventions.md` with a test showing the size of any difference, is shown on the results screen and is stated in the methods paragraph.
- **Group split.** 50/50 by default. Unequal groups are offered only where the backend supports them (power4mome, through `rbinary_rs()`'s `p1`). Interactions are always 50/50, because InteractionPoweR has no option for unequal groups, and the app says so.
- **Correlated predictors.** power4mome requires a binary X or W (generated with `x_fun`) to be uncorrelated with the other predictors. That fits a randomised condition. A binary W correlated with X isn't supported, and the user is told so plainly instead of being given an approximation.

*c. Validation targets.*

- Direct-call agreement: powerkit against `power_interaction()` with `k.x1` / `k.x2`, and against `power4test()` with `x_fun = list(x = list(rbinary_rs, p1 = ...))`.
- Type I error with a binary X or W.
- Published: Donnelly, Jorgensen & Rudolph (2023), Behavior Research Methods, 55(7), 3892–3909, doi:10.3758/s13428-022-01996-0. Its X and W are binary. It reports power for a conditional indirect effect, at a level of W it doesn't state, not for the index of moderated mediation, and has no model 14 example, so it fits only if powerkit also offers conditional indirect effects as a target and the level of W can be recovered.
- Published, interactions: an InteractionPoweR example with a binary variable, if the tutorial or package articles have one (to find).
- Agreement between powerkit's binary-W interaction and its 2x2 ANOVA when both X and W are binary, as a cross-check between backends.

Done when the remaining questions to Shu Fai Cheung are answered or set aside, and these tests pass. (The effect-size convention and the group split are decided; see b.)

**Example phase prompt (phase 2)**

```
Read docs/build-guide.md sections 4–6 and CLAUDE.md.
Implement the 2x2 between-subjects and 2x2 mixed designs:
1. Add their schema entries to inst/schema/design.schema.json.
2. Write backends/superpower.R mapping a validated spec to Superpower calls.
3. Implement search_n() returning the standard result object.
Do not change any test expectations in tests/testthat/. If a test fails,
report why instead of editing the test. Run the full test suite before finishing.
```

**Starter CLAUDE.md**

```markdown
# powerkit — project rules

## What this is
A unified power analysis tool for psychology. One spec format, routed to
validated R backends (Spower, power4mome, Superpower, InteractionPoweR).
See docs/build-guide.md.

## Non-negotiables
- Never write new statistical maths when a backend package does it; adapt the spec.
- Never edit expected values in tests/testthat/validation-*. They are
  transcribed from published sources by the maintainer. Report failures.
- Every result records spec hash, seed, backend, R + package versions.
- The Shiny app never computes power; it builds specs and calls the engine.
- Citations come only from inst/citations/refs.bib. Never invent references.
- Plain-English errors for users; no stack traces in the UI.

## Conventions
- R package with roxygen2 docs, testthat 3e, renv for versions.
- tidyverse style guide; functions small and pure where possible.
- Validation tests at high nrep are tagged and run nightly (a fast subset) or on demand (the full set), not per commit.

## Before finishing any task
- Run devtools::test() and devtools::check(); both must pass.
- Update NEWS.md with user-visible changes.
```

## Sources

- [Spower on CRAN](https://cran.r-project.org/web/packages/Spower/index.html) and [Chalmers (2025), Behavior Research Methods](https://link.springer.com/article/10.3758/s13428-025-02787-z)
- [power4mome on CRAN](https://cloud.r-project.org/web/packages/power4mome/index.html) and [vignette](https://sfcheung.r-universe.dev/power4mome/doc/power4mome.html)
- [pwrss mediation function](https://www.rdocumentation.org/packages/pwrss/versions/1.3.1/topics/power.z.mediation)
- [Superpower, Lakens & Caldwell (2021)](https://journals.sagepub.com/doi/10.1177/2515245920951503)
- [InteractionPoweR tutorial, AMPPS](https://www.psychologicalscience.org/journals/ampps/25152459231187531/)
- [pwrSEM, Wang & Rhemtulla (2021)](https://journals.sagepub.com/doi/10.1177/2515245920918253)
- [PowerAnalysisIL, KU Leuven](https://ppw.kuleuven.be/okp/software/poweranalysisil/)
- [LeBeau (2026), Simulation and Power Analysis Using R](https://iro.uiowa.edu/esploro/outputs/book/Simulation-and-Power-Analysis-Using-R/9985180977902771)
