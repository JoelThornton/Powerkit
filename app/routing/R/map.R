# Labs: a map of the methods. Generated from tree.yaml, so it can't drift
# from the design finder: research questions on the left, the questions
# that narrow them down in the middle, and every analysis on the right,
# coloured by whether powerkit calculates it. A second group shows the
# designs the screening questions send elsewhere (people within groups,
# many trials per person, time to an event, ...). Pure functions build the
# layout; the page draws it as an SVG the user can pan and zoom, with a
# plain list of the same map for screen readers. Nothing is calculated.

# What a screening answer an automatic node routes on means, in words.
map_branch_text <- list(
  outcome = list(question = "It depends on your outcome",
    values = list(score = "A score or scale", yesno = "Yes/no, or categories", count = "A count")),
  times = list(question = "It depends on how often each person is measured",
    values = list(once = "Once", twice = "Twice", many_conditions = "In three or more conditions"))
)

# How each status reads on the map, and its colour class.
map_status <- list(
  runs_validated = list(text = "Calculates in powerkit", class = "map-runs"),
  runs_validation_in_progress = list(text = "Calculates in powerkit (checks in progress)", class = "map-runs"),
  coming_soon = list(text = "Coming to powerkit", class = "map-soon"),
  not_in_powerkit = list(text = "Not in powerkit yet: guidance and other tools", class = "map-not")
)

