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
