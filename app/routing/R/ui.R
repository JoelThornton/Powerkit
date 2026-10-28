# Screen builders for the routing prototype. Each returns htmltools tags
# built from tree.yaml; none calculates anything. Every button reports its
# action through one Shiny input ("pick") as a string such as "route:known",
# "opt:2", "back" or "ep:E7"; app.R dispatches on it.

pick_button <- function(label, value, help = NULL, class = "btn btn-outline-primary choice") {
  tags$button(
    type = "button",
    class = class,
    onclick = sprintf("Shiny.setInputValue('pick', '%s', {priority: 'event'})", value),
    tags$span(class = "choice-label", label),
    if (!is.null(help)) tags$span(class = "choice-help", help)
  )
}

# Where you are and where to go (26 October 2026): "Back" and "Start
# again" sit at the top of every screen, above its heading, so they are
# found without scrolling; the screen's next step sits in a bar pinned to
# the bottom of the window (action_bar()), so it is always in view.
screen_nav_ui <- function(back = "back", back_label = "Back", restart = TRUE) {
  div(class = "screen-nav",
    if (!is.null(back)) pick_button(paste0("\u2190 ", back_label), back, class = "btn btn-link back-link"),
    if (restart) pick_button("Start again", "home", class = "btn btn-link restart-link"))
}

action_bar <- function(...) div(class = "nav-buttons action-bar", ...)

# What the prototype can do, as one quiet line under the top bar (it was a
# large warning box above everything).
prototype_banner <- function(tree) {
  div(class = "prototype-banner", role = "note", tree$banner)
}

# Placeholders for undecided settings ---------------------------------------

placeholder_ui <- function(setting) {
  if (is_decided(setting)) {
    return(div(
      class = "decided",
      tags$strong("Maintainer decision"), tags$span(class = "ref", sprintf("(%s):", setting$ref)), " ",
      setting$options[[setting$value]] %||% setting$value
    ))
  }
  div(
    class = "placeholder",
    div(class = "placeholder-label", "Undecided: for the maintainer", tags$span(class = "ref", setting$ref)),
    p(setting$question),
    tags$ul(lapply(unname(setting$options), tags$li)),
    if (!is.null(setting$proposed_text)) p(tags$em("Proposed: "), setting$proposed_text),
    p(class = "small text-muted mb-0", sprintf("Set 'value' for '%s' in app/routing/tree.yaml to record the decision.", setting$key))
  )
}

# A one-line version for cards, next to the question it affects. The full
# question and options are on the "For the maintainer" tab.
placeholder_inline <- function(setting) {
  if (is_decided(setting)) {
    return(tags$span(class = "decided-inline", sprintf("Maintainer decision (%s): %s", setting$ref, setting$options[[setting$value]] %||% setting$value)))
  }
  tags$span(class = "placeholder-inline", tags$strong("Undecided, for the maintainer"), sprintf(" (%s): %s", setting$ref, setting$question))
}

# The maintainer's view ------------------------------------------------------

# The undecided settings (the placeholders above and the "For the
# maintainer" tab) are questions for the maintainer, not for people using
# the app, so the public site leaves them out. They show when the app runs
# with the environment variable POWERKIT_MAINTAINER_VIEW=true, or when its
# address ends in ?view=maintainer.
maintainer_view_requested <- function(query = "") {
  identical(tolower(Sys.getenv("POWERKIT_MAINTAINER_VIEW")), "true") ||
    identical(shiny::parseQueryString(query %||% "")$view, "maintainer")
}

# Whether to show them now: the option powerkit.maintainer_view if set (for
# tests), else the session's choice (set in app.R's server), else the
# environment variable.
maintainer_view <- function() {
  opt <- getOption("powerkit.maintainer_view")
  if (!is.null(opt)) return(isTRUE(opt))
  session <- shiny::getDefaultReactiveDomain()
  if (!is.null(session)) return(isTRUE(session$userData$maintainer_view))
  maintainer_view_requested()
}

placeholders_at <- function(tree, where) {
  if (!maintainer_view()) return(NULL)
  shown <- settings_shown_at(tree, where)
  if (length(shown) == 0) return(NULL)
  div(class = "placeholders", lapply(shown, placeholder_ui))
}


# A standard name without its PROCESS model number, which is shown on its
# own line: the number is the label Hayes's PROCESS tool gives the shape of
# model, not part of the analysis's name (other software fits the
# same model without it).
standard_name <- function(doc_name) {
  pattern <- "\\s*\\((PROCESS models? [0-9][0-9, ]*)\\)"
  found <- regmatches(doc_name, regexpr(pattern, doc_name, perl = TRUE))
  if (length(found) == 0) return(list(name = doc_name, also = NULL))
  model <- sub(pattern, "\\1", found, perl = TRUE)
  list(name = sub(pattern, "", doc_name, perl = TRUE),
    also = sprintf("In Hayes's PROCESS tool this is %s; other software fits the same model without giving it a number.", model))
}

# Progress -------------------------------------------------------------------

# The app's four steps (the new design, 18 October 2026). Steps, not a
# percentage: the design finder's length depends on the answers.
progress_steps <- c(study = "Your study", design = "Find your design", numbers = "Your numbers", result = "Result")

