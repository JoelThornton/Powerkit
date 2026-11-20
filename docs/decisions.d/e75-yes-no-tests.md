## 2026-11-20 · Repeated yes/no answers: the likelihood-ratio test only; quadrature not adopted

E75 now tests a yes/no outcome by the likelihood ratio only: with two or
more answers per condition, the designs it plans, the Wald test ran
about 6.2% at alpha .05 when people differ a lot while the
likelihood-ratio test, already the default and simr's for a factor,
stayed near 5% (`validation-log.md`, 20 November 2026). This is not a
departure. Fitting each study by adaptive Gauss-Hermite quadrature
(`nAGQ = 10`) instead of glmer()'s Laplace approximation was tested as a
way to allow one answer per condition with groups, and not adopted:
with one answer it kept the likelihood-ratio test too liberal in five of
eight settings (6.6% to 10% through the engine; the Laplace fit reached 15.6% in one), and
with two or three answers the two fits gave the same rates, so it would
cost about 40% more time for no gain where E75 runs. One yes/no answer
per condition stays refused (one group: McNemar's test or Cochran's Q).
Small groups with a rare answer still run about 7% with two answers per
condition; queue item 32 decides how to tell researchers.
