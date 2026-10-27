# Routing prototype: how to run it

A clickable prototype of how a psychologist gets from their study to the
right power analysis, built from [`decision-tree.md`](decision-tree.md).

**It shows which analysis a study needs**, what the user would enter,
which backend would run it and whether powerkit runs it yet. For E1–E9 the
input screen also calculates: it passes the checked spec to the engine's
`run_spec()` and shows the result (phase 5). E9 runs in the background,
with a progress bar and a Cancel button. The app never computes power
itself. Every other end point is guidance only for now. Every screen
carries the banner *"Prototype: calculations are available for E1–E9;
other designs show guidance only for now."* It is not deployed
anywhere.

Everything it shows comes from one data file,
[`app/routing/tree.yaml`](../app/routing/tree.yaml). A test checks that this
file and `decision-tree.md` agree, so they can't drift apart.

## Run it (step by step)

**Trying it for the first time, with no R experience?** Follow
[`run-it-yourself.md`](run-it-yourself.md): it installs R, downloads
powerkit and starts it with one line, `source("run_powerkit.R")`, which
installs the recorded packages and the engine if needed. The steps below
are for people who already have R and the project set up.

You need R and RStudio. You don't need to know Shiny.

1. **Open the project.** In RStudio: *File → Open Project…* and choose
   `Powerkit.Rproj` in the repository folder. (This also starts renv, which
   keeps the project's packages separate from your others.)
2. **Install the packages it needs, once.** `shiny`, `bslib` and `yaml`
   are all recorded in `renv.lock`, so in the RStudio *Console* (bottom
   left) you can paste this and press Enter:

   ```r
   renv::restore()
   ```

   That installs the versions the project records (it installs the
   engine's packages too, which takes a while the first time). If you only
   want the prototype, this is enough:

   ```r
   install.packages(c("shiny", "bslib", "yaml"))
   ```
3. **Start the prototype.** In the Console:

   ```r
   source("run_routing_prototype.R")
   ```

   A browser window (or RStudio's viewer) opens with the prototype. If a
   package is missing, the script stops and prints the install line from
   step 2; it never installs anything itself.
4. **Stop it** by pressing *Esc* in the Console, or the red *Stop* button
   at the top of the Console.

Alternatively, open `app/routing/app.R` and click **Run App** at the top of
the editor.

## What you'll see

The first screen offers three routes (decision-tree.md, 4.1). **Every
route starts with four screening questions** (decision-tree.md, chart S):

1. What kind of outcome?
2. How are the data grouped?
3. How many times is each person measured?
4. What's your goal?

Designs powerkit doesn't cover, such as counts, nested or dyadic data,
trends over time, equivalence and precision, leave there at an honest card
before any test is suggested. Your screening answers also shape the later
questions: for example, after "Once", options for the same people measured
twice aren't offered, and the outcome and "who gives the data" questions
aren't asked again. Every question, and the end-point list, also offers
**"None of these fit / I'm not sure"**, which leads to a card suggesting a
statistician. Why this exists: [`routing-audit.md`](routing-audit.md).

After the screening:

- **I know my analysis.** A list of the end points that fit your
  screening answers, grouped into "Runs in powerkit (validated)", "Runs,
  validation in progress", "Coming soon" and "Not in powerkit yet". For
  example, after "Twice" it doesn't offer the independent-groups tests.
  Clicking one opens its card.
- **Help me choose.** The tree, one question per screen. A row of chips
  shows your answers so far: click any chip to go back to that question.
  **Back** steps back one question. The tree ends on an end-point card.
- **Plan my whole study** (the guided route). Describe the variables once
  (main predictor, outcome, mediators, moderator, covariates). The options
  follow the screening answers: the outcome types S1 allows, and, after
  "Twice", "the same people in two conditions, or before and after" and a
  baseline covariate. Then tick the
  analyses you plan, mark the primary ones, and choose how they support the
  claim (each alone; all must be significant; any one is enough). The plan
  shows one card per analysis, plus clearly marked placeholders where the
  combined N and the consistency check will appear once the engine is
  connected.

Each **end-point card** shows:
- the analysis in plain English, and its standard name;
- what the user would enter;
- the effect-size justification prompt;
- the backend and default method;
- its status:
  - *Runs in powerkit* (green), validated, with links to the validation
    log and test file;
  - *Runs, validation in progress* (blue, with a badge), for designs that
    run but whose full validation run isn't recorded yet (none at present;
    the group is hidden in the list when it's empty), with the same links;
  - *Coming soon*;
  - a generic card for a category of design powerkit doesn't cover
    (time-to-event, dyadic data, precision), with the neutral sentence
    *"Established tools exist for this design; powerkit hasn't checked
    them."* (whether to name the tools is open question 18);
  - *Not in powerkit yet: use [package]*, with a link and one line on what
    the package does, taken from [`coverage.md`](coverage.md);
  - for analyses no tool offers (E30, E32, E39, E42, and Cochran's Q in
    E26): *no ready-made tool*, with the two options, a custom simulation
    in R (for example with Spower) or advice from a statistician. E42 also
    says it isn't covered by the five tools powerkit builds on.

Screenshots of each route are in
[`figures/routing-prototype/`](figures/routing-prototype/). Worked examples for every design
in the routing audit, with a screenshot of each end card, are in
[`walkthroughs.md`](walkthroughs.md). To re-run them against the running
prototype: `node app/routing/walkthroughs/screenshots.js` (needs Node and
Playwright; the script's header explains).

## "Something doesn't fit?" (for user testing)

Every card, including the cards on the guided route's plan, ends with a
**Something doesn't fit?** link. It opens the exact path taken (the route,
each question and answer, the guided route's variables, and the end
point) as text with a **Copy the path** button, and asks what the user
expected instead. Copying happens in the browser; nothing is sent
anywhere. How the copied paths are used in testing sessions:
[`user-testing.md`](user-testing.md); the test cases they become:
[`test-cases.md`](test-cases.md).

## Input screens (E1–E14)

Cards for the end points powerkit runs (E1–E14) have an **Enter your
values** button. It opens a screen with one field for each line of the
card's "What you would enter", with the plain-English hints beside them,
followed by the closing questions (what you want to find out, alpha,
power or sample size, direction where it applies, where the effect size
comes from, and expected attrition).

- **Effect sizes, SDs and correlations start empty** and must be filled
  in, with a justification. Whether they should offer suggested values
  instead is undecided: the setting `effect_size_inputs` (shown on the
  screen; `judgement-calls.md`, B10).
- **Other settings start at the default of the tool powerkit wraps**, and
  each says whose default it is (for example "pwr's default
  (pwr.t.test(sig.level = 0.05), pwr 1.3-0)"). The defaults were read from
  the installed packages' function signatures. Where a tool has no
  default (pwr, Spower, Superpower and InteractionPoweR have no target power),
  the field starts empty and says so.
- **Check my answers** first checks the fields on the screen (empty,
  not a number, out of range), naming each by its label. It then builds a
  design spec and checks it with the engine's `validate_spec()`, showing
  the engine's messages with the screen's field names in place of spec
  paths.
- **E1–E6 ask how power is worked out**: pwr's formula (the default) or
  Spower's simulation "if you expect your data won't meet the test's
  assumptions". For E2 the choice appears only with Student's t-test;
  Welch's is always simulated (no pwr formula).
- **Every screen has a "Random seed" field**, starting at powerkit's fixed
  default (1, `forms.yaml`, `default_seed`), so the same answers always
  give the same result (`judgement-calls.md` B15).
- **E1–E9 calculate** (phase 5): a valid spec goes to the engine's `run_spec()` and the screen
  shows the result.
- **E10–E14 (mediation, moderated mediation), power at a fixed N** start
  with a rough preview:
  the same spec and seed with 100 simulations, in a separate R process
  with a progress bar and Cancel, shown as a range ("Rough preview from
  100 simulations: power is likely between X% and Y%. Don't report this;
  run the full analysis."). It has no script or citations. Then, for
  mediation power at a fixed N (E10–E12), **Run the full analysis** (the
  expected wait is on the button) runs the app's defaults in the
  background, as for E9, and shows the usual result screen. For moderated
  mediation, **Download R script to run the full analysis on your
  computer** gives a script (the engine's `export_run_script()`) with the
  expected run time and what to install. A required N (E10–E14) has no
  preview and goes straight to the R script. Decided in
  [`phase5-simulations.md`](phase5-simulations.md). Screenshots in
  `docs/figures/results/`: `preview_E10_power.png`,
  `full_run_progress_E10_power.png`, `full_run_E10_power.png`,
  `preview_script_E13_power.png` and `script_E10_sample_size.png`.
- **E9 (interaction) runs in the background** (`forms.yaml`,
  `background`): a separate R process (callr) runs the same
  `run_calculation()`, so the app stays responsive. The screen shows an
  estimated progress bar, labelled as an estimate from the usual run time
  (about 5 seconds for power, about 80 seconds for a required N; the
  backend doesn't report its own progress), the time so far, and a
  **Cancel** button that stops the process. Leaving the screen, starting
  a new check or closing the browser also stops it. Screenshots:
  `docs/figures/results/progress_E9_sample_size_1000.png` and
  `result_E9_sample_size_1000.png`.
- **Copy my answers** copies the route taken, the end point and the values
  entered as plain text, to share with a colleague. The text is also shown
  in a box, in case the browser blocks copying.
- The screens are described in `app/routing/forms.yaml`; the logic is in
  `R/forms.R` and the screen in `R/forms_ui.R`.

### The result screen (E1–E9)

- **The number in plain English**, matching what the user asked for: the
  required N (with the size per group or per cell), the power at the given
  N, or the smallest detectable effect (E7, E8). Simulated results give
  their 95% interval or Monte Carlo standard error. A fixed line says
  this is planned power, not "observed power".
- **The inputs it used** (the values entered), **the backend credited by
  name** with its version and the function powerkit called, the **validation
  status** (green "Validated" or "Validation in progress", with the card's
  validation note), and **where powerkit differs from the tool's defaults**
  (the card's departures, from `conventions.md`).
- **Download R script** (the engine's `export_script()`: reproduces the
  result with the backend package alone) and **Citations**
  (`export_citations()`).
- **The methods paragraph** is a placeholder.
- A reproducibility record (backend, method, seed, spec hash, R and
  package versions, check run, run time) and the spec that was run.
- **The seed** is shown under the result. A simulated result adds
  "Calculated by simulation with [k] replications; a different seed can
  shift the result slightly." The seed is written into the spec, the
  reproducibility record and the R script.
- Undecided, shown as placeholders on the screen: how results are worded
  (`result_wording`), how N is rounded and reported (`n_rounding`), and
  whether to show a power curve (`power_curve`); `judgement-calls.md`
  B11–B13. The seed (`calculation_seed`, B15) is decided: a fixed
  default.
- The logic is in `R/results.R`.

**The engine is used read-only.** The prototype uses the installed
`powerkit` package if there is one, or loads `engine/` with
`pkgload::load_all()` (about 5 seconds, once per session). It calls only
`validate_spec()`, `run_spec()` (E1–E9), `export_script()` and
`export_citations()`; it never computes power itself. Where neither is available, the screen says the spec
couldn't be checked, and the tests that need the engine are skipped
locally. **On GitHub the app-tests job installs the engine** (from
`engine/`, with the package versions in `renv.lock`), so those tests run
there, and fail rather than skip if the engine can't be loaded
(`POWERKIT_APP_TESTS_NEED_ENGINE`).

## Recording your decisions

Judgement calls and open questions that `decision-tree.md` leaves undecided
appear in the app as grey dashed placeholders labelled *"Undecided, for the
maintainer"*. The last tab, **For the maintainer: undecided settings**,
lists them all.

These are shown only in the maintainer's view, so the public site doesn't
show them: open the app with `?view=maintainer` at the end of its address
(for example
<https://joelthornton-powerkit.share.connect.posit.cloud/?view=maintainer>),
or run it with the environment variable `POWERKIT_MAINTAINER_VIEW=true`.

## Links to a page

Each tab has its own address: `?page=about`, `?page=whats-new`,
`?page=labs` or `?page=feedback` at the end of the app's address (the plan
tab is the plain address; `?view=maintainer&page=maintainer` opens the
maintainer's tab). The online app runs inside Posit Connect Cloud's frame,
which keeps the browser's address bar from changing, so the top bar has a
"Copy link to this page" button that copies the public address with the
page on show. Run on one's own computer, the address bar follows the tab.

Each is a setting in `app/routing/tree.yaml` (the `settings:` section). To
record a decision, change its `value:` from `null` to one of its option
keys, for example:

```yaml
  - key: alpha_power_defaults
    ...
    value: conventional
```

Restart the prototype and the placeholder becomes "Maintainer decision: …".
No code changes are needed. One setting also changes the routing: setting
`guided_route` to `"no"` removes the "Plan my whole study" route.

## Marking an end point as validated

When a full validation run is recorded in `docs/validation-log.md`, flip
the end point's status in `app/routing/tree.yaml`:

```yaml
  E9:
    status: runs_validated              # was: runs_validation_in_progress
    validation:
      note: "Full run passed (date)."   # what the card says
```

Then change the same row's "Validated?" cell in `decision-tree.md` (table
2.3) to start with "Yes". The docs-match test checks the two agree.

## Changing the tree

Edit `app/routing/tree.yaml`. If you add, remove or rename an end point or a
question, make the same change in `decision-tree.md` (table 2.2 or 2.3),
or the docs-match test will fail. That is deliberate.

Three fields in `tree.yaml` carry the screening answers through the tree
(its comment above `nodes:` explains them):
- `sets` on an option records an answer, for example `sets: {times: once}`;
- `when` on an option shows it only for matching answers, for example
  `when: {times: twice}`;
- a node with `branch_on` is never shown. It routes on a recorded answer,
  because the screening already asked it.

The safety net's wording and target are in `safety_net:`. To change the
screening wording (open question 16), edit the `s1` to `s4` and `t1`
nodes, and the S1–S4 and T1 rows of table 2.2.

## Accessibility

Checked on 16 October 2026 with axe-core 4.10.2 (WCAG 2.1 A and AA, plus
its best-practice rules) on 14 screens (including the input screen empty, with problems and checked, and an open "Something doesn't fit?") at desktop width and at phone width
(375 px):
- start;
- a screening question;
- a card that runs (E2), a not-in-powerkit card (E45) and the safety-net
  card;
- the end-point list;
- the guided route's three screens;
- the maintainer tab.

All 20 runs found no violations and no sideways scrolling. To re-run:
`node app/routing/walkthroughs/accessibility.js`, with the prototype
running.

**Fixed in this pass:**
- **Colour contrast:**
  - a darker primary blue (#0a5a8c), because the default (#007bc2) was
    4.28:1 on the page background;
  - help text on the choice buttons was faded with opacity (3.2:1);
  - question IDs were 4.4:1;
  - the maintainer placeholders were faded to about 2.7:1 by a clash with
    Bootstrap 5's own `.placeholder` class, which is now overridden.
- **Structure:**
  - the page declares its language;
  - a header and a main landmark;
  - a top-level heading, visually hidden;
  - heading levels no longer skip: each screen's title is a second-level
    heading, with card sections below it;
  - the settings table has a caption and column headers, and scrolls
    inside its own box at phone width (it made the whole page scroll
    sideways by 360 px).
- **Keyboard:** after each answer, focus moves to the new screen's heading.
  Before, it fell back to the top of the page. Every choice, chip and
  button is a native button, so Tab, Enter and Space work.
- **Touch targets:** the answer chips are at least 44 x 44 px (fixed
  16 October 2026).
- **Question IDs:** "Question Q1" and "Screening question S2" are hidden
  from users and screen readers (`hidden`, `aria-hidden`), and kept in the
  page source (`data-question-id`) for tests and reviewers. The E-number
  on each card is still shown.
- **Not by colour alone:** every status says what it is in words: "Runs in
  powerkit", "Runs, validation in progress" (also a labelled badge),
  "Coming soon", "Not in powerkit yet". The undecided placeholders are
  labelled "Undecided: for the maintainer".

**Not checked, or not clear:**
- **Screen readers:** not tested with a real one (NVDA, VoiceOver). The
  focus move announces the new heading in principle; that needs
  confirming.
- **Zoom:** 200% zoom and text-only zoom weren't tested separately from
  the phone-width check.
- **Placeholder style:** the dashed grey boxes rely on a dashed border
  and grey background to look different from user-facing text, as well as
  on their label.
- **Charts:** the mermaid flowcharts in `docs/` have no text alternatives
  beyond their surrounding text.

## Run the tests

In the RStudio Console, from the project folder:

```r
testthat::test_dir("app/routing/tests/testthat")
```

They take a few seconds (plus about 5 seconds to load the engine for the
input-screen checks, where it is available) and check:
- that every route reaches an end point, with no dead ends, unreachable
  questions or loops, following the screening answers as a user would;
- that every route starts with the screening, and that no test powerkit
  runs is suggested before it ends;
- that every question, in every context a user can reach, offers "None of
  these fit / I'm not sure";
- that each misroute found by the [routing audit](routing-audit.md) now
  reaches the right end point (`test-misroutes.R`);
- that each worked example in [`walkthroughs.md`](walkthroughs.md) still
  reaches the end point recorded for it, in all three routes
  (`test-walkthroughs.R`);
- that every guided-route answer combination leads somewhere;
- that every card offers "Something doesn't fit?" with the full path,
  and that the app makes no network calls (`test-feedback.R`);
- that each input screen asks for every line of its card, starts effect
  sizes empty, labels every field and default, catches missing and
  out-of-range values, and builds a spec that passes `validate_spec()`
  (`test-forms.R`; skipped where the engine isn't available);
- that every "not in powerkit" end point has a package, a link and a
  description (generic cards: their own text instead);
- that every MVP capability in `coverage.md` appears in the app;
- that every screen renders with the prototype banner;
- that the app never calls a power function, and uses only
  `validate_spec()` from the engine;
- that `tree.yaml` matches `decision-tree.md`.

They run on GitHub on every pull request and push
(`.github/workflows/routing-prototype-tests.yaml`). That job runs in the
CI image, which holds the package versions in `renv.lock`, and installs
the engine itself, so the input
screens' checks with `validate_spec()` run there too; the prototype never
computes power. They aren't part of the engine's `devtools::test()`.