screen_step <- function(screen, has_result = FALSE) {
  if (screen %in% c("start", "aim", "check")) return("study")
  if (identical(screen, "form")) return(if (isTRUE(has_result)) "result" else "numbers")
  if (identical(screen, "g_sim")) return("numbers")
  "design"
}

progress_ui <- function(current) {
  at <- match(current, names(progress_steps))
  tags$nav(class = "progress-steps", `aria-label` = "Progress",
    tags$ol(lapply(seq_along(progress_steps), function(i) {
      state <- if (i < at) "done" else if (i == at) "current" else "todo"
      tags$li(class = state, `aria-current` = if (i == at) "step",
        tags$span(class = "step-num", `aria-hidden` = "true", if (i < at) "\u2713" else i),
        tags$span(progress_steps[[i]], if (i < at) tags$span(class = "visually-hidden", " (done)")))
    })))
}

# The browser's Back and Forward buttons ------------------------------------

# The app changes screens without loading pages, so the browser had no
# earlier page to go back to and Back left powerkit. Each screen or tab
# change now adds a browser history entry (nav_js), and Back or Forward
# restores the app as it was at that entry (app.R, "Browser history").

# The parts of the app's state that make up "where you are", saved with
# each history entry. Not the calculation itself: it is run again.
nav_fields <- c("screen", "from_labs", "labs_seed", "start", "route", "node", "ctx", "history",
  "skip_screening",
  "endpoint", "came_from", "form_values", "form_k", "answers", "ticked", "primary", "asks", "rule",
  "plan_id", "plan_results", "plan_values", "plan_shared", "plan_filled", "checked_project")

# What makes one entry differ from the last: the screen, the question or
# card on it, how many answers were given, and the tab.
nav_key <- function(screen, node, endpoint, n_answers, tab) {
  paste(screen %||% "", node %||% "", endpoint %||% "", n_answers, tab %||% "", sep = "|")
}

# Page addresses ---------------------------------------------------------------

# Each tab has its own address (?page=labs and so on), so a page can be
# shared by link. The plan tab is the plain address.
page_slugs <- function() {
  c(plan = "Plan a power analysis", about = "About", "whats-new" = "What's new",
    labs = labs_tab_title, feedback = "Feedback", maintainer = "For the maintainer: undecided settings")
}

# The tab an address asks for, or NULL for the plan tab or a page that
# isn't there (the maintainer's tab only in the maintainer's view).
page_from_query <- function(query = "") {
  slug <- shiny::parseQueryString(query %||% "")$page
  if (is.null(slug)) return(NULL)
  slug <- tolower(slug)
  if (identical(slug, "maintainer") && !maintainer_view_requested(query)) return(NULL)
  tab <- page_slugs()[slug]
  if (is.na(tab)) NULL else unname(tab)
}

# The address name for a tab ("plan" is the plain address).
page_slug <- function(tab) {
  slug <- names(page_slugs())[match(tab %||% "", page_slugs())]
  if (is.na(slug)) "plan" else slug
}

# The online app's public address. It runs inside Posit Connect Cloud's
# frame, so the browser's address bar can't show which page is open; the
# share button in the top bar (share_page_ui()) gives this address with
# the page instead.
public_address <- "https://joelthornton-powerkit.share.connect.posit.cloud"

# The top bar's button: copies a link to the page on show (and the Labs
# tool open, as ?page=labs&tool=...).
share_page_ui <- function() {
  div(class = "share-page",
    tags$span(class = "share-page-status", role = "status", `aria-live` = "polite"),
    tags$button(type = "button", class = "btn btn-sm share-page-btn", onclick = "pkSharePage(this)",
      `data-public` = public_address, "Share this page"))
}

# Each history entry carries its page in the address (?page=...); a link
# with ?page= opens that page.
nav_js <- "
  window.pkPageUrl = function(page) {
    var url = new URL(window.location.href);
    if (page && page !== 'plan') url.searchParams.set('page', page); else url.searchParams.delete('page');
    return url.toString();
  };
  Shiny.addCustomMessageHandler('pk_nav', function(m) {
    var entry = { pk: m.pos };
    window.pkPage = m.page;
    var url = pkPageUrl(m.page);
    if (m.replace) history.replaceState(entry, '', url);
    else history.pushState(entry, '', url);
  });
  window.addEventListener('popstate', function(e) {
    if (e.state && e.state.pk) Shiny.setInputValue('pk_nav_to', e.state.pk, { priority: 'event' });
  });
  // Copy a link to the page: the public address inside Connect Cloud's
  // frame, else this address (without the maintainer's view).
  window.pkSharePage = function(btn) {
    var framed = false; try { framed = window.self !== window.top; } catch (e) { framed = true; }
    var base = framed ? btn.getAttribute('data-public') + '/' : window.location.origin + window.location.pathname;
    var page = window.pkPage || 'plan';
    var params = new URLSearchParams();
    if (page !== 'plan') params.set('page', page);
    if (page === 'labs' && window.pkLabsTool) params.set('tool', window.pkLabsTool);
    var link = base + (params.toString() ? '?' + params.toString() : '');
    var status = btn.parentNode.querySelector('.share-page-status');
    pkCopyText(link, null);
    if (status) { status.textContent = 'Link copied'; setTimeout(function() { status.textContent = ''; }, 3000); }
  };
"

# Start screen ---------------------------------------------------------------

