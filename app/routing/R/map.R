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

map_screening <- c("s1", "o5a", "s2", "s2_trials", "s3", "t1", "s4")
map_elsewhere <- "Designs set by how the data are collected"

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
map_graph <- function(tree) {
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
    add_node(id, "endpoint", ep$plain_name %||% id,
      list(status = status$key, statusText = status$text, standard = ep$doc_name %||% ""))
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
  nodes <- lapply(nodes, function(n) {
    if (identical(n$kind, "endpoint")) {
      t <- tags[[n$id]]
      n$rq <- as.list(t$rq)
      n$outcome <- as.list(t$outcome)
      n$times <- as.list(t$times)
    }
    n
  })
  list(nodes = unname(nodes), edges = unname(edges))
}

map_json <- function(tree) {
  as.character(jsonlite::toJSON(map_graph(tree), auto_unbox = TRUE))
}

# The same map as nested lists, for screen readers and for reading
# without a mouse.
map_list_ui <- function(node) {
  item <- function(k) {
    label <- if (identical(k$kind, "endpoint")) {
      tags$a(href = "#", onclick = sprintf("pkMapOpen('%s'); return false;", k$id), k$text)
    } else k$text
    tags$li(
      if (!is.null(k$answer)) tagList(tags$span(class = "text-muted", k$answer), " → "),
      label,
      if (identical(k$kind, "endpoint")) tags$span(class = "small text-muted", paste0(" (", map_status[[k$status]]$text, ")")),
      if (length(k$children)) map_list_ui(k))
  }
  tags$ul(lapply(node$children, item))
}