# The map as a tree of nested lists: list(kind, id, answer, text, children).
# kind is "root", "group", "question", "endpoint" or "see" (a question
# already drawn elsewhere on the map, shown once and referred to after).
map_tree <- function(tree) {
  drawn <- new.env()
  node <- function(id, answer) {
    if (is_endpoint_id(id)) {
      ep <- tree$endpoints[[id]]
      return(list(kind = "endpoint", id = id, answer = answer, text = ep$plain_name %||% id, status = ep$status %||% "not_in_powerkit"))
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
  # The screening questions' own end points (not "continue").
  screening <- c("s1", "o5a", "s2", "s3", "t1", "s4")
  elsewhere <- lapply(screening, function(id) {
    n <- tree$nodes[[id]]
    opts <- Filter(function(o) is_endpoint_id(o$`next` %||% ""), n$options)
    if (!length(opts)) return(NULL)
    list(kind = "question", id = id, answer = NULL, text = n$text,
      children = lapply(opts, function(o) node(o$`next`, o$label)))
  })
  list(kind = "root", id = "root", text = "Your study", children = list(
    list(kind = "group", id = "group_questions", answer = NULL, text = "What do you want your study to show?",
      children = questions$children),
    list(kind = "group", id = "group_elsewhere", answer = NULL, text = "Designs set by how the data are collected",
      children = Filter(Negate(is.null), elsewhere))
  ))
}

map_node_text <- function(n) {
  if (is_automatic(n)) map_branch_text[[n$branch_on]]$question else n$text
}

# Box sizes, in SVG units.
map_geom <- list(width = 250, gap_x = 70, line = 15, pad = 10, gap_y = 12, wrap = 36)

map_lines <- function(x) if (is.null(x) || !nzchar(x)) character() else strwrap(x, map_geom$wrap)

map_box_height <- function(node) {
  n <- length(map_lines(node$answer)) + length(map_lines(node$text)) + if (identical(node$kind, "endpoint")) 1 else 0
  2 * map_geom$pad + n * map_geom$line
}

# Positions: leaves stacked top to bottom in order, each parent centred on
# its children, one column per depth. Returns a data frame of boxes (with
# their parent's row) for drawing.
map_layout <- function(map) {
  rows <- list()
  next_y <- 0
  place <- function(node, depth, parent) {
    h <- map_box_height(node)
    i <- length(rows) + 1
    rows[[i]] <<- list(node = node, depth = depth, parent = as.integer(parent), h = h, y = NA_real_)
    kids <- node$children
    if (length(kids)) {
      centres <- vapply(kids, function(k) place(k, depth + 1, as.integer(i)), numeric(1))
      y <- mean(range(centres)) - h / 2
    } else {
      y <- next_y
      next_y <<- next_y + h + map_geom$gap_y
    }
    rows[[i]]$y <<- y
    y + h / 2
  }
  place(map, 0, NA_integer_)
  data.frame(
    id = vapply(rows, function(r) r$node$id, ""),
    kind = vapply(rows, function(r) r$node$kind, ""),
    status = vapply(rows, function(r) r$node$status %||% "", ""),
    depth = vapply(rows, `[[`, 0, "depth"),
    parent = vapply(rows, `[[`, 0L, "parent"),
    x = vapply(rows, function(r) r$depth * (map_geom$width + map_geom$gap_x), 0),
    y = vapply(rows, `[[`, 0, "y"),
    h = vapply(rows, `[[`, 0, "h"),
    answer = I(lapply(rows, function(r) map_lines(r$node$answer))),
    text = I(lapply(rows, function(r) map_lines(r$node$text))),
    stringsAsFactors = FALSE
  )
}

# The map's boxes for the page: one per box, with its parent's index (0
# for none, counted from 1), its lines of text and its status. The page
# lays out the boxes that are open (map_js).
map_data <- function(tree, layout = map_layout(map_tree(tree))) {
  lapply(seq_len(nrow(layout)), function(i) {
    r <- layout[i, ]
    status <- map_status[[r$status]]
    list(i = i, parent = if (is.na(r$parent)) 0L else r$parent, depth = r$depth, id = r$id, kind = r$kind,
      cls = status$class %||% "", status = status$text %||% "",
      answer = as.list(r$answer[[1]]), text = as.list(r$text[[1]]))
  })
}

map_svg <- function(tree) {
  json <- as.character(jsonlite::toJSON(map_data(tree), auto_unbox = TRUE))
  tagList(
    tags$script(id = "map-data", type = "application/json", HTML(json)),
    tag("svg", list(id = "map-svg", xmlns = "http://www.w3.org/2000/svg", width = "100%", height = "100%",
      `aria-hidden` = "true", focusable = "false", tag("g", list(id = "map-pan")))))
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

map_ui <- function(tree) {
  map <- map_tree(tree)
  endpoints <- unique(Filter(is_endpoint_id, map_layout(map)$id))
  names(endpoints) <- vapply(endpoints, function(e) tree$endpoints[[e]]$plain_name %||% e, "")
  endpoints <- endpoints[order(names(endpoints))]
  tagList(
    h3("A map of the methods"),
    p("Every analysis powerkit knows about, arranged by the question a study asks. Read it from the left: what you want to show, then the questions that narrow it down, then the analyses. Blue analyses calculate in powerkit; amber ones are coming; grey ones aren't in powerkit yet, and their page points to tools that do them. Click an analysis to open its page."),
    p(class = "small", "Click a question to open the answers under it, and an analysis to open its page. Drag to move around; scroll or use the buttons to zoom. The map is drawn from the same questions as “Help me choose”, so it always matches them."),
    div(class = "map-controls nav-buttons",
      tags$button(type = "button", class = "btn btn-outline-primary btn-sm", onclick = "pkMapZoom(1.25)", `aria-label` = "Zoom in", "+"),
      tags$button(type = "button", class = "btn btn-outline-primary btn-sm", onclick = "pkMapZoom(0.8)", `aria-label` = "Zoom out", "−"),
      tags$button(type = "button", class = "btn btn-outline-primary btn-sm", onclick = "pkMapFit()", "Fit to the window"),
      tags$button(type = "button", class = "btn btn-outline-primary btn-sm", onclick = "pkMapOpenAll(true)", "Open every question"),
      tags$button(type = "button", class = "btn btn-outline-primary btn-sm", onclick = "pkMapOpenAll(false)", "Close them all"),
      tags$label(`for` = "map_find", class = "visually-hidden", "Find an analysis on the map"),
      tags$select(id = "map_find", class = "form-select form-select-sm map-find", onchange = "pkMapFind(this.value)",
        tags$option(value = "", "Find an analysis…"),
        lapply(seq_along(endpoints), function(i) tags$option(value = endpoints[[i]], names(endpoints)[i])))),
    div(class = "map-legend small",
      span(class = "map-key map-runs", "Calculates in powerkit"),
      span(class = "map-key map-soon", "Coming"),
      span(class = "map-key map-not", "Not in powerkit yet")),
    div(id = "map-viewport", class = "map-viewport", map_svg(tree)),
    uiOutput("map_page"),
    tags$details(class = "map-as-list",
      tags$summary("The map as a list"),
      map_list_ui(map))
  )
}

# The page for an analysis on the map: its card, as the design finder shows
# it, with its status.
map_page_ui <- function(tree, ep_id) {
  if (is.null(ep_id) || !nzchar(ep_id) || is.null(tree$endpoints[[ep_id]])) return(NULL)
  div(class = "map-page", id = "map-page", tabindex = "-1",
    card_ui(tree, ep_id, compact = TRUE),
    p(class = "small", "To plan this analysis, go to “Plan a power analysis” and choose “I know my analysis”, or answer the questions under “Help me choose”."))
}

map_css <- "
  .map-viewport { height: 70vh; min-height: 420px; border: 1px solid var(--pk-line, #d8dee6); border-radius: 12px; overflow: hidden; background: #fbfcfd; cursor: grab; touch-action: none; }
  .map-viewport.dragging { cursor: grabbing; }
  .map-node rect { fill: #fff; stroke: #c9d2dc; stroke-width: 1; }
  .map-node text { font-size: 12px; fill: #1f2933; }
  .map-group rect, .map-root rect { fill: #14284B; stroke: #14284B; }
  .map-node.map-group text, .map-node.map-root text { fill: #fff; font-weight: 600; }
  .map-endpoint, .map-question, .map-group { cursor: pointer; }
  .map-closed rect { stroke: #0A5A8C; stroke-width: 1.5; }
  .map-node .map-toggle { font-size: 16px; font-weight: 700; fill: #0A5A8C; }
  .map-node.map-group .map-toggle, .map-node.map-root .map-toggle { fill: #f2b84b; }
  .map-node:focus rect, .map-node:hover rect { stroke-width: 3; }
  .map-endpoint.map-runs rect { fill: #e8f1f8; stroke: #0A5A8C; stroke-width: 1.5; }
  .map-endpoint.map-soon rect { fill: #fff6e5; stroke: #b45309; }
  .map-endpoint.map-not rect { fill: #f3f4f6; stroke: #9aa3ad; }
  .map-endpoint:hover rect, .map-endpoint:focus rect, .map-endpoint.map-found rect { stroke-width: 3; }
  .map-endpoint:focus { outline: none; }
  .map-see rect { fill: #fafafa; stroke-dasharray: 4 3; }
  .map-answer { fill: #5b6672 !important; font-style: italic; }
  .map-name { font-weight: 650; }
  .map-status { font-size: 11px !important; fill: #44505e !important; }
  .map-edge { fill: none; stroke: #b8c2cc; stroke-width: 1.5; }
  .map-legend { display: flex; gap: 1rem; margin: 0.5rem 0; flex-wrap: wrap; }
  .map-key::before { content: ''; display: inline-block; width: 1.6em; height: 0.7em; border-radius: 2px; margin-right: 0.4em; vertical-align: 0; }
  .map-key.map-runs::before { background: #0A5A8C; }
  .map-key.map-soon::before { background: #b45309; }
  .map-key.map-not::before { background: #9aa3ad; }
  .map-find { width: auto; max-width: 22rem; display: inline-block; }
  .map-page { margin-top: 1rem; }
"

# Pan and zoom without a library: the map's group is moved and scaled by a
# transform, by dragging (mouse, pen or touch), the wheel and the buttons.
map_js <- "
  (function() {
    var G = { width: 250, gapX: 70, line: 15, pad: 10, gapY: 12 };
    var s = { x: 10, y: 10, k: 0.9 }, drag = null, nodes = null, open = {}, started = false;
    var NS = 'http://www.w3.org/2000/svg';
    function g() { return document.getElementById('map-pan'); }
    function vp() { return document.getElementById('map-viewport'); }
    function draw() { var el = g(); if (el) el.setAttribute('transform', 'translate(' + s.x + ',' + s.y + ') scale(' + s.k + ')'); }
    function load() {
      if (nodes) return nodes;
      var d = document.getElementById('map-data'); if (!d) return null;
      nodes = JSON.parse(d.textContent);
      nodes.forEach(function(n) { n.kids = []; n.h = 2 * G.pad + G.line * (n.answer.length + n.text.length + (n.kind === 'endpoint' ? 1 : 0)); });
      nodes.forEach(function(n) { if (n.parent) nodes[n.parent - 1].kids.push(n); });
      // Open at first: the start and its two groups, so the research
      // questions show; everything further is opened by clicking.
      nodes.forEach(function(n) { if (n.depth < 2) open[n.i] = true; });
      return nodes;
    }
    function el(name, attrs, text) {
      var e = document.createElementNS(NS, name);
      for (var k in attrs) e.setAttribute(k, attrs[k]);
      if (text !== undefined) e.textContent = text;
      return e;
    }
    // Leaves of the open tree stacked top to bottom; each open box centred
    // on its children; one column per depth.
    function layout() {
      var y = 0, shown = [];
      function place(n) {
        shown.push(n); n.x = n.depth * (G.width + G.gapX);
        if (n.kids.length && open[n.i]) {
          var c = n.kids.map(place); n.y = (Math.min.apply(null, c) + Math.max.apply(null, c)) / 2 - n.h / 2;
        } else { n.y = y; y += n.h + G.gapY; }
        return n.y + n.h / 2;
      }
      place(nodes[0]);
      return shown;
    }
    function render() {
      var root = g(); if (!root || !load()) return;
      while (root.firstChild) root.removeChild(root.firstChild);
      var shown = layout();
      shown.forEach(function(n) {
        if (!n.parent || !shown.includes(nodes[n.parent - 1])) return;
        var p = nodes[n.parent - 1], x1 = p.x + G.width, y1 = p.y + p.h / 2, x2 = n.x, y2 = n.y + n.h / 2, m = (x1 + x2) / 2;
        root.appendChild(el('path', { 'class': 'map-edge', d: 'M' + x1 + ',' + y1 + ' C' + m + ',' + y1 + ' ' + m + ',' + y2 + ' ' + x2 + ',' + y2 }));
      });
      shown.forEach(function(n) {
        var closed = n.kids.length && !open[n.i];
        var box = el('g', { 'class': 'map-node map-' + n.kind + ' ' + n.cls + (closed ? ' map-closed' : ''), 'data-id': n.id, 'data-i': n.i });
        box.appendChild(el('rect', { x: n.x, y: n.y, width: G.width, height: n.h, rx: 8 }));
        var lines = n.answer.map(function(t) { return [t, 'map-answer']; })
          .concat(n.text.map(function(t) { return [t, n.kind === 'endpoint' ? 'map-name' : 'map-text']; }));
        if (n.kind === 'endpoint') lines.push([n.status, 'map-status']);
        lines.forEach(function(l, j) { box.appendChild(el('text', { 'class': l[1], x: n.x + G.pad, y: n.y + G.pad + (j + 1) * G.line - 3 }, l[0])); });
        if (n.kids.length) box.appendChild(el('text', { 'class': 'map-toggle', x: n.x + G.width - 18, y: n.y + n.h / 2 + 5 }, closed ? '+' : '−'));
        if (n.kind === 'endpoint' || n.kids.length) box.setAttribute('tabindex', '0');
        root.appendChild(box);
      });
      draw();
    }
    function toggle(i) { open[i] = !open[i]; render(); }
    function openTo(n) { while (n.parent) { n = nodes[n.parent - 1]; open[n.i] = true; } }
    function sizeSvg() { var svg = document.getElementById('map-svg'), v = vp(); if (svg && v) { svg.setAttribute('width', v.clientWidth); svg.setAttribute('height', v.clientHeight); } }
    window.pkMapZoom = function(f, cx, cy) {
      var v = vp(); if (!v) return;
      if (cx === undefined) { cx = v.clientWidth / 2; cy = v.clientHeight / 2; }
      var k = Math.min(3, Math.max(0.1, s.k * f)); f = k / s.k;
      s.x = cx - (cx - s.x) * f; s.y = cy - (cy - s.y) * f; s.k = k; draw();
    };
    window.pkMapFit = function() {
      var e = g(), v = vp(); if (!e || !v) return;
      var b = e.getBBox(); s.k = Math.min(1.2, v.clientWidth / (b.width + 20), v.clientHeight / (b.height + 20));
      s.x = 10 - b.x * s.k; s.y = 10 - b.y * s.k; draw();
    };
    // Open every question, or close all but the research questions.
    window.pkMapOpenAll = function(all) {
      if (!load()) return;
      open = {}; nodes.forEach(function(n) { if (all || n.depth < 2) open[n.i] = true; });
      render(); pkMapFit();
    };
    function centreOn(n) {
      var v = vp(); if (!v) return;
      s.k = Math.max(s.k, 0.9);
      s.x = v.clientWidth / 2 - (n.x + G.width / 2) * s.k; s.y = v.clientHeight / 2 - (n.y + n.h / 2) * s.k; draw();
    }
    window.pkMapFind = function(id) {
      if (!id || !load()) return;
      var n = nodes.find(function(m) { return m.id === id; }); if (!n) return;
      openTo(n); render(); centreOn(n);
      var box = document.querySelector('#map-pan [data-i=\"' + n.i + '\"]');
      if (box) { box.classList.add('map-found'); box.focus({ preventScroll: true }); }
    };
    window.pkMapOpen = function(id) {
      Shiny.setInputValue('map_endpoint', id, { priority: 'event' });
      setTimeout(function() { var p = document.getElementById('map-page'); if (p) { p.scrollIntoView({ block: 'start' }); p.focus({ preventScroll: true }); } }, 400);
    };
    function activate(box) {
      var n = nodes[+box.getAttribute('data-i') - 1];
      if (n.kind === 'endpoint') pkMapOpen(n.id); else if (n.kids.length) toggle(n.i);
    }
    document.addEventListener('click', function(e) {
      var box = e.target.closest && e.target.closest('#map-pan .map-node'); if (box && !moved) activate(box);
    });
    document.addEventListener('keydown', function(e) {
      var box = e.target.closest && e.target.closest('#map-pan .map-node');
      if (box && (e.key === 'Enter' || e.key === ' ')) { e.preventDefault(); activate(box); }
    });
    var moved = false;
    document.addEventListener('pointerdown', function(e) {
      var v = vp(); if (!v || !v.contains(e.target)) return;
      moved = false; drag = { x: e.clientX - s.x, y: e.clientY - s.y, x0: e.clientX, y0: e.clientY };
    });
    document.addEventListener('pointermove', function(e) {
      if (!drag) return;
      if (Math.abs(e.clientX - drag.x0) + Math.abs(e.clientY - drag.y0) > 4) { moved = true; vp().classList.add('dragging'); }
      if (moved) { s.x = e.clientX - drag.x; s.y = e.clientY - drag.y; draw(); }
    });
    document.addEventListener('pointerup', function() { var v = vp(); drag = null; if (v) v.classList.remove('dragging'); setTimeout(function() { moved = false; }, 0); });
    document.addEventListener('wheel', function(e) {
      var v = vp(); if (!v || !v.contains(e.target)) return;
      e.preventDefault(); var r = v.getBoundingClientRect();
      pkMapZoom(e.deltaY < 0 ? 1.1 : 1 / 1.1, e.clientX - r.left, e.clientY - r.top);
    }, { passive: false });
    window.addEventListener('resize', sizeSvg);
    // First view: the research questions, fitted to the window.
    window.pkMapShown = function() {
      var v = vp(); if (!v || v.clientHeight === 0) return;
      sizeSvg();
      if (!started) { started = true; render(); pkMapFit(); }
    };
  })();
"