# The aim (tree.yaml, start_questions), on its own screen after the route
# is chosen: one card per answer. Estimation and equivalence go to their
# cards (start_exit()); testing a prediction goes on to the screening.
aim_question <- function(tree) Filter(function(q) identical(q$id, "aim"), tree$start_questions)[[1]]

aim_ui <- function(tree) {
  q <- aim_question(tree)
  tagList(
    screen_nav_ui(),
    h2(q$question),
    div(class = "choices", lapply(names(q$options), function(k) {
      o <- q$options[[k]]
      pick_button(o$label, paste0("aim:", k), o$help)
    })),
    p(class = "text-muted small", tree$routes$screening_note)
  )
}

# Where the aim sends the user before the design finder: a card for aims
# powerkit doesn't support yet, or NULL.
# The screening context the aim sets (its goal, for equivalence), so the
# screening doesn't ask the goal again.
aim_context <- function(tree, start) {
  aim_question(tree)$options[[start$aim %||% "predict"]]$sets %||% list()
}

start_exit <- function(tree, start) {
  aim_question(tree)$options[[start$aim %||% "predict"]]$`next`
}

# The start screen (26 October 2026): only the three ways to start. The
# aim follows on its own screen; whether the sample size is fixed and how
# several tests are handled are asked on the input screen, where they are
# used.
start_ui <- function(tree, start = list()) {
  routes <- tree$routes$options
  if (!guided_route_enabled(tree)) routes <- Filter(function(r) r$id != "guided", routes)
  tagList(
    h2(tree$routes$question),
    div(class = "choices route-choices", lapply(routes, function(r) pick_button(r$label, paste0("route:", r$id), r$help))),
    placeholders_at(tree, "start")
  )
}

# Trail of answers so far ------------------------------------------------------

trail_ui <- function(history) {
  if (length(history) == 0) return(NULL)
  div(
    class = "trail",
    tags$span(class = "trail-title", "Your answers so far (click one to change it):"),
    lapply(seq_along(history), function(i) {
      tags$button(
        type = "button", class = "chip",
        onclick = sprintf("Shiny.setInputValue('pick', 'trail:%d', {priority: 'event'})", i),
        history[[i]]$answer
      )
    })
  )
}

# One question screen ("Help me choose") ------------------------------------

# `ctx` holds the screening answers so far; options are filtered by it and
# the safety net comes last. "opt:i" refers to the i-th option shown.
node_ui <- function(tree, node_id, history, ctx = list(), route = NULL) {
  node <- tree$nodes[[node_id]]
  label <- node$sub_id %||% node$doc_id
  opts <- visible_options(tree, node, ctx)
  screening <- node$doc_id %in% c("S1", "S2", "S3", "S4", "O5a", "T1")
  # "I know my analysis" is a menu: someone who knows their test can go
  # straight to the list. The other routes need the screening answers to
  # route at all, so the skip isn't offered there.
  skip <- tree$routes$skip_screening
  may_skip <- screening && identical(route, "known")
  tagList(
    screen_nav_ui(),
    trail_ui(history),
    # The question ID stays in the page source (for tests and reviewers) but
    # isn't shown to users or read out by screen readers.
    div(class = "question-id", hidden = NA, `aria-hidden` = "true", `data-question-id` = label,
      sprintf("%s %s", if (screening) "Screening question" else "Question", label)),
    h2(node$text),
    if (!is.null(node$help)) p(class = "lead", node$help),
    div(class = "choices", lapply(seq_along(opts), function(i) {
      o <- opts[[i]]
      pick_button(o$label, paste0("opt:", i), o$help,
        class = if (isTRUE(o$safety)) "btn btn-outline-secondary choice choice-safety" else "btn btn-outline-primary choice")
    })),
    if (may_skip) {
      div(class = "choices list mt-4",
        pick_button(skip$label, "skip_screening", skip$help,
          class = "btn btn-outline-secondary choice choice-safety"))
    },
    placeholders_at(tree, node_id)
  )
}

# "I know my analysis" list ---------------------------------------------------

# With screening answers (`ctx`), the list offers only the end points that
# fit them (endpoints_for_context()).
known_ui <- function(tree, history = list(), ctx = NULL) {
  groups <- list(
    "Runs in powerkit (validated)" = "runs_validated",
    "Runs, validation in progress" = "runs_validation_in_progress",
    "Coming soon" = "coming_soon",
    "Not in powerkit yet" = "not_in_powerkit"
  )
  eps <- tree$endpoints
  total <- length(eps)
  if (!is.null(ctx)) eps <- eps[endpoints_for_context(tree, ctx)]
  tagList(
    screen_nav_ui(),
    trail_ui(history),
    h2("Which analysis do you want?"),
    p(class = "lead", "Pick it by name. Each one opens its card."),
    if (!is.null(ctx)) {
      p(class = "text-muted", sprintf("Showing the %d of %d analyses that fit your screening answers. To see others, change an answer above.", length(eps), total))
    } else {
      tagList(
        p(class = "text-muted", sprintf(tree$routes$skip_screening$note, total)),
        div(class = "choices list",
          pick_button(tree$routes$skip_screening$filter_label, "screen_me",
            class = "btn btn-outline-secondary choice choice-safety"))
      )
    },
    lapply(names(groups), function(g) {
      ids <- names(eps)[vapply(eps, function(e) e$status %in% groups[[g]], logical(1))]
      if (length(ids) == 0) return(NULL)
      tagList(
        h3(class = "h4 mt-4", g),
        div(class = "choices list", lapply(ids, function(id) {
          pick_button(eps[[id]]$plain_name, paste0("ep:", id),
            # The standard name, without a PROCESS model number or the
            # internal code (shown to the maintainer only).
            if (maintainer_view()) sprintf("%s (%s)", standard_name(eps[[id]]$doc_name)$name, id) else standard_name(eps[[id]]$doc_name)$name)
        }))
      )
    }),
    div(class = "choices list mt-4", pick_button(tree$safety_net$label, paste0("ep:", tree$safety_net$endpoint), class = "btn btn-outline-secondary choice choice-safety"))
  )
}

