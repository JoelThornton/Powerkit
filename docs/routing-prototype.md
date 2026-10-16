# Routing prototype: how to run it

A clickable prototype of how a psychologist gets from their study to the
right power analysis, built from [`decision-tree.md`](decision-tree.md).

**It is routing only.** It shows which analysis a study needs, what the
user would enter, which backend would run it and whether powerkit runs it
yet. It makes no engine calls and calculates nothing. The maths is wired in
at build phase 5. Every screen carries the banner *"Prototype: shows which
analysis you need; it doesn't calculate anything yet."* It is not deployed
anywhere.

Everything it shows comes from one data file,
[`app/routing/tree.yaml`](../app/routing/tree.yaml). A test checks that this
file and `decision-tree.md` agree, so they can't drift apart.

## Run it (step by step)

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

## Recording your decisions

Judgement calls and open questions that `decision-tree.md` leaves undecided
appear in the app as grey dashed placeholders labelled *"Undecided, for the
maintainer"*. The second tab, **For the maintainer: undecided settings**,
lists them all.

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
its best-practice rules) on ten screens at desktop width and at phone width
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
- **Touch targets:** the answer chips are smaller than 44 x 44 px on a
  phone.
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

They take a few seconds and check:
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
- that every "not in powerkit" end point has a package, a link and a
  description (generic cards: their own text instead);
- that every MVP capability in `coverage.md` appears in the app;
- that every screen renders with the prototype banner;
- that the app never calls the engine;
- that `tree.yaml` matches `decision-tree.md`.

They run on GitHub on every pull request and push
(`.github/workflows/routing-prototype-tests.yaml`). That job installs only
the prototype's packages; it doesn't install or run the engine. They
aren't part of the engine's `devtools::test()`.
