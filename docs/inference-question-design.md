# Asking what users will conclude: design options

*Drafted 17 October 2026. **Options only: nothing here is decided, and
nothing is recommended.** Linked from
[`judgement-calls.md`](judgement-calls.md), B6 and G7.*

## What this page is for

The guided "plan my whole study" route
([`decision-tree.md`](decision-tree.md), section 4) asks users to mark their
primary analyses. Step 3 then asks how those analyses support the study's
claim. This page sets out how that question could be asked **before** the
user sets alpha and power, in plain English, and what each answer would do
to alpha, power and N.

## Where the idea comes from, and what has been checked

- The three cases are from Mark Rubin's work on multiple testing: Rubin
  (2021), *Synthese*, 199, 10969–11000, doi:10.1007/s11229-021-03276-4, and
  Rubin (2024), *Methods in Psychology*, 10, 100140,
  doi:10.1016/j.metip.2024.100140. **Both were opened on 17 October 2026**
  from texts the maintainer supplied. Rubin (2021) was read in the author
  preprint (SSRN abstract 3904565), which gives no volume or pages; the
  volume and pages above are as printed in Rubin (2024)'s reference list.
  Page numbers for Rubin (2021) below are the preprint's. Rubin (2024) was
  read in the published version.
- The cases below are now quoted from the papers. The conditions for
  disjunction are fuller in the paper than in the maintainer's earlier
  description; the differences are set out under "Guidance on choosing
  'any one is enough'".
- **Rubin's framework is about when to adjust alpha.** He does discuss
  power, for example: conjunction tests "lack statistical power" (Rubin,
  2021, author preprint, p. 7, with a worked example; also pp. 16, 17, 19
  and 20), and inconsistent
  corrections "lead to an unjustifiable loss of statistical power" (Rubin,
  2024, p. 4). **What to power the study for in each case, and how N
  changes (the tables below), is not in either paper. That part is
  powerkit's own extension and should be checked with Mark Rubin before it
  is used.**
- **Two different authors.** Mark Rubin (2021, 2024) wrote the multiple
  testing papers. Mikael Rubin (2025, *International Journal of
  Psychology*, doi:10.1002/ijop.70017) wrote a review of power analysis in
  R, cited elsewhere in the roadmap. They should not be confused in
  citations.
- The competing view is represented by Frane (2019), not opened. As
  printed in Rubin (2024)'s reference list: "Frane, A.V., 2019. Misguided
  opposition to multiplicity adjustment remains a problem. J. Mod. Appl.
  Stat. Methods 18 (2), eP2836. https://doi.org/10.22237/jmasm/1556669400."
- Mark Rubin's blog post on redundant corrections
  (markrubin.substack.com/p/redundant-multiple-testing-corrections) could
  not be fetched: the session's proxy refused the host (403). Nothing here
  draws on it.

## The question

**Draft wording (one option):**

> **Your study tests more than one hypothesis. Which of these is closest to
> what you plan to conclude?**
>
> 1. **Each separately.** I will draw a separate conclusion from each test.
>    For example: "the training improved memory" and, separately, "the
>    training improved mood".
> 2. **One overall idea, supported if any one test is significant.** For
>    example: "the training has *some* benefit", and a significant result on
>    memory *or* mood would count.
> 3. **One overall idea, supported only if all the tests are significant.**
>    For example: "the training improves memory *and* mood", and I will only
>    claim it if both are significant.
>
> *Not sure?* (leads to the explanation below, and to the safety net.)

Other ways to ask it (options, not chosen):

- as a sentence to complete: "I will claim my hypothesis is supported if
  … (each test on its own / any one test / every test) is significant";
- with the user's own hypothesis labels (H1, H2, H3) filled in from the
  guided route's step 2;
- asked per group of hypotheses, for a study with more than one overall
  idea.

## What each answer means

