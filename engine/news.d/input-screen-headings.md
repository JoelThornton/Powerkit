* App: the input screen's group headings are the same with explanations
  on or off (`group_heading()` in `forms_ui.R`): a group with an effect
  field is headed "Effect size: <its title>" instead of swapping to a bare
  "Effect size", which gave two groups one heading, and the screen shows
  the card's "Standard name:" line. A field inside Shiny's conditional
  wrapper (`display: contents`) no longer rises beside its group's floated
  heading: the wrapper's children clear the float.
