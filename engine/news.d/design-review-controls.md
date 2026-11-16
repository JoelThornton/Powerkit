* App styles (design review): buttons, text boxes, menus and file pickers
  share one corner radius and border colour on every screen (they kept
  Bootstrap's defaults outside the input form); `btn-outline-secondary`
  takes the app's navy; ionRangeSlider's shiny skin takes the app's blue,
  so the Labs sliders match the result screen's; a fold whose summary is
  laid out with flex (`.result-more`, `.result-validation`, `.card-more`,
  `.mismatch`, `.capabilities-fold`) draws its own arrow, since flex
  removes the browser's; the Settings and "Guess the answer first" folds
  centre their line; on a phone the "Keep this result" buttons take the
  full width.
* `power_curve_plot()` puts the "This analysis" label on the side of the
  point with room for it, and shortens it to the number when neither side
  has room (it ran off the edge of a phone's chart).
* The result's departures heading reads "Where powerkit differs from other
  tools' defaults".
