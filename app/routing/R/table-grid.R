# Table inputs as a labelled grid (12 November 2026). A table of means,
# SDs or proportions was a text box taking "one line per group, one number
# per outcome", which researchers found hard to follow. The grid names its
# rows and columns from the levels the user has already typed (the
# field's `rows_from` and `cols_from`), with one box per number. The text
# box stays underneath as the value the server reads (parse_table()), so
# validation, saving and the exports are unchanged; the grid writes into
# it, and "Type it as text instead" shows it for pasting. The grid sits
# above the box, under the field's label.

table_grid_kind <- function(f) {
  path <- f$path %||% ""
  if (grepl("probabilities$", path)) "proportions" else if (grepl("\\.sd$", path)) "sds" else "means"
}

table_grid_note <- function(f) {
  switch(table_grid_kind(f),
    means = paste(
      "Enter the mean you expect in each box. powerkit asks for means rather than one overall effect size because means are easier",
      "to justify, from earlier studies or from the difference that would matter; it works the effect size out from them."),
    sds = "Enter the SD you expect in each box, in the means' units.",
    proportions = "Enter the proportion you expect in each box, from 0 to 1.")
}

table_grid_label <- function(label) sub(":.*$", "", label)
table_grid_layout <- function(f) {
  layout <- sub("^[^:]*:\\s*", "", f$label %||% "")
  if (identical(layout, f$label)) return(NULL)
  paste0("As text: ", layout, ".")
}

# A card that also takes one overall effect size (Cohen's w, partial
# eta-squared) offers it beside the grid: the choice sets the select that
# switches the form over (`alternative` in forms.yaml or with_eta_squared()).
table_grid_alternative_ui <- function(f) {
  alt <- f$alternative
  if (is.null(alt)) return(NULL)
  tags$button(type = "button", class = "btn btn-link btn-sm pk-grid-alt",
    `data-field` = field_input_id(list(id = alt$field)), `data-value` = alt$value,
    onclick = paste("var s = document.getElementById(this.getAttribute('data-field')); if (!s) return;",
      "s.value = this.getAttribute('data-value'); if (window.jQuery) jQuery(s).trigger('change'); else s.dispatchEvent(new Event('change', {bubbles: true}));"),
    alt$label)
}

# The grid's container: the JS builds it from the level fields' values.
table_grid_ui <- function(f) {
  id <- field_input_id(f)
  rows_from <- unlist(f$rows_from %||% "X_levels")
  cols_from <- f$cols_from %||% "Y_levels"
  div(class = "pk-grid", id = paste0(id, "_grid"), `data-target` = id,
    `data-rows` = paste(field_input_id(list(id = rows_from)), collapse = " "),
    `data-cols` = field_input_id(list(id = cols_from)),
    `data-rows-name` = f$rows_name %||% "category of the first variable",
    `data-cols-name` = f$cols_name %||% "category of the second",
    p(class = "small pk-grid-note", table_grid_note(f)),
    div(class = "pk-grid-body"),
    table_grid_example(f),
    div(class = "pk-grid-ways",
      tags$button(type = "button", class = "btn btn-link btn-sm pk-grid-text", "Type it as text instead"),
      table_grid_alternative_ui(f)),
    if (!is.null(table_grid_layout(f))) p(class = "small pk-grid-layout", hidden = NA, table_grid_layout(f)))
}

table_grid_example <- function(f) {
  kind <- table_grid_kind(f)
  vals <- switch(kind, means = list(c("10.0", "20.0"), c("12.5", "23.0")), sds = list(c("4.0", "6.0"), c("4.0", "6.0")),
    proportions = list(c("0.30", "0.50"), c("0.45", "0.60")))
  cells <- function(r) lapply(vals[[r]], tags$td)
  tags$details(class = "pk-grid-example small",
    tags$summary("See an example"),
    p(sprintf("A study with groups called Control and Training, and two outcomes, Recall and Speed, would fill the boxes like this (each number is the %s for that group on that outcome):",
      switch(kind, means = "mean expected", sds = "SD expected", proportions = "proportion expected"))),
    tags$table(class = "pk-grid-table pk-grid-sample",
      tags$thead(tags$tr(tags$th(""), tags$th("Recall"), tags$th("Speed"))),
      tags$tbody(tags$tr(tags$th("Control"), cells(1)), tags$tr(tags$th("Training"), cells(2)))))
}