| Answer | Rubin's name | Alpha for each test | What "power" means | Effect on N |
| --- | --- | --- | --- | --- |
| 1. Each separately | Individual testing | The alpha the user sets, no correction | Power for each test on its own | The largest N of the separate analyses |
| 2. Any one is enough | Disjunction testing | Corrected (for example Bonferroni, alpha / k) | Either each test's own power at the corrected alpha, or the power that at least one is significant (to be decided) | Rises if each test must keep its own power at the corrected alpha |
| 3. All must be significant | Conjunction testing | The alpha the user sets, no correction | Power that **all** tests are significant (joint power), which is lower than each test's own power | Rises if joint power is the target |

### 1. Each separately (individual testing)

Each conclusion stands or falls on its own test. Rubin (2021, author
preprint, p. 7): "individual testing does not require an adjustment to the
alpha level of each test", and this applies "even when multiple instances
of individual testing take place side-by-side within the same study"
(p. 8). Power is planned for each
test as if it were the only one, which is what the single-analysis routes
and the established tools already do. The study's N is the largest of the
separate Ns.

*Plain-English explanation for the screen:* "Each result is its own
finding, so each test uses the alpha you chose. The sample size is the
largest one any of your tests needs."

### 2. One overall idea, supported if any one test is significant (disjunction)

If any one significant result would support the claim, there are several
chances to get a false positive for that one claim. With independent tests
at alpha = .05 and every null true, the chance of at least one false
positive is .098 for 2 tests and .143 for 3 (table 2 below; Rubin, 2021,
author preprint, p. 5, gives the same .098 for two tests). So a correction
is needed: "alpha adjustment is only appropriate in the case of
disjunction testing" (Rubin, 2021, author preprint, p. 1). The correction
lowers each test's alpha and so raises the N each test needs.

*Plain-English explanation for the screen:* "Because any one of your
results would count, chance alone has more opportunities to give you a
false positive. Each test therefore uses a stricter alpha (your alpha
divided by the number of tests), which needs a larger sample."

### 3. One overall idea, supported only if all are significant (conjunction)

If the claim needs every test to be significant, a false positive on the
claim needs every test to give one. No correction is needed: conjunction
testing "does not require an adjustment to the alpha level for tests of
each constituent null hypothesis" (Rubin, 2021, author preprint, p. 6,
citing Berger, 1982, among others; the intersection–union principle,
`decision-tree.md` 3.5). But the chance of getting **all** significant
results is lower than each test's own power: two independent tests at .80
each give .80 × .80 = .64. This is Rubin's own example: two tests "each
tested with a power value of .80" give "a power level of .64, which is
lower than the desired power of .80" (p. 7).

*Plain-English explanation for the screen:* "Your claim needs every test to
come out significant. That doesn't need a stricter alpha, but it is harder
to get all of them than any one, so a study powered at 80% for each test
has less than 80% power for the claim as a whole."

## Guidance on choosing "any one is enough"

**What the maintainer described (17 October 2026), before the papers were
opened:** a set of tests treated as "any one is enough" should meet both
of these:

1. **The family includes all, and only, the relevant hypotheses.**
2. **The hypotheses are interchangeable for the joint claim.**

**What Rubin (2021, author preprint, pp. 16–17) says.** He gives two
requirements for testing *any* joint hypothesis (disjunction or
conjunction), and one extra assumption for disjunction:

- **First requirement (any joint hypothesis):** "the hypothesis should
  allow a statistical inference that has relevant and meaningful
  theoretical and/or practical implications". To meet it, "the family must
  contain all relevant constituent hypotheses and no irrelevant constituent
  hypotheses" (p. 16).
- **Second requirement (any joint hypothesis): the right form of testing.**
  "Researchers should use disjunction testing when the rejection of any of
  the constituent hypotheses is sufficient to reject the joint hypothesis
  as a whole and the extent of generalisation across constituent
  hypotheses is unimportant" (p. 16). Conjunction testing is for "when it
  is important to demonstrate the confirmation of all constituent
  hypotheses" (p. 16).
