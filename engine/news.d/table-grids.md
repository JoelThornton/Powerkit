* App: table inputs (means, SDs and proportions on E6, E20, E21, E23,
  E47, E55, E56 and E59) are entered in a labelled grid
  (app/routing/R/table-grid.R). Rows and columns are named from the
  fields in `rows_from` and `cols_from`, with counts expanded as
  `expand_level_counts()` does and two-factor rows named as
  combinations. The grid writes the same comma-and-line text into the
  field's text box, which the server still reads, so validation, drafts
  and exports are unchanged; "Type it as text instead" shows the box. The
  label names what goes in; the line-by-line layout is shown only with
  the text box. Each grid has an example and, for means, a line on why
  powerkit asks for means.
* App: a table field with an `alternative` (forms.yaml on E6;
  `with_eta_squared()` on the ANOVA and ANCOVA cards) shows a link beside
  the grid that sets the card's effect-size choice to Cohen's w or
  partial eta-squared, which was otherwise offered only as a choice under
  "Units of the means".
