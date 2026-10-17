# Questions for upstream maintainers (drafts, not sent)

Drafts written for the maintainer, who reviews and sends them. Nothing here
has been sent. Earlier reports that were sent and answered are recorded in
`docs/conventions.md` (Departures 4 and 8) and `docs/decisions.md`
("Upstream reports fixed; upstream watch").

## power4mome: Shu Fai Cheung (draft, 16 October 2026)

**Status:** draft, not sent.

**Where to send:** the maintainer's choice: a GitHub issue or discussion
on [sfcheung/power4mome](https://github.com/sfcheung/power4mome), or
email.

**Note for the maintainer (not part of the message):** two earlier
questions for Shu Fai Cheung are in `docs/decisions.md` (15 October 2026,
"Published values: InteractionPoweR notes"): whether a binary X can be
correlated with W, and whether the Monte Carlo CI test has been checked
with a binary X. Add them if you want to ask everything at once; they are
left out below to keep the message to the two questions you asked for.

---

> **Subject:** Two questions about power4mome: seeding with product terms, and multi-category X
>
> Hi Shu Fai,
>
> Thank you for power4mome. powerkit, an open-source power analysis tool
> for psychology (https://github.com/JoelThornton/Powerkit), uses it for
> all of its mediation and moderated-mediation designs (PROCESS models 4,
> 6, 7 and 14), and it has been a pleasure to build on. Thanks also for
> fixing the `power4mome.bz` option so quickly.
>
> Two short questions, whenever you have time:
>
> 1. **Reproducibility with a product term.** For a model with a product
>    term (for example `m ~ x + w + x:w`), it looks as if the population
>    standardisation (`psi_std_monte_carlo()`, with `n_std` draws) uses
>    the random-number state from before `iseed` is applied. Two calls
>    with the same `iseed` can then give slightly different results,
>    depending on what ran before them in the session. We now call
>    `set.seed()` with the same seed just before each `power4test()` call.
>    Is that the intended way to get reproducible results, or is there an
>    argument or option we have missed?
>
> 2. **Multi-category X.** Does power4mome support an X with three or
>    more groups in mediation and moderated mediation? If so, what is the
>    recommended way to specify it (`model`, `pop_es` and `x_fun`), and
>    which test function would you use?
>
> Thanks again for the package and for your help.
>
> Best wishes,
> [maintainer's name]

## Spower: Phil Chalmers (draft, 17 October 2026)

**Status:** draft, not sent.

**Where to send:** the maintainer's choice: a GitHub issue on Spower's
repository, or email.

**Note for the maintainer (not part of the message):** powerkit doesn't
use a non-zero null correlation, so nothing in powerkit is affected
today. Recorded in `docs/decisions.md` (17 October 2026, "Spower:
one-sided tests against a non-zero null correlation") and
`docs/coverage-roadmap.md` (flags). The line numbers are from Spower 0.7's
CRAN source, `R/p_r.R`.

---

> **Subject:** p_r(): one-sided tests when rho isn't 0
>
> Hi Phil,
>
> Thank you for Spower. powerkit, an open-source power analysis tool for
> psychology (https://github.com/JoelThornton/Powerkit), uses it for its
> simulation options, and the one-sided fix in 0.7 was very welcome.
>
> One small thing I noticed while reading `p_r()` in 0.7. When
> `rho != 0`, the p-value is replaced with the Fisher's z test against
> `rho`:
>
> ```r
> out$p.value <- pnorm(abs(t), lower.tail=FALSE)*2
> ```
>
> (`R/p_r.R`, line 75). As far as I can tell this is two-sided whatever
> `two.tailed` or `alternative` says, so `p_r(50, .5, rho = .3,
> two.tailed = FALSE)` would give the two-sided p-value. When `rho = 0`
> the p-value comes from `cor.test()` and follows `alternative`, as
> expected.
>
> Is that intended? If not, something like
> `pnorm(t, lower.tail = FALSE)` for "greater" and `pnorm(t)` for "less"
> might be all it needs. I may well be missing something, so please
> ignore this if so.
>
> Thanks again,
> Joel

