* The smallest detectable effect (goal `sensitivity`) for the remaining
  regression and moderation cards.
  - By the simulated search (`simulated_effect_sensitivity()`, with a 95%
    interval): moderation of a yes/no outcome (the X x W odds ratio) and
    of a count (the X x W rate ratio; `count_interaction_backend()` gains
    `simulated_sensitivity`); an outcome in unordered categories and its
    moderation (the pattern of log odds ratios against the first category
    scaled, reported as the Wald test's category or, for the
    likelihood-ratio test, the category furthest from 1); moderated
    regression with a yes/no X or W (the correlation of XW with Y, which
    InteractionPoweR simulates; the exported script now repeats that
    search rather than the fixed-model one).
  - By the formula search (`formula_search_sensitivity()`): the three-way
    interaction's standardised coefficient, with InteractionPoweR's
    `power_interaction_3way_r2()`; coefficients impossible with the
    correlations entered count as no power.
  The results' label for the interaction correlation loses its article
  ("is correlation of the interaction with Y = 0.1"), so the figure no
  longer reads "the smallest the correlation". Tests: power simulated
  afresh at each effect found (4,000 replications, another seed), every
  script run, and the three-way coefficient checked against
  InteractionPoweR's own sample size at the value found.