# End-point card ------------------------------------------------------------

# The validation note and links for a validated design, inside the card's
# "More about this analysis".
validated_line_ui <- function(tree, ep) {
  if (!identical(ep$status, "runs_validated")) return(NULL)
  p(class = "validated-line", tags$strong("Validated: "), ep$validation$note, " ",
    tags$a(href = tree$links$validation_log, target = "_blank", "Validation log"), " \u00b7 ",
    tags$a(href = paste0(tree$links$tests_folder, "/", ep$validation$file), target = "_blank", tags$code(ep$validation$file)))
}

status_ui <- function(tree, ep) {
  links <- tree$links
  validation_links <- function() tagList(
    tags$a(href = links$validation_log, target = "_blank", "Validation log"), " · ",
    tags$a(href = paste0(links$tests_folder, "/", ep$validation$file), target = "_blank", tags$code(ep$validation$file))
  )
  package_list <- function() tags$ul(lapply(ep$packages, function(pk) {
    tags$li(HTML(sprintf("<strong><a href=\"%s\" target=\"_blank\">%s</a></strong>: %s",
      htmltools::htmlEscape(pk$url), htmltools::htmlEscape(pk$name), htmltools::htmlEscape(pk$what))))
  }))
  not_five <- if (identical(ep$five_tools, "not covered")) {
    p(tags$strong("Not covered by the five tools"), " powerkit builds on (Superpower, Spower, power4mome, InteractionPoweR, G*Power).")
  }
  switch(
    ep$status,
    # A design that runs and is validated needs no box saying so (26
    # October 2026); its validation note is under "More about this
    # analysis" (validated_line_ui()).
    runs_validated = NULL,
    runs_validation_in_progress = div(
      class = "status status-in-progress",
      tags$span(class = "badge-progress", "Validation in progress"),
      tags$strong("Runs, validation in progress."), " ", ep$validation$note, " ", validation_links(),
      # A card that runs one test but not a related one (E26: Cochran's Q).
      if (is.character(ep$no_ready_made_tool)) p(class = "mb-0", tags$strong(paste0(ep$no_ready_made_tool, ":")), " ", tree$no_ready_made_tool_text)
    ),
    coming_soon = div(class = "status status-soon", tags$strong("Coming soon."), " ", ep$coming_soon_note),
    not_in_powerkit = if (isTRUE(ep$generic)) {
      div(
        class = "status status-not",
        tags$strong(ep$card_heading %||% "Not in powerkit yet."),
        p(class = if (!isTRUE(ep$established_tools)) "mb-0", ep$card_text),
        if (isTRUE(ep$established_tools)) named_tools_ui(tree, ep) %||% p(class = "mb-0", tree$established_tools_text)
      )
    } else if (isTRUE(ep$no_ready_made_tool)) {
      div(
        class = "status status-not",
        tags$strong("Not in powerkit yet."),
        not_five,
        p(ep$status_text %||% tree$no_ready_made_tool_text),
        package_list(),
        p(class = "small mb-0", if (!isFALSE(ep$from_coverage)) "From powerkit's review of what other tools cover. ", "powerkit can't check results from other tools.")
      )
    } else {
      div(
        class = "status status-not",
        tags$strong("Not in powerkit yet: use ",
          lapply(seq_along(ep$packages), function(i) {
            pk <- ep$packages[[i]]
            tagList(if (i > 1) " or ", tags$a(href = pk$url, target = "_blank", pk$name))
          })
        ),
        not_five,
        package_list(),
        if (is.character(ep$no_ready_made_tool)) p(tags$strong(paste0(ep$no_ready_made_tool, ":")), " ", tree$no_ready_made_tool_text),
        p(class = "small mb-0", "From powerkit's review of what other tools cover. powerkit can't check results from other tools.")
      )
    }
  )
}

# The draft note on other defensible analyses: shown only once the setting
# other_analyses_note is "show" (open question 20; off while undecided).
other_analyses_ui <- function(tree, ep) {
  if (is.null(ep$alternatives) || !identical(setting_by_key(tree, "other_analyses_note")$value, "show")) return(NULL)
  p(class = "other-analyses", sub("{alternatives}", paste(unlist(ep$alternatives), collapse = "; "), tree$other_analyses_text, fixed = TRUE))
}

# Other established tools on generic "not covered" cards (setting
# name_other_tools, `name`), from the end point's `tools` (each sourced in
# docs/card-sources.md).
named_tools_ui <- function(tree, ep) {
  if (is.null(ep$tools) || !identical(setting_by_key(tree, "name_other_tools")$value, "name")) return(NULL)
  tagList(
    p(class = "mb-1", tree$named_tools_text),
    tags$ul(class = "mb-0", lapply(ep$tools, function(t) tags$li(tags$a(href = t$url, target = "_blank", t$name), ": ", t$what)))
  )
}

