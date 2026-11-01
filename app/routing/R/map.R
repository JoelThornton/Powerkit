# Labs: a map of the methods. Generated from tree.yaml, so it can't drift
# from the design finder. Every question and every analysis is one node of
# a graph; each answer is an edge. Analyses carry tags worked out from the
# paths that reach them (what the study wants to show, the outcome, how
# often people are measured, whether powerkit calculates it), and the page
# filters on them. The page draws the graph with Cytoscape.js (bundled in
# www/vendor, MIT), with a plain list of the same map for screen readers.
# Pure functions build the data; nothing is calculated.

# What a screening answer an automatic node routes on means, in words.
map_branch_text <- list(
  outcome = list(question = "It depends on your outcome",
    values = list(score = "A score or scale", yesno = "Yes/no, or categories", count = "A count", ordinal = "Ordered categories")),
  times = list(question = "It depends on how often each person is measured",
    values = list(once = "Once", twice = "Twice", many_conditions = "In three or more conditions")),
  goal = list(question = "It depends on your goal",
    values = list(detect = "Detect an effect", equivalence = "Show there's no meaningful effect")),
  grouping = list(question = "It depends on how the data are grouped",
    values = list(independent = "Independent people", clusters = "People within groups"))
)

# How each status reads on the map, and its colour class.
map_status <- list(
  runs_validated = list(text = "Calculates in powerkit", key = "runs"),
  runs_validation_in_progress = list(text = "Calculates in powerkit (checks in progress)", key = "runs"),
  coming_soon = list(text = "Coming to powerkit", key = "soon"),
  not_in_powerkit = list(text = "Not in powerkit yet: guidance and other tools", key = "not")
)

# The filters down the side: each group's values and how they read.
map_filters <- list(
  outcome = c(score = "A score or scale", yesno = "Yes/no, or categories", count = "A count", ordinal = "Ordered categories", other = "Not fixed by the questions"),
  times = c(once = "Once", twice = "Twice", many_conditions = "Three or more times", other = "Not fixed by the questions"),
  status = c(runs = "Calculates in powerkit", soon = "Coming", not = "Not in powerkit yet")
)

# What each analysis is, beyond the questions: its test and how it relates
# to others (methods-map.yaml, next to tree.yaml).
map_meta <- function(path = file.path(getOption("powerkit.routing_dir", "."), "methods-map.yaml")) {
  yaml::read_yaml(path)
}

map_screening <- c("s1", "o5a", "s2", "s2_trials", "s3", "t1", "s4", "c1", "d1")
map_elsewhere <- "Designs set by how the data are collected"
map_known_only <- "Chosen by name (in \u201cI know my analysis\u201d)"

# The end points an automatic node leads to, through further automatic
# nodes, named by the answers on the way ("Show there's no meaningful
# effect, people within groups").
automatic_endpoints <- function(tree, id, label = NULL) {
  if (is_endpoint_id(id)) return(stats::setNames(id, label))
  n <- tree$nodes[[id]]
  if (is.null(n) || !is_automatic(n)) return(character())
  words <- map_branch_text[[n$branch_on]]
  unlist(lapply(names(n$routes), function(value) {
    step <- words$values[[value]] %||% value
    automatic_endpoints(tree, n$routes[[value]], if (is.null(label)) step else paste0(label, ", ", tolower(step)))
  }))
}

