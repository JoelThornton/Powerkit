## 2026-11-22 · Group treatment trials with a score use the Welch-Satterthwaite degrees of freedom

**Decision (maintainer).** For a group treatment trial (people randomised
one by one, the second condition delivered in groups) with a score
outcome, powerkit keeps the variance of powertools' `irgtt.cont()` and
tests it with the Welch-Satterthwaite degrees of freedom, (Uc + Ue)² /
(Uc² / (n − 1) + Ue² / (J − 1)), instead of `irgtt.cont()`'s own df
(Departure 38).

**Why.** The independent check of item 24 drew such trials as the input
screen describes them and analysed them by Welch's test of the people
taking part individually against the groups' means. Their power agreed
with Satterthwaite's df (.546 simulated, .548 by formula, at 10 groups
of 8 and 80 individuals, ICC 0.1, d = 0.4) and not with `irgtt.cont()`
(.512), whose df, a weighted average of J − 1 and n − 1 with no source
on its help page, are about half as many. The difference is under a
point with 30 or more groups and up to about 12 points with 4 to 6, so
the old answer asked for more groups than a trial needs. A yes/no
outcome still runs on `irgtt.bin()`'s z test, which has no df. The
question is recorded for powertools' authors in
`docs/upstream-questions.md`.