# Rank-based tests (setting rank_based_tests, `label`): on cards whose end
# point names the rank-based alternative, say the figure only approximates it.
# Where powerkit simulates the rank test (`rank_test_simulated`), the card
# points to the test version instead.
rank_test_ui <- function(tree, ep) {
  if (is.null(ep$rank_test)) return(NULL)
  if (isTRUE(ep$rank_test_simulated)) {
    return(p(class = "rank-test-note", sub("{rank_test}", ep$rank_test, tree$rank_test_simulated_text, fixed = TRUE)))
  }
  if (!identical(setting_by_key(tree, "rank_based_tests")$value, "label")) return(NULL)
  p(class = "rank-test-note", sub("{rank_test}", ep$rank_test, tree$rank_test_text, fixed = TRUE))
}

# On the safety-net card: what to write down for a statistician, filled in
# from the answers so far (`history`: list(node, answer, ctx) entries).
prepare_ui <- function(tree, history = list()) {
  prep <- tree$safety_net$prepare
  answer_for <- function(nodes) {
    got <- vapply(Filter(function(h) h$node %in% nodes && !identical(h$answer, tree$safety_net$label), history), function(h) h$answer, character(1))
    if (length(got) == 0) tags$em(prep$not_answered) else paste(got, collapse = "; ")
  }
  stopped <- Filter(function(h) identical(h$answer, tree$safety_net$label), history)
  div(
    class = "prepare",
    h3(class = "h5", "What to write down for a statistician"),
    p(prep$intro),
    tags$ul(
      lapply(prep$items, function(it) tags$li(tags$strong(paste0(it$label, ": ")), answer_for(unlist(it$nodes)))),
      if (length(stopped) > 0) tags$li(tags$strong(paste0(prep$stopped_at, ": ")), tree$nodes[[stopped[[length(stopped)]]$node]]$text),
      lapply(unlist(prep$also), tags$li)
    )
  )
}

# Plain-English hints for the glossary terms in a piece of text, leaving
# out terms already explained higher up the same card.
hints_ui <- function(tree, text, exclude = character()) {
  found <- Filter(function(g) !(g$term %in% exclude), glossary_for(tree, text))
  lapply(found, function(g) div(class = "hint", tags$dfn(g$term), ": ", g$hint))
}

card_ui <- function(tree, ep_id, compact = FALSE, history = list()) {
  ep <- tree$endpoints[[ep_id]]
  # Headings follow the page outline: the full card's title is the screen's
  # h2; a compact card sits under the plan's h2.
  section_heading <- function(text) (if (compact) h4 else h3)(class = "h5", text)
  runs <- ep$status %in% c("runs_validated", "runs_validation_in_progress", "coming_soon")
  div(
    class = paste("card endpoint-card", if (compact) "compact"),
    div(
      class = "card-body",
      # The end point's ID and engine template are for reviewers: kept in
      # the page source, shown only in the maintainer's view.
      div(class = "card-eid", hidden = if (!maintainer_view()) NA, `aria-hidden` = if (!maintainer_view()) "true", ep_id),
      (if (compact) h3 else h2)(class = "card-title h3", ep$plain_name),
      p(class = "standard-name", "Standard name: ", tags$strong(standard_name(ep$doc_name)$name), if (!is.null(ep$template) && maintainer_view()) tagList(" · ", tags$code(ep$template))),
      if (!is.null(standard_name(ep$doc_name)$also)) p(class = "also-called small text-muted", standard_name(ep$doc_name)$also),
      hints_ui(tree, standard_name(ep$doc_name)$name),
      status_ui(tree, ep),
      if (identical(ep_id, tree$safety_net$endpoint) && !compact) prepare_ui(tree, history),
      if (!is.null(ep$card_points)) tags$ul(class = "card-points", lapply(ep$card_points, tags$li)),
      other_analyses_ui(tree, ep),
      rank_test_ui(tree, ep),
      # What the input screen will ask and which package calculates it:
      # useful before starting, but it repeats the input screen, so it is
      # folded (22 October 2026).
      if (!is.null(ep$inputs) || runs) tags$details(class = "card-more",
        tags$summary("More about this analysis: what you'd enter, and which package calculates it"),
        if (!is.null(ep$inputs)) tagList(section_heading("What you would enter"), tags$ul(lapply(ep$inputs, function(input) tags$li(
          input,
          hints_ui(tree, input)
        )))),
        validated_line_ui(tree, ep),
        if (runs) tagList(
          p(class = "backend", tags$strong("Backend: "), ep$backend, " · ", tags$strong("Default method: "), ep$method),
          hints_ui(tree, paste(ep$backend, ep$method), exclude = vapply(glossary_for(tree, ep$doc_name), `[[`, "", "term"))
        ),
        if (!compact && runs) tagList(
          section_heading("What you'd be asked next"),
          tags$ol(lapply(closing_questions_for(tree, ep_id), function(q) tags$li(
            q$text,
            if (!is.null(q$note)) tags$span(class = "text-muted", paste0(" ", q$note)),
            if (maintainer_view()) lapply(unlist(q$setting), function(key) div(placeholder_inline(setting_by_key(tree, key))))
          )))
        )
      ),
      if (!compact && ep$status == "not_in_powerkit" && !isTRUE(ep$generic) && maintainer_view()) div(
        lapply(c("not_in_spec_wording", "r_script_for_uncovered"), function(key) div(placeholder_inline(setting_by_key(tree, key))))
      ),
      if (!compact) placeholders_at(tree, ep_id),
      # End points that calculate on their input screen (forms.yaml,
      # `calculates`, copied into tree$calculates when the app starts).
      if (!ep_id %in% unlist(tree$calculates)) p(class = "no-numbers", "No numbers are calculated in this prototype.")
    )
  )
}

