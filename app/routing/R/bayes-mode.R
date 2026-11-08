# Bayes mode: an opt-in switch on the start screen for researchers who will
# analyse with Bayes factors. With it on, every card that has a Bayes
# factor version opens its input screen with that version chosen, and a
# card without one says so before the input screen. It asks nothing of
# anyone who leaves it off (docs/decisions.md, 5 November 2026: no
# "p-values or Bayes factors?" question for everyone).

# Kept for this browser tab (sessionStorage), so a reload or a shared link
# opened in the same tab keeps it; a new tab starts with it off.
bayes_mode_js <- "
  window.pkSetBayesMode = function(on) {
    try { window.sessionStorage.setItem('powerkit-bayes-mode', on ? '1' : '0'); } catch (e) {}
    if (window.Shiny && Shiny.setInputValue) Shiny.setInputValue('bayes_mode', !!on, {priority: 'event'});
  };
  $(document).on('shiny:connected', function() {
    var on = false;
    try { on = window.sessionStorage.getItem('powerkit-bayes-mode') === '1'; } catch (e) {}
    if (on) Shiny.setInputValue('bayes_mode', true, {priority: 'event'});
  });
"

bayes_mode_toggle_ui <- function(on = FALSE) {
  div(class = "bayes-mode-toggle form-check form-switch",
    tags$input(class = "form-check-input", type = "checkbox", role = "switch", id = "bayes_mode_switch",
      checked = if (isTRUE(on)) NA,
      `aria-describedby` = "bayes_mode_help",
      onchange = "pkSetBayesMode(this.checked)"),
    tags$label(class = "form-check-label", `for` = "bayes_mode_switch", "Bayes mode: I'll analyse with Bayes factors"),
    p(id = "bayes_mode_help", class = "small text-muted mb-0",
      "Every design that has a Bayes factor version opens with it chosen, and its result leads with the chances of strong",
      "evidence for an effect, strong evidence for none, and misleading evidence. You can switch back to a p-value on any card."))
}

# The note on a card in Bayes mode: whether its input screen opens on the
# Bayes factor version.
bayes_mode_card_note <- function(tree, ep_id, on = FALSE) {
  if (!isTRUE(on) || is.null(tree$endpoints[[ep_id]])) return(NULL)
  if (!is.null(tree$bayes_designs[[ep_id]])) {
    return(div(class = "status bayes-mode-note", role = "note",
      tags$strong("Bayes mode: "), "the input screen opens with this design's Bayes factor version chosen."))
  }
  div(class = "status status-soon bayes-mode-note", role = "note",
    tags$strong("Bayes mode: "), "powerkit has no Bayes factor version of this design yet, so its plan uses a p-value.")
}

# In Bayes mode the Bayes factor tests plan with a design prior by
# default (the maintainer's decision, 8 November 2026): "How unsure you
# are" (about the effect, correlation or proportions) starts empty rather than at 0, so the plan waits
# for the user's own SD. powerkit doesn't suggest one, as on the results
# screen (bayes_uncertain_ui()); 0 still plans for exactly the effect.
# The design prior's SD on each Bayes factor card: the effect (t-tests),
# the correlation and the proportions.
bayes_mode_prior_fields <- c("effect_sd", "r_sd", "p_sd")

bayes_mode_groups <- function(groups, on = FALSE) {
  if (!isTRUE(on)) return(groups)
  lapply(groups, function(g) {
    g$fields <- lapply(g$fields, function(f) {
      # The test version: the Bayes factor version to start with.
      if (identical(f$path, "target_test.method") && "bayes_factor" %in% names(f$choices)) {
        f[["default"]] <- "bayes_factor"
        f$default_source <- "Bayes mode, which you turned on at the start; any other version can still be chosen"
        return(f)
      }
      if (!f$id %in% bayes_mode_prior_fields) return(f)
      f[["default"]] <- NULL
      f$default_source <- paste("Bayes mode: say how unsure you are about the effect, so the plan averages over the effects you",
        "think plausible (a design prior; O'Hagan, Stevens and Campbell, 2005, call the result assurance). powerkit won't",
        "suggest an SD: choose one you could defend, for example from the earlier study's standard error. 0 plans for",
        "exactly the value entered")
      f
    })
    g
  })
}

# The input screen's starting values in Bayes mode: the Bayes factor test
# version, unless the screen already has a test version.
bayes_mode_form_values <- function(tree, ep_id, values = list(), on = FALSE) {
  d <- tree$bayes_designs[[ep_id]]
  if (!isTRUE(on) || is.null(d) || !is.null(values[[d$field]])) return(values)
  values[[d$field]] <- "bayes_factor"
  values
}
