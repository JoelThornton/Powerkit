## 2026-11-21 · Repeated yes/no answers: warn with the simulated Type I error

E75's likelihood-ratio test of a yes/no outcome finds differences that
aren't there more often than alpha when one answer is rare: 6.3% to
8.9% at alpha .05 with two or fewer of the rarer answer expected in the
rarest cell, and 7.3% with a 2% chance of yes even at 100 people a group
(validation-log.md, 21 November 2026). Fitting by quadrature did not
remove it (20 November 2026). Options were to refuse designs below a
minimum expected number of the rarer answer, or to run them and warn.
The design is a real one researchers run, so powerkit runs it and
warns. The grid showed no rule on the inputs that marks where the excess
starts (the expected count in the rarest cell, people a group and the
chance of yes each matter), so every yes/no run also simulates the test
with no difference at the planned sample size, with the run's seed and
number of studies, and the result, the write-up and the planning
document state that rate among the analysis's limitations when it is
more than 2 Monte Carlo SEs above alpha, with the advice the grid
supports: more answers from each person in each condition, which helps
more than more people. The extra cost is one simulation at the planned
sample size. Counts and ordered categories are unchanged.