# Guided route ----------------------------------------------------------------

# `ctx` holds the screening answers: a variable with `screen_key` offers
# only the option the screening chose (plus the safety net).
guided_variables_ui <- function(tree, answers, ctx = list(), history = list()) {
  g <- tree$guided
  if (identical(ctx$times, "many_conditions")) {
    return(tagList(
      screen_nav_ui(),
      trail_ui(history),
      h2("Plan my whole study: your variables"),
      div(class = "status status-soon", g$many_conditions_note),
      placeholders_at(tree, "guided_variables"),
      action_bar(pick_button("Continue in 'Help me choose'", "continue:choose", class = "btn btn-primary"))
    ))
  }
  tagList(
    screen_nav_ui(back = NULL),
    trail_ui(history),
    h2("Plan my whole study: your variables"),
    p(class = "lead", g$intro),
    p(class = "text-muted", g$scope_note),
    placeholders_at(tree, "guided_variables"),
    lapply(g$variables, function(v) {
      opts <- guided_options(v, ctx)
      selected <- answers[[v$id]]
      if (is.null(selected) || !selected %in% names(opts)) selected <- names(opts)[1]
      radioButtons(paste0("g_", v$id), v$label, choiceNames = unname(unlist(opts)), choiceValues = names(opts), selected = selected, width = "100%")
    }),
    action_bar(pick_button("Next: choose the analyses", "guided:analyses", class = "btn btn-primary"))
  )
}

# Each analysis gets one choice: not planned, main (the sample size is set
# by it) or extra (reported, but it doesn't set the sample size).
analysis_role_choices <- c(
  "Not planned" = "none",
  "Main analysis: the sample size must be big enough for this" = "main",
  "Extra analysis: I'll report it, but it doesn't set the sample size" = "extra"
)

analysis_role <- function(id, ticked, primary) {
  if (!id %in% ticked) "none" else if (id %in% primary) "main" else "extra"
}

guided_analyses_ui <- function(tree, answers, ticked, primary, asks, rule) {
  apps <- applicable_analyses(tree, answers)
  g <- tree$guided
  # Show the question about how the main analyses combine only when there
  # are two or more of them.
  role_inputs <- vapply(apps, function(a) sprintf("input['role_%s']", a$id), character(1))
  several_main <- sprintf("[%s].filter(function(v) { return v === 'main'; }).length >= 2", paste(role_inputs, collapse = ", "))
  tagList(
    screen_nav_ui("guided:variables", "Back to the variables"),
    h2("Plan my whole study: your analyses"),
    p(class = "lead", "For each analysis, say whether you plan it, and whether it is a main analysis. The sample size is worked out for the main analyses."),
    lapply(apps, function(a) {
      res <- resolve_analysis(tree, a, answers, asks[[a$id]])
      ask <- res$ask %||% res$asked
      div(
        class = "analysis-row",
        radioButtons(paste0("role_", a$id), tags$strong(a$label), choices = analysis_role_choices,
          selected = analysis_role(a$id, ticked, primary), width = "100%"),
        if (!is.null(ask)) radioButtons(paste0("ask_", a$id), ask$text, choices = c(vapply(ask$options, function(o) o$label, character(1)), tree$safety_net$label), selected = asks[[a$id]] %||% character(0), width = "100%")
      )
    }),
    conditionalPanel(several_main,
      radioButtons("g_rule", "You have more than one main analysis. What does your study's claim need?",
        choiceNames = lapply(g$combination_rules, function(r) tagList(tags$strong(r$label), tags$br(), tags$span(class = "text-muted", r$note))),
        choiceValues = vapply(g$combination_rules, function(r) r$id, character(1)),
        selected = rule %||% "each", width = "100%"
      )
    ),
    action_bar(pick_button("Show my plan", "guided:plan", class = "btn btn-primary"))
  )
}