# The map as a tree of nested lists, for the plain list and the tests:
# list(kind, id, answer, text, children). A question already drawn
# elsewhere is shown once and referred to after ("see").
map_tree <- function(tree) {
  drawn <- new.env()
  node <- function(id, answer) {
    if (is_endpoint_id(id)) {
      ep <- tree$endpoints[[id]]
      return(list(kind = "endpoint", id = id, answer = answer, text = ep$plain_name %||% id,
        status = ep$status %||% "not_in_powerkit"))
    }
    n <- tree$nodes[[id]]
    if (isTRUE(drawn[[id]])) {
      return(list(kind = "see", id = id, answer = answer, text = paste0("See “", map_node_text(n), "” above")))
    }
    drawn[[id]] <- TRUE
    if (is_automatic(n)) {
      words <- map_branch_text[[n$branch_on]]
      kids <- Map(function(value, target) node(target, words$values[[value]] %||% value), names(n$routes), unlist(n$routes))
      return(list(kind = "question", id = id, answer = answer, text = words$question, children = unname(kids)))
    }
    kids <- lapply(n$options, function(o) node(o$`next`, o$label))
    list(kind = "question", id = id, answer = answer, text = n$text, children = kids)
  }
  questions <- node("q1", NULL)
  elsewhere <- lapply(map_screening, function(id) {
    n <- tree$nodes[[id]]
    if (is_automatic(n)) {
      # S4 is answered by the aim and the grouping: list the cards it
      # leads to, through its automatic steps.
      ends <- automatic_endpoints(tree, id)
      if (!length(ends)) return(NULL)
      return(list(kind = "question", id = id, answer = NULL, text = map_node_text(n),
        children = unname(Map(node, ends, names(ends)))))
    }
    opts <- Filter(function(o) is_endpoint_id(o$`next` %||% ""), n$options)
    if (!length(opts)) return(NULL)
    list(kind = "question", id = id, answer = NULL, text = n$text,
      children = lapply(opts, function(o) node(o$`next`, o$label)))
  })
  list(kind = "root", id = "root", text = "Your study", children = list(
    list(kind = "group", id = "group_questions", answer = NULL, text = "What do you want your study to show?",
      children = questions$children),
    list(kind = "group", id = "group_elsewhere", answer = NULL, text = map_elsewhere,
      children = Filter(Negate(is.null), elsewhere))
  ))
}

map_node_text <- function(n) {
  if (is_automatic(n)) map_branch_text[[n$branch_on]]$question else n$text
}