- **Extra assumption for disjunction: exchangeability.** "In the case of
  disjunction testing, researchers also need to assume that the
  constituent hypotheses are theoretically exchangeable with regards to
  inferences about the joint hypothesis under investigation" (p. 16): "a
  significant result in relation to any of the constituent hypotheses must
  provide the same logical basis for rejecting the joint null hypothesis"
  (p. 16). He adds: "the exchangeability assumption is violated if
  researchers have an a priori theoretical expectation that one or more of their
  constituent hypotheses will yield a different result to the others"
  (pp. 16–17). Rubin (2024, p. 2) uses the word "interchangeable" for the
  same idea.
- **His summary** (p. 17): researchers "should only undertake the
  disjunction testing of a joint null hypothesis when that hypothesis (a)
  enables a relevant theoretical and/or practical inference and (b) is
  better suited to disjunction testing rather than conjunction testing."

**How this differs from the earlier description:**

- "All, and only, the relevant hypotheses" is in the paper, but as part of
  a requirement for every joint hypothesis, including conjunction, not
  only for disjunction.
- "Interchangeable" matches; the paper's word is "exchangeable" (2021),
  and it adds that an a priori expectation that one test will differ
  breaks it.
- The paper adds two things the earlier description didn't have: the
  joint hypothesis must support a "relevant and meaningful" inference, and
  disjunction fits when "the extent of generalisation across constituent
  hypotheses is unimportant".
- The paper also says conjunction suits theory testing: "it is more
  logical for researchers to use conjunction testing rather than
  disjunction testing when they want to make a statistical inference about
  a joint hypothesis that comprises a family of hypotheses that belong to
  the same theory" (p. 17).

Possible guidance text (an option, now checked against the paper's
conditions): "Choose this only if the overall idea is one you would report
as a finding in its own right, every test in the set bears on it, any one
of them would count equally, and you have included all the tests that
would count. If you expect one test to come out differently, or it matters
*which* test is significant, choose 'each separately' instead. If your
theory predicts all of them, consider 'all must be significant'."

## The competing view

Some methodologists hold that multiple tests in one study call for a
correction more generally, whatever the claim. Rubin (2021, author
preprint, p. 2) calls this "the most common view": "alpha adjustment is
almost always required during multiple testing". He quotes Bennett et al.
(2009, p. 417): "it is a statistical necessity that we must adapt our
threshold criteria to the number of statistical tests completed on the
same dataset" (second-hand, quoted in Rubin, 2021, p. 2).

Frane (2019) has the title "Misguided opposition to multiplicity
adjustment remains a problem". An earlier draft of this page said Rubin
(2024) lists it as an example of that position. That overstated it: Rubin
(2024, p. 1) cites Frane only for a phrase, "this is not an
"anti-adjustment article" (Frane, 2019, p. 3)", and doesn't describe
Frane's arguments. **Frane's arguments were not read**, so this page
doesn't summarise them. Ways powerkit could show this view (options):

- a note under the question: "Some methodologists recommend a correction
  whenever several tests are run. You can choose a correction for any
  answer.";
- a correction offered as an extra option for answers 1 and 3, recorded in
  the methods paragraph;
- no note.

## Worked numbers

**Set-up:** a two-sample t-test (two-sided), effect d = 0.5, alpha = .05,
target power .80 per test. Computed with R 4.3.3, pwr 1.3.0 and mvtnorm
1.2.4 (code in the appendix).

**One test:** n = 63.77 per group, rounded up to **64 per group (128 in
total)**; power at 64 per group is .8015 (`pwr::pwr.t.test()`).

### Table 1. Joint power when each test has power .80 (alpha = .05 per test)

"Correlated" means the test statistics are correlated at .5, for example
outcomes measured on the same people that correlate .5. Computed with
`mvtnorm::pmvnorm()`, treating the test statistics as multivariate normal
(a large-sample approximation to the t-test).

| Tests (k) | All significant: independent | All significant: correlated .5 | At least one: independent | At least one: correlated .5 |
| --- | --- | --- | --- | --- |
| 2 | .640 | .687 | .960 | .913 |
| 3 | .512 | .611 | .992 | .950 |