guided_plan_ui <- function(tree, answers, ticked, primary, asks, rule,
                           history = list(), route_label = "Plan my whole study", raw_answers = answers,
                           forms = NULL, results = list(), shared = list()) {
  g <- tree$guided
  rule_def <- Filter(function(r) identical(r$id, rule), g$combination_rules)[[1]]
  role_badge <- function(id) if (id %in% primary) tags$span(class = "badge bg-primary ms-2", "Main analysis") else tags$span(class = "badge bg-secondary ms-2", "Extra analysis")
  # One row per analysis: its name, its role, what powerkit calls it and
  # the button to its input screen; the full card is folded away.
  rows <- lapply(ticked, function(id) {
    a <- analysis_by_id(tree, id)
    res <- resolve_analysis(tree, a, answers, asks[[id]])
    head <- div(class = "plan-head", tags$strong(a$label), role_badge(id))
    body <- if (!is.null(res$endpoint)) {
      ep <- tree$endpoints[[res$endpoint]]
      tagList(
        p(class = "plan-design", ep$plain_name),
        # The analysis's input screen, opened from the plan: the same one
        # the other routes reach from the card.
        if (!is.null(forms) && has_form(forms, res$endpoint)) div(class = "plan-actions",
          plan_result_line(plan_result(results, id, res$endpoint)),
          pick_button(if (is.null(plan_result(results, id, res$endpoint))) "Enter your values" else "Change your values",
            paste0("gform:", id), class = "btn btn-primary")),
        tags$details(class = "plan-more", tags$summary("More about this analysis"),
          card_ui(tree, res$endpoint, compact = TRUE),
          mismatch_ui(paste0("mismatch-", id), path_text(tree, route_label, history, res$endpoint,
            extra = c(guided_lines(tree, raw_answers), paste0("- Analysis: ", a$label)))))
      )
    } else if (!is.null(res$ask)) {
      div(class = "status status-soon", "Answer the follow-up question on the previous screen: ", res$ask$text)
    } else {
      div(class = "status status-not", tags$strong("Not in powerkit yet. "), res$unmapped,
        if (!is.null(res$package)) p(tags$a(href = res$package$url, target = "_blank", res$package$name), ": ", res$package$what))
    }
    div(class = "plan-item", head, body)
  })
  shared_rel <- shared_relationships(tree, ticked)
  labels <- vapply(g$analyses, function(a) a$label, character(1))
  names(labels) <- vapply(g$analyses, function(a) a$id, character(1))
  several_main <- length(intersect(ticked, primary)) >= 2
  separate <- tagList(
    if (length(ticked) == 0) p("No analyses ticked yet.") else rows,
    h3(class = "h4 mt-4", "Combined sample size"),
    if (several_main) p(tags$strong("Your claim:"), paste0(" ", rule_def$label, ".")),
    combined_n_ui(tree, ticked, primary, asks, answers, forms, results),
    if (several_main) tags$details(class = "plan-more", tags$summary("About your claim and significance levels"), p(rule_def$note)),
    if (length(shared_rel) || length(ticked) >= 2) tags$details(class = "plan-more",
      tags$summary("Check that your numbers describe the same study"),
      shared_values_ui(tree, ticked, answers, asks, shared),
      if (length(shared_rel)) tagList(
        p("These relationships appear in more than one analysis but are asked for in different ways, so check by eye that your numbers describe the same study:"),
        tags$ul(lapply(shared_rel, function(s) {
          tags$li(sprintf("%s%s appears in: %s.", toupper(substr(s$label, 1, 1)), substr(s$label, 2, nchar(s$label)), paste(labels[s$sharing], collapse = "; ")), if (!is.null(s$note)) tags$span(class = "text-muted", paste0(" ", s$note)))
        }))))
  )
  # When the whole-study simulation covers the plan, it comes first: one
  # description of the study, every analysis run on the same simulated
  # studies. The separate calculations are folded below it.
  sim <- whole_study_plan(tree, answers, ticked, primary, asks)
  tagList(
    screen_nav_ui("guided:analyses", "Back to the analyses"),
    h2("Your plan"),
    if (isTRUE(sim$ok)) tagList(
      whole_study_entry_ui(sim, ticked = ticked, labels = labels, badge = role_badge),
      tags$details(class = "plan-separate", tags$summary(class = "h4", "Or calculate each analysis on its own"), separate)
    ) else tagList(
      separate,
      whole_study_entry_ui(sim)
    ),
    placeholders_at(tree, "plan")
  )
}

# The last calculation made for an analysis from the plan, if it is for
# the end point the analysis leads to now (a changed follow-up answer can
# send it elsewhere).
plan_result <- function(results, id, endpoint) {
  r <- results[[id]]
  if (is.null(r) || !identical(r$endpoint, endpoint)) return(NULL)
  r
}

plan_result_line <- function(r) {
  if (is.null(r)) return(NULL)
  p(class = "plan-result", if (identical(r$goal, "sample_size")) {
    HTML(sprintf("Your calculation: <strong>N = %s</strong>.", whole(r$n)))
  } else {
    "You calculated something other than the sample size. To count this analysis in the combined sample size, calculate the sample size."
  })
}

# Values entered once (open question 12, decided 26 October 2026): each
# shared value that two or more ticked analyses ask for, with its value and
# the analysis it was entered in.
shared_values_ui <- function(tree, ticked, answers, asks, shared) {
  eps <- vapply(ticked, function(id) resolve_analysis(tree, analysis_by_id(tree, id), answers, asks[[id]])$endpoint %||% "", "")
  rows <- list()
  for (v in tree$guided$shared_values) {
    users <- ticked[eps %in% names(v$fields)]
    if (length(users) < 2) next
    s <- shared[[v$id]]
    rows[[length(rows) + 1]] <- tags$li(tags$strong(v$label), ": ",
      if (is.null(s)) "not entered yet" else sprintf("%s (entered for %s)", s$value, analysis_by_id(tree, s$from)$label),
      tags$span(class = "text-muted", sprintf(" Used by: %s.", paste(vapply(users, function(id) analysis_by_id(tree, id)$label, ""), collapse = "; "))))
  }
  if (length(rows) == 0) return(NULL)
  tagList(
    p("Enter these once: a value you type on one analysis's input screen fills in the others when you open them, so they describe the same study. You can still change it on any of them, and the latest value is used from then on."),
    tags$ul(class = "shared-values", rows)
  )
}

