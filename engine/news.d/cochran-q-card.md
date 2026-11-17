* Cochran's Q has a card of its own (E78, "The same people, a yes/no
  outcome in each of three or more conditions") in the yes/no and
  categories group. Its form asks only for the conditions, the outcome,
  each condition's chance of 'yes' and the SD of people's tendency to say
  yes, and runs the existing engine route (`repeated_glmm` with
  `target_test > method = "cochran_q"`). Before, the test was a version of
  the generalised mixed model card, which a search for Cochran's Q
  reached under that card's name, in the multilevel group, with simr and
  a several-minute run on its header. The design finder's yes/no branch
  for three or more conditions now asks how each person answers: once in
  each condition (Cochran's Q) or any other way (the mixed model card).
