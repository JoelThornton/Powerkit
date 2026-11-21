# Whether the card a route ends on can hold what the user said about their
# study (coverage audit, 12 November 2026). A route must never quietly drop
# an answer: when the card can't do what was asked (an equivalence aim, an
# outcome other than a score), it says so at the top, names what the user
# said, and says where to go instead. The finder's routing is unchanged;
# this only words what each card can't take.

route_outcome_words <- c(score = "a score", yesno = "a yes/no outcome", count = "a count", ordinal = "ordered categories")

# Cards built for some outcomes only, reached by every outcome on their
# route: what each takes, in words.
route_card_outcomes <- list(
  E35 = list(takes = "score", words = "a score measured over time in two groups"),
  E45 = list(takes = "score", words = "a score measured over time, with normally distributed errors"),
  E74 = list(takes = "score", words = "two scores measured over time"),
  E34 = list(takes = c("score", "yesno"), words = "a score or a yes/no outcome"),
  E62 = list(takes = c("score", "yesno"), words = "a score or a yes/no outcome"),
  E68 = list(takes = c("score", "yesno"), words = "a score or a yes/no outcome")
)

# The designs the equivalence card (E36) covers, from what the finder was told.
equivalence_covers <- function(ctx) {
  outcome <- ctx$outcome %||% "score"
  times <- ctx$times %||% "once"
  (identical(outcome, "score") && times %in% c("once", "twice")) || (identical(outcome, "yesno") && identical(times, "once"))
}

equivalence_gap_words <- function(ctx) {
  outcome <- ctx$outcome %||% "score"
  times <- ctx$times %||% "once"
  if (identical(times, "many_conditions")) return("the same people in three or more conditions")
  if (identical(outcome, "yesno")) return("a yes/no outcome measured twice or more")
  if (outcome %in% c("count", "ordinal")) return(route_outcome_words[[outcome]])
  "this design"
}

# The messages for a card reached with these answers (`ctx`), or none.
route_fit_messages <- function(tree, ep_id, ctx = list()) {
  ep <- tree$endpoints[[ep_id %||% ""]]
  if (is.null(ep)) return(character())
  # A part of the study no card plans (tree.yaml, finder_gaps), on any
  # card the finder ends on, the safety net included.
  out <- unname(unlist(tree$finder_gaps[ctx$gap %||% character()]))
  if (identical(ep_id, tree$safety_net$endpoint)) return(out)
  covered <- !identical(ep$status, "not_in_powerkit")
  if (identical(ctx$goal, "equivalence")) {
    if (identical(ep_id, "E36")) {
      if (!equivalence_covers(ctx)) {
        out <- c(out, sprintf(paste(
          "You described %s. This card's equivalence tests cover two groups, the same people measured twice, one mean, a correlation",
          "or two proportions, so none of them fits your design yet. A simulation in R of the two one-sided tests for your model is",
          "the usual route; a statistician can help set one up."), equivalence_gap_words(ctx)))
      }
    } else if (covered) {
      out <- c(out, paste(
        "You said you want to show there's no meaningful effect. This card plans to detect an effect, which is not the same:",
        "a study can fail to find an effect without showing it is absent. Powerkit has no equivalence version of this design yet.",
        "A simulation in R of the two one-sided tests for your model is the usual route; this card's R script can be a starting point."))
    }
  }
  fit <- route_card_outcomes[[ep_id]]
  outcome <- ctx$outcome
  if (!is.null(fit) && !is.null(outcome) && !outcome %in% fit$takes) {
    out <- c(out, sprintf(paste(
      "You said your outcome is %s. This card plans for %s, so its answer would not fit your study. Data like yours are usually",
      "analysed with a generalised mixed model, whose power is simulated in R (for example with simr); Powerkit doesn't calculate it yet."),
      route_outcome_words[[outcome]], fit$words))
  }
  if (identical(ep_id, "E26") && identical(ctx$times, "many_conditions")) {
    out <- c(out, paste(
      "You said the same people are in three or more conditions. This card compares two (McNemar's test). For three or more,",
      "use the card for the same people measured more than once with a yes/no outcome, which plans Cochran's Q."))
  }
  if (identical(ep_id, "E41") && identical(ctx$hypothesis, "mediation")) {
    out <- c(out, paste(
      "You said the effect works through something else (mediation), with the same people measured more than once.",
      "This card doesn't calculate an indirect effect: it plans the effect of something measured on each occasion (X),",
      "of something measured once per person (W), and whether W changes X's effect. Within-person mediation needs two",
      "more paths, from X to the mediator and from the mediator to the outcome allowing for X, and a timing in which the",
      "mediator is measured after X and before the outcome. Powerkit doesn't plan it yet; its power is simulated in R",
      "with a multilevel mediation model. You can still use this card for one of its own effects."))
  }
  if (identical(ep_id, "E41") && identical(ctx$trajectory, "one_group")) {
    out <- c(out, paste(
      "You described one group's change over time. This card plans it as the effect of something that changes from",
      "occasion to occasion (X), here time, and tests \u201cX's effect within people\u201d: the average change. It takes X's",
      "effect per SD of X, so multiply the average change per unit of time by the SD of the occasions (for weeks 1 to 8,",
      "about 2.45), and do the same for how much people's own rates of change differ (the SD of X's effect). With the",
      "same occasions for everyone, this gives the same model as a growth curve with a random slope. The card also asks",
      "for something measured once per person (W): if there is none, give W's effect and the moderation as 0. The",
      "answer is the power to detect the average change, not differences between people's changes."))
  }
  if (identical(ep_id, "E41") && identical(ctx$times, "twice") && !identical(ctx$hypothesis, "mediation")) {
    out <- c(out, paste(
      "If one measurement predicts the other later, allowing for the earlier score (for example, whether baseline anxiety predicts",
      "depression at follow-up, adjusting for baseline depression), that is a regression with the baseline as a covariate, which",
      "the multiple regression card plans."))
  }
  out
}

