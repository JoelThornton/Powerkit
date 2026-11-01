# Planning a Bayesian study: a design note

*31 October 2026. A draft for the maintainer to decide on, for `next.md`
item 4 (Bayes factors beyond the t-tests). Nothing here is built yet. The
numbers are computed with bfpwr 0.1.6, the package powerkit already uses for
its Bayes factor t-tests; where a claim rests on a source that is not yet in
`engine/inst/citations/refs.bib`, it says so.*

## The worry

Much of what goes wrong with power analysis in psychology is ritual rather
than maths: a conventional effect size (d = 0.5), a conventional threshold
(p < .05), a conventional target (80%), entered because they are expected.
Bayes factors can inherit the same ritual. "The chance that BF10 exceeds 10
if d is 0.5" is a power analysis with a new threshold; it is useful, but on
its own it invites "BF > 10" to become the new "p < .05", and it plans
around a single guessed effect, as the frequentist version does.

Bayesian planning has more to offer than that, and powerkit could show it
honestly. This note sets out what the options are, what the package already
installed can do, and a recommendation.

## What powerkit does now

The one-sample, paired and two-group t-test cards offer a Bayes factor test
version (bfpwr's `powertbf01()`, closed form; Pawel and Held, 2025, from
`citation("bfpwr")`). It gives the chance the Bayes factor passes a
threshold (BF10 of 10 by default, Cauchy analysis prior with scale 0.707),
and, with no effect, the chance of strong evidence for none and of
misleading evidence. Fixed N, equal groups.

It plans for exactly the effect entered unless the user gives an SD for
their uncertainty. That is Departure 15 (`conventions.md`), still waiting
for the maintainer's decision; bfpwr's own default is different (below).

## Two priors, not one

bfpwr keeps two priors apart, and its vignette (`using-bfpwr`, section on
the z-test Bayes factor) explains why:

- the **analysis prior** is the prior the Bayes factor will be computed
  with once the data are in (`plocation`, `pscale`): what a sceptical
  reader should accept;
- the **design prior** is what the planner believes about the true effect
  now (`dpm`, `dpsd`): "a design prior that encodes more optimistic
  assumptions about the parameter than the analysis prior", or the null
  itself, "to compute the probability of misleading evidence".

Averaging the chance of compelling evidence over a design prior with some
spread is often called *assurance* (a term from the Bayesian design
literature; its source still has to be added to `refs.bib`). It answers a
better question than power at one guessed d: given what I honestly believe,
and its uncertainty, how likely is this study to be informative?

The choice matters a lot. Two groups of 120, analysis prior Cauchy(0.707),
compelling evidence meaning BF10 > 10:

| What the planner believes about d (design prior) | Chance of BF10 > 10 |
| --- | --- |
| Exactly 0.5 (powerkit's default) | 80.3% |
| About 0.5, give or take 0.15 (normal, SD 0.15) | 71.1% |
| About 0.3, give or take 0.15 | 32.5% |
| bfpwr's default: the analysis prior itself (normal, mean 0, SD 0.707) | 58.7% |

And the sample size for 80%: 120 per group if d is exactly 0.5, 159 if it
is about 0.5 give or take 0.15, 745 if it is about 0.3 give or take 0.15.
Honest uncertainty about the effect costs participants, which is exactly
what a single guessed effect hides.

## The whole spread of outcomes, not one probability

A Bayes factor can come out three ways: compelling evidence for an effect,
compelling evidence for no effect, or inconclusive. And when the truth is
the opposite of what it says, it is misleading. bfpwr gives all of these
(`ptbf01()`, its distribution function, with the design prior set to the
effect or to the null).

They expose something a single "power" hides. With 120 per group, the
largest BF01 the data can produce (t = 0) is 7.1, so "BF > 10 either way"
can never be met in favour of no effect at this size: the chance is 0%,
however true the null is. Evidence for the null needs far more people
(largest BF01 4.7 with 50 per group, 14.1 with 500, 19.9 with 1,000; with
the null true, BF01 passes 3 69% of the time with 50 per group, 82% with
120, 92% with 500). Symmetric thresholds are not symmetric in what they ask
of a study. A planning screen that shows the three outcomes side by side,
under the effect and under the null, makes this visible.

## Sequential designs

A Bayes factor can be checked as the data come in, stopping when it is
compelling either way or at a maximum N. The planning question then
becomes how many people the study is likely to need, and how often it will
stop at the maximum still inconclusive. This is the main argument for
Bayes factor design analysis in psychology (Schönbrodt and Wagenmakers's
BFDA; not yet in `refs.bib`), and the BFDA package is on GitHub only.

bfpwr has no sequential functions. Two routes:

- **BFDA from GitHub**: established, but outside CRAN; renv and the online
  app can install GitHub packages (they install powerkit itself that way).
- **powerkit's own simulation**, computing each look's Bayes factor with
  bfpwr's `tbf01()` on simulated data: the same kind of experiment as
  MANOVA's, with no new maths, and the same two priors as above.

Either way, the frequentist error rates of a sequential design depend on
the stopping rule, and a simulation shows them; whether the Bayes factor's
own interpretation is unaffected by optional stopping is a claim to check
against its sources before powerkit states it.

## Planning without a threshold

A different goal avoids thresholds altogether: plan for how precise the
estimate will be, for example how narrow the posterior (or credible)
interval for d is likely to be, or how likely it is to fall inside a region
of practical equivalence. This is the Bayesian counterpart of precision
planning (`next.md`, item 4, decided for the frequentist interval) and
fits powerkit's aim of moving away from ritual. No package has been checked
for it yet.

## A Labs Bayes mode

The maintainer's idea, sketched:

1. Choose the analysis prior (its centre and scale), with a picture of it
   and a sentence on what it claims.
2. Choose the design prior separately: a single effect, or an effect with
   a stated uncertainty, again drawn.
3. See, for a chosen N (a slider), the three outcomes and the misleading
   evidence, under the design prior and under the null, as the table
   above but live; and the N needed for a chosen chance of compelling
   evidence.
4. Optionally, sequential: the distribution of the N at which the study
   stops.

Every number from bfpwr through the engine, as the other Labs tools do.
It teaches what the cards can't: that the priors, the thresholds and the
uncertainty about the effect are choices with consequences.

## Recommendation

1. **Decide Departure 15 with this in mind.** Keep "exactly the effect
   entered" as the default only if the card also shows the result under a
   design prior with spread; otherwise make a stated uncertainty the
   default. The table above is the case for showing both.
2. **Build the Labs Bayes mode first** (fixed N, t-tests), from bfpwr, to
   see how the two priors and the three outcomes read to researchers
   before changing the cards.
3. **Then extend the cards**: proportions (bfpwr's binomial Bayes factor)
   and correlations (its z-test Bayes factor on Fisher's z), with the
   three-outcome display.
4. **Sequential designs by powerkit's own simulation** using bfpwr's
   `tbf01()`, rather than depending on a GitHub-only package, unless BFDA
   turns out to do something a simulation can't.
5. **Add the sources first**: the assurance literature, Schönbrodt and
   Wagenmakers on BFDA, and the paper the maintainer linked
   (arXiv 2502.02914, which this session could not open: the environment's
   network doesn't allow arxiv.org), each checked against the original
   before anything quotes them.

## Decisions for the maintainer

- Departure 15: the default design prior, and whether the card shows both.
- Whether the Labs Bayes mode comes before any change to the cards.
- Sequential designs: our own simulation, or BFDA.
- Whether a precision goal for Bayesian estimation belongs in the queue.
