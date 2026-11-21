* Design finder (app): the answers given in the finder now set the input
  screen they settle (`finder_form_values()`, `R/route-fit.R`): the
  outcome type on the trial cards, the mixed-model cards and the cluster
  trial, ordered categories on the repeated counts and ratings card, and
  whether each person is in one condition or all of them. A note on the
  input screen lists what was set. Before, the screen opened on each
  card's defaults, so a yes/no outcome with each person in one condition
  opened as a score with both conditions.
* The finder asks how many categories a yes/no-or-categories answer has
  before a card is offered: on trials (new question S2c), in groups (C0)
  and answered twice by the same people (Q3c). Three or more go to the
  safety net with a note on what is missing (`finder_gaps` in tree.yaml):
  for paired answers, marginal homogeneity (Stuart-Maxwell) and symmetry
  (Bowker) are different questions. People in groups with a count,
  ordered or yes/no outcome are asked what the hypothesis involves (C1),
  as with a score; the grouped cards (E34, E62, E68) then say they take a
  score or a yes/no outcome rather than appearing to fit a count.