route_fit_ui <- function(tree, ep_id, ctx = list()) {
  messages <- route_fit_messages(tree, ep_id, ctx)
  if (!length(messages)) return(NULL)
  div(class = "status status-soon route-fit-note", role = "note",
    lapply(messages, function(m) p(class = "mb-1", m)),
    if (identical(ep_id, "E41") && identical(ctx$times, "twice") && !identical(ctx$hypothesis, "mediation")) pick_button("Open multiple regression", "ep:E24", class = "btn btn-outline-primary btn-sm"))
}

# "Plan my whole study" (V-02, V-05): what the route can't do for this
# card, in place of the note about separate people when that isn't why.
guided_single_note <- function(tree, ctx, start) {
  aim <- start$aim %||% "predict"
  # Replicating goes through the same questions as testing a prediction.
  if (!aim %in% c("predict", "replicate")) {
    label <- aim_question(tree)$options[[aim]]$label %||% aim
    return(sprintf("\u201cPlan a whole study\u201d covers several analyses of a study that tests predictions. For “%s”, this is the one card that plans it: work it out here, then press “Add this to my study plan” under the result if you want it in your plan.", label))
  }
  if (!identical(ctx$grouping, "independent")) return(tree$guided$single_analysis_note)
  NULL
}

whole_study_bayes_note <- function(on) {
  if (!isTRUE(on)) return(NULL)
  div(class = "status status-soon bayes-mode-note", role = "note",
    tags$strong("Bayes factors: "),
    "the plan and the whole-study simulation use p-values: Powerkit has no Bayes factor version of them yet. An analysis opened from the plan on its own card opens on its Bayes factor version where it has one.")
}

# The safety net's way on (V-09): search by name, or the map.
safety_net_ways_ui <- function() {
  div(class = "safety-ways",
    p("Two ways that might still find an analysis:"),
    action_bar(
      pick_button("Search every analysis by name", "route:known", class = "btn btn-outline-primary"),
      actionButton("safety_open_map", "Open the methods map", class = "btn btn-outline-primary")))
}

# The finder's answers, carried into the input screen (finder audit, 21
# November 2026): each card's fields that a screening answer settles, and
# the value each answer gives. Only a field the card has and a value among
# its choices is set; anything the user then changes stays theirs.
finder_form_fills <- list(
  outcome = list(
    E33 = list(field = "outcome_type", values = c(score = "continuous", yesno = "binary")),
    E63 = list(field = "outcome_type", values = c(score = "continuous", yesno = "binary")),
    E67 = list(field = "outcome_type", values = c(score = "continuous", yesno = "binary")),
    E41 = list(field = "two_outcome", values = c(score = "continuous", yesno = "binary")),
    E62 = list(field = "two_outcome", values = c(score = "continuous", yesno = "binary")),
    E68 = list(field = "three_outcome", values = c(score = "continuous", yesno = "binary")),
    E34 = list(field = "outcome_type", values = c(score = "standardised", yesno = "proportion")),
    E75 = list(field = "glmm_outcome", values = c(count = "count", yesno = "binary", ordinal = "categorical"))
  ),
  trajectory = list(
    E41 = list(field = "two_level_effect", values = c(one_group = "within_effect"))
  ),
  assignment = list(
    E33 = list(field = "crossed_participants", values = c(within = "within_factor", between = "between_factor")),
    E63 = list(field = "crossed_participants", values = c(within = "within_factor", between = "between_factor")),
    E75 = list(field = "glmm_people", values = c(within = "within_factor", between = "between_factor"))
  )
)

#' Input values the finder's answers (`ctx`) settle for card `ep_id`: a
#' named list of field values.
finder_form_values <- function(forms, ep_id, ctx = list()) {
  fields <- form_fields(form_groups(forms, ep_id))
  by_id <- stats::setNames(fields, vapply(fields, function(f) f$id %||% "", character(1)))
  out <- list()
  for (key in names(finder_form_fills)) {
    fill <- finder_form_fills[[key]][[ep_id]]
    answer <- ctx[[key]]
    if (is.null(fill) || is.null(answer) || !answer %in% names(fill$values)) next
    value <- fill$values[[answer]]
    field <- by_id[[fill$field]]
    if (is.null(field) || !value %in% names(field$choices)) next
    out[[fill$field]] <- value
  }
  out
}

#' The note at the top of an input screen opened from the finder: which
#' fields were set from the answers (`filled`) and still hold them in
#' `values`, as the screen labels them.
finder_filled_note_ui <- function(forms, ep_id, filled, values = filled) {
  # Only what still holds the finder's value (a test version or Bayes
  # factor choice made afterwards may have set it).
  filled <- filled[vapply(names(filled), function(id) identical(values[[id]], filled[[id]]), logical(1))]
  if (!length(filled)) return(NULL)
  fields <- form_fields(form_groups(forms, ep_id))
  items <- lapply(names(filled), function(id) {
    f <- Filter(function(x) identical(x$id, id), fields)[[1]]
    tags$li(paste0(f$label, ": "), tags$strong(f$choices[[filled[[id]]]]))
  })
  div(class = "alert alert-info carried-note finder-filled-note", role = "note",
    p(tags$strong("Set from your answers. "), "Check these match your study; change them below if they don't."),
    tags$ul(items))
}