A simulation with real t-tests (64 per group, 20,000 replications, seed
20261017) agrees within Monte Carlo error: for k = 2, all .690 and at least
one .915; for k = 3, all .614 and at least one .951 (standard errors about
.002 to .003).

So for "all must be significant", positive correlation raises joint power
above the independence figure, but it stays below .80.

### Table 2. Chance of at least one false positive, every null true (alpha = .05 per test, no correction)

| Tests (k) | Independent | Correlated .5 |
| --- | --- | --- |
| 2 | .098 | .091 |
| 3 | .143 | .125 |

### Table 3. "Any one is enough" with Bonferroni (alpha / k)

| Tests (k) | Alpha per test | n per group for .80 per test | Per-test power at 64 per group | At least one significant at 64 per group: independent | Correlated .5 |
| --- | --- | --- | --- | --- | --- |
| 1 | .05 | 64 | .80 | — | — |
| 2 | .025 | 78 | .712 | .917 | .852 |
| 3 | .0167 | 86 | .656 | .959 | .872 |

Two readings of the same numbers, which the design would need to choose
between:

- if each test must keep 80% power at the corrected alpha, N rises from 64
  to 78 (k = 2) or 86 (k = 3) per group;
- if the target is the chance that at least one test is significant, 64 per
  group already gives .85 to .96, depending on k and the correlation.

### Table 4. "All must be significant" with 80% joint power

If joint power .80 is the target and the tests are assumed independent,
each test needs power .80^(1/k):

| Tests (k) | Per-test power needed | n per group | Joint power at that n if correlated .5 |
| --- | --- | --- | --- |
| 2 | .894 | 84 | .827 |
| 3 | .928 | 95 | .838 |

Assuming independence is conservative here when the correlation is
positive: at .5 the joint power is above .80. How far above depends on the
correlation, which users rarely know. The roadmap's row C2 lists tools that
compute joint power directly (power4mome `rejection_rates(collapse =
"all_sig")`; powertools `coprimary.t()`, which assumes one-sided tests).

## Open questions for the maintainer

- Does the question appear only in the guided route, or also in the
  single-analysis routes (B6)?
- For "any one is enough", what is the power target: each test's own
  power, or the chance that at least one is significant?
- For "all must be significant", is joint power the target, and is the
  independence figure acceptable, or does it need a whole-study simulation
  (D6)?
- Which correction for disjunction: Bonferroni only, or also Holm or
  Hochberg (rPowerSampleSize 1.0.2 has power functions for both, for
  continuous endpoints)?
- Is a correction offered for answers 1 and 3, to reflect the competing
  view (G7)?
- Check the extension of Rubin's framework to power with Mark Rubin.
  Both papers are now opened; wording attributed to him on screen should
  use the quotes above.
- Should the guidance for "any one is enough" use Rubin's fuller
  conditions (above), or the shorter two-point version?

## Appendix: R code and output

Run on 17 October 2026 from `/tmp` with `Rscript --vanilla worked-numbers.R`
(not inside the repository). `pmvnorm()` uses a randomised method for
k = 3, so the script sets a seed; the numbers above were identical on two
runs.

