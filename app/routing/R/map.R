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
    values = list(score = "A score or scale", yesno = "Yes/no, or categories", count = "A count")),
  times = list(question = "It depends on how often each person is measured",
    values = list(once = "Once", twice = "Twice", many_conditions = "In three or more conditions"))
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
  outcome = c(score = "A score or scale", yesno = "Yes/no, or categories", count = "A count", other = "Not fixed by the questions"),
  times = c(once = "Once", twice = "Twice", many_conditions = "Three or more times", other = "Not fixed by the questions"),
  status = c(runs = "Calculates in powerkit", soon = "Coming", not = "Not in powerkit yet")
)

map_screening <- c("s1", "o5a", "s2", "s3", "t1", "s4")
map_elsewhere <- "Designs set by how the data are collected"

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
  tags$details(class = "map-filter", open = NA,
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
    h3("A map of the methods"),
    p("Every analysis powerkit knows about, and the questions that lead to each, drawn from the same questions as “Help me choose”. Filter it down the side, drag and zoom to move around, and click anything to read about it."),
    div(class = "map-layout",
      div(class = "map-sidebar",
        tags$label(`for` = "map_search", class = "h6", "Search"),
        tags$input(id = "map_search", type = "search", class = "form-control form-control-sm",
          placeholder = "e.g. mediation, paired, proportion", oninput = "pkMapFilter()"),
        map_checks("rq", rq, "What the study wants to show"),
        map_checks("outcome", map_filters$outcome, "The outcome"),
        map_checks("times", map_filters$times, "How often each person is measured"),
        map_checks("status", map_filters$status, "In powerkit"),
        tags$fieldset(class = "map-filter",
          tags$legend(class = "h6", "View"),
          div(class = "form-check form-switch",
            tags$input(class = "form-check-input", type = "checkbox", id = "map_questions", onchange = "pkMapFilter()"),
            tags$label(class = "form-check-label", `for` = "map_questions", "Show the questions in between")),
          tags$label(`for` = "map_layout", class = "small mt-2", "Arrangement"),
          tags$select(id = "map_layout", class = "form-select form-select-sm", onchange = "pkMapLayout()",
            tags$option(value = "web", "As a web"),
            tags$option(value = "tree", "As a tree, left to right"),
            tags$option(value = "rings", "In rings, from the centre"))),
        div(class = "nav-buttons mt-2",
          tags$button(type = "button", class = "btn btn-outline-primary btn-sm", onclick = "pkMapFit()", "Fit to the window"),
          tags$button(type = "button", class = "btn btn-link btn-sm", onclick = "pkMapReset()", "Clear filters")),
        p(class = "small text-muted map-count", id = "map-count", `aria-live` = "polite")),
      div(class = "map-stage",
        div(id = "map-canvas", class = "map-canvas", role = "img",
          `aria-label` = "A graph of powerkit's questions and analyses. The same map is available as a list below it."),
        div(id = "map-details", class = "map-details", hidden = NA))),
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
  .map-layout { display: grid; grid-template-columns: 17rem 1fr; gap: 1rem; align-items: start; }
  @media (max-width: 800px) { .map-layout { grid-template-columns: 1fr; } }
  .map-sidebar { background: #fff; border: 1px solid var(--pk-line, #d8dee6); border-radius: 12px; padding: 0.9rem 1rem;
                 max-height: 82vh; overflow-y: auto; }
  .map-sidebar .h6 { font-weight: 650; color: var(--pk-navy, #14284B); margin: 0.7rem 0 0.3rem 0; font-size: 0.85rem; }
  .map-filter { margin: 0; }
  .map-filter > summary { cursor: pointer; }
  .map-filter .form-check { display: flex; gap: 0.45rem; align-items: flex-start; padding-left: 0; margin-bottom: 0.15rem; }
  .map-filter .form-check-input { float: none; flex: none; margin: 0.2rem 0 0 0; }
  .map-filter .form-switch .form-check-input { width: 2em; }
  .map-filter .form-check-label { font-size: 0.85rem; line-height: 1.3; }
  .map-stage { position: relative; }
  .map-canvas { height: 82vh; min-height: 460px; border: 1px solid var(--pk-line, #d8dee6); border-radius: 12px;
                background: radial-gradient(circle at 25% 15%, #ffffff 0%, #eef3f8 75%); }
  .map-details { position: absolute; top: 0.75rem; right: 0.75rem; width: 19rem; max-width: calc(100% - 1.5rem); background: #fff;
                 border: 1px solid var(--pk-line, #d8dee6); border-radius: 12px; box-shadow: 0 8px 24px rgba(20, 40, 75, 0.15);
                 padding: 0.9rem 1rem; max-height: calc(100% - 1.5rem); overflow-y: auto; }
  .map-details h4 { font-size: 1rem; color: var(--pk-navy, #14284B); margin: 0 1.5rem 0.35rem 0; }
  .map-details .map-close { position: absolute; top: 0.4rem; right: 0.6rem; border: 0; background: none; font-size: 1.3rem; line-height: 1; }
  .map-details ol { padding-left: 1.1rem; font-size: 0.85rem; }
  .map-badge { display: inline-block; border-radius: 1rem; padding: 0.05rem 0.6rem; font-size: 0.75rem; font-weight: 600; margin-bottom: 0.5rem; }
  .map-badge.runs { background: #e3eff8; color: #0A5A8C; }
  .map-badge.soon { background: #fff1d6; color: #8a4a00; }
  .map-badge.not { background: #eef0f2; color: #4b5563; }
  .map-key::before { content: ''; display: inline-block; width: 0.8em; height: 0.8em; border-radius: 50%; margin-right: 0.35em; vertical-align: -0.05em; }
  .map-key.map-runs::before { background: #0A5A8C; }
  .map-key.map-soon::before { background: #d97706; }
  .map-key.map-not::before { background: #9aa3ad; }
  .map-page { margin-top: 1rem; }
  .map-as-list { margin-top: 1rem; }
"

# The page side: draws the graph, filters it and shows a node's details.
map_js <- "
  (function() {
    var cy = null, data = null, started = false, running = null;
    function load() {
      if (data) return data;
      var d = document.getElementById('map-data'); if (!d) return null;
      data = JSON.parse(d.textContent); return data;
    }
    function elements() {
      var d = load(), els = [], hubs = {};
      els.push({ data: { id: 'root', label: 'Your study', kind: 'root' } });
      d.nodes.forEach(function(n) {
        els.push({ data: Object.assign({}, n) });
        if (n.kind === 'hub') { hubs[n.rq] = n.id; els.push({ data: { id: 'root-' + n.id, source: 'root', target: n.id, label: '' } }); }
      });
      d.edges.forEach(function(e) { els.push({ data: Object.assign({}, e) }); });
      // Shortcuts for the view without the questions in between: each
      // research question straight to its analyses.
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
        { selector: 'node', style: { 'label': 'data(label)', 'text-wrap': 'wrap', 'text-max-width': 170, 'font-size': 11,
            'font-family': 'Inter, system-ui, sans-serif', 'text-valign': 'center', 'text-halign': 'right', 'text-margin-x': 6,
            'color': '#1f2933', 'background-color': '#c9d2dc', 'width': 14, 'height': 14, 'min-zoomed-font-size': 7 } },
        { selector: 'node[kind = \"root\"], node[kind = \"hub\"]', style: { 'shape': 'round-rectangle', 'background-color': '#14284B',
            'color': '#fff', 'text-halign': 'center', 'text-margin-x': 0, 'width': 'label', 'height': 'label', 'padding': 12,
            'font-size': 13, 'font-weight': 700, 'text-max-width': 190 } },
        { selector: 'node[kind = \"hub\"]', style: { 'background-color': '#0A5A8C', 'font-size': 13, 'text-max-width': 170 } },
        { selector: 'node[kind = \"root\"], node[kind = \"hub\"], node.hover, node.hit, node:selected', style: { 'min-zoomed-font-size': 0 } },
        { selector: 'node[kind = \"endpoint\"].hover', style: { 'font-size': 14, 'z-index': 20, 'text-background-color': '#fff', 'text-background-opacity': 0.9,
            'text-background-padding': 3 } },
        { selector: 'node[kind = \"question\"]', style: { 'shape': 'round-rectangle', 'background-color': '#ffffff', 'border-width': 1.5,
            'border-color': '#9fb3c8', 'text-halign': 'center', 'text-margin-x': 0, 'width': 'label', 'height': 'label', 'padding': 8,
            'text-max-width': 170, 'font-size': 11, 'color': '#14284B' } },
        { selector: 'node[kind = \"endpoint\"]', style: { 'width': 18, 'height': 18, 'font-weight': 600, 'border-width': 3, 'border-color': '#fff' } },
        { selector: 'node[status = \"runs\"]', style: { 'background-color': '#0A5A8C', 'width': 22, 'height': 22 } },
        { selector: 'node[status = \"soon\"]', style: { 'background-color': '#d97706' } },
        { selector: 'node[status = \"not\"]', style: { 'background-color': '#9aa3ad' } },
        { selector: 'edge', style: { 'width': 1.4, 'line-color': '#c3ccd6', 'curve-style': 'bezier', 'target-arrow-shape': 'triangle',
            'target-arrow-color': '#c3ccd6', 'arrow-scale': 0.7 } },
        { selector: '.dim', style: { 'opacity': 0.12 } },
        { selector: 'node.hit', style: { 'border-color': '#f2b84b', 'border-width': 5 } },
        { selector: 'node:selected', style: { 'border-color': '#f2b84b', 'border-width': 5 } },
        { selector: 'edge.path', style: { 'line-color': '#0A5A8C', 'target-arrow-color': '#0A5A8C', 'width': 3, 'label': 'data(label)',
            'font-size': 10, 'text-wrap': 'wrap', 'text-max-width': 140, 'text-background-color': '#fff', 'text-background-opacity': 0.9,
            'text-background-padding': 2, 'color': '#0A5A8C', 'z-index': 10 } }
      ];
    }
    function layoutOptions(which) {
      if (which === 'web') return { name: 'cose', animate: true, animationDuration: 500, nodeRepulsion: function() { return 400000; },
        idealEdgeLength: function() { return 130; }, nodeOverlap: 40, gravity: 0.3, nodeDimensionsIncludeLabels: true,
        boundingBox: { x1: 0, y1: 0, w: cy.width(), h: cy.height() }, numIter: 2000, padding: 30, randomize: true };
      if (which === 'rings') return { name: 'breadthfirst', circle: true, roots: '#root', spacingFactor: 0.9, animate: true,
        animationDuration: 500, padding: 30 };
      return { name: 'dagre', rankDir: 'LR', nodeSep: 6, rankSep: 60, animate: true, animationDuration: 500, padding: 30 };
    }
    // Lay out what is shown; with a search, zoom to the matches and the
    // routes to them.
    window.pkMapLayout = function() {
      if (!cy) return;
      var which = (document.getElementById('map_layout') || {}).value || 'web';
      if (running) running.stop();
      var layout = running = cy.elements(':visible').layout(layoutOptions(which));
      layout.one('layoutstop', function() {
        var hits = cy.nodes('.hit');
        if (hits.length) cy.animate({ fit: { eles: hits.union(hits.predecessors(':visible')), padding: 60 } }, { duration: 400 });
      });
      layout.run();
    };
    window.pkMapFit = function() { if (cy) cy.animate({ fit: { eles: cy.elements(':visible'), padding: 30 } }, { duration: 300 }); };
    function checked(group) {
      return Array.prototype.map.call(document.querySelectorAll('.map-sidebar input[data-group=\"' + group + '\"]:checked'),
        function(i) { return i.value; });
    }
    function overlaps(a, b) { return a.some(function(x) { return b.indexOf(x) >= 0; }); }
    // An analysis shows when it matches every filter; a question shows
    // when an analysis it leads to shows.
    window.pkMapFilter = function() {
      if (!cy) return;
      var rq = checked('rq'), outcome = checked('outcome'), times = checked('times'), status = checked('status');
      var q = ((document.getElementById('map_search') || {}).value || '').trim().toLowerCase();
      var between = (document.getElementById('map_questions') || {}).checked !== false;
      var shown = cy.collection();
      cy.batch(function() {
        cy.elements().removeClass('dim hit path');
        cy.nodes('[kind = \"endpoint\"]').forEach(function(n) {
          var d = n.data();
          var ok = overlaps(d.rq, rq) && overlaps(d.outcome, outcome) && overlaps(d.times, times) && status.indexOf(d.status) >= 0;
          n.style('display', ok ? 'element' : 'none');
          if (ok) shown = shown.union(n);
          if (ok && q && (d.label + ' ' + d.standard).toLowerCase().indexOf(q) >= 0) n.addClass('hit');
        });
        cy.nodes('[kind = \"question\"]').forEach(function(n) {
          var leads = between && n.successors('node[kind = \"endpoint\"]').intersection(shown).length > 0;
          n.style('display', leads ? 'element' : 'none');
        });
        cy.nodes('[kind = \"hub\"]').forEach(function(n) { n.style('display', rq.indexOf(n.data('rq')) >= 0 ? 'element' : 'none'); });
        cy.edges().forEach(function(e) { e.style('display', (e.data('shortcut') ? !between : between || e.source().data('kind') === 'root') ? 'element' : 'none'); });
        if (q) {
          var hits = cy.nodes('.hit');
          cy.elements().addClass('dim');
          hits.removeClass('dim');
          hits.predecessors().removeClass('dim');
        }
      });
      var count = document.getElementById('map-count');
      if (count) count.textContent = shown.length + ' of ' + cy.nodes('[kind = \"endpoint\"]').length + ' analyses shown' +
        (q ? '; ' + cy.nodes('.hit').length + ' match “' + q + '”' : '') + '.';
      pkMapLayout();
    };
    window.pkMapReset = function() {
      document.querySelectorAll('.map-sidebar input[type=checkbox]').forEach(function(i) { i.checked = true; });
      var s = document.getElementById('map_search'); if (s) s.value = '';
      pkMapClose();
      pkMapFilter();
    };
    function esc(s) { var d = document.createElement('div'); d.textContent = s; return d.innerHTML; }
    // The answers on the shortest route to a node from the start,
    // highlighted on the graph.
    function route(n) {
      var paths = cy.elements(':visible').dijkstra({ root: cy.$id('root'), directed: true });
      var path = paths.pathTo(n), steps = [];
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
        html += '<h4>' + esc(d.label) + '</h4><span class=\"map-badge ' + d.status + '\">' + esc(d.statusText) + '</span>' +
          (d.standard ? '<p class=\"small mb-1\">Usual name: <strong>' + esc(d.standard) + '</strong></p>' : '') +
          (steps.length ? '<p class=\"small mb-1\">One way to get here:</p><ol>' +
            steps.map(function(s) { return '<li>' + esc(s) + '</li>'; }).join('') + '</ol>' : '') +
          '<button type=\"button\" class=\"btn btn-primary btn-sm\" data-id=\"' + esc(d.id) + '\" onclick=\"pkMapOpen(this.dataset.id)\">Read about this analysis</button>';
      } else {
        var under = n.successors('node[kind = \"endpoint\"]').filter(function(x) { return x.style('display') !== 'none'; });
        route(n);
        html += '<h4>' + esc(d.label) + '</h4><p class=\"small mb-0\">' + under.length + ' of the analyses shown lie beyond this point.</p>';
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
      cy = cytoscape({ container: box, elements: elements(), style: style(), wheelSensitivity: 0.3, minZoom: 0.08, maxZoom: 3,
        layout: { name: 'preset' } });
      window.pkMapGraph = cy;
      cy.on('tap', 'node', function(e) { details(e.target); });
      cy.on('mouseover', 'node', function(e) { e.target.addClass('hover'); box.style.cursor = 'pointer'; });
      cy.on('mouseout', 'node', function(e) { e.target.removeClass('hover'); box.style.cursor = ''; });
      cy.on('tap', function(e) { if (e.target === cy) pkMapClose(); });
      cy.on('dbltap', 'node[kind = \"endpoint\"]', function(e) { pkMapOpen(e.target.id()); });
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
map_js <- paste0("var MAP_ELSEWHERE = ", jsonlite::toJSON(map_elsewhere, auto_unbox = TRUE), ";\n", map_js)
