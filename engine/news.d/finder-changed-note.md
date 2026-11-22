* App: the input screen's "Set from your answers" note
  (`finder_filled_note_ui()`) is rendered by `output$finder_filled_note`
  from the current field values, so a field changed after the design
  finder set it is listed with the screen's value and the finder's,
  in a warning. Before, a changed field silently left the list.