# The graph: one node per question and per analysis (an analysis reached
# by several paths is one node), one edge per answer. Each analysis's tags
# collect the research questions, outcomes and numbers of measurements on
# the paths that reach it; "other" where a path doesn't fix one. Returns
# list(nodes, edges), each a list of records for the page.
map_graph <- function(tree, meta = map_meta()) {
  family_of <- unlist(lapply(tree$analysis_families, function(f) stats::setNames(rep(f$id, length(f$endpoints)), unlist(f$endpoints))))
  family_label <- stats::setNames(vapply(tree$analysis_families, `[[`, "", "label"), vapply(tree$analysis_families, `[[`, "", "id"))
  nodes <- list()
  edges <- list()
  tags <- list()
  add_node <- function(id, kind, label, extra = list()) {
    if (is.null(nodes[[id]])) nodes[[id]] <<- c(list(id = id, kind = kind, label = label), extra)
  }
  add_edge <- function(from, to, label) {
    key <- paste(from, to, label, sep = "|")
    if (is.null(edges[[key]])) {
      edges[[key]] <<- list(id = paste0("e", length(edges) + 1), source = from, target = to, label = label)
    }
  }
  tag <- function(ep, ctx) {
    t <- tags[[ep]] %||% list(rq = character(), outcome = character(), times = character())
    t$rq <- union(t$rq, ctx$rq)
    t$outcome <- union(t$outcome, ctx$outcome %||% "other")
    t$times <- union(t$times, ctx$times %||% "other")
    tags[[ep]] <<- t
  }
  narrow <- function(ctx, when) {
    for (k in c("outcome", "times")) if (!is.null(when[[k]])) ctx[[k]] <- unlist(when[[k]])
    ctx
  }
  endpoint <- function(id) {
    ep <- tree$endpoints[[id]]
    status <- map_status[[ep$status %||% "not_in_powerkit"]]
    test <- meta$endpoints[[id]] %||% "other"
    family <- unname(family_of[id])
    if (is.na(family)) family <- ""
    add_node(id, "endpoint", ep$plain_name %||% id,
      list(status = status$key, statusText = status$text, standard = standard_name(ep$doc_name %||% "")$name,
        test = test, family = family, familyLabel = if (nzchar(family)) family_label[[family]] else ""))
  }
  # Walk the design finder from a node with the context so far; a node
  # already on the current path is not walked again.
  walk <- function(id, ctx, path) {
    if (is_endpoint_id(id)) {
      endpoint(id)
      tag(id, ctx)
      return(invisible())
    }
    if (id %in% path) return(invisible())
    n <- tree$nodes[[id]]
    if (is.null(n)) return(invisible())
    if (is_automatic(n)) {
      words <- map_branch_text[[n$branch_on]]
      add_node(id, "question", words$question)
      for (value in names(n$routes)) {
        target <- n$routes[[value]]
        c2 <- ctx
        c2[[n$branch_on]] <- value
        add_edge(id, target, words$values[[value]] %||% value)
        walk(target, c2, c(path, id))
      }
      return(invisible())
    }
    add_node(id, "question", n$text)
    for (o in n$options) {
      target <- o$`next`
      if (is.null(target) || identical(target, "continue")) next
      add_edge(id, target, o$label)
      walk(target, narrow(apply_sets(ctx, o), o$when), c(path, id))
    }
  }
  # Each answer to the first question is a hub of the map.
  for (i in seq_along(tree$nodes$q1$options)) {
    o <- tree$nodes$q1$options[[i]]
    hub <- paste0("rq", i)
    add_node(hub, "hub", o$label, list(rq = o$label))
    add_edge(hub, o$`next`, "")
    walk(o$`next`, narrow(list(rq = o$label), o$when), "q1")
  }
  add_node("elsewhere", "hub", map_elsewhere, list(rq = map_elsewhere))
  for (id in map_screening) {
    n <- tree$nodes[[id]]
    if (is_automatic(n)) {
      # S4, answered by the aim and the grouping: one edge to each card.
      ends <- automatic_endpoints(tree, id)
      if (!length(ends)) next
      add_node(id, "question", map_node_text(n))
      add_edge("elsewhere", id, "")
      for (i in seq_along(ends)) {
        add_edge(id, ends[[i]], names(ends)[i])
        endpoint(ends[[i]])
        tag(ends[[i]], list(rq = map_elsewhere))
      }
      next
    }
    opts <- Filter(function(o) is_endpoint_id(o$`next` %||% ""), n$options)
    if (!length(opts)) next
    add_node(id, "question", n$text)
    add_edge("elsewhere", id, "")
    for (o in opts) {
      add_edge(id, o$`next`, o$label)
      endpoint(o$`next`)
      tag(o$`next`, narrow(apply_sets(list(rq = map_elsewhere), o), o$when))
    }
  }
  # Analyses the questions don't lead to (they are chosen by name) still
  # sit in their family's region; they have no hub of their own.
  for (f in tree$analysis_families) {
    for (id in unlist(f$endpoints)) {
      if (is.null(nodes[[id]]) && !is.null(tree$endpoints[[id]])) {
        endpoint(id)
        tag(id, list(rq = map_known_only))
      }
    }
  }
  # The families the analyses belong to (tree.yaml, `analysis_families`),
  # as regions of the map, and how the analyses relate.
  on_map <- names(nodes)[vapply(nodes, function(n) identical(n$kind, "endpoint"), logical(1))]
  for (f in tree$analysis_families) {
    if (any(unlist(f$endpoints) %in% on_map)) add_node(paste0("fam_", f$id), "family", f$label, list(family = f$id))
  }
  for (r in meta$relations) {
    if (r$from %in% on_map && r$to %in% on_map) {
      key <- paste("rel", r$from, r$to, sep = "|")
      edges[[key]] <- list(id = paste0("rel-", r$from, "-", r$to), source = r$from, target = r$to, label = r$label, rel = 1)
    }
  }
  nodes <- lapply(nodes, function(n) {
    if (identical(n$kind, "endpoint")) {
      t <- tags[[n$id]]
      n$rq <- as.list(t$rq)
      n$outcome <- as.list(t$outcome)
      n$times <- as.list(t$times)
    }
    n
  })
  tests <- lapply(names(meta$tests), function(k) c(list(id = k), meta$tests[[k]]))
  families <- lapply(tree$analysis_families, function(f) list(id = f$id, label = f$label))
  list(nodes = unname(nodes), edges = unname(edges), tests = tests, families = families)
}