map_checks <- function(group, values, title) {
  tags$details(class = "map-filter",
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

map_ui <- function(tree) {
  map <- map_tree(tree)
  rq <- vapply(tree$nodes$q1$options, `[[`, "", "label")
  rq <- stats::setNames(c(rq, map_elsewhere), c(rq, map_elsewhere))
  tagList(
    tags$script(src = "vendor/cytoscape.min.js"),
    tags$script(src = "vendor/dagre.min.js"),
    tags$script(src = "vendor/cytoscape-dagre.js"),
    tags$script(id = "map-data", type = "application/json", HTML(map_json(tree))),
    h3("Methods map"),
    p("Every analysis powerkit knows about, drawn from the same questions as “Help me choose”. Each thing a study can want to show is a star; its analyses are the planets around it. Drag to fly about, scroll to zoom, search or filter on the left, and click a planet to read about it."),
    div(class = "map-stage",
      div(id = "map-canvas", class = "map-canvas", role = "img",
        `aria-label` = "A map of powerkit's analyses, grouped around what a study wants to show. The same map is available as a list below it."),
      tags$button(type = "button", class = "map-panel-toggle", onclick = "pkMapPanel()", `aria-controls` = "map-sidebar",
        `aria-expanded` = "true", "Filters"),
      div(class = "map-sidebar", id = "map-sidebar",
        tags$label(`for` = "map_search", class = "h6", "Search"),
        tags$input(id = "map_search", type = "search", class = "form-control form-control-sm",
          placeholder = "e.g. mediation, paired, proportion", oninput = "pkMapFilter()"),
        tags$label(`for` = "map_layout", class = "h6", "View"),
        tags$select(id = "map_layout", class = "form-select form-select-sm", onchange = "pkMapFilter()",
          tags$option(value = "cosmos", "The cosmos: analyses around what they show"),
          tags$option(value = "tree", "The questions: every route, left to right")),
        tags$label(`for` = "map_names", class = "h6", "Names"),
        tags$select(id = "map_names", class = "form-select form-select-sm", onchange = "pkMapNames()",
          tags$option(value = "plain", "In plain words"),
          tags$option(value = "standard", "The tests' usual names")),
        map_checks("rq", rq, "What the study wants to show"),
        map_checks("outcome", map_filters$outcome, "The outcome"),
        map_checks("times", map_filters$times, "How often each person is measured"),
        map_checks("status", map_filters$status, "In powerkit"),
        div(class = "nav-buttons mt-2",
          tags$button(type = "button", class = "btn btn-light btn-sm", onclick = "pkMapFit()", "See everything"),
          tags$button(type = "button", class = "btn btn-link btn-sm map-clear", onclick = "pkMapReset()", "Clear filters")),
        p(class = "small map-count", id = "map-count", `aria-live` = "polite")),
      div(id = "map-details", class = "map-details", hidden = NA)),
    uiOutput("map_page"),
    tags$details(class = "map-as-list",
      tags$summary("The map as a list"),
      map_list_ui(map))
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
  .map-stage { position: relative; height: 88vh; min-height: 520px; border-radius: 16px; overflow: hidden;
               background: radial-gradient(ellipse at 30% 20%, #23336b 0%, #0f1736 45%, #070b1f 100%); }
  .map-canvas { position: absolute; inset: 0;
    background-image:
      radial-gradient(1.2px 1.2px at 20px 30px, #ffffffcc, transparent), radial-gradient(1px 1px at 120px 80px, #ffffff99, transparent),
      radial-gradient(1.5px 1.5px at 200px 160px, #cfe3ffcc, transparent), radial-gradient(1px 1px at 60px 190px, #ffffff88, transparent),
      radial-gradient(1px 1px at 260px 40px, #ffe9c499, transparent), radial-gradient(1.3px 1.3px at 160px 240px, #ffffffaa, transparent),
      radial-gradient(1px 1px at 300px 220px, #ffffff77, transparent), radial-gradient(2px 2px at 90px 120px, #9fc3ff66, transparent);
    background-size: 320px 280px; }
  .map-sidebar { position: absolute; top: 0.75rem; left: 0.75rem; max-height: calc(100% - 1.5rem); width: 17.5rem; overflow-y: auto; padding: 2.4rem 1rem 0.9rem 1rem;
                 background: rgba(10, 16, 40, 0.72); backdrop-filter: blur(8px); border: 1px solid rgba(160, 190, 255, 0.18);
                 border-radius: 14px; color: #dfe7ff; }
  .map-sidebar.closed { display: none; }
  .map-panel-toggle { position: absolute; top: 1.1rem; left: 1.1rem; z-index: 3; border: 1px solid rgba(160, 190, 255, 0.35);
                      background: rgba(20, 30, 70, 0.85); color: #fff; border-radius: 999px; padding: 0.15rem 0.8rem; font-size: 0.8rem; }
  .map-sidebar .h6 { display: block; font-weight: 650; color: #ffffff; margin: 0.8rem 0 0.35rem 0; font-size: 0.82rem; letter-spacing: 0.02em; }
  .map-sidebar .form-control, .map-sidebar .form-select { background-color: rgba(255, 255, 255, 0.08); color: #fff; border-color: rgba(160, 190, 255, 0.3); }
  .map-sidebar .form-control::placeholder { color: #a9b6d8; }
  .map-sidebar .form-select option { color: #000; }
  .map-filter { margin: 0; }
  .map-filter > summary { cursor: pointer; display: list-item; }
  .map-filter[open] > summary { margin-bottom: 0.3rem; }
  .map-filter .form-check { display: flex; gap: 0.45rem; align-items: flex-start; padding-left: 0; margin-bottom: 0.2rem; }
  .map-filter .form-check-input { float: none; flex: none; margin: 0.2rem 0 0 0; background-color: rgba(255, 255, 255, 0.12); border-color: rgba(200, 215, 255, 0.5); }
  .map-filter .form-check-input:checked { background-color: #5cc8ff; border-color: #5cc8ff; }
  .map-filter .form-check-label { font-size: 0.82rem; line-height: 1.3; color: #dfe7ff; }
  .map-count { color: #a9b6d8; margin-top: 0.5rem; }
  .map-clear { color: #9fd4ff; }
  .map-details { position: absolute; top: 0.75rem; right: 0.75rem; width: 20rem; max-width: calc(100% - 1.5rem); max-height: calc(100% - 1.5rem); overflow-y: auto;
                 background: rgba(10, 16, 40, 0.82); backdrop-filter: blur(8px); color: #e8eefc; border: 1px solid rgba(160, 190, 255, 0.25);
                 border-radius: 14px; box-shadow: 0 10px 40px rgba(0, 0, 0, 0.45); padding: 1rem 1.1rem; }
  .map-details h4 { font-size: 1.05rem; color: #fff; margin: 0 1.5rem 0.4rem 0; }
  .map-details .map-close { position: absolute; top: 0.4rem; right: 0.6rem; border: 0; background: none; color: #fff; font-size: 1.3rem; line-height: 1; }
  .map-details ol { padding-left: 1.1rem; font-size: 0.85rem; }
  .map-details p { color: #cdd7f3; }
  .map-badge { display: inline-block; border-radius: 1rem; padding: 0.05rem 0.6rem; font-size: 0.75rem; font-weight: 600; margin-bottom: 0.5rem; }
  .map-badge.runs { background: rgba(92, 200, 255, 0.18); color: #8fdcff; }
  .map-badge.soon { background: rgba(255, 179, 71, 0.2); color: #ffc978; }
  .map-badge.not { background: rgba(170, 180, 210, 0.18); color: #c3cbe2; }
  .map-key::before { content: ''; display: inline-block; width: 0.8em; height: 0.8em; border-radius: 50%; margin-right: 0.35em; vertical-align: -0.05em; }
  .map-key.map-runs::before { background: #5cc8ff; box-shadow: 0 0 6px #5cc8ff; }
  .map-key.map-soon::before { background: #ffb347; box-shadow: 0 0 6px #ffb347; }
  .map-key.map-not::before { background: #9aa7c7; }
  .map-page { margin-top: 1rem; }
  .map-as-list { margin-top: 1rem; }
  @media (max-width: 800px) { .map-sidebar { width: calc(100% - 1.5rem); } }
"

# The page side: lays out the cosmos (or the tree of questions), filters
# it and shows a planet's details.
map_js <- "
  (function() {
    var cy = null, data = null, started = false, running = null;
    var hues = ['#7c9cff', '#ff7eb6', '#4fe0b6', '#ffd166', '#c792ea', '#5cc8ff', '#ff9f68', '#9be15d', '#f78fb3', '#b0c4de'];
    var glow = { runs: '#5cc8ff', soon: '#ffb347', not: '#9aa7c7' };
    function load() {
      if (data) return data;
      var d = document.getElementById('map-data'); if (!d) return null;
      data = JSON.parse(d.textContent); return data;
    }
    function elements() {
      var d = load(), els = [], hubs = {}, h = 0;
      els.push({ data: { id: 'root', label: 'Your study', kind: 'root' } });
      d.nodes.forEach(function(n) {
        var x = Object.assign({}, n);
        if (n.kind === 'hub') { x.hue = hues[h++ % hues.length]; hubs[n.rq] = n.id; }
        if (n.kind === 'endpoint') { x.glow = glow[n.status]; x.plain = n.label; }
        els.push({ data: x });
        if (n.kind === 'hub') els.push({ data: { id: 'root-' + n.id, source: 'root', target: n.id, label: '' } });
      });
      d.edges.forEach(function(e) { els.push({ data: Object.assign({}, e) }); });
      // In the cosmos each analysis is joined straight to what it shows.
      d.nodes.forEach(function(n) {
        if (n.kind !== 'endpoint') return;
        n.rq.forEach(function(rq) {
          if (hubs[rq]) els.push({ data: { id: 'short-' + n.id + '-' + hubs[rq], source: hubs[rq], target: n.id, label: '', shortcut: 1 } });
        });
      });
      return els;
    }
    function style() {
      return [
        { selector: 'node', style: { 'label': 'data(label)', 'text-wrap': 'wrap', 'text-max-width': 170, 'font-size': 13,
            'font-family': 'Inter, system-ui, sans-serif', 'color': '#e8eefc', 'text-outline-color': '#0a1030', 'text-outline-width': 2,
            'text-valign': 'bottom', 'text-margin-y': 7, 'min-zoomed-font-size': 6, 'z-index': 10 } },
        { selector: 'node[kind = \"endpoint\"]', style: { 'width': 26, 'height': 26, 'background-color': 'data(glow)',
            'underlay-color': 'data(glow)', 'underlay-opacity': 0.28, 'underlay-padding': 9, 'underlay-shape': 'ellipse',
            'border-width': 2, 'border-color': '#ffffff', 'border-opacity': 0.55 } },
        { selector: 'node[status = \"runs\"]', style: { 'width': 32, 'height': 32 } },
        { selector: 'node[kind = \"hub\"]', style: { 'width': 96, 'height': 96, 'background-color': 'data(hue)',
            'border-width': 6, 'border-color': '#ffffff', 'border-opacity': 0.35,
            'underlay-color': 'data(hue)', 'underlay-opacity': 0.35, 'underlay-padding': 26, 'underlay-shape': 'ellipse',
            'font-size': 24, 'font-weight': 700, 'text-max-width': 300, 'text-margin-y': 14, 'color': '#ffffff', 'text-outline-width': 3,
            'min-zoomed-font-size': 0 } },
        { selector: 'node[kind = \"root\"]', style: { 'shape': 'round-rectangle', 'width': 'label', 'height': 'label', 'padding': 12,
            'background-color': '#14284B', 'text-valign': 'center', 'text-margin-y': 0, 'font-weight': 700 } },
        { selector: 'node[kind = \"question\"]', style: { 'shape': 'round-rectangle', 'width': 'label', 'height': 'label', 'padding': 9,
            'background-color': '#16224d', 'border-width': 1, 'border-color': '#6f86c9', 'text-valign': 'center', 'text-margin-y': 0,
            'font-size': 12, 'text-outline-width': 0, 'color': '#dfe7ff' } },
        { selector: 'node[kind = \"orbit\"]', style: { 'shape': 'ellipse', 'width': 'data(size)', 'height': 'data(size)',
            'background-opacity': 0, 'border-width': 1.2, 'border-color': 'data(hue)', 'border-opacity': 0.22, 'border-style': 'dashed',
            'label': '', 'events': 'no', 'z-index': 0 } },
        { selector: 'edge', style: { 'width': 1, 'line-color': '#8ea6e8', 'opacity': 0.35, 'curve-style': 'bezier',
            'target-arrow-shape': 'triangle', 'target-arrow-color': '#8ea6e8', 'arrow-scale': 0.6, 'z-index': 1 } },
        { selector: 'edge[shortcut]', style: { 'target-arrow-shape': 'none', 'opacity': 0.12, 'width': 1, 'curve-style': 'straight' } },
        { selector: 'edge.far', style: { 'line-style': 'dashed', 'opacity': 0.08 } },
        { selector: '.dim', style: { 'opacity': 0.12 } },
        { selector: 'node.hover', style: { 'font-size': 17, 'z-index': 30, 'min-zoomed-font-size': 0 } },
        { selector: 'node.hit, node:selected', style: { 'border-color': '#ffe08a', 'border-width': 4, 'border-opacity': 1,
            'underlay-opacity': 0.6, 'min-zoomed-font-size': 0, 'z-index': 30 } },
        { selector: 'edge.path', style: { 'line-color': '#ffe08a', 'target-arrow-color': '#ffe08a', 'opacity': 0.9, 'width': 3 } }
      ];
    }
    function view() { return (document.getElementById('map_layout') || {}).value || 'cosmos'; }
    function checked(group) {
      return Array.prototype.map.call(document.querySelectorAll('.map-sidebar input[data-group=\"' + group + '\"]:checked'),
        function(i) { return i.value; });
    }
    // The cosmos: each star's analyses on rings around it, far enough
    // apart that no two labels meet, and the stars spread on a wide
    // circle with room between their systems.
    var R0 = 250, GAP = 150, STEP = 230;
    function cosmos() {
      cy.remove('node[kind = \"orbit\"]');
      var hubs = cy.nodes('[kind = \"hub\"]').filter(function(h) { return h.style('display') !== 'none'; });
      var placed = {}, systems = [];
      hubs.forEach(function(h) {
        var planets = h.outgoers('edge[shortcut]').targets().filter(function(n) { return n.style('display') !== 'none' && !placed[n.id()]; });
        planets.forEach(function(n) { placed[n.id()] = h.id(); });
        var rings = [], left = planets.length, r = R0;
        while (left > 0) { var cap = Math.max(5, Math.floor(2 * Math.PI * r / STEP)); rings.push({ r: r, k: Math.min(cap, left) }); left -= cap; r += GAP; }
        var outer = rings.length ? rings[rings.length - 1].r : R0;
        systems.push({ hub: h, planets: planets, rings: rings, size: outer + 420 });
      });
      var total = systems.reduce(function(a, s) { return a + 2 * s.size; }, 0);
      var R = systems.length > 1 ? total / (2 * Math.PI) : 0, at = 0;
      var pos = {};
      systems.forEach(function(s, i) {
        var angle = systems.length > 1 ? (at + s.size) / R : 0;
        at += 2 * s.size;
        var cx = R * Math.cos(angle), cy0 = R * Math.sin(angle);
        pos[s.hub.id()] = { x: cx, y: cy0 };
        var j = 0, offset = i * 0.7;
        s.rings.forEach(function(ring, k) {
          cy.add({ group: 'nodes', data: { id: 'orbit-' + s.hub.id() + '-' + k, kind: 'orbit', size: 2 * ring.r, hue: s.hub.data('hue') },
            position: { x: cx, y: cy0 } });
          for (var m = 0; m < ring.k; m++) {
            var a = offset + k * 0.4 + 2 * Math.PI * m / ring.k;
            pos[s.planets[j].id()] = { x: cx + ring.r * Math.cos(a), y: cy0 + ring.r * Math.sin(a) };
            j++;
          }
        });
      });
      cy.edges('[shortcut]').forEach(function(e) { e.toggleClass('far', placed[e.target().id()] !== e.source().id()); });
      cy.nodes('[kind = \"orbit\"]').lock();
      var shown = cy.nodes().filter(function(n) { return pos[n.id()]; });
      if (running) running.stop();
      running = shown.layout({ name: 'preset', positions: function(n) { return pos[n.id()]; }, animate: true, animationDuration: 700,
        fit: false });
      running.one('layoutstop', focus);
      running.run();
    }
    function tree() {
      cy.remove('node[kind = \"orbit\"]');
      if (running) running.stop();
      running = cy.elements(':visible').layout({ name: 'dagre', rankDir: 'LR', nodeSep: 18, rankSep: 140, animate: true,
        animationDuration: 600, fit: false });
      running.one('layoutstop', focus);
      running.run();
    }
    // After a layout: fly to the search matches, or show everything.
    function focus() {
      var hits = cy.nodes('.hit');
      if (hits.length) fitTo(hits, 1.1);
      else pkMapFit();
    }
    // Fit some nodes into the part of the map the filters panel leaves
    // free.
    function fitTo(eles, zoomCap) {
      var side = document.getElementById('map-sidebar');
      var left = side && !side.classList.contains('closed') ? side.offsetWidth + 24 : 0;
      var w = cy.width() - left - 160, h = cy.height() - 160, bb = eles.boundingBox({ includeLabels: false, includeUnderlays: false });
      var z = Math.min(w / Math.max(bb.w, 1), h / Math.max(bb.h, 1), zoomCap || 1.2);
      z = Math.max(z, cy.minZoom());
      cy.animate({ zoom: z, pan: { x: left + 80 + w / 2 - z * (bb.x1 + bb.w / 2), y: 70 + h / 2 - z * (bb.y1 + bb.h / 2) } }, { duration: 650 });
    }
    window.pkMapFit = function() {
      if (!cy) return;
      fitTo(cy.nodes(':visible').not('[kind = \"orbit\"]'));
    };
    // Star names stay readable from far away.
    function scaleNames() {
      var z = cy.zoom();
      var f = Math.min(90, Math.max(24, 15 / z));
      cy.nodes('[kind = \"hub\"]').style({ 'font-size': f, 'text-max-width': 12 * f });
    }
    function overlaps(a, b) { return a.some(function(x) { return b.indexOf(x) >= 0; }); }
    // An analysis shows when it matches every filter. In the cosmos the
    // questions are hidden; in the tree a question shows when an analysis
    // it leads to shows.
    window.pkMapFilter = function() {
      if (!cy) return;
      var rq = checked('rq'), outcome = checked('outcome'), times = checked('times'), status = checked('status');
      var q = ((document.getElementById('map_search') || {}).value || '').trim().toLowerCase();
      var isTree = view() === 'tree';
      var shown = cy.collection();
      cy.batch(function() {
        cy.elements().removeClass('dim hit path');
        cy.nodes('[kind = \"endpoint\"]').forEach(function(n) {
          var d = n.data();
          var ok = overlaps(d.rq, rq) && overlaps(d.outcome, outcome) && overlaps(d.times, times) && status.indexOf(d.status) >= 0;
          n.style('display', ok ? 'element' : 'none');
          if (ok) shown = shown.union(n);
          if (ok && q && (d.plain + ' ' + d.standard).toLowerCase().indexOf(q) >= 0) n.addClass('hit');
        });
        cy.nodes('[kind = \"hub\"]').forEach(function(n) {
          var has = n.outgoers('edge[shortcut]').targets().intersection(shown).length > 0;
          n.style('display', !isTree && rq.indexOf(n.data('rq')) >= 0 && has ? 'element' : 'none');
        });
        cy.nodes('[kind = \"question\"], [kind = \"root\"]').forEach(function(n) {
          var leads = isTree && (n.data('kind') === 'root' || n.successors('node[kind = \"endpoint\"]').intersection(shown).length > 0);
          n.style('display', leads ? 'element' : 'none');
        });
        if (isTree) cy.nodes('[kind = \"hub\"]').forEach(function(n) {
          if (rq.indexOf(n.data('rq')) >= 0 && n.successors('node[kind = \"endpoint\"]').intersection(shown).length) n.style('display', 'element');
        });
        cy.edges().forEach(function(e) { e.style('display', (e.data('shortcut') ? !isTree : isTree) ? 'element' : 'none'); });
        if (q) {
          var hits = cy.nodes('.hit');
          cy.elements().not('[kind = \"orbit\"]').addClass('dim');
          hits.removeClass('dim');
          hits.connectedEdges().removeClass('dim');
          hits.incomers('node').removeClass('dim');
          if (isTree) hits.predecessors().removeClass('dim');
        }
      });
      var count = document.getElementById('map-count');
      if (count) count.textContent = shown.length + ' of ' + cy.nodes('[kind = \"endpoint\"]').length + ' analyses shown' +
        (q ? '; ' + cy.nodes('.hit').length + ' match “' + q + '”' : '') + '.';
      if (isTree) tree(); else cosmos();
    };
    window.pkMapLayout = window.pkMapFilter;
    // Planets named in plain words, or by the test's usual name.
    window.pkMapNames = function() {
      if (!cy) return;
      var standard = ((document.getElementById('map_names') || {}).value || 'plain') === 'standard';
      cy.nodes('[kind = \"endpoint\"]').forEach(function(n) {
        n.data('label', standard && n.data('standard') ? n.data('standard') : n.data('plain'));
      });
    };
    window.pkMapReset = function() {
      document.querySelectorAll('.map-sidebar input[type=checkbox]').forEach(function(i) { i.checked = true; });
      var s = document.getElementById('map_search'); if (s) s.value = '';
      pkMapClose();
      pkMapFilter();
    };
    window.pkMapPanel = function() {
      var p = document.getElementById('map-sidebar'), b = document.querySelector('.map-panel-toggle');
      var closed = p.classList.toggle('closed');
      if (b) b.setAttribute('aria-expanded', closed ? 'false' : 'true');
    };
    function esc(s) { var d = document.createElement('div'); d.textContent = s; return d.innerHTML; }
    // The answers on the shortest route to an analysis through the
    // design finder's questions (whichever view is showing).
    function route(n) {
      var graph = cy.elements().not('edge[shortcut]').not('[kind = \"orbit\"]');
      var path = graph.dijkstra({ root: cy.$id('root'), directed: true }).pathTo(n), steps = [];
      path.forEach(function(x) {
        if (x.isEdge()) { x.addClass('path'); if (x.data('label')) steps.push(x.data('label')); }
        else if (x.data('kind') === 'hub') steps.push(x.data('label'));
      });
      return steps;
    }
    function details(n) {
      var box = document.getElementById('map-details'); if (!box) return;
      cy.edges().removeClass('path');
      var d = n.data(), html = '<button type=\"button\" class=\"map-close\" aria-label=\"Close\" onclick=\"pkMapClose()\">×</button>';
      if (d.kind === 'endpoint') {
        var steps = route(n);
        n.connectedEdges('[shortcut]').addClass('path');
        html += '<h4>' + esc(d.label) + '</h4><span class=\"map-badge ' + d.status + '\">' + esc(d.statusText) + '</span>' +
          (d.standard && d.standard !== d.label ? '<p class=\"small mb-1\">Usual name: <strong>' + esc(d.standard) + '</strong></p>' : '') +
          (d.plain !== d.label ? '<p class=\"small mb-1\">In plain words: <strong>' + esc(d.plain) + '</strong></p>' : '') +
          (steps.length ? '<p class=\"small mb-1\">One way to get here in “Help me choose”:</p><ol>' +
            steps.map(function(s) { return '<li>' + esc(s) + '</li>'; }).join('') + '</ol>' : '') +
          '<button type=\"button\" class=\"btn btn-info btn-sm\" data-id=\"' + esc(d.id) + '\" onclick=\"pkMapOpen(this.dataset.id)\">Read about this analysis</button>';
        cy.animate({ center: { eles: n }, zoom: Math.max(cy.zoom(), 1) }, { duration: 500 });
      } else if (d.kind === 'hub') {
        var planets = n.outgoers('edge[shortcut]').targets().filter(function(x) { return x.style('display') !== 'none'; });
        var near = n.outgoers('edge[shortcut]').not('.far').targets().filter(function(x) { return x.style('display') !== 'none'; });
        html += '<h4>' + esc(d.label) + '</h4><p class=\"small mb-0\">' + planets.length + ' analyses shown for this' +
          (planets.length > near.length ? ' (' + (planets.length - near.length) + ' of them orbit another star too; the dashed lines lead to them)' : '') +
          '. Click one to read about it.</p>';
        fitTo(n.union(near));
      } else {
        var under = n.successors('node[kind = \"endpoint\"]').filter(function(x) { return x.style('display') !== 'none'; });
        route(n);
        html += '<h4>' + esc(d.label) + '</h4><p class=\"small mb-0\">' + under.length + ' of the analyses shown lie beyond this question.</p>';
      }
      box.innerHTML = html;
      box.hidden = false;
    }
    window.pkMapClose = function() {
      var b = document.getElementById('map-details'); if (b) b.hidden = true;
      if (cy) { cy.edges().removeClass('path'); cy.nodes().unselect(); }
    };
    window.pkMapOpen = function(id) {
      Shiny.setInputValue('map_endpoint', id, { priority: 'event' });
      setTimeout(function() {
        var p = document.getElementById('map-page');
        if (p) { p.scrollIntoView({ block: 'start' }); p.focus({ preventScroll: true }); }
      }, 400);
    };
    function start() {
      var box = document.getElementById('map-canvas');
      if (!box || !window.cytoscape || !load()) return false;
      cy = cytoscape({ container: box, elements: elements(), style: style(), wheelSensitivity: 0.3, minZoom: 0.04, maxZoom: 2.5,
        layout: { name: 'preset' } });
      window.pkMapGraph = cy;
      cy.on('tap', 'node', function(e) { details(e.target); });
      cy.on('tap', function(e) { if (e.target === cy) pkMapClose(); });
      cy.on('dbltap', 'node[kind = \"endpoint\"]', function(e) { pkMapOpen(e.target.id()); });
      cy.on('mouseover', 'node', function(e) { e.target.addClass('hover'); box.style.cursor = 'pointer'; });
      cy.on('mouseout', 'node', function(e) { e.target.removeClass('hover'); box.style.cursor = ''; });
      // The stars drift a little as the map moves.
      cy.on('viewport', function() { var p = cy.pan(); box.style.backgroundPosition = (p.x * 0.15) + 'px ' + (p.y * 0.15) + 'px'; });
      cy.on('zoom', scaleNames);
      pkMapFilter();
      return true;
    }
    // The map can only measure itself once it is on screen.
    window.pkMapShown = function() {
      var box = document.getElementById('map-canvas'); if (!box || box.offsetParent === null) return;
      if (!started) { started = start(); } else if (cy) { cy.resize(); }
    };
  })();
"