```r
# Worked numbers for docs/inference-question-design.md.
# Run from /tmp with: Rscript --vanilla worked-numbers.R
# Packages: pwr (pwr.t.test() for a two-sample t-test) and
# mvtnorm (multivariate normal probabilities for correlated test statistics).

library(pwr)
library(mvtnorm)

alpha <- 0.05
d <- 0.5
target <- 0.80
ks <- c(2, 3)
rho <- 0.5
# pmvnorm() uses a randomised quasi-Monte Carlo method for k = 3; fix its seed.
set.seed(1)

cat("R", R.version.string, "| pwr", as.character(packageVersion("pwr")),
    "| mvtnorm", as.character(packageVersion("mvtnorm")), "\n\n")

# 1. One test: n per group for 80% power, two-sided, alpha = .05, d = 0.5.
one <- pwr.t.test(d = d, sig.level = alpha, power = target, type = "two.sample")
n_one <- ceiling(one$n)
pow_one <- pwr.t.test(n = n_one, d = d, sig.level = alpha, type = "two.sample")$power
cat(sprintf("1. One test: n per group = %.2f, rounded up %d; power at %d = %.4f\n\n",
            one$n, n_one, n_one, pow_one))

# 2. Joint power when each test has power p, with k tests.
#    Independent tests: closed form.
#    Correlated tests: the k test statistics are treated as multivariate
#    normal with a common correlation rho, each with the mean that gives
#    power p for a two-sided z test at alpha (a large-sample approximation
#    to the t-test). P(all significant) and P(at least one significant)
#    come from mvtnorm::pmvnorm().
crit <- qnorm(1 - alpha / 2)
mean_for_power <- function(p, a = alpha) {
  c0 <- qnorm(1 - a / 2)
  uniroot(function(m) pnorm(m - c0) + pnorm(-m - c0) - p, c(0, 20))$root
}
joint_mvn <- function(k, p, r, a = alpha) {
  c0 <- qnorm(1 - a / 2)
  m <- rep(mean_for_power(p, a), k)
  S <- matrix(r, k, k); diag(S) <- 1
  # P(none significant) = P(all |Z| < c)
  none <- pmvnorm(lower = rep(-c0, k), upper = rep(c0, k), mean = m, sigma = S)[1]
  # P(all significant) = sum over sign patterns of P(each Z beyond c in that tail)
  signs <- as.matrix(expand.grid(rep(list(c(-1, 1)), k)))
  all_sig <- sum(apply(signs, 1, function(s) {
    lo <- ifelse(s > 0, c0, -Inf); hi <- ifelse(s > 0, Inf, -c0)
    pmvnorm(lower = lo, upper = hi, mean = m, sigma = S)[1]
  }))
  c(all = all_sig, any = 1 - none)
}

cat("2. Joint power, each test at power .80, alpha = .05 per test\n")
for (k in ks) {
  ind_all <- target^k
  ind_any <- 1 - (1 - target)^k
  cor <- joint_mvn(k, target, rho)
  cat(sprintf("   k = %d: independent all = %.3f, any = %.3f | rho = %.1f all = %.3f, any = %.3f\n",
              k, ind_all, ind_any, rho, cor["all"], cor["any"]))
}
cat("\n")

# 3. False-positive rate for "at least one" when all nulls are true.
cat("3. Chance of at least one false positive, all nulls true, alpha = .05 per test\n")
for (k in ks) {
  S <- matrix(rho, k, k); diag(S) <- 1
  cor_fwer <- 1 - pmvnorm(lower = rep(-crit, k), upper = rep(crit, k), sigma = S)[1]
  cat(sprintf("   k = %d: independent = %.3f | rho = %.1f = %.3f\n", k, 1 - (1 - alpha)^k, rho, cor_fwer))
}
cat("\n")

# 4. Bonferroni for disjunction: alpha / k per test.
cat("4. Bonferroni (alpha / k) for 'at least one'\n")
for (k in ks) {
  a_k <- alpha / k
  n_k <- ceiling(pwr.t.test(d = d, sig.level = a_k, power = target, type = "two.sample")$n)
  p_at_n_one <- pwr.t.test(n = n_one, d = d, sig.level = a_k, type = "two.sample")$power
  # power of the disjunction at n_one with corrected alpha
  ind_any <- 1 - (1 - p_at_n_one)^k
  cor_any <- joint_mvn(k, p_at_n_one, rho, a_k)["any"]
  cat(sprintf("   k = %d: alpha per test = %.4f; n per group for 80%% per test = %d; per-test power at n = %d is %.3f; P(at least one) at n = %d: independent %.3f, rho = %.1f %.3f\n",
              k, a_k, n_k, n_one, p_at_n_one, n_one, ind_any, rho, cor_any))
}
cat("\n")

# 5. Conjunction: per-test power needed for joint power .80 (independent
#    tests), and the n per group that gives it.
cat("5. 'All' with joint power .80 if tests were independent\n")
for (k in ks) {
  p_each <- target^(1 / k)
  n_c <- ceiling(pwr.t.test(d = d, sig.level = alpha, power = p_each, type = "two.sample")$n)
  cor_all <- joint_mvn(k, pwr.t.test(n = n_c, d = d, sig.level = alpha, type = "two.sample")$power, rho)["all"]
  cat(sprintf("   k = %d: per-test power %.3f; n per group %d; joint power at that n if rho = %.1f: %.3f\n",
              k, p_each, n_c, rho, cor_all))
}
cat("\n")

# 6. Simulation check of section 2 with real t-tests (fixed seed).
#    Two groups of n_one; k outcomes per person with correlation rho
#    within each group; true d = 0.5 on every outcome; Welch is not used
#    (var.equal = TRUE, as in pwr).
set.seed(20261017)
nrep <- 20000
cat(sprintf("6. Simulation check: %d replications, n = %d per group, seed 20261017\n", nrep, n_one))
for (k in ks) {
  S <- matrix(rho, k, k); diag(S) <- 1
  sig <- matrix(FALSE, nrep, k)
  for (i in seq_len(nrep)) {
    g1 <- rmvnorm(n_one, mean = rep(0, k), sigma = S)
    g2 <- rmvnorm(n_one, mean = rep(d, k), sigma = S)
    m <- colMeans(g2) - colMeans(g1)
    sp <- sqrt((apply(g1, 2, var) + apply(g2, 2, var)) / 2)
    t <- m / (sp * sqrt(2 / n_one))
    sig[i, ] <- abs(t) > qt(1 - alpha / 2, 2 * n_one - 2)
  }
  all_sim <- mean(rowSums(sig) == k)
  any_sim <- mean(rowSums(sig) >= 1)
  se <- function(p) sqrt(p * (1 - p) / nrep)
  cat(sprintf("   k = %d, rho = %.1f: per-test %.3f; all = %.3f (MC SE %.3f); any = %.3f (MC SE %.3f)\n",
              k, rho, mean(sig), all_sim, se(all_sim), any_sim, se(any_sim)))
}
```