map_json <- function(tree, meta = map_meta()) {
  as.character(jsonlite::toJSON(map_graph(tree, meta), auto_unbox = TRUE))
}

# The same map as nested lists, for screen readers and for reading
# without a mouse; each analysis says its test.
map_list_ui <- function(node, meta = map_meta()) {
  item <- function(k) {
    label <- if (identical(k$kind, "endpoint")) {
      tags$a(href = "#", onclick = sprintf("pkMapOpen('%s'); return false;", k$id), k$text)
    } else k$text
    test <- if (identical(k$kind, "endpoint")) meta$tests[[meta$endpoints[[k$id]] %||% "other"]]$label
    tags$li(
      if (!is.null(k$answer)) tagList(tags$span(class = "text-muted", k$answer), " → "),
      label,
      if (identical(k$kind, "endpoint")) tags$span(class = "small text-muted", paste0(" (", test, "; ", map_status[[k$status]]$text, ")")),
      if (length(k$children)) map_list_ui(k, meta))
  }
  tags$ul(lapply(node$children, item))
}

map_checks <- function(group, values, title, open = FALSE) {
  tags$details(class = "map-filter", open = if (open) NA,
    tags$summary(class = "h6", title),
    lapply(seq_along(values), function(i) {
      id <- paste0("mapf_", group, "_", i)
      div(class = "form-check",
        tags$input(class = "form-check-input", type = "checkbox", id = id, `data-group` = group,
          value = names(values)[i], checked = NA, onchange = "pkMapFilter()"),
        tags$label(class = paste("form-check-label", if (group == "status") paste0("map-key map-", names(values)[i])),
          `for` = id, unname(values[i])))
    }))
}

