## 2026-11-21 · Replication planner: the size from which every larger replication meets the goal

The replication planner's BayesRepDesign goals are searched over whole
totals from the package's pors*() chance functions, not its ssd*()
searches, which assume the chance crosses the target once on a continuous
standard error. The pooled (meta-analytic) goal can be met by a tiny
replication, because the original's result carries the pooled estimate,
missed at moderate sizes, and met again at large ones; ssdMeta() also
reports numerical problems where the chance rises steadily
(upstream-questions.md, BayesRepDesign question 3). The planned size is
the smallest total from which every larger total, up to the largest
searched, meets the goal: a plan then does not rest on a size just below a
gap, and adding participants never loses the goal. Smaller totals that
also meet it are reported beside that size, and a goal met only by small
replications is reported as such and does not set the sample size. Every
total up to 1,000 is checked; beyond it a 400-point grid, with each change
pinned to the exact total by bisection, since the standard error falls
smoothly as the total grows. The exported R scripts use the same search.
