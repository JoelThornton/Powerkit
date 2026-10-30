# Phase 3b: statistical decisions needed before coding binary X and W

*Decided 29 October 2026 (`decisions.md`): section 1, option B; section 2, the split asked on the mediation cards (50/50 default) and fixed at 50/50 for interactions; reliability for E15's score only. E15 and E16 are built. Sections 3 and 5 remain for E17.*

Phase 3b adds a yes/no (binary) X or W to regression interactions and to
mediation and moderated mediation (build guide, section 8). This page
lists the statistical decisions that coding needs. **Nothing here is
decided by this page.** Where the maintainer has already decided something
(`docs/decisions.md`, 15 October 2026, "Maintainer decisions: binary X and
W phase"), that is quoted, and only what it leaves open is listed.

Sources are the installed packages' own documentation:
- power4mome 0.2.1 help pages: `rbinary_rs`, `sim_data` / `power4test`
  (argument `x_fun` and its section "Specify The Distributions of
  Exogenous Variables Or Error Terms Using `x_fun`"), and the package
  vignette "power4mome" (section on further features);
- InteractionPoweR 0.2.4 help page `power_interaction` (arguments
  `k.x1`, `k.x2`, `adjust.correlations`, `N.adjustment`, `tol`).

Anything not taken from these is marked **unsourced** or **to check**.

## What the backends do (facts)

**power4mome.**
- A binary variable is generated through `x_fun`, for example
  `x_fun = list(x = list(power4mome::rbinary_rs, p1 = .70))` (the
  `sim_data` help page gives this form, for `w`).
- `rbinary_rs(n = 10, p1 = 0.5, pmean = 0, psd = 1)`: "Generate random
  numbers from a distribution of 0 or 1, rescaled to have user-specified
  population mean and standard deviation". `p1` is "the probability of
  being 1, before rescaling". With the defaults, the variable has
  population mean 0 and SD 1, so a path from it in `pop_es` is per SD of
  the variable.
- "To use `x_fun`, the variables must have zero covariances with other
  variables in the population" (`sim_data` help).
- "If a variable is an endogenous variable ... then `x_fun` is used to
  generate its error term" (`sim_data` help): a binary M or Y is not
  covered this way.
- The vignette says "basic support for generating nonnormal variables,
  including dichotomous variables is available" through `x_fun`.

**InteractionPoweR.**
- `k.x1`, `k.x2`: "Number of discrete values for x1 [x2]. Can be used to
  make a variable binary or ordinal."
- `adjust.correlations` (default `TRUE`): "If variables are ordinal or
  binary, should correlations be adjusted so that output data has the
  specified correlation structure?" The adjustment is done by simulation
  (`N.adjustment`, default 1,000,000; tolerance `tol`, default 0.005).
- The group split is fixed at 50/50 (no option for unequal groups; already
  recorded in `docs/decisions.md`, 15 October 2026).

## 1. How users specify the effect of a 0/1 X when paths are standardised

**Already decided (15 October 2026):** "v1 uses fully standardised paths,
following both backends ... A path from a binary X therefore means 'per SD
of X'. Entering a condition effect as Cohen's d (Y standardised, X left as
0/1) comes later."

**What it leaves open.** The SD of a 0/1 variable is sqrt(p(1 - p)), so it
depends on the group split p. The same standardised path therefore means a
different difference between the groups at different splits. For example,
in a regression of a standardised M on X alone, the difference between
the group means is the standardised path divided by sqrt(p(1 - p)): 2
times the path at p = .5, 2.18 times at p = .3. (This is an illustration of
the dependence, not a recommended formula.)

Options (none chosen):
- **A. Standardised path only, per SD of X** (v1 as decided). The app
  explains that the meaning depends on the split.
- **B. Standardised path, with the implied group difference shown** next
  to it (no new input; display only).
- **C. A group difference as the input** (the later Cohen's d option;
  see section 4), converted to power4mome's standardised path using the
  split.

What power4mome's docs say: only that `rbinary_rs()` rescales to the
given `pmean` and `psd`. They don't say how users should think about a
standardised path from a binary variable. **To check** with Shu Fai
Cheung if needed.

## 2. Whether the group proportion is an input

**Already decided (15 October 2026):** "50/50 by default. Unequal groups
only where the backend supports them (power4mome, through `rbinary_rs()`'s
`p1`). Interactions are always 50/50."

**What it leaves open:**
- Whether the app asks for the split at all in the MVP forms, or only in
  an advanced option. Asking matters more under option A, since the split
  changes what a standardised path means.
- Whether the split is a property of the population (the proportion in
  the population) or of the design (the planned allocation). power4mome's
  `p1` is a population probability: each simulated sample has a random
  number of 1s, not a fixed allocation. A planned allocation (exactly n1
  and n2 per group) is **not** what `rbinary_rs()` does. Whether that
  matters for power here is **to check** (it is likely small, but that is
  unverified).
- For interactions, the app has to say the split is 50/50. Whether to
  refuse other splits or to warn is for the maintainer.

## 3. How power4mome generates binary variables (and what follows)

From the docs above: through `x_fun` with `rbinary_rs()`, which takes `p1`
and is rescaled to `pmean = 0`, `psd = 1` by default.

Open points:
- **Zero covariance.** Already decided: a binary X or W correlated with
  the other predictors isn't supported, and the user is told so. Left
  open: how the spec expresses this (forbid `X<->W` for a binary X or W,
  or require it to be 0).
- **Binary W in moderated mediation.** With `x_fun` on W and a product
  term X:W, the population is standardised by Monte Carlo
  (`psi_std_monte_carlo()`), which now runs under powerkit's seed (PR #20).
  Whether the standardisation uses `x_fun`'s distribution for W is **to
  check** in power4mome's source or with its author.
- **Binary M or Y.** Not covered by `x_fun` (it would set the error
  term). Out of scope for phase 3b unless the maintainer decides
  otherwise.
- **The Monte Carlo CI with a binary X.** Whether power4mome's Monte
  Carlo CI test has been checked with a binary X is an open question for
  Shu Fai Cheung (`docs/decisions.md`, 15 October 2026).
- **InteractionPoweR.** With `adjust.correlations = TRUE`, the
  correlations the user enters are those of the observed binary data
  (point-biserial for a binary X with Y). Whether the form asks for those
  correlations or for something users find easier to judge (such as a
  group difference) is open. The analytic `power_interaction_r2()`, which
  powerkit uses only to bracket N, is documented as valid only for
  continuous, normally distributed variables. Whether bracketing with it
  is still safe for a binary X or W is **to check** (the search widens
  its grid if the bracket is off, but that hasn't been tested for binary
  variables).

## 4. How this interacts with the planned Cohen's d departure

**Already decided (15 October 2026):** Cohen's d input "comes later. It
will be a departure, so it goes in `docs/conventions.md` with a test
showing the size of any difference."

Open points, for when it is built:
- **Which SD standardises d.** For the X → M path: M's total SD, or M's SD
  within groups (residual). For the X → Y path: Y's total SD, or Y's SD
  within groups given M (and W). These give different numbers. **Unsourced, to check:** that G*Power's d
  for two groups uses the pooled within-group SD, and that power4mome's
  standardised paths use total SDs; and which convention each established
  mediation tool uses.
- **Which effect d describes.** The a path (X → M), the direct effect
  (X → Y given M), or the total effect of X on Y. Users from experimental
  psychology may think of d as the total effect, but the model needs
  paths.
- **The conversion depends on the split** (section 1), so the departure
  test must show the size of the difference at more than one split.
- **Consistency with the basic tests.** powerkit's independent-samples
  t-test uses d with the pooled SD (Spower's convention). Whether the
  mediation d should match that definition is for the maintainer.
- **Departure size.** Whatever is chosen, CLAUDE.md requires a test
  showing the size of the difference from the standardised-path
  convention, a note in `docs/conventions.md`, the results screen and the
  methods paragraph.

## 5. Validation targets (from the build guide, section 8c)

Already listed there: direct-call agreement with `power_interaction()`
(`k.x1` / `k.x2`) and with `power4test()` (`x_fun` with `rbinary_rs()`);
Type I error with a binary X or W; Donnelly, Jorgensen & Rudolph (2023),
which fits only if conditional indirect effects become a target; an
InteractionPoweR example with a binary variable (to find); and agreement
between a binary-W interaction and the 2 x 2 ANOVA when X and W are both
binary. Open: whether that last cross-check is expected to agree exactly
(the ANOVA's cells have fixed sizes; InteractionPoweR's median split and
the regression parametrisation may differ), which needs a statistical
judgement before a tolerance can be set.