# The map opens full screen (1 November 2026): a dark view of the methods
# from far away, with the families of analyses as glowing regions; zooming
# in brings out the analyses, coloured by their test, family or status,
# and the lines between related tests. Search and clicks fly to an
# analysis; its panel says what it does, its test and its relatives.
map_ui <- function(tree, meta = map_meta()) {
  map <- map_tree(tree)
  rq <- vapply(tree$nodes$q1$options, `[[`, "", "label")
  rq <- c(rq, map_elsewhere, map_known_only)
  rq <- stats::setNames(rq, rq)
  tests <- stats::setNames(vapply(meta$tests, `[[`, "", "label"), names(meta$tests))
  used <- unique(unlist(meta$endpoints))
  tests <- tests[names(tests) %in% used]
  tagList(
    tags$script(src = "vendor/cytoscape.min.js"),
    tags$script(src = "vendor/dagre.min.js"),
    tags$script(src = "vendor/cytoscape-dagre.js"),
    tags$script(id = "map-data", type = "application/json", HTML(map_json(tree, meta))),
    tags$script(src = "methods-map.js"),
    h3("Methods map"),
    p("Every analysis powerkit knows about, as a map: the families of analyses are regions, and each analysis is a light within its family, coloured by the test it uses. Lines join tests that are related. Scroll or pinch to zoom, drag to move, search or filter, and click an analysis to read about it."),
    tags$button(type = "button", class = "btn btn-primary mb-3", onclick = "pkMapFull(true)", "Open the map full screen"),
    div(class = "map-stage", id = "map-stage", role = "region", `aria-label` = "Methods map",
      div(id = "map-canvas", class = "map-canvas", role = "img",
        `aria-label` = "A map of powerkit's analyses, grouped into families and joined to related tests. The same map is available as a list below it."),
      div(class = "map-nebula", `aria-hidden` = "true"),
      div(class = "map-hud",
        tags$button(type = "button", class = "map-hud-btn map-panel-toggle", onclick = "pkMapPanel()", `aria-controls` = "map-sidebar",
          `aria-expanded` = "true", "Filters"),
        div(class = "map-title", tags$span(class = "map-title-name", "Methods map"), tags$span(class = "map-count", id = "map-count", `aria-live` = "polite")),
        div(class = "map-search",
          tags$label(`for` = "map_search", class = "visually-hidden", "Search the map"),
          tags$input(id = "map_search", type = "search", class = "form-control",
            placeholder = "Search: mediation, paired, chi-square ...", oninput = "pkMapFilter()",
            onkeydown = "if (event.key === 'Enter') { event.preventDefault(); pkMapFirstHit(); }")),
        tags$button(type = "button", class = "map-hud-btn map-full-btn", id = "map-full-btn", onclick = "pkMapFull()", "Full screen")),
      div(class = "map-sidebar", id = "map-sidebar",
        tags$label(`for` = "map_layout", class = "h6", "View"),
        tags$select(id = "map_layout", class = "form-select form-select-sm", onchange = "pkMapFilter()",
          tags$option(value = "earth", "Families: analyses by what they are"),
          tags$option(value = "cosmos", "Aims: analyses around what they show"),
          tags$option(value = "tree", "Questions: every route, left to right")),
        tags$label(`for` = "map_colour", class = "h6", "Colour by"),
        tags$select(id = "map_colour", class = "form-select form-select-sm", onchange = "pkMapColour()",
          tags$option(value = "test", "The test (t, F, chi-square, z ...)"),
          tags$option(value = "family", "The family"),
          tags$option(value = "status", "Whether powerkit calculates it")),
        div(class = "form-check form-switch map-switch",
          tags$input(class = "form-check-input", type = "checkbox", role = "switch", id = "map_relations", onchange = "pkMapFilter()"),
          tags$label(class = "form-check-label", `for` = "map_relations", "Show every connection")),
        tags$label(`for` = "map_names", class = "h6", "Names"),
        tags$select(id = "map_names", class = "form-select form-select-sm", onchange = "pkMapNames()",
          tags$option(value = "plain", "In plain words"),
          tags$option(value = "standard", "The tests' usual names")),
        map_checks("test", tests, "The test"),
        map_checks("rq", rq, "What the study wants to show"),
        map_checks("outcome", map_filters$outcome, "The outcome"),
        map_checks("times", map_filters$times, "How often each person is measured"),
        map_checks("status", map_filters$status, "In powerkit"),
        div(class = "nav-buttons mt-2",
          tags$button(type = "button", class = "btn btn-light btn-sm", onclick = "pkMapFit()", "See everything"),
          tags$button(type = "button", class = "btn btn-link btn-sm map-clear", onclick = "pkMapReset()", "Clear filters"))),
      div(id = "map-legend", class = "map-legend", `aria-label` = "Colour key"),
      div(class = "map-zoom",
        tags$button(type = "button", class = "map-hud-btn", onclick = "pkMapZoom(1.5)", `aria-label` = "Zoom in", "+"),
        tags$button(type = "button", class = "map-hud-btn", onclick = "pkMapZoom(1 / 1.5)", `aria-label` = "Zoom out", "−"),
        tags$button(type = "button", class = "map-hud-btn", onclick = "pkMapFit()", `aria-label` = "See everything", "⌂")),
      div(class = "map-hint", id = "map-hint", "Scroll to zoom in. Click a family to fly into it, or an analysis to read about it."),
      div(id = "map-details", class = "map-details", hidden = NA)),
    uiOutput("map_page"),
    tags$details(class = "map-as-list",
      tags$summary("The map as a list"),
      map_list_ui(map, meta))
  )
}