Output:

```text
R R version 4.3.3 (2024-02-29) | pwr 1.3.0 | mvtnorm 1.2.4 

1. One test: n per group = 63.77, rounded up 64; power at 64 = 0.8015

2. Joint power, each test at power .80, alpha = .05 per test
   k = 2: independent all = 0.640, any = 0.960 | rho = 0.5 all = 0.687, any = 0.913
   k = 3: independent all = 0.512, any = 0.992 | rho = 0.5 all = 0.611, any = 0.950

3. Chance of at least one false positive, all nulls true, alpha = .05 per test
   k = 2: independent = 0.098 | rho = 0.5 = 0.091
   k = 3: independent = 0.143 | rho = 0.5 = 0.125

4. Bonferroni (alpha / k) for 'at least one'
   k = 2: alpha per test = 0.0250; n per group for 80% per test = 78; per-test power at n = 64 is 0.712; P(at least one) at n = 64: independent 0.917, rho = 0.5 0.852
   k = 3: alpha per test = 0.0167; n per group for 80% per test = 86; per-test power at n = 64 is 0.656; P(at least one) at n = 64: independent 0.959, rho = 0.5 0.872

5. 'All' with joint power .80 if tests were independent
   k = 2: per-test power 0.894; n per group 84; joint power at that n if rho = 0.5: 0.827
   k = 3: per-test power 0.928; n per group 95; joint power at that n if rho = 0.5: 0.838

6. Simulation check: 20000 replications, n = 64 per group, seed 20261017
   k = 2, rho = 0.5: per-test 0.803; all = 0.690 (MC SE 0.003); any = 0.915 (MC SE 0.002)
   k = 3, rho = 0.5: per-test 0.802; all = 0.614 (MC SE 0.003); any = 0.951 (MC SE 0.002)
```
