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
  E34 = list(takes = c("score", "yesno", "count"), words = "a score or a yes/no outcome")
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
  if (is.null(ep) || identical(ep_id, tree$safety_net$endpoint)) return(character())
  covered <- !identical(ep$status, "not_in_powerkit")
  out <- character()
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
        "a study can fail to find an effect without showing it is absent. powerkit has no equivalence version of this design yet.",
        "A simulation in R of the two one-sided tests for your model is the usual route; this card's R script can be a starting point."))
    }
  }
  fit <- route_card_outcomes[[ep_id]]
  outcome <- ctx$outcome
  if (!is.null(fit) && !is.null(outcome) && !outcome %in% fit$takes) {
    out <- c(out, sprintf(paste(
      "You said your outcome is %s. This card plans for %s, so its answer would not fit your study. Data like yours are usually",
      "analysed with a generalised mixed model, whose power is simulated in R (for example with simr); powerkit doesn't calculate it yet."),
      route_outcome_words[[outcome]], fit$words))
  }
  if (identical(ep_id, "E26") && identical(ctx$times, "many_conditions")) {
    out <- c(out, paste(
      "You said the same people are in three or more conditions. This card compares two (McNemar's test); powerkit has nothing",
      "for three or more yet (Cochran's Q, or a logistic mixed model simulated in R with simr). You can plan one pair of conditions here."))
  }
  if (identical(ep_id, "E41") && identical(ctx$times, "twice")) {
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
    if (identical(ep_id, "E41") && identical(ctx$times, "twice")) pick_button("Open multiple regression", "ep:E24", class = "btn btn-outline-primary btn-sm"))
}

# "Plan my whole study" (V-02, V-05): what the route can't do for this
# card, in place of the note about separate people when that isn't why.
guided_single_note <- function(tree, ctx, start) {
  aim <- start$aim %||% "predict"
  # Replicating goes through the same questions as testing a prediction.
  if (!aim %in% c("predict", "replicate")) {
    label <- aim_question(tree)$options[[aim]]$label %||% aim
    return(sprintf("Plan my whole study plans several analyses of a study that tests predictions. For “%s”, this is the one card that plans it: work it out here, then press “Add this to my study plan” under the result if you want it in your plan.", label))
  }
  if (!identical(ctx$grouping, "independent")) return(tree$guided$single_analysis_note)
  NULL
}

whole_study_bayes_note <- function(on) {
  if (!isTRUE(on)) return(NULL)
  div(class = "status status-soon bayes-mode-note", role = "note",
    tags$strong("Bayes factors: "),
    "the plan and the whole-study simulation use p-values: powerkit has no Bayes factor version of them yet. An analysis opened from the plan on its own card opens on its Bayes factor version where it has one.")
}

# The safety net's way on (V-09): search by name, or the map.
safety_net_ways_ui <- function() {
  div(class = "safety-ways",
    p("Two ways that might still find an analysis:"),
    action_bar(
      pick_button("Search every analysis by name", "route:known", class = "btn btn-outline-primary"),
      actionButton("safety_open_map", "Open the methods map", class = "btn btn-outline-primary")))
}