# The page for an analysis on the map: its card, as the design finder shows
# it.
map_page_ui <- function(tree, ep_id) {
  if (is.null(ep_id) || !nzchar(ep_id) || is.null(tree$endpoints[[ep_id]])) return(NULL)
  div(class = "map-page", id = "map-page", tabindex = "-1",
    card_ui(tree, ep_id, compact = TRUE),
    p(class = "small", "To plan this analysis, go to “Plan a power analysis” and choose “I know my analysis”, or answer the questions under “Help me choose”."))
}

map_css <- "
  .map-stage { position: relative; height: 82vh; min-height: 540px; border-radius: 18px; overflow: hidden; color: #e8eefc;
               background: radial-gradient(ellipse at 50% 120%, #1b3a6b 0%, #0c1838 38%, #050817 75%, #02030a 100%);
               box-shadow: 0 20px 60px rgba(5, 10, 30, 0.35); }
  .map-stage.map-full { position: fixed; inset: 0; height: 100vh; height: 100dvh; min-height: 0; border-radius: 0; z-index: 2000; }
  body.map-full-open { overflow: hidden; }
  .map-canvas { position: absolute; inset: 0; z-index: 1;
    background-image:
      radial-gradient(1.2px 1.2px at 20px 30px, #ffffffcc, transparent), radial-gradient(1px 1px at 120px 80px, #ffffff99, transparent),
      radial-gradient(1.5px 1.5px at 200px 160px, #cfe3ffcc, transparent), radial-gradient(1px 1px at 60px 190px, #ffffff88, transparent),
      radial-gradient(1px 1px at 260px 40px, #ffe9c499, transparent), radial-gradient(1.3px 1.3px at 160px 240px, #ffffffaa, transparent),
      radial-gradient(1px 1px at 300px 220px, #ffffff77, transparent), radial-gradient(2px 2px at 90px 120px, #9fc3ff66, transparent);
    background-size: 320px 280px; }
  .map-nebula { position: absolute; inset: -10%; z-index: 0; pointer-events: none; opacity: 0.9;
    background: radial-gradient(40% 30% at 20% 25%, rgba(92, 120, 255, 0.18), transparent 70%),
                radial-gradient(35% 28% at 80% 30%, rgba(255, 126, 182, 0.12), transparent 70%),
                radial-gradient(45% 35% at 60% 85%, rgba(79, 224, 182, 0.10), transparent 70%);
    animation: pk-nebula 40s ease-in-out infinite alternate; }
  @keyframes pk-nebula { from { transform: translate3d(0, 0, 0) scale(1); } to { transform: translate3d(-3%, 2%, 0) scale(1.06); } }
  @media (prefers-reduced-motion: reduce) { .map-nebula { animation: none; } }
  .map-hud { position: absolute; top: 0; left: 0; right: 0; z-index: 4; display: flex; align-items: center; gap: 0.75rem; padding: 0.7rem 0.9rem;
             background: linear-gradient(180deg, rgba(3, 6, 20, 0.75), rgba(3, 6, 20, 0)); pointer-events: none; }
  .map-hud > * { pointer-events: auto; }
  .map-search { flex: 0 1 26rem; position: relative; }
  .map-search .form-control { background: rgba(14, 22, 54, 0.85); color: #fff; border: 1px solid rgba(160, 190, 255, 0.35); border-radius: 999px;
                              padding-left: 1rem; min-height: 38px; backdrop-filter: blur(6px); }
  .map-search .form-control::placeholder { color: #a9b6d8; }
  .map-search .form-control:focus { border-color: #9fd4ff; box-shadow: 0 0 0 0.2rem rgba(92, 200, 255, 0.25); }
  .map-title { flex: 1 1 auto; display: flex; align-items: baseline; gap: 0.75rem; min-width: 0; }
  .map-title-name { font-weight: 700; letter-spacing: 0.18em; text-transform: uppercase; font-size: 0.85rem; color: #fff; }
  .map-count { font-size: 0.8rem; color: #a9b6d8; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  .map-hud-btn { border: 1px solid rgba(160, 190, 255, 0.35); background: rgba(14, 22, 54, 0.8); color: #fff; border-radius: 999px;
                 padding: 0.3rem 0.9rem; font-size: 0.85rem; min-height: 36px; min-width: 36px; backdrop-filter: blur(6px); }
  .map-hud-btn:hover, .map-hud-btn:focus { background: rgba(40, 60, 130, 0.95); border-color: #9fd4ff; }
  .map-sidebar { position: absolute; top: 3.6rem; left: 0.75rem; bottom: 0.75rem; width: 17.5rem; overflow-y: auto; padding: 0.4rem 1rem 0.9rem 1rem; z-index: 3;
                 background: rgba(8, 13, 34, 0.74); backdrop-filter: blur(10px); border: 1px solid rgba(160, 190, 255, 0.18);
                 border-radius: 14px; color: #dfe7ff; }
  .map-sidebar.closed { display: none; }
  .map-sidebar .h6 { display: block; font-weight: 650; color: #ffffff; margin: 0.8rem 0 0.35rem 0; font-size: 0.82rem; letter-spacing: 0.02em; }
  .map-sidebar .form-control, .map-sidebar .form-select { background-color: rgba(255, 255, 255, 0.08); color: #fff; border-color: rgba(160, 190, 255, 0.3); }
  .map-sidebar .form-control::placeholder { color: #a9b6d8; }
  .map-sidebar .form-select option { color: #000; }
  .map-switch { margin: 0.8rem 0 0 0; display: flex; align-items: center; gap: 0.5rem; padding-left: 2.5em; }
  .map-switch .form-check-label { font-size: 0.85rem; color: #fff; font-weight: 600; }
  .map-switch .form-check-input:checked { background-color: #5cc8ff; border-color: #5cc8ff; }
  .map-filter { margin: 0; }
  .map-filter > summary { cursor: pointer; display: list-item; }
  .map-filter[open] > summary { margin-bottom: 0.3rem; }
  .map-filter .form-check { display: flex; gap: 0.45rem; align-items: flex-start; padding-left: 0; margin-bottom: 0.2rem; }
  .map-filter .form-check-input { float: none; flex: none; margin: 0.2rem 0 0 0; background-color: rgba(255, 255, 255, 0.12); border-color: rgba(200, 215, 255, 0.5); }
  .map-filter .form-check-input:checked { background-color: #5cc8ff; border-color: #5cc8ff; }
  .map-filter .form-check-label { font-size: 0.82rem; line-height: 1.3; color: #dfe7ff; }
  .map-clear { color: #9fd4ff; }
  .map-legend { position: absolute; left: 50%; transform: translateX(-50%); bottom: 0.9rem; z-index: 3; display: flex; flex-wrap: wrap; justify-content: center;
                gap: 0.35rem 0.5rem; max-width: min(56rem, calc(100% - 9rem)); padding: 0.4rem 0.7rem; border-radius: 14px;
                background: rgba(8, 13, 34, 0.7); backdrop-filter: blur(8px); border: 1px solid rgba(160, 190, 255, 0.16); }
  .map-legend button { border: 0; background: transparent; color: #dfe7ff; font-size: 0.78rem; padding: 0.15rem 0.35rem; border-radius: 999px; display: inline-flex; align-items: center; gap: 0.35rem; }
  .map-legend button:hover, .map-legend button:focus { background: rgba(255, 255, 255, 0.1); }
  .map-legend button[aria-pressed='false'] { opacity: 0.4; text-decoration: line-through; }
  .map-legend .dot { width: 0.7rem; height: 0.7rem; border-radius: 50%; flex: none; }
  .map-zoom { position: absolute; right: 0.9rem; bottom: 0.9rem; z-index: 3; display: flex; flex-direction: column; gap: 0.35rem; }
  .map-zoom .map-hud-btn { padding: 0; width: 40px; height: 40px; font-size: 1.1rem; line-height: 1; }
  .map-hint { position: absolute; left: 50%; top: 3.8rem; transform: translateX(-50%); z-index: 2; font-size: 0.82rem; color: #cdd7f3;
              background: rgba(8, 13, 34, 0.6); border-radius: 999px; padding: 0.3rem 0.9rem; pointer-events: none; transition: opacity 0.6s ease; white-space: nowrap; }
  .map-hint.gone { opacity: 0; }
  .map-details { position: absolute; top: 3.6rem; right: 0.75rem; width: 22rem; max-width: calc(100% - 1.5rem); max-height: calc(100% - 4.4rem); overflow-y: auto; z-index: 5;
                 background: rgba(8, 13, 34, 0.86); backdrop-filter: blur(10px); color: #e8eefc; border: 1px solid rgba(160, 190, 255, 0.25);
                 border-radius: 16px; box-shadow: 0 10px 40px rgba(0, 0, 0, 0.45); padding: 1rem 1.1rem; }
  .map-details h4 { font-size: 1.1rem; color: #fff; margin: 0 1.5rem 0.4rem 0; }
  .map-details h5 { font-size: 0.8rem; text-transform: uppercase; letter-spacing: 0.08em; color: #a9b6d8; margin: 0.9rem 0 0.35rem 0; }
  .map-details .map-close { position: absolute; top: 0.4rem; right: 0.6rem; border: 0; background: none; color: #fff; font-size: 1.4rem; line-height: 1; min-width: 36px; min-height: 36px; }
  .map-details ol, .map-details ul { padding-left: 1.1rem; font-size: 0.85rem; }
  .map-details p { color: #cdd7f3; }
  .map-details .map-test { border-left: 3px solid var(--test, #5cc8ff); padding: 0.35rem 0.6rem; background: rgba(255, 255, 255, 0.05); border-radius: 0 8px 8px 0; font-size: 0.85rem; }
  .map-rel { list-style: none; padding-left: 0 !important; }
  .map-rel li { margin-bottom: 0.3rem; }
  .map-rel button { border: 0; background: none; color: #9fd4ff; padding: 0; text-align: left; text-decoration: underline; font-size: 0.85rem; }
  .map-rel .map-rel-text { color: #a9b6d8; }
  .map-tag { display: inline-block; border-radius: 1rem; padding: 0.05rem 0.6rem; font-size: 0.75rem; font-weight: 600; margin: 0 0.3rem 0.5rem 0; }
  .map-tag.runs { background: rgba(92, 200, 255, 0.18); color: #8fdcff; }
  .map-tag.soon { background: rgba(255, 179, 71, 0.2); color: #ffc978; }
  .map-tag.not { background: rgba(170, 180, 210, 0.18); color: #c3cbe2; }
  .map-tag.fam { background: rgba(255, 255, 255, 0.1); color: #fff; }
  .map-key::before { content: ''; display: inline-block; width: 0.8em; height: 0.8em; border-radius: 50%; margin-right: 0.35em; vertical-align: -0.05em; }
  .map-key.map-runs::before { background: #5cc8ff; box-shadow: 0 0 6px #5cc8ff; }
  .map-key.map-soon::before { background: #ffb347; box-shadow: 0 0 6px #ffb347; }
  .map-key.map-not::before { background: #9aa7c7; }
  .map-page { margin-top: 1rem; }
  .map-as-list { margin-top: 1rem; }
  @media (max-width: 800px) {
    .map-sidebar { width: calc(100% - 1.5rem); bottom: auto; max-height: 60%; }
    .map-legend { max-width: calc(100% - 5rem); left: 0.75rem; transform: none; justify-content: flex-start; }
    .map-hint { display: none; }
    .map-count { display: none; }
    .map-title-name { display: none; }
    .map-search { flex: 1 1 auto; }
  }
"

# The page side is www/methods-map.js (lays out the map, filters it, flies
# about and shows an analysis's details); nothing goes in the page head.
map_js <- ""