# The note on an input screen opened from the plan, naming the values
# filled in from other analyses.
carried_note_ui <- function(tree, filled) {
  if (length(filled) == 0) return(NULL)
  items <- lapply(names(filled), function(sid) {
    v <- Filter(function(x) identical(x$id, sid), tree$guided$shared_values)[[1]]
    tags$li(v$label, tags$span(class = "text-muted", sprintf(" (from %s)", analysis_by_id(tree, filled[[sid]])$label)))
  })
  div(class = "alert alert-info carried-note", role = "note",
    p(tags$strong("Filled in from your plan. "), "These values were entered for another analysis on your plan, so both describe the same study. Change them here if they should differ; the plan then uses the new value."),
    tags$ul(items))
}

# The combined sample size for the main analyses: the largest N any of them
# needs, with that analysis named (docs/decisions.md, 22 October 2026). It
# uses only the calculations the user has run from the plan, and says
# which main analyses are still missing.
combined_n_ui <- function(tree, ticked, primary, asks, answers, forms, results) {
  mains <- intersect(ticked, primary)
  if (length(mains) == 0) return(p("Mark at least one analysis as a main analysis: the sample size is worked out for the main analyses."))
  label <- function(id) analysis_by_id(tree, id)$label
  n <- list(); to_do <- character(); elsewhere <- character()
  for (id in mains) {
    res <- resolve_analysis(tree, analysis_by_id(tree, id), answers, asks[[id]])
    r <- if (!is.null(res$endpoint)) plan_result(results, id, res$endpoint)
    if (!is.null(r) && identical(r$goal, "sample_size")) {
      n[[id]] <- r$n
    } else if (!is.null(res$endpoint) && !is.null(forms) && has_form(forms, res$endpoint)) {
      to_do <- c(to_do, id)
    } else {
      elsewhere <- c(elsewhere, id)
    }
  }
  largest <- if (length(n)) names(n)[which.max(unlist(n))]
  complete <- length(to_do) == 0 && length(elsewhere) == 0
  # One string per paragraph, so no stray spaces appear around the bold N.
  esc <- function(x) htmltools::htmlEscape(x)
  names_of <- function(ids) esc(paste(vapply(ids, label, ""), collapse = "; "))
  big_n <- if (!is.null(largest)) sprintf("<strong>N = %s</strong>", whole(n[[largest]]))
  div(class = "combined-n",
    if (!is.null(largest) && complete) p(class = "lead", HTML(sprintf(
      "Your study needs %s: the most any of your main analyses needs (%s). With that many, every main analysis reaches the power you asked for.",
      big_n, esc(label(largest)))))
    else if (!is.null(largest)) p(HTML(sprintf(
      "Largest so far: %s (%s). This is not the study's sample size until every main analysis is counted.", big_n, esc(label(largest)))))
    else p("Calculate the sample size for each main analysis (\u201cEnter your values\u201d above). The plan then shows the largest, which is the sample size the study needs."),
    if (length(to_do)) p(HTML(sprintf("Still to calculate: %s.", names_of(to_do)))),
    if (length(elsewhere)) p(HTML(sprintf(
      "powerkit can't calculate these yet, so work out their sample size elsewhere and use the largest number overall: %s.", names_of(elsewhere)))),
    if (length(mains) >= 2) p(class = "text-muted",
      "Each main analysis's input screen already takes your claim into account, so these numbers can be compared directly.")
  )
}

# Screen A's answers as the input screen should see them when it is opened
# from the plan. A main analysis among two or more takes its claim from the
# plan's answer to "What does your study's claim need?" (the rule ids are
# the claim ids), with the number of main analyses as the number of tests.
# An extra analysis, or a single main one, is powered on its own.
plan_form_start <- function(start, id, primary, rule) {
  start <- start %||% list()
  several <- id %in% primary && length(primary) >= 2
  start$claim <- if (several) rule %||% "each" else "one"
  start$n_tests <- if (several && start$claim %in% c("any", "all")) length(primary)
  start
}

# For the maintainer -------------------------------------------------------------

settings_table_ui <- function(tree) {
  tagList(
    h2("Undecided judgement calls and open questions"),
    p("Each is a setting in app/routing/tree.yaml. While its value is empty, the app shows a placeholder where it applies. Set the value to one of the option keys to record a decision; no code changes are needed."),
    div(class = "table-responsive", tabindex = "0", role = "region", `aria-label` = "Undecided settings", tags$table(
      class = "table table-sm",
      tags$caption(class = "visually-hidden", "Undecided settings, their sources, questions, options and current values"),
      tags$thead(tags$tr(tags$th(scope = "col", "Setting"), tags$th(scope = "col", "Source"), tags$th(scope = "col", "Question"), tags$th(scope = "col", "Options (key: label)"), tags$th(scope = "col", "Current value"))),
      tags$tbody(lapply(tree$settings, function(s) tags$tr(
        tags$td(tags$code(s$key)), tags$td(s$ref), tags$td(s$question),
        tags$td(tags$ul(lapply(names(s$options), function(k) tags$li(tags$code(k), ": ", s$options[[k]])))),
        tags$td(if (is_decided(s)) s$value else tags$em("Undecided"))
      )))
    ))
  )
}