table_grid_css <- "
  .pk-grid-table { border-collapse: separate; border-spacing: 0.35rem; margin: 0.25rem 0 0.25rem -0.35rem; }
  .pk-grid-table th { font-weight: 600; font-size: 0.9rem; text-align: left; padding: 0 0.25rem; }
  .pk-grid-table thead th { text-align: center; }
  .pk-grid-table input { width: 6.5rem; }
  .pk-grid-sample td { color: #5a6672; text-align: center; padding: 0 0.5rem; }
  .pk-grid-empty { font-size: 0.9rem; color: #5a6672; }
  .pk-grid-wrap { overflow-x: auto; }
  .pk-grid-example { margin: 0.25rem 0; }
  textarea.pk-grid-hidden { position: absolute !important; width: 1px !important; height: 1px !important; overflow: hidden; clip: rect(0 0 0 0); padding: 0 !important; border: 0 !important; }
"

table_grid_js <- "
(function() {
  function levels(id) {
    var el = document.getElementById(id);
    if (!el || !el.value) return [];
    // A count stands for numbered names, as expand_level_counts() reads it.
    var m = el.value.match(/^\\s*([0-9]+)\\s*$/);
    if (m) {
      var n = parseInt(m[1], 10), lab = document.querySelector('label[for=\"' + id + '\"]');
      lab = lab ? lab.textContent.toLowerCase() : '';
      var prefix = /group/.test(lab) ? 'Group' : /condition/.test(lab) ? 'Condition' : /categor/.test(lab) ? 'Category' : /timepoint/.test(lab) ? 'Time' : 'Level';
      if (n >= 2 && n <= 50) return Array.from({ length: n }, function(_, i) { return prefix + ' ' + (i + 1); });
    }
    return el.value.split(',').map(function(s) { return s.trim(); }).filter(function(s) { return s.length; });
  }
  function rowNames(grid) {
    var out = [''];
    grid.getAttribute('data-rows').split(' ').forEach(function(id) {
      var lv = levels(id), next = [];
      out.forEach(function(prefix) { lv.forEach(function(l) { next.push(prefix ? prefix + ' \\u00d7 ' + l : l); }); });
      out = next;
    });
    return out;
  }
  function parse(text) {
    return (text || '').split('\\n').map(function(l) { return l.trim(); }).filter(function(l) { return l.length; })
      .map(function(l) { return l.split(',').map(function(s) { return s.trim(); }); });
  }
  function target(grid) { return document.getElementById(grid.getAttribute('data-target')); }
  function write(grid) {
    var t = target(grid);
    if (!t) return;
    var lines = Array.prototype.map.call(grid.querySelectorAll('.pk-grid-body tbody tr'), function(tr) {
      return Array.prototype.map.call(tr.querySelectorAll('input'), function(i) { return i.value.trim(); }).join(', ');
    });
    var text = lines.every(function(l) { return /^[ ,]*$/.test(l); }) ? '' : lines.join('\\n');
    grid.pkWritten = text;
    if (t.value !== text) { t.value = text; window.jQuery ? jQuery(t).trigger('input').trigger('change') : t.dispatchEvent(new Event('input', { bubbles: true })); }
  }
  function build(grid) {
    var t = target(grid), body = grid.querySelector('.pk-grid-body');
    if (!t || !body || grid.classList.contains('pk-grid-text-on')) return;
    var rows = rowNames(grid), cols = levels(grid.getAttribute('data-cols'));
    var key = rows.join('|') + '#' + cols.join('|');
    if (grid.pkKey === key && grid.pkWritten === t.value) return;
    grid.pkKey = key;
    if (!rows.length || !cols.length) {
      t.classList.add('pk-grid-hidden'); t.setAttribute('tabindex', '-1');
      body.innerHTML = '';
      var p = document.createElement('p'); p.className = 'pk-grid-empty';
      p.textContent = 'Boxes for these numbers appear here once each ' + grid.getAttribute('data-rows-name') + ' and each ' +
        grid.getAttribute('data-cols-name') + ' is named above.';
      body.appendChild(p);
      grid.pkWritten = t.value;
      return;
    }
    var old = parse(t.value);
    var table = document.createElement('table'); table.className = 'pk-grid-table';
    var head = table.createTHead().insertRow();
    head.appendChild(document.createElement('th'));
    cols.forEach(function(c) { var th = document.createElement('th'); th.scope = 'col'; th.textContent = c; head.appendChild(th); });
    var tb = table.createTBody();
    rows.forEach(function(r, i) {
      var tr = tb.insertRow();
      var th = document.createElement('th'); th.scope = 'row'; th.textContent = r; tr.appendChild(th);
      cols.forEach(function(c, j) {
        var inp = document.createElement('input');
        inp.type = 'text'; inp.inputMode = 'decimal'; inp.className = 'form-control form-control-sm';
        inp.setAttribute('aria-label', r + ', ' + c);
        inp.value = (old[i] && old[i][j] !== undefined) ? old[i][j] : '';
        inp.addEventListener('input', function() { write(grid); });
        tr.insertCell().appendChild(inp);
      });
    });
    body.innerHTML = '';
    var wrap = document.createElement('div'); wrap.className = 'pk-grid-wrap'; wrap.appendChild(table);
    body.appendChild(wrap);
    t.classList.add('pk-grid-hidden'); t.setAttribute('tabindex', '-1');
    write(grid);
  }
  function refresh() { document.querySelectorAll('.pk-grid').forEach(build); }
  var pending = false;
  function soon() { if (!pending) { pending = true; setTimeout(function() { pending = false; refresh(); }, 30); } }
  document.addEventListener('click', function(e) {
    var b = e.target.closest && e.target.closest('.pk-grid-text');
    if (!b) return;
    var grid = b.closest('.pk-grid'), t = target(grid);
    if (!t) return;
    var text = grid.classList.toggle('pk-grid-text-on');
    grid.querySelector('.pk-grid-body').hidden = text;
    var layout = grid.querySelector('.pk-grid-layout'); if (layout) layout.hidden = !text;
    b.textContent = text ? 'Use the boxes instead' : 'Type it as text instead';
    if (text) { t.classList.remove('pk-grid-hidden'); t.removeAttribute('tabindex'); t.focus(); }
    else { grid.pkKey = null; build(grid); }
  });
  // A link to the hidden text box (an error message's) goes to the first empty box instead.
  // Only links are redirected: focus set by a script or a test stays on the text box.
  document.addEventListener('click', function(e) {
    var a = e.target.closest && e.target.closest('a'), href = a ? a.getAttribute('href') || '' : '';
    var t = href.indexOf('#f_') === 0 && document.getElementById(href.slice(1));
    if (!t || !t.classList.contains('pk-grid-hidden')) return;
    var grid = document.getElementById(t.id + '_grid');
    var box = grid && (Array.prototype.find.call(grid.querySelectorAll('.pk-grid-body input'), function(i) { return !i.value; }) ||
      grid.querySelector('.pk-grid-body input, .pk-grid-text'));
    if (!box) return;
    e.preventDefault();
    box.scrollIntoView({ block: 'center' });
    box.focus();
  });
  document.addEventListener('input', function(e) { if (!(e.target.closest && e.target.closest('.pk-grid'))) soon(); });
  if (window.jQuery) jQuery(document).on('change shiny:value shiny:updateinput', soon);
  document.addEventListener('change', soon);
  new MutationObserver(function(m) { if (m.some(function(r) { return r.addedNodes.length; })) soon(); })
    .observe(document.documentElement, { childList: true, subtree: true });
})();
"
