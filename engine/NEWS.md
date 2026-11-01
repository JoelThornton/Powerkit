# powerkit 0.27.0

A batch of new features, built as one round.

* Minimum-effect tests on the one-sample, paired and two-group t-tests
  (`target_test > method` "minimum_effect", with the smallest effect of
  interest in `population > margin`, or `population > raw > margin` in the
  outcome's own units): the effect shown to be larger than the margin, by
  pwrss's `power.t.student()` with the margin on the effect's side
  (one-sided, or outside both margins for a two-sided hypothesis). Power,
  sample size and the smallest detectable effect (pwrss's own solution);
  the exported script reproduces each. pwrss's test treats the margin as a
  value in SD units; a margin fixed in the outcome's units, tested with a
  shifted central t, gives very slightly more power (Known difference 10).
  The smallest detectable d for 57 per group and a margin of 0.2 is
  0.6735; the 0.681 a calculation by hand gives comes from using one
  group's degrees of freedom (56) instead of the test's (112).
* The two-group t-test takes a point-biserial correlation
  (`population > metric` "point_biserial", `population > r`), as G\*Power's
  point-biserial model does: d is worked out from r and the planned share
  in group 2, which gives the model's power at any allocation (G\*Power's
  example, r = .25 one-sided with power .95, needs 164). The smallest
  detectable effect is also given as r.
* An independent t-test with unequal groups started its sample-size search
  below two people in the smaller group (for example four in all at 1 : 3),
  which pwr refuses; the smallest n now keeps two in each group.
* Participants and items in three or more conditions (E63, design
  `mixed_model`, template `crossed_conditions`): every participant in
  every condition, a mean per condition, the SDs of participants'
  averages, of their condition effects (one shared by every condition,
  `(1 | participant:cond)`), of items' averages and of the residual, and
  the items split equally between the conditions or (with an optional
  item-by-condition SD) in every condition. Simulated with simr's
  `powerSim()`, testing that the conditions differ with lmerTest's
  Satterthwaite F test (`target_test > effect` "condition"), or one pair
  (`effect` "pairwise", `comparison`) with its Satterthwaite t test
  adjusted for all the pairs by `stats::p.adjust()` (`p_adjust`, Holm by
  default, as on the one-way ANOVA cards). The check run, exported
  script and simulated data set follow the design. Agrees with a
  simulation written separately without simr, with the Type I error near
  alpha; published value to come. Reached from the design finder's
  question on many trials or stimuli.
* Participants and items in three or more conditions (E63) may have the
  conditions between participants (`variables > X > type`
  "between_factor"): the participants split equally between the
  conditions, each with a random intercept only
  (`sd_participant_condition` doesn't apply), every participant
  responding to every item or to their condition's own block of items.
  The check run allows for the residual noise in each group's estimate
  when it checks an SD. Checked against a simulation written separately,
  with the Type I error near alpha.
* A yes/no outcome on each trial (correct or not) for participants and
  items (E33 and E63, `variables > Y > type` "binary", `population >
  metric` "probability"): each condition's chance of "yes" for a typical
  participant and item (`population > probabilities`), every SD on the
  log-odds scale and no residual SD, simulated as a logistic mixed model
  (simr's `makeGlmer()`, lme4's `glmer()`). The test is the Wald test
  (`target_test > method` "wald": glmer's z test for two conditions,
  simr's Wald chi-square through car for three or more, car's
  `linearHypothesis()` for a pair) or the likelihood-ratio test
  ("likelihood_ratio"; for a pair, against the model in which that pair
  shares a mean). The app's default is the Wald test for two
  conditions and the likelihood-ratio test for three or more, simr's
  default for a factor: there, with no difference, the Wald chi-square
  test rejected 6.2% of 2,000 simulated studies at alpha .05 and the
  likelihood ratio 5.65%. New dependency: car (already installed with
  simr).
  Checked against a simulation written separately with glmer, with the
  Type I error near alpha. The design finder's question on many trials
  or stimuli takes yes/no outcomes to these cards.
* Three levels (E64, design `mixed_model`, template `three_level`):
  people in groups in larger groups (pupils in classes in schools), with
  two conditions assigned to whole sites, to groups within each site or
  to people within each group (`population > assignment`). The inputs
  are Cohen's d over the outcome's total SD, the sites' and groups'
  shares of the variance (`icc_site`, `icc_group`), how much the effect
  varies across sites or groups where it can (`icc_effect_site`,
  `icc_effect_group`), the group size and the groups per site; n is a
  whole number of sites. Simulated with simr on y ~ cond + (1 | site) +
  (1 | site:group) (with the condition's random effects where they
  apply), tested by Satterthwaite's t test (Departure 16). Agrees with a
  simulation written separately, with the Type I error near alpha;
  published value to come. The design finder asks whether the groups
  are part of larger groups (C2).

# powerkit 0.26.0

Fixes from a review of 0.25.0, and its follow-ups.

* The variance tests of one and two groups are computed exactly, from the
  chi-square and F distributions the G*Power 3.1 manual gives (sections
  26.5 and 15.5), with base R's `pchisq()` and `pf()`
  (`backend-variance.R`), instead of simulated: they give the manual's
  examples exactly (N = 81 and 103; 193 per group, power 0.800105) and
  agree with Spower's simulation, which stays available with
  `options > method` "simulation". Known difference 4 is retired. The
  formula takes an allocation ratio for two groups (the simulation still
  can't). The exported script reproduces the result with base R alone.
* Hotelling's T-squared is computed exactly, by its noncentral F
  distribution (Anderson, 2003, *An Introduction to Multivariate
  Statistical Analysis*, 3rd ed., sections 5.3.4 and 5.4), with base R's
  `pf()` (`backend-hotelling.R`), instead of simulated: for one group
  against fixed values (E60; p and N - p df, noncentrality N times the
  squared Mahalanobis distance) and for a MANOVA of two groups (E59;
  p and N - p - 1 df, noncentrality N1 N2 / N times the distance). It
  gives the same power as pwrss's noncentral F tests and agrees with
  Spower's simulation, which stays available with `options > method`
  "simulation". Known difference 8 now applies only to MANOVA with three
  or more groups.
* Project rule: where no package has a formula, a closed-form result from a
  published source may be written in the engine, cited and checked against
  simulation (`CLAUDE.md`); where a method is clearly better, it becomes the
  default and the conventional one stays an option.
* Repeated-measures and mixed ANOVA from a *published* partial
  eta-squared (as SPSS, R and JASP report it) gave too little power, and
  too large a sample size, when a within factor has three or more levels:
  pwrss's `power.f.mixed.anova(rho.within = NA)` takes the noncentrality
  as f-squared times N, but a published value needs f-squared times the
  effect's error df, as Superpower's `ANOVA_exact()` and G\*Power's "as in
  SPSS" option use. The engine now rescales the value it passes to pwrss
  (`pwrss_mixed_eta()`), and the exported script does the same. Three
  conditions, means 600/620/650, SD 100, r = .6, 40 people: 60.3% before,
  88.8% now, as `ANOVA_exact()` gives. Two levels were right before and
  are unchanged; the "planned" (G\*Power) route is unchanged.
  `conventions.md` states the rescaling.
* MANOVA (E59) and one-sample Hotelling's T-squared (E60) failed on the
  result screen: `effect_from_units()` now returns NULL for designs other
  than the t-tests and equivalence tests it describes.
* 2 x 2 ANOVA with unequal group sizes (E22): the sample-size search now
  steps by the smallest N that splits into the cells' ratio
  (`cell_ratio_step()`), instead of failing with "non-conformable
  arguments".
* New `runs_simulation(spec)`: whether `run_spec()` would simulate. The app
  uses it to run long simulations (pairwise comparisons, Friedman's and
  Kruskal-Wallis tests, factorial logistic regression, the Hartung-Knapp
  meta-analysis) in the background with a progress bar, rather than
  holding up the app.
* Plain-English messages: choosing partial eta-squared with a test that
  needs means names the test in words, once; the smallest-effect message
  no longer says "goal type"; a backend's error isn't repeated twice.
* App: the meta-analysis result, write-up and ethics version count
  studies, not participants, name the test used (Hartung-Knapp or z) and
  the effect (d or r); F, chi-square and rank tests are no longer called
  "two-sided"; the pair to compare matches group names whatever their
  case; internal notes no longer show in the help; the About page lists
  every backend and no internal codes, and its opening line is current.
* App: the analysis search also finds tests by their other names (rank
  tests, post hoc, ICC, mixed models, HLM and more; `tree.yaml`,
  `search_words`), treats hyphens as spaces and matches one- and
  two-letter words only whole. "I know the terms" becomes an
  "Explanations" switch, on by default, and no longer hides the help
  under each field. The Labs tools are renamed: Methods map, Power
  visualiser and Effect size converter; "Pre-replication notes" keeps
  the term of the paper it comes from (Karhulahti et al., 2025).
* Whole-study simulation (experimental): people measured twice. A
  baseline B (`variables > B`, the outcome's first measurement) predicts
  Y (path `B->Y`), may correlate with W and with a measured X
  (`population > correlations` "X<->B", "W<->B"; 0 for two groups), and
  every analysis adjusts Y for it, as the ANCOVA card (E23) does
  (decided 31 October 2026). In the app's plan this covers the
  comparison when the ANCOVA is chosen, and the moderation and a
  mediation through one mediator measured twice, which have no card of
  their own yet; the mixed ANOVA's group x time test, moderated
  mediation and two mediators measured twice are not yet simulated. The
  check run confirms the baseline's path and correlations, the implied
  values add its correlation with Y, and the methods paragraph says that
  every analysis adjusted for the first measurement.
* Two-way MANOVA: the `manova` template takes a second between factor B
  (one row of means per combination of A and B, A's levels outer) and
  tests either main effect or the interaction (`target_test > effect`)
  with Pillai's trace of `stats::manova(y ~ A * B)`, simulated with
  Spower. The check run recovers every cell's means; the exported script
  and the simulated data set carry both factors. Checked against a
  simulation written separately (fitted in the other order), with the
  Type I error near alpha for each effect. The app's MANOVA card (E59)
  asks whether the groups come from one factor or two.
* Participants and items (E33): the condition may vary between
  participants (`variables > X > type` "between_factor"): half the
  participants in each condition, each with a random intercept only
  (`sd_participant_slope` and `r_participant` don't apply), every
  participant responding to every item (items in both conditions, with
  an optional by-item condition slope) or each condition with its own
  half of the items. n must be even. The check run, exported script and
  simulated data set follow the design; checked against a simulation
  written separately without simr, with the Type I error near alpha.
  The design finder's question on many trials or stimuli offers "each
  person is in one of them".

# powerkit 0.25.0

* Two-level model (E62, design `mixed_model`, template `two_level`):
  people within groups, with a predictor measured on each person (X), one
  measured on each group (W) and their cross-level interaction, fitted
  by simr's `powerSim()` on `y ~ x + w + x:w + (1 + x | group)` and each
  effect tested by lmerTest's Satterthwaite t test (`target_test >
  effect` "within_effect", "between_effect" or
  "cross_level_interaction"). The inputs are each effect per SD of its
  predictor, the SDs of the groups' averages and of their X effects and
  the correlation between them, the residual SD and the group size; n is
  the number of people, a whole number of groups. Agrees with a
  separately written simulation (MASS and lmerTest), with the Type I
  error near alpha; published value to come. App: a new question for
  people within groups (C1) separates conditions given to groups (E34)
  from measured predictors at either level (E62); outcomes other than
  scores still go to E34.
* Whole-study simulation (experimental): X may be two groups or
  conditions (`variables > X > type` "binary", `population > x_prob`, the
  share in the second group, 0.5 by default), drawn by power4mome's
  `rbinary_rs()`. The group comparison is the regression of Y on the
  groups (Student's t test); moderation and mediation with a yes/no X
  are simulated on the same data sets, so a study plan can give joint
  power for a group comparison with a moderation or a mediation on the
  same people. The groups must be uncorrelated with W (power4mome draws
  them on their own), as when people are randomised; the check run
  confirms the share, and the implied values give the comparison's d.
* App: an "I know the terms" setting in the top bar, remembered in the
  viewer's browser, shows the technical names first (on the cards and in
  the list of analyses) and hides the plain-English hints, the help
  under the fields and the "also called" lines; notes, assumptions,
  departures and known differences stay. Plain English stays the default.
* App: "I know my analysis" goes straight to every analysis, in closed
  groups by family (`tree.yaml`, `analysis_families`) with a search box,
  without the screening questions; a test checks every analysis is in
  exactly one group. "Help me choose" keeps the questions.
* Meta-analysis (E61): the random-effects model plans for the
  Hartung-Knapp test by default (`target_test > test` "hartung_knapp";
  Departure 18), simulated with Spower and powerkit's experiment
  `p_meta_hk()`, which fits metafor's `rma(method = "DL", test = "knha")`
  (new dependency, metafor 5.2-1); metapower's z test stays available
  (`test` "z"). It gives less power with few studies: about 16.5% against
  21.4% for d = 0.15 in ten studies of 40 with I-squared 0.5. Checked
  against a separately written simulation of IntHout, Ioannidis and
  Borm's (2014) formulas, with the Type I error near alpha. IntHout et al.
  added to `refs.bib`.
* A planned meta-analysis (E61): design `meta_analysis`, template
  `mean_effect`, through metapower's `mpower()` (new dependency,
  metapower 0.2.2). Power, or the number of studies needed (n is the
  number of studies), for the z test of the average effect under the
  fixed-effect or random-effects model, from Cohen's d or r, the size of a
  typical study and I-squared. Validated against simulated meta-analyses;
  Valentine, Pigott and Rothstein's (2010) worked examples are ready to
  transcribe. metapower's rounding of Fisher's z for r is Known
  difference 9 (up to about 1.3 points); its power for the heterogeneity
  test disagrees with simulation and isn't used
  (`docs/upstream/metapower-homogeneity.R`). Jackson and Turner (2017) and
  Valentine et al. (2010) added to `refs.bib`.
* Cohen's w, as G*Power takes it, for the chi-square tests: `population >
  metric` "w" with `population > w` on `chi_square_independence` (pwr's
  `pwr.chisq.test()`) and `chi_square_gof` (pwrss's `power.chisq.gof()`),
  the degrees of freedom from the numbers of levels. Power, sample size
  and the smallest detectable w all work; the check run confirms w and the
  df, and the exported scripts reproduce the result. A simulation needs
  the proportions, so it is refused with w in plain words, and there is no
  simulated data set. The same table gives the same power from its
  proportions and from its w (a test).
* Partial eta-squared, as G*Power takes it, for the one-way and two-way
  ANCOVA and for three-factor ANOVA with every factor between
  participants: `population > metric` "eta_squared" on `oneway_ancova`,
  `factorial_ancova` and `factorial_three`, run with pwrss's
  `power.f.ancova()` (with `k.covariates` for the ANCOVAs; the covariates'
  R-squared isn't needed, as a published ANCOVA's partial eta-squared
  already allows for them). A published F or Cohen's f converts into it.
  Three factors with a within-participants factor are refused in plain
  words. The check run confirms the error df (N minus the groups minus
  the covariates). From the same population, Shieh's method (the means
  route) and G*Power's (partial eta-squared) differ a little: 81.3%
  against 81.8% in the test example (`docs/conventions.md`, ANCOVA).
* One-way repeated measures without sphericity: `oneway_within` takes an
  SD per condition (`population > sd` as a list) and a correlation per
  pair (`population > r`, the upper triangle row by row), passed to
  Superpower's `ANOVA_design()`, and `target_test > correction` ("none",
  the default as in Superpower, "GG" or "HF"), passed to `ANOVA_exact()`
  and `ANOVA_power()`. Impossible correlation matrices are refused in
  plain words. With unequal correlations a Greenhouse-Geisser correction
  can cost several points of power (56.1% against 47.6% in the test
  example). The app's E54 asks whether the SD and correlation are the same
  in every condition, and the write-up names the correction.
* `power_picture()`: for a two-group t-test, the central and noncentral t
  densities (`stats::dt()`) with the critical t, pwr's power, beta, the
  df, the noncentrality and the smallest significant d (critical t times
  sqrt(1 / n1 + 1 / n2), Lakens, 2013). The app's Labs draws it as "A
  picture of power".
* Simulated data sets for MANOVA and one-sample Hotelling's T-squared
  (the multivariate normal scores the simulation draws) and the one-way
  ANCOVA (one standard normal covariate carrying all of the covariates'
  R-squared, the outcome with the unadjusted SD within each group). New
  `simulated_data_note()` says what a data set chooses that the plan
  leaves open; the app shows it under the download.
* Friedman's test: `target_test > method` "friedman" on `oneway_within`,
  with `population > score_shape` (normal, skewed or heavy-tailed).
  Simulated with Spower and powerkit's own experiment, `p_friedman()`
  (`stats::friedman.test()`), on scores that are each condition's mean, the
  person's own level and a deviation of the chosen shape, so the
  correlation between conditions is r (at least 0). Checked against a
  simulation written separately with `MASS::mvrnorm()`; Type I error near
  alpha for every shape. The app offers it on E54, whose card no longer
  says the ANOVA figure only approximates it.
* Spearman's rho and Kendall's tau on skewed or heavy-tailed scores:
  `population > score_shape` on the correlation template, drawn by
  powerkit's `shaped_pair_scores()` and passed to Spower's `p_r()` as its
  generator; normal scores keep Spower's own. The app's write-up now names
  the rank correlation (it said "a Pearson correlation"), and neither the
  formula's departures nor the formula-based explore panel are shown for
  it.
* Pairwise comparisons after a one-way ANOVA: `target_test > effect`
  "pairwise" with `method` "t_test" on `oneway_between` and
  `oneway_within`, `comparison` (the two levels whose difference is
  tested) and `p_adjust` ("holm", the default, "bonferroni" or "none").
  Simulated with Superpower's `ANOVA_power(p_adjust =)`, which adjusts the
  p-values of all the pairwise t-tests together; the power is the chosen
  pair's (`pc_results`). Bonferroni's power matches `stats::power.t.test()`
  at alpha / m. Departure 17: Holm's adjustment by default where
  Superpower adjusts none. The app offers it as a test version on E18 and
  E54.
* One-sample Hotelling's T-squared: template `basic_test/hotelling_one`
  (one group, two to nine outcomes `Y1` to `Y9`) with `population > means`,
  `mu0` (the fixed values), `sds` and `r`, `target_test > method`
  "hotelling_t2". Simulated with Spower and powerkit's own experiment,
  `p_hotelling_one()`: multivariate normal scores, and the test of the
  intercept of `lm(scores - mu0 ~ 1)` (`stats::anova()`, exact with one
  group). Matches the exact noncentral F test (0.620 against 0.6195 at
  N = 40 for the example). Known difference 8 now covers it. The app's
  card is E60, reached from F2.

# powerkit 0.24.1

* Effect-size conversion: a t statistic, or an F with one numerator df,
  is converted into Cohen's d or d_z by psych's `t2d()`, the exact
  relation (d = t / sqrt(n) for one group or pairs, t sqrt(1 / n1 + 1 / n2)
  for two groups; Lakens, 2013, now in `refs.bib`), instead of effectsize's `t_to_d()` and `F_to_d()`, which
  divide by the error df and assume equal groups (`conventions.md`,
  "Effect-size conversion": 2.6% larger d for one group of 20, 11% smaller
  for groups of 10 and 30). `conversion > n1` and `n2` now enter a t or F
  conversion, and are refused when only one is given, for a design with one
  group, or with more error df than n1 + n2 - 2. The provenance and the
  citations name the package that converted (psych, or effectsize for r, d
  and odds ratios); psych is now cited whenever it ran, safeguard power
  included. A spec saved with 0.24.0's conversion keeps its value, and
  `effect_conversion$earlier` says so.
* `reproduce_project()` runs a simulation on the number of cores the
  project records (`provenance > cores`, now saved): Spower, simr and
  InteractionPoweR draw one random stream per core, so the same seed gave
  another answer on another number of cores, and a saved project failed to
  reproduce. A file saved before this says why a simulated result may
  differ.
* The app: the two-group t-test card and Labs' "Plan from a published
  result" take the published group sizes for a conversion; the result and
  the write-up name the package that converted. The MANOVA card says why it
  asks for means rather than an effect size. An unexpected engine fault on
  the input screen, the whole-study plan or Labs now gives a plain message
  instead of R's own.
* `man/` regenerated with roxygen2 8.1.1; three pages had fallen behind
  their sources.
* Repository: the app's suite runs on GitHub as two jobs side by side
  (`test-results.R`, and the rest). `scripts/setup-cloud-session.sh` writes
  the shell settings R needs to `~/.powerkit-env.sh`, sourced from the
  first line of `~/.bashrc`, where non-interactive shells read it too;
  `CLAUDE.md` gives test and check commands that work without devtools.
  `docs/status.md` is again a short current-state page with item numbers
  that match `next.md`; `adding-a-test.md`'s old queue is gone.
* Tests: the mixed-model tests share one simulation instead of running
  three (about half that file's time).

# powerkit 0.24.0

* One-way MANOVA: template `basic_test/manova` (two or more groups, two to
  nine outcomes named `Y1` to `Y9`) with `population > means` (one row per
  group), `sds` (one per outcome) and `r` (between every pair of outcomes),
  tested with Pillai's trace (`target_test > method` "pillai_trace"; with
  two groups, Hotelling's T-squared). Simulated with Spower and powerkit's
  own experiment, `p_manova()` (multivariate normal scores from
  SimDesign's `rmvnorm()`, `stats::manova()`); SimDesign is a new import.
  Exported scripts carry the experiment. Known difference 8.
* `joint_power()`: the chance that every one of several outcomes of the
  same randomised comparison is significant, with PUMP's `pump_power()`
  (designs `d1.1_m1c` for independent t-tests and `d2.2_m2rc` for
  cluster-randomised trials), given each outcome's effect, one correlation
  between the outcomes and the study's N. PUMP is a new import (1.0.5, in
  `renv.lock` with the packages it needs). The app's study plan offers it.
* `refs.bib` adds the four sources of the app's new latent profile and
  latent class guidance card: Tein, Coxe and Cham (2013), Nylund,
  Asparouhov and Muthén (2007), Nylund-Gibson and Choi (2018) and Spurk
  et al. (2020).
* `write_study_plan()` and `read_study_plan()`: several analyses in one
  file (format "powerkit-study-plan"), each stored as a project, so each
  reopens and reproduces on its own with `reproduce_project()`. The app's
  study plan saves and opens through them.
* `refs.bib` adds Brysbaert and Stevens (2018), whose Table 2 (a
  masked-priming lexical-decision study) gives the example values the app
  now shows beside each input of the crossed participants-and-items model.
* Moderation by its R-squared change: template `two_way` takes
  `population > metric` "r2_change" with `r2_change` (the R-squared the
  product term adds) and optional `r2_main` (X and W's R-squared, 0 if not
  given), instead of InteractionPoweR's correlations. Power from pwrss's
  `power.f.regression()` with Cohen's f^2 = R2_change / (1 - R2_full), the
  fixed-model test G*Power uses; slightly above InteractionPoweR's own
  formula (Known difference 7, sized in `conventions.md`). Reliability and
  yes/no X or W still need the correlations, and say so; no simulated data
  set. The moderation input screen asks how the interaction is given.
* Repeated-measures and mixed ANOVA by effect size: templates
  `oneway_within`, `2x2_mixed` and `mixed` take `population > metric`
  "eta_squared" with `eta_squared` and `eta_source`: "published" (as a
  repeated-measures ANOVA reports it, already reflecting the correlation
  between measurements) or "planned" (G*Power's default, with the
  correlation in `population > r`). Power from pwrss's
  `power.f.mixed.anova()` (`rho.within = NA` for the published kind;
  sphericity assumed). A published F converts only into the published
  kind. The app's input screens ask which kind it is, required, with no
  default. Validation placeholder for the G*Power manual's repeated-measures
  example (`test-validation-anova-eta.R`).
* App, Labs: "Plan from a published result" takes an effect as a paper
  reported it (a t or F statistic, r, d, an odds ratio or f, or the
  effect size itself, for two groups, paired data, one group, a
  correlation or a between-participants ANOVA) and shows the converted
  effect size (`convert_effect()`) and the safeguard effect size
  (`safeguard_effect()`, for the t-tests and the correlation), with a note
  that published effects tend to be too large. The app only calls the
  engine.
* Between-participants ANOVA by its effect size: templates
  `oneway_between`, `2x2_between` and `factorial_between` take
  `population > metric` "eta_squared" with `population > eta_squared`, the
  partial eta-squared of the effect tested (for one factor, its
  eta-squared), as G*Power takes it, instead of group means. Power comes
  from pwrss's `power.f.ancova()` (no covariates, equal groups, the ANOVA F
  test; Welch's F, rank tests and unequal cells still need means, and say
  so). `convert_effect()` also turns a published F (with both dfs, new
  `conversion > df`) or Cohen's f into it. The check run confirms pwrss's
  df and its f^2 (noncentrality / N); the R script reproduces the result;
  no simulated data set (there are no means to draw from); the smallest
  detectable effect isn't available on this route yet. The app's one-way,
  2 x 2 and factorial input screens offer "An effect size: partial
  eta-squared, as in G*Power" beside the means. Validation placeholders in
  `test-validation-anova-eta.R` (anova chunk).
* Effect-size conversion: `effect_justification > conversion` gives the
  effect as published in another form (`from`: "t", "F" with one
  numerator df, "r", "d" or "odds_ratio"; `value`; `df_error` for t and F;
  optional `n1`, `n2` for r and d with unequal groups), instead of the
  population effect. `validate_spec()` converts it with the effectsize
  package before the schema is checked, puts the result in the population
  (d for the one-sample and independent t-tests, d_z for the paired t-test,
  r for the correlation) and records it as `conversion > result`; it then
  feeds safeguard power if that is asked for. New exported
  `convert_effect()`. The result gains `effect_conversion` (the published
  value, the converted effect and the effectsize call), the provenance and
  the citations export list effectsize, and the app's input screens for
  those four cards ask "Is your effect size published in another form?",
  with the conversion shown beside the result and in the write-up.
  effectsize 1.0.3 and its dependencies (bayestestR, datawizard, insight,
  parameters, performance) are added to `renv.lock`, with insight 1.6.0:
  1.7.0, released the same day, was not yet on the package server CI uses.

# powerkit 0.23.0

* Participants responding to many items in two conditions (E33): design
  `mixed_model`, template `crossed_two_condition`. The condition varies
  within participants; items are in one condition each (`item_design`
  "between", the default) or in both ("within", with an optional by-item
  slope). Inputs in the outcome's units: the difference, the SDs of
  participants' intercepts and slopes (and their correlation), of items'
  intercepts and of the residual, and the number of items; `goal$n` is the
  number of participants. Simulated with simr's `powerSim()` on a
  `makeLmer()` model, the condition tested with lmerTest's Satterthwaite t
  test (`fixed("cond", "sa")`, Departure 16, not simr's default `"z"`). The
  check run refits a large simulated data set and recovers every value;
  exported scripts call simr alone; the simulated data set is long (one
  row per trial). New dependencies: simr and lmerTest (and lme4,
  already installed). In the app, the E33 card calculates (power in the
  app, the number of participants from the R script), reached through a
  new question after "Many trials or stimuli per person".
* Mediation with a yes/no X (E16): templates `process_4` and `process_6`
  take a binary X, drawn by power4mome's `rbinary_rs()` with
  `population$x_prob`, the share in X's second level (0.5 if omitted), and
  rescaled to SD 1, so the paths stay standardised. The check run recovers
  the split; exported scripts pass `x_fun`; simulated data show X as its
  level names. `implied_group_difference()` now returns one entry per
  difference and covers each mediator that X alone predicts (the general
  relation for an unequal split, `psych::r2d()` for equal groups). In the
  app, the E16 card calculates (one mediator), and the parallel and serial
  mediation screens ask whether X is a score or two groups.
* Moderated regression with a yes/no X or W (E15): template `two_way`
  takes a binary X or W, simulated with InteractionPoweR's
  `power_interaction(k.x1 or k.x2 = 2)` (a 50/50 split; the yes/no
  variable's correlations are those of the observed 0/1 data). A
  reliability for the yes/no variable is refused; both variables yes/no
  is pointed to the 2 x 2 ANOVA; sensitivity analysis isn't offered (the
  fixed-model formula assumes continuous variables, and is used only to
  bracket the sample-size search). New `implied_group_difference()`: the
  difference between the groups that the yes/no variable's correlation
  with Y implies (`psych::r2d()`). Exported scripts and simulated data
  use the two-level variable. In the app, the E15 card calculates.
* Simulated data sets for planned contrasts (Spower's `gen_anova.test()`
  with equal SDs), logistic and Poisson regression with one predictor
  (X standardised or a yes/no group, Y from the model pwrss's formulas
  assume; only without other predictors) and cluster trials with a score
  outcome (cluster-randomised and group treatment: a random intercept per
  group with variance `icc`, total SD 1; a `cluster` column numbers the
  groups). Multisite trials, yes/no cluster outcomes and a baseline
  covariate aren't covered yet.
* Simulated data sets for more designs: the rank tests (scores of the
  chosen shape, shifted by the effect), equivalence and non-inferiority
  tests (drawn as the t-test, two proportions or correlation they test),
  one proportion, goodness of fit, two independent and two dependent
  correlations (Spower's `gen_r()` and `gen_2r()`), factorial logistic
  regression (each cell's 'yes' with its proportion) and ordinal outcomes
  in two groups (group 2's shares from `Hmisc::pomodm()`). McNemar's test
  isn't covered: its spec gives only the discordant proportions.
* Unequal group sizes in a 2 x 2 between-participants ANOVA:
  `options$cell_ratio`, the relative size of each cell (two rows of two
  positive whole numbers), for template `2x2_between`. `goal$n` is split
  in that ratio and must give whole cells. Power is simulated with
  Superpower's `ANOVA_power()` and one n per cell (Type III sums of
  squares); the exact method and sensitivity analysis are refused, since
  `ANOVA_exact()` takes equal cells only, and `cell_ratio` is refused for
  any other template. Checked against pwrss's `power.f.ancova.shieh()`
  with one covariate that explains nothing. Recruitment, exported scripts
  and the simulated data download use the unequal cells. In the app, the
  unequal-groups card (E22) now calculates; a mixed design with unequal
  groups goes to the safety net.
* Technical details: `run_spec()` results have `details`, the test's
  statistic, degrees of freedom, critical value(s) and noncentrality at
  the n analysed, read from the backend package's own output (pwrss's
  `df`, `ncp` and `t.alpha` / `f.alpha` / `z.alpha` / `chisq.alpha`;
  for z tests, the mean of z under the alternative; for the exact test of
  one proportion, its critical counts and actual alpha). pwr returns
  none, so for Student's t-tests, the two-proportions z test and the
  chi-square test of independence pwrss's own version of the same test
  supplies them, only when its power equals pwr's. Superpower's exact
  ANOVAs give df (the ANOVA table) and noncentrality (`main_results`),
  with the critical F from `stats::qf()`, kept only if they reproduce
  Superpower's power. `NULL` for simulated results, sensitivity analyses
  and backends that don't report them. In the app, a folded section
  "Technical details (for checking against G*Power or R)" under "How it
  was calculated" shows them, or says why they aren't given.
* A simulated required sample size now reports the power reached there:
  `n_required$power`, with `power_lower` and `power_upper`, the fitted
  probit curve's power at the required n and its 95% interval. The app
  shows it under the result, as it already did for exact results.
* Factorial logistic regression: template `factorial` for design
  `logistic_regression` (A and B between-participants factors, a yes/no
  Y, and `population$probabilities`, the proportion of 'yes' in each
  cell, one row per level of A; `target_test$method` `"wald_chi_square"`
  and `effect` one main effect or the interaction). Simulated with
  Spower's `p_glm(family = binomial())`: the logistic model with both
  factors and their interaction in effect (sum-to-zero) coding, its
  coefficients solved so that every cell's proportion is reproduced
  exactly, and the Wald test of the effect's coefficients through
  `car::lht()`. Equal cells. The check run recovers every cell's
  proportion; exported scripts call Spower alone. In the app, the
  factorial logistic regression card now calculates.
* Ordinal outcomes in two groups: design `ordinal_regression`, template
  `ordinal_two_groups` (X, the two groups; Y, categorical with its levels
  in order; `population$probabilities`, group 1's share in each
  category, and `population$odds_ratio`, group 2 against group 1 under
  proportional odds). Power is powertools' `propodds()` (Whitehead's
  method, two-sided), which matches Hmisc's `popower()`; an odds ratio
  below 1 is passed as its reciprocal, which gives the same power. Groups
  may differ in size (`options$allocation_ratio`). Shares that don't
  match the categories or don't add up to 1 are refused in plain
  English. In the app, the ordinal outcome card now calculates.
* Moderated mediation with parallel mediators: templates `process_7` and
  `process_14` take mediators M1, M2, ... as well as a single M, with
  `population$residual_correlations` between them and
  `target_test$path` (`"X->Mk->Y"`) naming the mediator whose index of
  moderated mediation is tested. In model 14 the product of Mk and W is
  `MkW`. power4mome fits every mediator's equation and the residual
  covariance; in a model with a product term power4mome reads that value
  as the residual correlation (checked by simulation), so it is passed
  as given. The check run recovers every path and the residual
  correlation. In the app, the moderated mediation card for several
  mediators calculates (a preview, then an R script), with the link W
  changes chosen on its input screen; the guided route sends a moderator
  of three or more groups to the "no end point" note rather than to that
  card.
* Three-way regression interactions: template `three_way` for design
  `regression_interaction` (variables X, W, Z and Y; the correlations of
  X, W, Z and the products XW, XZ and WZ with Y, the correlations among
  X, W and Z, optional reliabilities, and `population$b_XWZ`, the
  standardised coefficient of the three-way product; `target_test$effect`
  `"three_way_interaction"`). Power is InteractionPoweR's analytic
  `power_interaction_3way_r2()` (the change in R-squared when XWZ is
  added; predictors treated as fixed, as InteractionPoweR has no
  three-way simulation). Correlations InteractionPoweR can't turn into a
  valid matrix are refused in plain English. The check run confirms the
  values InteractionPoweR received; exported scripts call it alone. In
  the app, the three-way interaction card (reached from the design
  finder's moderation questions) now calculates, with an input screen.

# powerkit 0.22.0

* Simulated data sets: `simulated_data(spec, n, seed, file)` draws one
  data set of `n` participants from the spec's population with the
  backend's own generator (Spower's `gen_*()`, Superpower's
  `ANOVA_design()`, InteractionPoweR's `generate_interaction()`,
  power4mome's `power4test(do_the_test = FALSE)`), and writes it as CSV.
  The first column, `SIMULATED_NOT_REAL_DATA`, marks every row; columns
  are named after the variable labels, in a form SPSS, JASP, jamovi,
  Python and R all accept; repeated measures are one row per
  participant. `simulated_data_available()` says whether a design is
  covered (the basic tests except the rank tests, the Superpower ANOVA
  designs, Welch's ANOVA, regression interactions, mediation and
  moderated mediation). The R script from `export_script()` ends with
  the code that builds the same data set for the same seed. In the app,
  a CSV download on the results screen, with a note that it is for
  writing analysis code, not evidence or a pilot.
* Non-inferiority: templates `noninf_independent`, `noninf_paired`,
  `noninf_one_sample` and `noninf_two_proportions` for design
  `equivalence_test`, with `target_test$method = "non_inferiority"`,
  `population$margin` and `population$better` (`"higher"` or `"lower"`).
  A one-sided test against the margin, by pwrss's `power.t.student()` and
  `power.z.twoprops()` (`margin`, `alternative = "one.sided"`). pwrss
  picks the side from the sign of the effect minus the margin, so the
  spec checks refuse an expected effect at or beyond the margin, in plain
  English. Unequal groups through `options$allocation_ratio`. Exported
  scripts call pwrss alone. In the app, four more choices under "What you
  are comparing" on the equivalence screen.
* Spearman's rho and Kendall's tau: `target_test$method = "spearman"` or
  `"kendall"` for template `correlation`, simulated with Spower's
  `p_r(method =)` on bivariate normal scores whose Pearson correlation is
  `population$r`. In the app, a test version on the correlation screen.
* The Pitman-Morgan test of two paired variances: template
  `paired_variances` (`population$var1`, `var2` and `r`, the correlation
  between the measurements), simulated with Spower's `p_r()` on the sum
  and the difference of the paired scores, whose correlation is zero
  exactly when the variances are equal. In the app, its own card (E57),
  reached from the design finder's variance question when each person is
  measured twice.
* Measurement invariance over time: `population$over = "occasions"` for
  template `invariance`, with `population$stability` (the factor's
  correlation between the two occasions), by semPower's
  `semPower.powerLI()`, the same people measured twice. In the app, an
  "Across what" question on the invariance screen.

# powerkit 0.21.0

* Structural equation models: three templates for design `sem`, each the
  chi-square difference (likelihood ratio) test of one restriction
  against the model without it, by semPower's own functions. Measurement
  invariance (template `invariance`, `semPower.powerMI()`): one factor of
  `population$indicators` items with loading `population$loading` in two
  groups, the last `population$noninvariant` items having loading
  `population$loading_group2` (level `"metric"`, against the configural
  model) or intercepts shifted by `population$intercept_difference` item
  SDs (level `"scalar"`, against the metric model) in the second group;
  `options$allocation_ratio` splits n between the groups. The correlation
  between two factors (template `factor_correlation`,
  `semPower.powerCFA(nullEffect = "cor = 0")`), from each factor's items
  and loading. One slope of a latent regression (template
  `latent_regression`, `semPower.powerRegression()`), with one to five
  latent predictors, one correlation between every pair, and the items and
  loading of every factor. Power at each n is `semPower.postHoc()` on the
  F0 of one call to the function, which is what it computes at that n.
  Spec checks in plain English (an item must stay invariant; impossible
  slopes or predictor correlations). `sem_summary()` gains `template`, and
  gives the restriction's df for these templates. Exported scripts call
  semPower alone and reproduce the result. Unit tests against each
  function called directly, power and required N
  (`test-backend-sempower.R`); validation file
  `test-validation-sem-latent.R` (chunk `sem_latent`) with published
  placeholders and checks against semPower's simulated power. In the app,
  the latent variables card's screen starts with "What you want to test".

* Welch's one-way ANOVA: `target_test$method = "welch_f"` for template
  `oneway_between`, simulated with Spower's
  `p_anova.test(var.equal = FALSE)`, with `population$sds` (each group's
  SD, in the outcome's own units; `sd` for every group if absent). The
  check run recovers each group's mean and SD; exported scripts call
  Spower alone. In the app, a test version on the one-way ANOVA screen.
* Equivalence for a correlation (template `tost_correlation`,
  `TOSTER::power_z_cor(alternative = "equivalence")`) and for two
  proportions (template `tost_two_proportions`,
  `TOSTER::power_twoprop(alternative = "equivalence")`, equal groups). In
  the app, two more choices under "What you are comparing" on the
  equivalence screen.
* Repeated measures: the result gains `manova` (`manova_summary()`), the
  MANOVA approach's power (Pillai's trace) at the n analysed, from the
  same `Superpower::ANOVA_exact()` run, when the target effect involves a
  within factor with three or more levels. The result screen and the
  write-up give it beside the univariate F.

# powerkit 0.20.1

* The package description (`DESCRIPTION`), `CITATION.cff` and the README
  now name every backend powerkit calls (pwrss, powertools, TOSTER,
  semPower and bfpwr were missing) and every family of designs it runs.
  The README's status table, which still listed only the first seven
  designs, now groups everything that runs by family and package.
* `_dependencies.R` declares bfpwr, TOSTER and psych, which the engine
  imports, and pkgload, which the app uses to load the engine from source.
  `scripts/setup-cloud-session-apt.sh` installs exactly this list, so
  without them the engine couldn't be installed on that route. A test in
  the app's suite (`test-repo-consistency.R`) now checks that every
  package the engine imports is declared there.
* In the app, when the engine isn't available, the input screen now says
  how to get it (start with `run_powerkit.R`, or use the online app)
  instead of only that it is missing; `run_routing_prototype.R` warns at
  start-up when the engine can't be loaded. The "How you adjusted it"
  field for an effect from a previous study now asks for the reason when
  the effect was kept as published.
* In the app, names of variables and their levels (groups, conditions,
  the outcome) are optional: they only label the result and the write-up.
  An empty name stands for a neutral one taken from the field's label
  ("Group 1", "Outcome"), shown greyed in the box. Lists of level names,
  which set how many levels there are, are still needed.
* Documentation: the app's READMEs and header comments no longer say the
  app calculates nothing, and five relative links in `docs/archive/` that
  broke when those pages moved there now resolve.

# powerkit 0.20.0

* Bayes factor t-tests (one sample, paired, two groups): templates
  `one_sample_t`, `paired_t` and `independent_t` with
  `target_test$method = "bayes_factor"`, computed in closed form by bfpwr's
  `powertbf01()` (new dependency, bfpwr 0.1.6; Pawel & Held, 2025). Power
  is the probability that the JZS Bayes factor BF10 reaches
  `target_test$evidence_threshold` (default 10, bfpwr's), with a Cauchy
  analysis prior of scale `target_test$prior_scale` (default 1/sqrt(2),
  bfpwr's) and a normal design prior on the effect with SD
  `population$effect_sd` (default 0: exactly the effect entered;
  Departure 15). These tests have no alpha (the schema refuses one), no
  simulation and no sensitivity goal; two groups must be equal. The result
  gains `bayes`: the settings and, at the analysed n, the probability of
  strong evidence for no effect and of misleading strong evidence for an
  effect when there is none (`ptbf01()`). Exported scripts call bfpwr.
  bfpwr treats the effect estimate as normal, so at small samples it gives
  a little less power than simulated Bayes factors (Known difference 6).
  Unit tests against direct bfpwr calls (`test-backend-bayes.R`);
  validation file `test-validation-bayes-factor.R` (chunk `bayes`) with a
  published placeholder, checks against simulated Bayes factors, the
  no-effect side and the size of Known difference 6. In the app, the
  one-sample, paired and two-group cards offer the Bayes factor t-test as a
  test version.

# powerkit 0.19.0

* Three-factor ANOVA (design `factorial_anova`, template
  `factorial_three`): three crossed factors `A`, `B` and `C`, each a
  `between_factor` or a `within_factor` with two or more levels, the
  between factors listed first. Means are a nested array (A by B by C),
  with one SD and, when any factor is within participants, one
  correlation `r` between every pair of a participant's cells, so
  sphericity holds. Power for any main effect, two-way interaction or the
  three-way interaction (`target_test$effect`: `main_effect_A`/`B`/`C`,
  `interaction_AB`/`AC`/`BC`/`ABC`) on Superpower's `ANOVA_exact()` (or
  `ANOVA_power()` by simulation), with the design string built from the
  factor types (such as `"2b*2w*2w"`). `goal > n` is the total number of
  participants, split equally across the combinations of the between
  factors. No sensitivity goal yet. Unit tests against direct
  `ANOVA_exact()` calls (`test-backend-factorial-three.R`); validation
  file `test-validation-anova-three.R` (chunk `anova`) with a published
  placeholder, analytic and simulation checks and a Type I error check. In
  the app, a new three-factor ANOVA card, reached from the design finder's
  "how many factors" question.

# powerkit 0.18.0

* Rank tests, simulated with Spower: the Wilcoxon signed-rank test for one
  sample (`one_sample_t`) and for pairs (`paired_t`), with
  `target_test$method = "wilcoxon_signed_rank"`; the Mann-Whitney test
  (`independent_t`, `"mann_whitney"`, unequal groups allowed); and the
  Kruskal-Wallis test (`factorial_anova/oneway_between`,
  `"kruskal_wallis"`). Spower's `p_wilcox.test()` and `p_kruskal.test()`
  run the tests on scores drawn from `population$score_shape`: `normal`
  (the default), `skewed` (standardised chi-square with 10 df, as in
  Spower's examples) or `heavy_tailed` (t with 3 df, rescaled to SD 1),
  shifted by the effect, so d, d_z and the means in SD units mean what
  they mean for the t-tests and ANOVA. The signed-rank test assumes
  symmetric scores (or differences), so `skewed` is refused for it. No
  formula (`options$method = "exact"` is refused), and no sensitivity goal
  yet. Exported scripts write the score generators out. Unit tests against
  direct Spower calls (`test-backend-rank.R`); validation file
  `test-validation-rank-tests.R` (chunk `rank`) with placeholders for
  G*Power's values, direct-call and Type I error checks, and the size of
  the difference from the t-test. Known difference 5 in
  `docs/conventions.md`: G*Power adjusts the t-test by an efficiency factor
  instead of simulating the rank test. In the app, the one-sample,
  paired, two-group and one-way ANOVA cards offer the rank test as a test
  version.

# powerkit 0.17.0

* Two-factor ANOVA beyond the 2 x 2 between and mixed designs (design
  `factorial_anova`): template `factorial_within`, both factors within
  participants, 2 x 2 or larger (Superpower's `"kw*mw"` design, one SD and
  one correlation between every pair of cells, so sphericity holds; the
  correlation must be above -1 / (cells - 1)), and template
  `factorial_between`, both factors between participants with at least one
  at three or more levels (`"kb*mb"`, equal cells, one SD; 2 x 2 stays
  `2x2_between`). Either main effect or the interaction, on
  `ANOVA_exact()` (`ANOVA_power()` on request); power and the required
  sample size, no sensitivity goal yet. `population$means` has one row per
  level of A, as for `mixed`. The check run recovers every cell's mean and
  SD and, for the within design, every pairwise correlation. New example
  specs `anova_factorial_within.json` and `anova_factorial_between.json`;
  unit tests against `ANOVA_exact()` called directly; validation file
  `test-validation-anova-factorial.R` with placeholders, in the `anova`
  chunk.

* Two-way ANCOVA (template `factorial_anova/factorial_ancova`): two
  crossed between factors, adjusting for one or more covariates, either
  main effect or the interaction, by pwrss's `power.f.ancova.shieh()`
  (Shieh's method) with `factor.levels = c(k, m)` and the effect's rows of
  pwrss's `factorial.contrasts()` (pwrss alone tests only the interaction).
  Equal cells, one SD; power and the required sample size. Agrees with
  Superpower's `ANCOVA_analytic()` in the unit tests
  (`test-backend-factorial-ancova.R`); validation file
  `test-validation-anova-ancova.R` with placeholders, chunk `ancova`. New
  example spec `anova_factorial_ancova.json`. In the app, the ANCOVA card
  (E23) asks whether the groups are formed by one factor or two.

* App: cards E20 (two-factor within, now 2 x 2 or larger) and E21
  (two-factor between beyond 2 x 2) calculate, with input screens taking
  the cell means as a table. The design finder sends "both factors:
  everyone got every level" to E20; E21's card says three-factor designs
  are not covered yet.

# powerkit 0.16.1

* The app opens faster when a new copy of it starts: the About tab's
  credits now read each package's `citation()` without loading the
  package (`about_citation_text()` checks `system.file()` instead of
  `requireNamespace()`). Loading the backends there took about 2.5 of
  the 3 seconds a new app process spent before showing its first page;
  the backends now load when a calculation first needs them. The credits
  shown are unchanged.

# powerkit 0.16.0

* Clustered designs (card E34) with a yes/no outcome: `population$metric`
  `"proportion"` with `p1`, `p2` and `sigma_u` (the SD between groups, or
  of the effect across groups, on the log-odds scale) runs on powertools'
  `crt.parallel.bin()` or `multisite.bin()`, the z test of the log odds
  ratio (Y binary, effect `odds_ratio`, method `logistic_mixed`). Power
  and the required number of participants (a whole number of groups);
  no sensitivity goal, and groups of equal size only (`cluster_size_sd`
  is refused; see `docs/upstream-questions.md`). `cluster_summary()` now
  returns `outcome` and `sigma_u`. The exported script prints powertools'
  `crt.varexplore()` or `ms.varexplore()` table. New example specs
  `cluster_randomised_binary.json` and `multisite_binary.json`.

* Group treatment trials (design `cluster_trial`, template
  `group_treatment`; card E34): people are randomised one by one and the
  second condition is delivered in groups (for example, group therapy
  against individual treatment), the same number of people in each
  condition. A score runs on powertools' `irgtt.cont()` (t test with
  Satterthwaite df), a yes/no outcome on `irgtt.bin()` (z test of the
  difference in proportions); both inflate the grouped condition's
  variance by 1 + (m - 1) ICC. Power, the required number of participants
  (a whole number of groups, and as many people again) and, for a score,
  the smallest detectable d, found from the t-based power by root-finding
  rather than `irgtt.cont()`'s normal approximation (which falls a few
  points short of the target power; `docs/conventions.md`).
  `cluster_summary()` gains `grouped_design_effect`. New example specs
  `group_treatment.json` and `group_treatment_binary.json`.

* Clustered designs with a score outcome can adjust for a baseline score
  (one covariate): `population$baseline_r2_within` and, for a
  cluster-randomised trial, `baseline_r2_between`, passed to
  `crt.parallel.cont()` as `ncov = 1`, `RsqW` and `RsqB` (df J - 3), or to
  `multisite.cont()` as `Rsq`. `cluster_summary()` gains `baseline` and
  `design_effect_without_baseline`; its `design_effect` includes the
  adjustment, as powertools computes it. The help page's description of
  `RsqB` and `RsqW` is recorded in `docs/upstream-questions.md`.

* App: the "People nested in groups" screen asks whether the outcome is a
  score or yes/no, and for yes/no asks for the proportion in each
  condition and how much the groups differ. The result and the write-up
  describe the yes/no analysis. A third choice of assignment covers
  studies where only condition 2 is delivered in groups, and an optional
  question about a baseline score; a field in `forms.yaml` may name
  another to stand for it when left empty (`copy_if_empty`).

# powerkit 0.15.0

* Mixed ANOVA beyond 2 x 2 (design `factorial_anova`, template `mixed`;
  card E55): one between-participants factor A by one within-participants
  factor B, at least one with three or more levels (for example group by
  time with three timepoints), by Superpower's `ANOVA_exact()` on the
  design `"kb*mw"` (`ANOVA_power()` on request), for the main effect of A,
  of B, or the interaction. `population$means` has one row per level of A,
  each with one mean per level of B; one SD and one correlation `r`, so
  sphericity holds. Equal groups; `goal > n` is a multiple of the number
  of groups. The check run recovers every cell's mean and SD and, in each
  group, every pairwise correlation. Unit tests in `test-backend-mixed.R`;
  validation placeholders in `test-validation-anova-mixed.R` (in the
  `anova` chunk).

* Superpower's exact route now asks for more participants per group than
  there are cells in the design (at least 5), which is what
  `ANOVA_exact()` needs; before, a design with six or more cells per group
  could reach Superpower with too few and fail with Superpower's own
  message.

* App: a card and input screen for the mixed design. A new design-finder
  question after "No: at least one factor has three or more" asks which
  factors are different people; one between and one within leads to it,
  as does the guided route for three conditions measured twice. The
  input screen's table of cell means takes its rows and columns from the
  two factors' levels (`rows_from`, `cols_from` in `forms.yaml`).

* App: in the write-up, a table of values (the mixed design's cell means,
  the chi-square test's proportions) now reads as bracketed rows on one
  line instead of breaking across lines.

# powerkit 0.14.2

* App: the design finder asks once whether the aim is to show there is no
  meaningful effect, on the aim screen; the later goal question (S4) is
  answered from it. The analysis card no longer lists effect-size
  sources (the input screen does). The input screen drops repeated
  wording: the goal's section is titled "Your goal", effect sizes no
  longer say "(starts empty)", and the smallest-detectable-effect route
  is offered once. Validation notes no longer name test files, and
  "as in G*Power" asides are removed from cards and menus. On the result,
  departures that leave the answer practically unchanged (`forms.yaml`
  `departures_folded`: 2, 3, 8, 9, 11) are folded under "How it was
  calculated"; the others stay in view, with a pointer from the answer.
  The methods paragraph still states every departure. The whole-study
  screen says "experimental" once and describes "your study", not "the
  population".

# powerkit 0.14.1

* App: the plain reading of a target power counts out of 10 only for a
  whole number of tenths (80%, 90%) and otherwise out of 100, so 95% power
  reads "about 95 in 100 studies", not "10 in 10". For an equivalence
  test it now says the studies would show the difference lies inside the
  bounds, and that fewer would if the true difference is closer to a
  bound (not "if the true effect is smaller").
* App text corrected where it was out of date or misleading: the About
  tab's banner lists what now calculates (equivalence, multilevel trials,
  and mediation's quick look plus R script); the "I know my analysis"
  list shows standard names without internal codes or PROCESS model
  numbers; the methods paragraph names mediation models without PROCESS
  numbers; the equivalence card is named for what powerkit runs (TOST),
  not minimum-effect or non-inferiority tests; a choice's default note no
  longer repeats the choice ("Starts at As Cohen's d: ..."); and an empty
  number of Monte Carlo draws shows as power4mome's 1,000, not "none".

# powerkit 0.14.0

* One-way repeated-measures ANOVA (design `factorial_anova`, template
  `oneway_within`; card E54): one within-participants factor with three or
  more levels, the omnibus F test, by Superpower's `ANOVA_exact()` on the
  design `"kw"` (`ANOVA_power()` with `options > method = "simulation"`).
  The spec gives one mean per condition, one SD and `population$r`, the
  correlation between any two conditions; with one SD and one correlation
  the covariance matrix has compound symmetry, so sphericity holds and no
  correction applies. `goal > n` is the number of participants, each in
  every condition (at least 5, as `ANOVA_exact()` needs). The check run
  recovers each condition's mean and SD and every pairwise correlation.
  Unit tests in `test-backend-oneway-within.R` (against `ANOVA_exact()` and
  `power_oneway_within()` called directly, and the exported script);
  validation placeholders in `test-validation-anova-oneway-within.R` (in
  the `anova` chunk).

* App: a card and input screen for the one-way repeated-measures ANOVA.
  The design finder reaches it from "Three or more" conditions when the
  screening says the same people are in three or more conditions; "Any
  difference among the groups" (E18) is now shown only for different
  people in each group, and its card no longer says powerkit can't
  calculate the repeated-measures case.

# powerkit 0.13.0

* Structural equation model fit (design `sem`, template `model_fit`; card
  E37, "Check that a model or questionnaire structure fits"): the power of
  the chi-square test of exact fit to reject a model whose misfit in the
  population is a given RMSEA, and the sample size for a target power, by
  semPower's `semPower.postHoc()` (noncentrality (N - 1) x RMSEA^2 x df).
  The model is given by its degrees of freedom, or, for a confirmatory
  factor analysis, by its number of items and correlated factors, whose df
  `semPower.getDf()` counts with lavaan. New backend
  `engine/R/backend-sempower.R`; semPower 2.2.0 joins Imports and
  `renv.lock`. Every result for this design has `sem` (`sem_summary()`):
  the RMSEA, the df and, for a CFA, the lavaan model. No sensitivity goal
  or simulation yet; the test of close fit is not offered. semPower's
  method paper is in `refs.bib` (`semPower_method`). Validation
  placeholders in `test-validation-sem-model-fit.R` (chunk `sem_fit`).

* App: the card for model fit calculates, with an input screen asking for
  the items and factors of a CFA (or another model's df) and the RMSEA to
  detect. The result, the write-up and the ethics-board version say that
  this is power to show a model is wrong.

# powerkit 0.12.0

* Cluster-randomised trials (design `cluster_trial`, template
  `cluster_randomised`; card E34, "People nested in groups"): whole
  groups are assigned to one of two conditions, the same number of groups
  in each, and a score is compared. Power, the required number of
  participants (a whole number of groups) and the smallest detectable d,
  by powertools' `crt.parallel.cont()` (the design effect, with degrees of
  freedom from the number of groups, and its adjustment when group sizes
  vary). New backend `engine/R/backend-powertools.R`; powertools 1.0.0
  joins Imports and `renv.lock`. Every result for this design has
  `clusters` (`cluster_summary()`): the number of groups, the design
  effect and the effective sample size, which the result screen and the
  write-up state. Validation placeholders in
  `test-validation-cluster-randomised.R` (chunk `cluster`).

* Multisite trials (template `multisite`, design `cluster_trial`): people
  are randomised to two conditions within each group, half to each, by
  powertools' `multisite.cont()` (degrees of freedom from the number of
  groups, J - 1). The spec adds `population$icc_effect`, the share of the
  outcome's variance from the effect varying between groups (powertools'
  `icc1`); `icc` is the ICC of the group means (`icc0`). Valid sizes are a
  whole number of groups. `cluster_summary()` gains `assignment` and
  `icc_effect`; its design effect for a multisite trial is relative to an
  individually randomised trial, so it can be below 1. Validation
  placeholders in `test-validation-multisite.R` (chunk `multisite`).

* App: the "People nested in groups" card (E34) calculates, for whole
  groups assigned or for people randomised within groups (a first
  question on its input screen; the effect's variation between groups is
  asked for only in the second case). The design
  finder now asks the goal (S4) after "People within groups" before
  suggesting it, as for every card that calculates; equivalence for
  grouped data goes to the same card, which says it isn't covered yet,
  rather than to the equivalence card for separate people.

# powerkit 0.11.0

* Whole-study simulation (experimental): a sample size search. The goal
  of a whole-study spec can now be `sample_size` with a target `power`:
  `run_whole_study()` finds the smallest n by powerkit's simulation search
  (`search_n()`: short runs to bracket it, then `nrep` replications at
  several n smoothed by a probit curve), then reports a full run at that
  n, with the search's curve and simulations in `sample_size`. What
  reaches the target follows the claim: the one main analysis's power;
  the chance that every main analysis is significant ("all"); that at
  least one is ("any"); or, under "each", the power of the weakest main
  analysis at each n. The runs and their seeds are split into batches
  that don't depend on the number of cores.
* `export_whole_study_script()`: an R script that runs a whole-study
  spec, with its seed, on the user's own computer and saves the result
  and the citations, as `export_run_script()` does for one analysis.
  `export_citations()` now takes a whole-study result.
* App: the whole-study screen runs a quick look of 200 simulated studies
  (the choice of 1,000 is gone), and the result offers the script for the
  full run: the sample size for a target power (80% to 95%), or the power
  at the N entered from 1,000 simulated studies, with the expected run
  time of each.

# powerkit 0.10.1

* App: on "Plan my whole study", when the whole-study simulation covers
  the plan it is now the plan's first step ("Your whole study in one
  go"), with the analyses it will run; the separate calculations are
  folded below it. Each analysis on the plan is one line with its button,
  its full card folded behind "More about this analysis", and the note on
  the claim and the consistency check folded too. Where the simulation
  doesn't cover the plan, one folded line says what it would need.

* App: cards no longer lead with a PROCESS model number. The standard
  name is the analysis's own (for example "Simple mediation"), and a
  second line says which PROCESS model number Hayes's tool gives it.

# powerkit 0.10.0

* Equivalence tests (design `equivalence_test`, card E36): the two
  one-sided tests (TOST) for two independent groups (`tost_independent`),
  paired data (`tost_paired`) and one sample (`tost_one_sample`), by
  TOSTER's exact `power_t_TOST()`. The spec gives a symmetric equivalence
  bound (`population$bound`) and the expected true difference (`d`, or
  `dz` for paired data), as standardised values or in the outcome's own
  units (`population$raw$bound` with the means and SD; the bound is
  divided by the same SD as the difference). Each one-sided test is at
  level alpha, as TOST is defined. Goals: sample size and power; no
  smallest detectable effect (the bound, not the effect, is what a user
  would solve for, and TOSTER has no such function). An expected
  difference at or beyond the bound is refused in plain words. Checked
  against TOSTER called directly (including raw units), a large-sample
  approximation in base R, and Type I error at the bound; published
  examples are placeholders (`test-validation-equivalence-tests.R`, a new
  `equivalence` chunk in the full validation run). TOSTER (with jmvcore,
  ggdist and distributional) is added to `renv.lock`.

* Whole-study simulation (experimental, not yet checked by a
  statistician; `docs/conventions.md`, Departure 13). A new kind of spec
  (`kind: "whole_study"`, `inst/schema/whole-study.schema.json`) gives one
  population model for a whole study as standardised paths, and the
  planned analyses: the regression of Y on X (`x_y`), a two-way
  interaction (`interaction`), an indirect effect through one mediator or
  two (parallel or serial; `indirect`) and moderated mediation (PROCESS
  models 7 and 14; `index_of_mome`). `run_whole_study()` simulates the
  data with power4mome and fits each analysis to every simulated data set
  with its own model (`power4test()` with several fitted models), so each
  analysis's power and the joint power of the main analyses (all
  significant, or at least one at a Bonferroni-corrected alpha) come from
  the same replications. It runs a check run on 100,000 cases, reports a
  Clopper-Pearson interval for each rate, and gives the values the
  population implies for each analysis's own input screen.
  `validate_whole_study()` checks a spec in plain words (missing or extra
  paths, impossible R-squared); `whole_study_parameters()` lists the
  values a study's population needs. Power at a fixed N only. Tests:
  `test-whole-study.R` (exact bookkeeping of the joint power) and
  `test-validation-whole-study-crosscheck.R` (each analysis against
  powerkit's own calculation of it, and the size of the departure).

* App: the guided plan ("Plan my whole study") can simulate the whole
  study, as an experimental option, when every planned analysis is one
  the simulation covers. Its screen asks for each path once (values from
  the plan's input screens are filled in where they mean the same thing),
  runs in the background with a progress bar and Cancel, and shows each
  analysis's power, the chance the claim succeeds, the implied values
  beside what was entered on each analysis's screen, a draft methods
  paragraph and the run's details. This replaces the "coming soon" note
  on the plan.

* App: the equivalence card now calculates, with one input screen for the
  three comparisons ("What you are comparing"). The result, write-up and
  ethics-board text say what is being shown (that the difference lies
  inside the bounds) and give the bounds. Form groups can now be shown
  only for some choices (`shown_if` on a group), used for the group-size
  question, which only two groups need.

# powerkit 0.9.1

* Six designs are now marked validated (their cards, `tree.yaml` and
  table 2.3 of `docs/decision-tree.md`): planned contrasts, logistic
  regression, the generic t, F, chi-square and z tests, two dependent
  correlations, one variance against a fixed value and two variances.
  Each now matches the G*Power 3.1 manual's published examples in the
  validation tests (`docs/validation-log.md`, 27 October 2026); the two
  variance tests also match direct Spower calls and keep Type I error
  near alpha. No calculation changes.

# powerkit 0.9.0

* App: a "Share this page" button in the top bar copies a link that opens
  the page on show (`?page=labs&tool=prereplication` opens the Labs
  pre-replication notes directly). The online
  app runs inside Posit Connect Cloud's frame, where the address bar can't
  show the page, so this is how a page is shared there. No calculation
  changes.

* App: the result screen can show three effects side by side. Under the
  explore panel, the user may enter a conservative (smaller) and an
  optimistic (larger) effect; powerkit draws power by sample size for
  those and the plan's own effect, and states the N each needs at the
  plan's target power. Neither value is suggested or filled in. Offered
  where the explore panel is (the t-tests and the correlation by
  formula), not for a smallest-detectable-effect plan. The app only calls
  the engine; the plan is unchanged.

* App, Labs: a map of the methods (`app/routing/R/map.R`), drawn as an
  interactive node graph. `map_graph()` turns `tree.yaml` into one node per
  question and per analysis (an analysis reached by several routes is one
  node) and one edge per answer, and tags each analysis with what the study
  wants to show, the outcome and how often people are measured, from the
  routes that reach it. The page draws it as a "cosmos" with Cytoscape.js
  and its dagre layout (bundled in `app/routing/www/vendor`, MIT licence,
  no new R package): each thing a study can want to show is a star, and
  its analyses are planets on rings around it, spaced so labels don't
  meet; an analysis that belongs to several stars orbits one and is joined
  to the others by dashed lines. A filter panel down the side (research
  question, outcome, measurements, whether powerkit calculates it), search
  that flies to matches, clicking a star or planet to zoom in, a details
  panel with the route to an analysis through "Help me choose" and a link
  to its card, a switch between plain-words names and the tests' usual
  names, and a second view of every question as a left-to-right
  tree. A nested list of the same map is provided for screen readers.
  Nothing is calculated (docs/decisions.md, 27 October 2026).

* Safeguard power (Perugini, Gallucci & Costantini, 2014; refs.bib
  `Perugini2014_safeguard`). When the effect size comes from a previous
  study or a pilot, `effect_justification > safeguard` asks the engine to
  plan with the lower bound of a two-sided confidence interval around that
  estimate: the 60% interval for 80% protection against the estimate being
  too large (the default), or the 90% interval for 95%. Covers the
  one-sample, paired and independent t-tests and the correlation. The
  interval comes from psych: `cohen.d.ci()` (noncentral t, given the
  earlier study's n, or n1 and n2) for d and d_z, `r.con()` (Fisher's z)
  for r. `validate_spec()` puts the safeguard effect in the population and
  keeps the estimate in the justification, once, so the hash is stable;
  the result's `safeguard` element records the estimate, the interval, the
  bound used and psych's version. New export `safeguard_effect()`. psych
  joins Imports (it was already installed as a dependency of power4mome).
  A previous study's effect needs an `adjustment` or a `safeguard`.
* App: the effect-size source question offers safeguard power for those
  four tests, asking for the earlier study's sample size and the protection
  wanted. The result card and the write-up say which effect size was used
  and why; the explore panel starts from it.

# powerkit 0.8.0

* Engine and app: the one-sample, independent-samples and paired t-tests
  accept the effect in the outcome's own units (`population > metric`
  "raw", with `population > raw`): the expected mean, the fixed value and
  the SD (one sample); each group's mean and one within-group SD (two
  groups); or each condition's mean with either the SD of the differences
  or one SD and the correlation between the two measurements (paired).
  `validate_spec()` works out Cohen's d or d_z by the definition the schema
  gives (for paired data from one SD and r, the SD of the differences is
  SD * sqrt(2 * (1 - r))), so the backends and the exported R script are
  unchanged and the result equals giving that d directly (tests in
  test-effect-from-units.R). The result has a new `effect_from_units`
  element: the standardised effect, the difference and the SD it was
  divided by, and for a sensitivity goal the smallest detectable effect
  as a difference in the outcome's units. In the app, these three input
  screens ask how the effect will be given (Cohen's d, or the means and
  SD); the result states the d it was worked out to, the write-up gives
  the means and SD with d, and the explore panel starts from that d.

# powerkit 0.7.1

* App: each tab has its own address (`?page=about`, `whats-new`, `labs`,
  `feedback`; the plan tab is the plain address), so a page can be shared
  by link. Opening an address with `?page=` shows that tab, and the
  browser's history entries carry the page, so the address bar follows the
  tab when the app runs on its own. The online app runs inside Posit
  Connect Cloud's frame, where the address bar can't change, but a link
  with `?page=` still opens that page. No calculation changes.

# powerkit 0.7.0

* App: on large screens the base text size rises (17 to 19 px), and the
  page's width is set in rem, so the layout scales with it; long unbroken
  text (the spec hash, web addresses) wraps instead of widening the page.
  After "Check my answers" the result is scrolled to the top of the window
  and focused, once it has been drawn (the message used to arrive before
  the result, so the page scrolled only part way). The result screen's
  cards are reordered: the result with its notes, exploring, save and
  share with the write-up, then how it was calculated (departures, known
  differences, the reproducibility record and the spec). The result card
  points to the known differences when there are any. The short write-up
  no longer ends with the sentence pointing to departures in the
  supplement (docs/decisions.md); the full and plain-words versions are
  folded. No calculation changes.

* App: "Plan my whole study" works out the combined sample size. Each
  sample size calculated from the plan is kept, shown under its analysis,
  and the plan reports the largest N among the main analyses, naming the
  analysis that sets it (the rule recorded on 22 October 2026). Until
  every main analysis has one, the plan shows the largest so far and
  lists the main analyses still to calculate, and those powerkit can't
  calculate yet. Extra analyses don't count. A calculation for an end
  point the analysis no longer leads to (after a changed follow-up
  answer) is ignored.
* App: "Plan my whole study" asks for shared values once (open question
  12, decided 26 October 2026). An input that two analyses on the plan
  both ask for, under the same name (the correlation of X with the
  outcome or with the moderator, and the X -> M, M -> Y and direct
  X -> Y paths of mediation and moderated mediation), is filled in on
  the second analysis's input screen from the first, with a note naming
  where it came from; it stays editable, and the latest value is used
  from then on. The plan lists these values and which analyses use
  them. Inputs asked for in different ways (Cohen's d against cell
  means, a total effect against a direct path) are not converted; the
  plan still lists them for checking by eye. Each analysis also keeps
  the values last entered for it, so "Change your values" reopens them.

# powerkit 0.6.0

Batch 1: the five designs the engine already computed become reachable in
the app (docs/next.md).

* App: logistic regression with one predictor (E27) calculates in the app.
  Its card now says what powerkit does instead of "not in powerkit"; the
  input screen asks for the outcome and the predictor, whether the
  predictor is a score or a yes/no group (with the group names and split),
  the odds ratio, the proportion of "yes" at the starting point, and the
  predictor's R-squared with any other predictors. The direction question
  is asked, as for the other tests with a direction. When that R-squared is
  above 0, the result screen and the methods paragraph state Known
  difference 3 (forms.yaml, `known_differences_if_above_zero`, a new key).
  `single_predictor` leaves `engine_only`.

* App: Poisson regression with one predictor (E28) calculates in the app.
  Its card now says what powerkit does, and that negative binomial
  regression (for overdispersed counts) is still not covered; the input
  screen asks for the count outcome and the predictor, whether the
  predictor is a score or a yes/no group (with the group names and split),
  the rate ratio, the starting rate, the mean exposure and the predictor's
  R-squared with any other predictors, with the direction question.
  `single_predictor_count` leaves `engine_only`. Count outcomes now go
  through the screening questions like the others: a count measured once
  per person reaches E28, a count measured twice or more reaches the
  safety net, and moderation or mediation with a count reaches E32.

* App: planned contrasts (E19) calculate in the app. The design finder
  already sent "a specific comparison" among three or more groups to E19,
  whose card said powerkit couldn't do it. The input screen asks for the
  groups, the outcome, the group means, the SD and the contrast weights
  (one per group, adding up to 0), with an example of a comparison and a
  linear trend. Equal groups and two-sided only, as pwrss's
  `power.t.contrasts()` offers. `oneway_contrast` leaves `engine_only`.

* App: two dependent correlations get their own card (E51) and calculate
  in the app. The design finder reaches it from the relationship path
  ("one correlation stronger than another in the same people"), next to
  two independent correlations (E49), whose card now points to it. The
  input screen asks which kind (sharing a variable, or none in common),
  the variables' names, the two compared correlations and the
  correlations among the other pairs, with the direction question. The
  result screen and methods paragraph state Departure 12 (G*Power's
  unpooled Steiger test, not pwrss's pooled default). Both templates
  leave `engine_only`.

* App: the two variance tests get cards (E52, one variance against a fixed
  value; E53, two independent groups) and calculate in the app, by
  Spower's simulation. The design finder reaches them from a new answer to
  "What do you want your study to show?" (scores more spread out or more
  consistent; offered for a score measured once) and a new question, V1,
  "Whose spread of scores are you comparing?". The input screens ask for
  variances (the SD squared), with the direction question; the two-group
  test has equal groups only. Known difference 4 (simulated, where
  G*Power is exact) is on the result screen and in the methods paragraph.
  Both templates leave `engine_only`.

# powerkit 0.5.1

* App: the start screen asks only how to start (I know my analysis, Help
  me choose, Plan my whole study). The aim ("What is your study trying to
  do?") follows on its own screen, before the screening questions;
  estimation and equivalence still go to their cards. Whether the sample
  size is fixed is asked on the input screen with the goals that take a
  sample size, and still sets the write-up's wording. The claim (one test,
  several standing alone, any of several, all of several) is a setting on
  the input screen that starts at one test, with its note under the chosen
  claim; from a whole-study plan or an older project it starts at the
  claim given then. A number of tests typed before the claim is set back
  to one test is ignored. No calculation changes.

# powerkit 0.5.0

* App: a cleaner, card-based layout. Back and Start again sit at the top
  of every screen, and the screen's next step ("Enter your values",
  "Check my answers", the whole-study route's Next and Show my plan) is in
  a bar pinned to the bottom of the window, so neither needs scrolling to
  find. Choices are cards, two to a row on wide screens; the start
  screen's three questions sit side by side, with each option's
  explanation shown under the chosen option only. The header is a slim
  bar with the name, "Prototype" and the version; what the prototype can
  do moves to the About tab (renamed from "About this prototype").
  Validated designs no longer show a "Runs in powerkit" box (their
  validation note is under "More about this analysis"), and cards no
  longer show the internal design ID and engine template outside the
  maintainer's view. Results are in cards (the answer; exploring it; how
  it was calculated, with departures from the tools' defaults still in
  view; saving and sharing), with the values used, the seed and the
  limits of power folded under "More about this result". Input screens
  give a default's source without the function calls in brackets; the
  full source is the line's tooltip and stays in every export. No
  calculation or routing changes.

# powerkit 0.4.1

* App: in "Plan my whole study", each analysis on the plan that powerkit
  can calculate now has an "Enter your values" button that opens its
  input screen, as the card does on the other routes. Before, the plan
  showed the analyses' cards with no way to calculate any of them. When
  two or more analyses are main analyses, the input screen takes its
  claim from the plan's answer to "What does your study's claim need?"
  (each on its own, every one significant, or any one significant), with
  the number of main analyses as the number of tests; an extra analysis
  is powered on its own. "Back to my plan" returns to the plan.

# powerkit 0.4.0

powerkit has a version number from here on: 0.x.y while it is a prototype,
where the minor number counts batches of user-visible work that have
shipped, and 1.0.0 at release (docs/adding-a-test.md, "Version numbers").
0.4.0 is what is already online: the first prototype, the four-screen
design, the tests by formula, and the shorter input screen with Labs,
feedback and browser history. The version shows on the About page, in
every exported R script and in each result's provenance.

* Docs: docs/adding-a-test.md is the one page to follow when powerkit
  gains a power analysis it couldn't do before — what counts as added
  (engine, validation placeholders, card, input screen, a plain-words
  "What's new" entry, a version bump and the status update, all in one
  pull request), how a backend package is chosen with the maintainer,
  every file a design touches, and the queue of what to add next.

* Engine (not yet in the app): two dependent correlations in one group,
  by Steiger's z test with pwrss's `power.z.twocors.steiger()`. Template
  `overlapping_correlations` compares X with Y against X with Z;
  `nonoverlapping_correlations` compares X1 with Y1 against X2 with Y2
  (for example, the same two measures at two ages). Power at a fixed N or
  the required N, by formula; one-sided tests run in the direction of the
  specified difference. powerkit uses the unpooled test, as G*Power, not
  pwrss's pooled default (Departure 12); the required N is 1 to 4% larger
  than with pwrss's default. Correlations that can't hold together are refused with a
  plain-English message.
* Engine (not yet in the app): Poisson regression, the Wald z test of one
  predictor of a count outcome, by pwrss's `power.z.poisson()`
  (Demidenko's method with its variance correction, pwrss's default).
  Design `poisson_regression`, template `single_predictor_count`: a count
  outcome Y and a predictor X that is a score (rate ratio per SD, base
  rate at X's mean) or a yes/no group (rate ratio of the second group
  against the first, and the proportion in the second group), counted over
  a mean exposure, optionally adjusted for other predictors through X's
  R-squared with them. Power at a fixed N or the required N; one-sided
  tests run in the direction of the rate ratio. `variables` accepts a new
  type, `count`.

* Engine (not yet in the app): logistic regression, the Wald z test of one
  predictor, by pwrss's `power.z.logistic()` (Demidenko's method with its
  variance correction, pwrss's default). Design `logistic_regression`,
  template `single_predictor`: a yes/no outcome Y and a predictor X that is
  a score (odds ratio per SD, base probability at X's mean) or a yes/no
  group (odds ratio of the second group against the first, and the
  proportion in the second group), optionally adjusted for other
  predictors through X's R-squared with them. Power at a fixed N or the
  required N; one-sided tests run in the direction of the odds ratio.
* Engine (not yet in the app): planned comparisons (contrasts) between the
  levels of one between-participants factor, by pwrss's
  `power.t.contrasts()`. Template `oneway_contrast` of design
  `factorial_anova`: the group means, the within-group SD, and one weight
  per level in `target_test > weights`, adding up to 0. Trend tests are
  contrasts with the matching weights, and the weights' scale doesn't
  matter. Power at a fixed N or the required N; one contrast at a time,
  equal groups, two-sided.
* Engine: two variance tests, the ones G*Power computes in its sections 26
  and 15 (templates `one_variance` and `two_variances` of the basic-test
  design). One group's variance is compared with a fixed value by the
  chi-square test; two groups' variances by the F test. Both run through
  Spower's `p_var.test()` and are simulated, because no package powerkit
  builds on has a formula for them (`docs/conventions.md`, Known
  difference 4), so `options > method` can only be `"simulation"`. An
  allocation ratio is refused for the two-group test: Spower's generator
  cannot draw unequal groups (`docs/upstream-questions.md`). Not wired
  into the app.

* App: the browser's Back and Forward buttons move between powerkit's
  screens and tabs. Before, the app changed screens without the browser
  knowing, so Back left powerkit altogether. Values typed on an input
  screen are kept when you go back and forward again; a calculation is
  run again rather than restored.

* App: help for people unsure of their effect size, in the effect-size
  section. "Don't know what effect to expect?" is in view, with a button
  that sets the goal to the smallest detectable effect (and the source to
  "I can't justify an effect size" for the basic tests); on the 2 x 2
  designs and regression interactions it scales the entered pattern. "Not
  sure what number to put here?" sets out the four honest routes: the
  smallest effect that would matter, starting in the measure's own units
  (with how to turn a difference into d or d_z), a meta-analysis, one
  previous study reduced for bias, and not knowing. No number is
  suggested or filled in.

* App: Labs opens on a list of tools, so that more can be added; the
  pre-replication notes open when chosen, with a link back to the list,
  and stay open after a reload. "Plan the replication's sample size" no
  longer wipes a plan in progress without asking: it asks first. The
  notes' finding, original study and smallest effect that would matter
  go into "Why this effect size?" on the replication's input screen (the
  user's own words; no number is filled in), and a strip on the
  replication's screens links back to the notes, which are kept.

* App: shorter labels on the input screen, with the detail as help text
  under the field ("Why this effect size?" instead of a two-line label).
  Definitions of terms and the reason the direction is asked first open
  on request ("What these terms mean"); warnings stay in view. "How you
  adjusted it" appears only for a previous study. After "Check my
  answers", each problem also shows under its own field, and the
  settings open if a problem is inside them.

* App: four steps across the top of "Plan a power analysis" (Your study,
  Find your design, Your numbers, Result) show where you are: named steps,
  not a percentage, as the design finder's length depends on the answers.
  Cards fold what you'd enter, the package that calculates it and the
  next questions into "More about this analysis", so a card fits on
  about one screen; the effect-size guidance stays in view.

* App: the input screen is shorter and in a clearer order (about a third
  less scrolling). "What do you want to find out?" comes first, and the
  target power and the number of participants appear only for the goals
  that need them. The effect size and where it comes from are together
  in one highlighted section. Settings that start at a tool's default
  (test version, method, group-size ratio, attrition, seed) fold into one
  line that shows their values and opens to change them; it opens by
  itself when one has been changed. Everything is needed unless marked
  optional, instead of "(required)" on every field.

* App: the About, What's new, Labs, Feedback and maintainer tabs are built
  once when the app starts, not for every visitor, so the page opens
  faster when many people arrive together. The Labs citation falls back
  to a link instead of failing when the engine is only partly loaded.

* Spec: `effect_justification.type` accepts `own_study_result`, an effect
  size from the finished study itself (observed power). It is valid, and
  the checker warns that observed power is widely discouraged (Rubin,
  2025, p. 14).

* App: four decisions of 22 October 2026. Observed power can be chosen as
  the effect-size source, with a warning. The t-test, correlation and
  one-way ANOVA cards say their figure only approximates the rank-based
  test (Mann-Whitney, Wilcoxon, Spearman, Kruskal-Wallis). The "not
  covered" cards for time-to-event, dyadic, precision and factorial
  yes/no designs name established tools (Hmisc, apimpower, MBESS,
  Spower). Parallel mediation offers two mediators until more are
  validated.

* App: at most two long calculations (interactions in regression, and
  mediation's preview and full run) run at once across everyone using the
  app; anyone else is told plainly that powerkit is busy and to try again
  in a minute or two. Each runs in its own R process, and many at once
  could use up the online server's memory and stop the app for everyone.
  The limit is `background_limit` in `forms.yaml`, or
  `POWERKIT_BACKGROUND_LIMIT`.

* App: a Feedback tab for bug reports, questions, suggestions and other
  comments, linked from the top of every page and from each card's
  "Something doesn't fit?". It fills in where the user is (route,
  answers, the analysis reached and the values entered) and shows the
  whole message before it goes. Send stores it, with an optional email
  for a reply, in a feedback table in Supabase through one function,
  `send_powerkit_feedback()`, which checks the kind and length and caps
  messages per hour; the publishable key can't read the table. No account
  is needed. It is the only thing the app sends, and only on Send. The
  tab also offers a GitHub issue and copying the message, and an email
  button when an address is set (`tree.yaml`, `feedback: email`, or
  `POWERKIT_FEEDBACK_EMAIL`).

* App: the undecided settings (the "Undecided, for the maintainer"
  placeholders, recorded decisions and the "For the maintainer" tab) are
  now shown only in the maintainer's view, so people using the app see
  only what applies to them. Open the app with `?view=maintainer`, or set
  `POWERKIT_MAINTAINER_VIEW=true`, to see them.

* App: the banner names the analyses that calculate in plain words
  instead of end-point codes (E1–E9 and so on), and the browser tab reads
  "powerkit (prototype)". In "Plan my whole study", the combined sample
  size and the consistency check are labelled "Coming soon" instead of
  "once the engine is connected", and the combined N says what to do
  meanwhile (use the largest N from the analyses' cards).

* App: the generic t, F, chi-square and z tests (E50), as G\*Power's
  generic tests, for people who have worked out their test's noncentrality
  parameter. Found only from "I know my analysis". There is no sample
  size: the result is the power for a noncentrality, or the noncentrality
  needed for a target power, and the write-up says so. Engine: pwrss
  1.3.3's search for the noncentrality needed goes wrong for a t test with
  few degrees of freedom (with 3, it gives about 8331 where the answer is
  about 4.26), so the engine checks the answer with pwrss's own power and
  refuses a wrong one with a plain message.

* App: three changes to the input screen on test direction and multiple
  tests. (1) Tests that can be one-sided now start with "Does your
  hypothesis predict a direction?", with no answer filled in; the
  packages' two-sided default is still named. A two-sided p-value does
  not support a directional claim (Rubin, 2022). (2) When the claim needs
  all of several tests to be significant, the screen asks how many, and
  each test's target power is raised to the k-th root of the target
  (0.8 for two tests becomes 0.894 each), so that all succeed together
  with the target power if the tests are independent; the result, the
  80%/95% comparison and the write-up say so, and name the "reverse
  Bonferroni" (Francis & Thunell, 2021) as another approach powerkit
  doesn't take. Power at a fixed sample size is unchanged. (3) Where
  powerkit says no correction is needed for separate claims, it adds that
  under the error-statistical view a correction may be expected for a
  related group of tests (Mayo, 2018; Rubin, 2024, Journal of Trial and
  Error). Four references added to refs.bib.

* App: a new "Labs (experimental)" tab, kept apart from the main route.
  Its first tool, pre-replication notes, walks through the three
  questions of Karhulahti, Martončik and Adamkovič (2025) in the user's
  own words: the finding, epistemic goals (with the smallest effect that
  would matter), methodological quality (what the original did and what
  the replication will improve), value, and where they landed (go ahead,
  change the plan, or not worth replicating, as equal choices). An
  optional panel finds the original study's smallest detectable effect
  for the basic tests with the engine's sensitivity. Notes download as
  Markdown, copy, or print; they stay in the browser tab only, with a
  "Clear notes" button. Nothing is required or scored. On the input
  screen, choosing "A previous study" as the effect size's source shows
  one optional line pointing to Labs, which can be hidden. The paper is
  added to `refs.bib`.

* App: a plan checker. On the start screen, "Or check a plan someone
  shared with you" opens a saved project for a supervisor, reviewer or
  colleague: what the plan is for and what it found, the questions worth
  asking (no reasoning for the effect size, an estimate from a pilot or a
  previous study, a changed significance level or one-sided test with no
  reason, no target-power reason, no allowance for drop-out, a claim
  needing several tests), the reasons in the author's words, and every
  value entered. It reads the file only; "Open it in the app and rerun
  it" reruns it. The questions are prompts, not a pass or fail.

* App: the write-up has a third box, a plain-words version for an ethics
  application. It says why this many participants in words a lay panel
  can follow: how many will take part (and be recruited, allowing for
  drop-out), the effect planned for and your reasoning, the chance that a
  study of this size finds that effect and the chance it misses it, and
  whether the number came from a power analysis or from the resources
  available. It describes the plan; it doesn't say whether the study is
  ethical.

* App: the About tab now also says what powerkit doesn't do (it doesn't
  choose your effect size, collect data, use AI or replace a
  statistician), where the numbers come from and how far along it is. A
  new "What's new" tab lists dated changes in plain words, newest first,
  from `app/routing/whats-new.yaml`; each PR that changes what users see
  adds an entry there.

* App: changing the significance level from its default, or choosing a
  one-sided test, now opens a box asking why (optional). The reason goes
  into the write-up, for example "The significance level of .01 was chosen
  because ..." and "A one-sided test was used because ...". This builds
  the maintainer's decision of 18 October 2026 (alpha and a two-sided test
  stay pre-filled; a reason is asked only if either is changed).

* App: two new cards that calculate. The chi-square goodness-of-fit test
  (E48) has its own card, as the maintainer decided (judgement call 3.7):
  one group's outcome in several categories, compared with fixed
  proportions (equal ones if none are given), on pwrss's
  `power.chisq.gof()`. A test of two independent correlations (E49,
  Fisher's z, pwrss's `power.z.twocors()`): the same two variables measured
  in two separate groups. "Help me choose" reaches them from the
  categorical-outcome question and the relationship question. Both match
  pwrss in the engine's tests but haven't been checked against G\*Power;
  their cards say so.

* App: "Guess first", an optional teaching step at the end of every input
  screen. Write down the sample size, power or smallest effect you expect
  before pressing "Check my answers"; the result screen shows your guess
  next to the answer (for example, "Your guess: 60 participants. The answer: 394, 6.6
  times your guess."). The guess isn't part of the plan, the R script or
  the write-up, and nothing is collected.

* Regression interactions (E9) can now find the smallest effect you
  could detect at a given sample size: the correlation of the interaction
  with Y, with the other correlations kept as entered. It uses
  InteractionPoweR's fixed-model formula, `power_interaction_r2()`, which
  is quick but gives slightly higher power than the simulation used for
  sample size and power, so the true smallest effect may be slightly
  larger. The result screen, the write-up and the R script say so. In the
  engine, a backend can name its own method for the smallest detectable
  effect (`sensitivity_method`), recorded as `"analytic"`.

* Running powerkit on your own Mac works again: RcppArmadillo is updated
  to 15.6.2-1 in `renv.lock`. CRAN replaced 15.6.0-1 on 17 October 2026,
  so a Mac had to build the old version from source, which needs
  developer tools most people don't have.

* App: "I can't justify an effect size" and "the smallest effect I could
  detect across a range of sample sizes" now work for two proportions
  (E5) and the chi-square test (E6), as for the t-tests and the
  correlation. For two proportions, group 1's proportion is still needed
  and group 2's can stay empty: powerkit finds how far above group 1's it
  would need to be (a lower value looks for a decrease). For chi-square,
  the table can stay empty: powerkit finds the smallest Cohen's w for the
  numbers of categories, straight from `pwr.chisq.test()`. Engine: these
  two designs accept a zero effect for the smallest detectable effect.

* App: if you change the effect size after writing your reasoning for it,
  the result screen asks "Does your reasoning still apply?" and shows the
  old and new values. Your reasoning is kept, not wiped. Until you confirm
  it ("Yes, it still applies") or edit it, the plan can't be saved or
  exported and there is no write-up, so the write-up never quotes a reason
  written for a different number.

* App: Fisher's exact test is now a test version on the two-proportions
  screen (E5), for small samples or small expected counts; with it, the
  formula and simulation choices are hidden (it is pwrss's exact test
  only), Known difference 2 is shown and the z test's departures are not.
  One-way ANCOVA (E23) calculates on its own input screen: adjusted group
  means, one SD, the covariates' R-squared and their number, on pwrss's
  Shieh method. Both match pwrss in the engine's tests but haven't been
  checked against G\*Power; their cards say so.

* Engine: generic t, F, chi-square and z tests (design `generic_test`, not
  yet in the app), as G\*Power's "Generic" tests: power from a
  noncentrality parameter and degrees of freedom, or the noncentrality
  needed for a target power (goal `sensitivity`). There is no sample size,
  because the noncentrality already reflects it. Each is one pwrss call
  (`power.t.test()`, `power.f.test()`, `power.chisq.test()`,
  `power.z.test()`), checked against pwrss called directly and against
  base R's noncentral distributions. A generic binomial test is the exact
  test of one proportion, which powerkit already has.

* The online app can now update itself after each merge: Posit Connect
  Cloud publishes it from GitHub using `app/routing/manifest.json`, which a
  new workflow keeps current. One-time setup on the Connect Cloud website:
  `docs/hosting-options.md`, "Publishing from GitHub".

* App: the result screen now has a write-up, replacing the methods-paragraph
  placeholder. A short version for the paper and a full version for a
  supplement or preregistration state the test and its sides, alpha, the
  target power and why (a new optional field), the effect size with your
  reasoning word for word, N in total and per group with the power reached,
  the number to recruit, how a claim over several tests was handled, the
  package, version and seed, and the departures. Both are editable, and like
  saving they need your reasoning. The noncentrality parameter and critical
  value are left out (the maintainer's decision, 18 October 2026).
  `export_citations()` now points to the write-up instead of a placeholder.

* Engine: four more tests by formula, each one pwrss call (not yet in the
  app): Fisher's exact test of two proportions (`target_test > method =
  "fisher_exact"`), the chi-square goodness-of-fit test (template
  `chi_square_gof`; equal fixed proportions unless given), two independent
  correlations (template `two_correlations`, Fisher's z test) and one-way
  ANCOVA (template `oneway_ancova`, Shieh's method). Each has an example
  spec, an R script that reproduces it, and tests against pwrss called
  directly; goodness of fit also agrees with pwr's formula, and ANCOVA
  with Superpower's. Not yet checked against G\*Power.

* App: four more designs calculate on their input screens. One-way ANOVA
  for three or more separate groups (E18, Superpower), multiple regression
  for R-squared against 0 or an R-squared increase, which also covers one
  predictor's coefficient (E24, pwrss), one proportion against a fixed
  value (E25, pwrss's exact binomial test) and McNemar's test (E26,
  pwrss's exact test). Welch's t-test (E2) can now be worked out by
  pwrss's formula as well as by simulation. One proportion and McNemar
  show Known difference 2 (power goes up and down with N for exact tests
  of counts). These designs match G\*Power in the engine's tests but are
  not yet in the full validation run; their cards say so.

* App, "Plan my whole study" analyses screen: each analysis now has one
  choice (not planned, main analysis, or extra analysis) instead of two
  separate ticks, so an analysis can no longer be marked "primary" without
  being planned. The question about how the main analyses support the claim
  appears only when two or more are main, and its options are written in
  plain words (no "intersection-union").

* The result screen now states every departure and known difference that
  applies: for mediation (E10–E14), lavaan's maximum-likelihood fit rather
  than PROCESS's OLS (Departure 6) and Boos and Zhang's method switched off
  (Departure 8); for parallel mediators (E11), residuals free to correlate
  (Departure 7); and for regression interactions (E9), that fixed-model
  tools such as G\*Power give slightly higher power than powerkit's
  simulation (Known difference 1, under a separate heading).

* App, screen D of the new design: every result now has a plain reading
  that keeps the condition ("if the true effect is the one you entered,
  about 8 in 10 studies like this would get a significant result"), the
  effect-size source and the user's reasoning beside the number, and a line
  on what power can't tell you. A required N is shown at 80% and 95% power
  side by side. The t-tests and the correlation have an explore panel: a
  slider for the effect size and a plot of power by sample size, which
  never changes the plan. A test checks that no output template uses a
  verdict word such as "justified" or "adequate".

* App, screen C of the new design: the effect-size source now includes
  "I can't justify an effect size" (spec type `none`, new in the schema)
  for the t-tests and the correlation. It leads to the smallest effect you
  could detect, at one sample size or across a range of sample sizes (a
  table at 80% and 95% power). The reasoning ("source") is optional to
  calculate and required only to save a project or download the R script;
  the spec schema no longer requires it. An effect size from one earlier
  study gets a short warning pointing to bias correction (BUCSS).

* App, screen A of the new design: the start screen now asks three
  questions before the design finder. "Your sample size" (choose or fixed)
  starts the input screen at the smallest effect you could detect when N
  is fixed. "Your aim" sends estimation and equivalence to their cards.
  "Your claim" (one test; several claims, each on its own; any of several;
  all of several) adds a note, and for "any of several" divides alpha
  between the tests (Bonferroni). The basic tests (E1–E6) now offer the
  smallest detectable effect, and the t-tests and correlation need no
  effect size for it.

* Smallest detectable effect for the basic tests (engine only; not in the
  app yet): goal type `sensitivity` now works for the one-sample, paired
  and independent t-tests, the correlation, two proportions and the
  chi-square test on the formula path. pwr solves for the effect when it is
  left empty (for two proportions, group 2's proportion is searched with the
  same power call), in the direction of the effect you specified. For the t-tests and the
  correlation no effect size is needed (a zero effect gives a positive
  result). The exported R script reproduces it. This is the first step of the fixed-N
  route in the new design.

* New `write_project()`, `read_project()` and `reproduce_project()`: save a
  power analysis (spec with its seed, how it was reached in the app, the
  result, and the powerkit, R and package versions) as one JSON file, open
  it again with any differences reported in plain English, and rerun it to
  check it reproduces the saved numbers. The app has "Save project" on the
  result screen and "Or open a saved project" on the start screen, which
  puts the input screen back with the same values.

* Trying the prototype: `docs/run-it-yourself.md` gives plain-English
  steps for Windows and macOS (install R 4.5.3, download the ZIP, run one
  line), with troubleshooting. `run_powerkit.R` restores the recorded
  packages and the engine if needed and opens the app. A new CI workflow
  (`run-it-yourself.yaml`) follows those steps on clean Windows and macOS
  machines and checks the app answers. The app has an "About this
  prototype" tab: what it does, that it's a prototype, which end points
  calculate, how to report problems, and credits for every foundation tool
  from its own `citation()`. `docs/hosting-options.md` compares ways to
  host it (options only).

* Wave 2 groundwork (engine only; not in the app yet): `run_spec()` now
  runs a one-way between-participants ANOVA (template `oneway_between`,
  Superpower's `ANOVA_exact()`), multiple regression R² against 0 and R²
  increase (new design `multiple_regression`, pwrss's
  `power.f.regression()`), one proportion against a fixed value (exact
  binomial, pwrss's `power.exact.oneprop()`) and McNemar's exact test
  (pwrss's `power.exact.mcnemar()`). Welch's t-test can be calculated by
  formula on request (`options > method = "exact"`, pwrss's
  `power.t.welch()`); its default stays Spower simulation. Each has an
  example spec, an exported script that reproduces it with the backend
  alone, and tests against the backend called directly. For exact tests
  of counts the required N is the smallest that reaches the target, which
  can be lower than pwrss's own answer; G\*Power reports the same N as
  powerkit (Known difference 2). One-way ANOVA, R² against 0, R² increase and one
  proportion match the maintainer's G\*Power screenshots to seven
  decimals, a priori N included (G\*Power also reports 90 for the
  one-proportion example). McNemar matches G\*Power's exact
  option too (power, and N = 129).

* Documentation: `docs/judgement-session.md` sets out the nine open calls
  that change what users see, ordered by impact, for the maintainer's
  judgement session, and `docs/saving-projects.md` compares five ways to
  save projects (judgement call E6). Options and sources only; no code
  change.

* Validation: the `basic` chunk now checks two proportions in unequal
  groups against the maintainer's G\*Power screenshots (1 : 2 and 1 : 3 in
  both directions, one tail at 1 : 2, and a priori at 1 : 3), so E5's
  "Validated" label is backed by the validation chunk as well as the unit
  tests. No change to results.

* New `export_run_script()`: an R script that runs a spec, with its seed,
  through `run_spec()` on the user's own computer, then saves the result
  and writes the backend-only reproduction script and the citations. The
  app offers it for calculations too long to run there (a mediation
  required N, and moderated mediation).

* New `power_interval()`: an exact binomial (Clopper-Pearson) range for a
  simulated power, from the recorded rejections (base R's `binom.test()`).
  The app shows its quick previews as this range.

* The app prototype now runs mediation and moderated mediation (E10-E14).
  For power at a fixed N: a rough preview from 100 simulations, shown as a
  range and labelled not to be reported, then either the full analysis in
  a separate process with a progress bar and Cancel (mediation) or the R
  script to run the full analysis on your computer (moderated mediation).
  A required N goes straight to the R script: a preview of it would take
  15 minutes or more and often couldn't narrow the N down.

* Documentation: the walkthrough pictures in `docs/figures/walkthroughs/`
  are re-rendered from the current app prototype (for example, E4's card
  now names Fisher's z and Departure 10). No code change.

* Attrition is now applied. With `options > attrition`, `run_spec()`
  returns the number to recruit (`recruitment`): each group's analysed n
  divided by (1 - attrition) and rounded up, for example 72 + 72 = 144 to
  recruit for 64 + 64 analysed at 10%. The app's result screen shows the
  numbers analysed and to recruit, with a caveat that this common heuristic
  ignores how missing data will be handled (Rubin, 2025), and the exported
  R script works it out too.

* The app prototype's card for two proportions (E5) says "Validated"
  again, after the `basic` validation chunk was rerun with the z test
  (pwrss for unequal groups).

* `refs.bib` now holds four sources the maintainer checked in full text:
  Rubin (2021), Rubin (2024), Mikael Rubin (2025) and Frane (2019). An
  entry may now be verified "from full-text PDF held by the maintainer" as
  well as from a URL a session opened. `pwrss_method` and `stats_method`
  stay placeholders: neither package's `citation()` names a method paper.

* Two proportions (E5) in unequal groups now use pwrss's z test
  (`pwrss::power.z.twoprops(std.error = "pooled")`), which matches
  G*Power's power, instead of Cohen's h, which under-estimated the
  required N (360 rather than about 370 for 95% power at a 1 : 2 split).
  pwrss is now a required package and is cited from its own
  `citation()`; the exported R script calls it for this case.

* Two proportions (E5) now use the z test as G*Power runs it: base R's
  `stats::power.prop.test(strict = TRUE)` for equal groups, which matches
  G*Power to seven decimals. Results change slightly from pwr's Cohen's h
  formula (for example 164 rather than 160 per group for 95% power with
  proportions .10 and .25). Cohen's h stays available with
  `options > proportions_formula = "arcsine"`, and unequal groups still use
  it (Departure 11 in `docs/conventions.md`). The result's backend is
  recorded as stats, and the exported R script calls `power.prop.test()`.

* When the app prototype reports a required N calculated exactly, the
  result screen also shows the power that N actually gives, for example
  "With 64 per group, power is 80.1%." Not shown for a simulated N.

* Correlations (E4) keep pwr's Fisher's z formula. This is now recorded as
  Departure 10 in `docs/conventions.md`: G*Power uses the exact
  distribution of r, and the two differ by at most 0.004 in power and 1
  participant in N (r = .3 to .5, N = 20 to 100). It is shown on E4's card
  and on the result screen.

* The app prototype (`app/routing/`) now calculates regression interactions
  (E9) on the input screen. The engine runs in a background R process, with
  an estimated progress bar and a Cancel button (about 5 seconds for power,
  about 80 seconds for a required N). The result screen, fixed seed, R
  script and citations are the same as for E1–E8. No engine change.

* Basic tests (one-sample, independent and paired t-tests, correlation, two
  proportions, chi-square test of independence) are now calculated by
  formula with the pwr package by default, not by simulation: the same
  inputs always give the same answer, with no Monte Carlo noise. Spower
  simulation stays available with `options > method = "simulation"`, and
  is used for Welch's t-test, which pwr doesn't cover. The correlation and
  two-proportion formulas are approximations (Fisher's z, Cohen's h). The
  exported R script calls pwr, and the citations export credits pwr. pwr is
  now a dependency (Imports). Departure 9 in `docs/conventions.md`.

* Basic tests now need Spower 0.7 or later. One-sided tests use Spower's
  own one-sided test (its new `alternative` argument) instead of powerkit's
  workaround for Spower 0.6.4, which halved the two-sided p-value whatever
  the direction (Departure 4, now retired). Results are unchanged: with the
  same seed, every basic test gives the same power as before. Exported
  scripts for one-sided tests now call Spower's `p_t.test()`, `p_r()` or
  `p_prop.test()` with `alternative`, and need Spower 0.7.
* Validation (for maintainers): two new chunks,
  `mediation_crosscheck_parallel` and `mediation_crosscheck_serial`,
  compare the joint-significance test for parallel and serial mediation
  in power4mome (with powerkit's translation of the spec) and in simsem,
  with data generated from residual variances worked out separately from
  the engine. Run with `scripts/run-validation.R --only <chunk>` or the
  `full-validation` workflow.

* The citations export (text and BibTeX) doesn't print a refs.bib entry's verification
  note ("Verified ..."), which records where the entry was checked rather
  than being part of the reference.
* Moderated mediation (PROCESS models 7 and 14) has passed its full
  validation again, rerun after the seeding fix (17 October 2026). The
  mediation cross-check against pwrss and simsem passed its first full run.
* Validation (for maintainers): a new `mediation_crosscheck` chunk
  (`scripts/run-validation.R --only mediation_crosscheck`, and the
  `full-validation` workflow) compares simple mediation with two tools
  written independently of power4mome: pwrss's `power.z.mediation()`
  (Monte Carlo interval and joint tests) and simsem (joint test). pwrss and
  simsem are new Suggests, used only by this chunk. The tolerance rule is
  in docs/validation-log.md.

* New `export_script(spec, result, file)` writes a standalone R script that
  reproduces a result by calling the package that computed it (Spower,
  Superpower, InteractionPoweR or power4mome) directly, with your values
  filled in and a comment on each argument. powerkit isn't needed to run
  it. With the same package versions it gives the same numbers: it uses
  powerkit's seeds and batches, and for a sample-size goal it simulates the
  same sample sizes and fits the same curve. It ends by comparing its
  numbers with powerkit's and printing `sessionInfo()`. Available for every
  design `run_spec()` runs.
* New `export_citations(result, format = "text" or "bibtex")` lists what to
  cite: the package that computed the result (its own `citation()`), its
  method paper, powerkit, and the software used underneath (SimDesign;
  afex and MASS; lavaan and manymome; and R), each from its own
  `citation()`. Method papers come from powerkit's curated reference list,
  copied from the packages' own `citation()`: Superpower's and
  InteractionPoweR's are included; Spower's and power4mome's, and
  powerkit's own paper, are shown as placeholders. The methods paragraph
  is a placeholder too (not written yet). The repository now has a
  `CITATION.cff`.
* Results record each simulated sample size's seed in
  `provenance$simulations` (with its rejections, analysable replications,
  and whether the required-n curve was fitted to it), so every simulated
  value can be reproduced.
* Moderated mediation (PROCESS models 7 and 14): a run's result now depends
  only on its seed. For a model with a product term, power4mome
  standardises the population by Monte Carlo before its own seed takes
  effect, so results depended slightly on earlier calls in the session (and
  on the number of cores). powerkit now seeds that step too. Results for
  these two models differ slightly from earlier runs with the same seed;
  other designs are unchanged. Their validation is being rerun.
* Tests that use more than 2 cores are skipped on CRAN.

* `validate_spec()` no longer fails with "non-character argument" when a
  field that accepts more than one kind of value is `null`, such as
  `population > sd` in the 2x2 ANOVA designs (reported in PR #4). It now
  gives a plain-English problem: "'population > sd' should be a number or a
  list ([ ... ]), but it is empty (null)." A missing SD is reported as
  missing, and an SD given for a design that has none is reported as a field
  that doesn't belong there.

* Validation (for maintainers): the `full-validation` GitHub workflow now
  installs the system library igraph needs (glpk) before restoring
  packages, checks that the packages load before the chunk starts, and
  doesn't start or summarise a chunk if setup failed.
  `scripts/run-validation.R` stops with a clear message if `--cores` or
  `--cores-per-test` is missing a value or isn't a positive whole number.

* Mediation and moderated-mediation simulations now run in batches of at
  most 200 replications per power4mome call (fewer above 1,000 draws per
  confidence interval), keeping only each batch's counts. Memory use no
  longer grows with the number of replications: before, 10,000
  replications of a PROCESS model 7 design needed many gigabytes, more than
  most laptops have. The method is unchanged (each batch is an ordinary
  `power4test()` call), but results are not identical to earlier,
  unbatched runs with the same seed. The batch size is recorded in the
  result's provenance (`batch_size`). The number of batches depends only
  on the number of replications and the batch size, so the same seed and
  batch size give the same result on any number of cores.
* Validation (for maintainers): a `full-validation` GitHub Actions
  workflow runs one validation chunk on demand on GitHub's machines and
  uploads the results (docs/validation-log.md, "Running the full
  validation on GitHub"); `scripts/run-validation.R --cores-per-test k`
  gives each test k cores (Linux and macOS), and its summary now also
  records the manymome version.

* The "not available yet" messages for a yes/no (binary) X or W in
  regression interactions and mediation designs no longer suggest treating
  the variable as continuous: they say that doing so may give an
  inaccurate power estimate. For regression interactions, a 2x2 ANOVA
  design is suggested only when both X and W are yes/no.
* Validation (for maintainers): published required sample sizes can be
  given as a range (`c(lower, upper)`), which passes if it overlaps
  powerkit's interval, with narrow overlaps reported; and
  `scripts/run-validation.R --retry-skipped` reruns tests saved as SKIP
  (for example, after published values are filled in) without discarding
  other results.
* `run_spec()` now runs every MVP design:
  * basic tests (one-sample, independent and paired t-tests, correlation,
    two proportions, chi-square test of independence) via Spower;
  * two-way regression interactions, with or without measurement error,
    via InteractionPoweR;
  * simple, parallel and serial mediation (PROCESS models 4 and 6) and
    first- and second-stage moderated mediation (PROCESS models 7 and 14,
    index of moderated mediation) via power4mome, with Monte Carlo or
    percentile bootstrap confidence intervals.

  These designs are simulated (`options > nrep` replications, seeded and
  reproducible). Goals: power at a fixed n, or the required n with a 95%
  interval. Every run first checks, on one large simulated data set, that
  the backend reproduces the population you specified.
* One-sided basic tests (`target_test > alternative` `"greater"` or
  `"less"`) test the direction you specify; "greater" means the spec's
  effect (d, dz, r, or p2 minus p1) is positive.
* In paired designs, d_z is the second condition minus the first (in the
  order of X's levels). Printing a paired spec says so, in your labels.
* The two-proportions z test and the Pearson chi-square have no continuity
  correction, as in G*Power.
* Mediation designs use power4mome's default number of Monte Carlo draws
  per confidence interval (1,000) when `options > ci_draws` isn't given,
  and always test with the confidence interval (Boos and Zhang's method is
  off).
* Exact 2x2 ANOVA results now equal a direct `ANOVA_exact()` call with the
  same seed on every platform (they could differ around the 15th decimal
  place).
* Not available yet, with a plain-English message: sensitivity goals for
  designs other than 2x2 ANOVAs; binary X or W in regression interactions
  and mediation designs; measurement error (reliability) in mediation
  designs.
* powerkit is now licensed under the GPL (>= 3).
* New `run_spec()` runs a power analysis for 2x2 between and 2x2 mixed ANOVA
  designs, via Superpower. Goals: power at a fixed n, the required n, or
  the smallest detectable effect (sensitivity: the specified pattern of
  means is scaled, and the effect is reported in your units and as Cohen's
  f). Power is exact by default (`ANOVA_exact()`); set
  `options > method` to `"simulation"` for Monte Carlo simulation (95%
  interval for the required n; `options(powerkit.cores = k)` or
  `POWERKIT_CORES` spreads replications over cores). Every result includes
  a check that Superpower reproduces the specified population and a
  provenance record (spec hash, method, seed, backend, R and package
  versions).
* New optional spec field `options > method` (`"exact"` or `"simulation"`).
* New design specification format (spec version 0.1), defined by the JSON
  schema in `inst/schema/design.schema.json`. It covers the MVP designs:
  basic tests (one-sample, independent and paired t-tests, correlation, two
  proportions, chi-square test of independence), 2x2 between and 2x2 mixed
  ANOVA, two-way regression interactions, simple, parallel and serial
  mediation (PROCESS models 4 and 6) and moderated mediation (PROCESS
  models 7 and 14).
* `read_spec()` reads a spec from a JSON file or string.
* `validate_spec()` checks a spec's structure and that the population it
  describes is possible (e.g. path values imply an R-squared below 1,
  correlations are possible together, cell probabilities add up to 1, the
  sample size splits into whole groups). All problems are reported together
  in plain English.
* `spec_hash()` gives a content hash of a spec that ignores field order.
* Example specs for every template are in `inst/specs/`.
