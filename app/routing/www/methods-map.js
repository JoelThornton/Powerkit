// The methods map in Labs (R/map.R builds the data and the page).
//
// It answers the questions a researcher brings to it, in this order:
// where is a study like mine, what is it (in plain words, and which test),
// what is it next to (simpler designs that lead to it, and the ways to
// change it), and can powerkit plan it. So it has two states:
//
// - The whole map: the families of analyses as regions, the analyses
//   inside them, coloured by test, family or status. Search suggests
//   analyses as you type.
// - An analysis in focus: it moves to the middle, the designs that lead to
//   it gather on its left and the ways to change it on its right, each
//   line saying what changes. Clicking one moves the focus there, and the
//   trail at the top leads back.
//
// Drawn with Cytoscape.js. Nothing here is calculated.
(function() {
  var cy = null, data = null, started = false, running = null, first = true;
  var focusId = null, trail = [], colour = 'test', searchTimer = null, suggestAt = -1;
  var hues = ['#7c9cff', '#ff7eb6', '#4fe0b6', '#ffd166', '#c792ea', '#5cc8ff', '#ff9f68', '#9be15d', '#f78fb3', '#b0c4de',
              '#6ee7f9', '#fca5a5', '#a5b4fc', '#fde68a', '#86efac'];
  var statusColour = { runs: '#5cc8ff', soon: '#ffb347', not: '#9aa7c7' };
  var statusText = { runs: 'Calculates in powerkit', soon: 'Coming', not: 'Not in powerkit yet' };
  var tests = {}, familyHue = {};

  function load() {
    if (data) return data;
    var d = document.getElementById('map-data'); if (!d) return null;
    data = JSON.parse(d.textContent);
    (data.tests || []).forEach(function(t) { tests[t.id] = t; });
    (data.families || []).forEach(function(f, i) { familyHue[f.id] = hues[i % hues.length]; });
    return data;
  }
  function esc(s) { var d = document.createElement('div'); d.textContent = s == null ? '' : s; return d.innerHTML; }
  function el(id) { return document.getElementById(id); }
  function value(id, fallback) { var e = el(id); return e ? e.value : fallback; }
  function reduceMotion() { return window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches; }
  // "with three or more groups becomes" reads, on a line, as "with three
  // or more groups".
  function shortWords(s) { return (s || '').replace(/ (becomes|is)$/, ''); }

  // The questions of "Help me choose" are kept (hidden) so that the panel
  // can give a route to each analysis.
  function elements() {
    var d = load(), els = [];
    els.push({ data: { id: 'root', label: 'Your study', kind: 'root' } });
    d.nodes.forEach(function(n) {
      var x = Object.assign({}, n);
      if (n.kind === 'family') x.hue = familyHue[n.family] || '#7c9cff';
      if (n.kind === 'endpoint') {
        x.plain = n.label;
        x.cTest = (tests[n.test] || {}).colour || '#9aa7c7';
        x.cFamily = familyHue[n.family] || '#9aa7c7';
        x.cStatus = statusColour[n.status];
        x.col = x.cTest;
      }
      els.push({ data: x });
      if (n.kind === 'hub') els.push({ data: { id: 'root-' + n.id, source: 'root', target: n.id, label: '' } });
    });
    d.edges.forEach(function(e) {
      var x = Object.assign({}, e);
      if (e.rel) x.short = shortWords(e.label);
      els.push({ data: x });
    });
    return els;
  }

  function style() {
    return [
      { selector: 'node', style: { 'label': 'data(label)', 'text-wrap': 'wrap', 'text-max-width': 150, 'font-size': 12,
          'font-family': 'Inter, system-ui, sans-serif', 'color': '#e8eefc', 'text-outline-color': '#050a1f', 'text-outline-width': 2,
          'text-valign': 'bottom', 'text-margin-y': 6, 'min-zoomed-font-size': 7, 'z-index': 10,
          'transition-property': 'opacity, background-color, underlay-color, border-color', 'transition-duration': 350 } },
      { selector: 'node[kind = "root"], node[kind = "hub"], node[kind = "question"]', style: { 'display': 'none' } },
      { selector: 'node[kind = "endpoint"]', style: { 'width': 22, 'height': 22, 'background-color': 'data(col)',
          'underlay-color': 'data(col)', 'underlay-opacity': 0.3, 'underlay-padding': 8, 'underlay-shape': 'ellipse',
          'border-width': 2, 'border-color': '#ffffff', 'border-opacity': 0.6 } },
      { selector: 'node[kind = "endpoint"][status = "runs"]', style: { 'width': 28, 'height': 28 } },
      { selector: 'node[kind = "endpoint"][status = "not"]', style: { 'border-style': 'dashed', 'background-opacity': 0.65 } },
      { selector: 'node[kind = "family"]', style: { 'shape': 'ellipse', 'width': 'data(size)', 'height': 'data(size)',
          'background-color': 'data(hue)', 'background-opacity': 0.07, 'border-width': 2, 'border-color': 'data(hue)', 'border-opacity': 0.28,
          'underlay-color': 'data(hue)', 'underlay-opacity': 0.12, 'underlay-padding': 40, 'underlay-shape': 'ellipse',
          'text-valign': 'top', 'text-margin-y': -14, 'font-size': 30, 'font-weight': 700,
          'color': 'data(hue)', 'text-outline-width': 0, 'text-max-width': 520, 'min-zoomed-font-size': 0, 'z-index': 0 } },
      { selector: 'edge', style: { 'display': 'none' } },
      { selector: 'edge[rel]', style: { 'display': 'element', 'curve-style': 'unbundled-bezier', 'control-point-distances': 60,
          'control-point-weights': 0.5, 'line-color': '#ffe8a3', 'target-arrow-color': '#ffe8a3', 'target-arrow-shape': 'triangle',
          'opacity': 0, 'width': 1.6, 'arrow-scale': 0.7, 'events': 'no', 'label': '', 'z-index': 1 } },
      { selector: 'edge[rel].path', style: { 'opacity': 0.85, 'width': 2.4, 'z-index': 20 } },
      { selector: '.dim', style: { 'opacity': 0.14 } },
      { selector: 'node[kind = "family"].dim', style: { 'opacity': 0.35 } },
      { selector: 'node.hover', style: { 'font-size': 15, 'z-index': 30, 'min-zoomed-font-size': 0 } },
      { selector: 'node[kind = "family"].hover', style: { 'border-opacity': 0.6, 'background-opacity': 0.12 } },
      { selector: 'node.hit', style: { 'border-color': '#ffe08a', 'border-width': 4, 'border-opacity': 1,
          'underlay-opacity': 0.6, 'z-index': 30 } },
      // An analysis in focus, and its neighbours, as cards.
      { selector: '.away', style: { 'opacity': 0, 'events': 'no' } },
      { selector: 'node.card', style: { 'shape': 'round-rectangle', 'width': 'label', 'height': 'label', 'padding': 14,
          'background-color': 'data(col)', 'background-opacity': 0.16, 'border-color': 'data(col)', 'border-width': 2,
          'border-opacity': 0.9, 'border-style': 'solid', 'underlay-padding': 6, 'underlay-shape': 'round-rectangle', 'underlay-opacity': 0.12,
          'text-valign': 'center', 'text-margin-y': 0, 'font-size': 20, 'text-max-width': 250, 'color': '#ffffff',
          'text-outline-width': 0, 'min-zoomed-font-size': 0, 'z-index': 30 } },
      { selector: 'node.card[status = "not"]', style: { 'border-style': 'dashed' } },
      { selector: 'node.card.centre', style: { 'font-size': 27, 'font-weight': 700, 'padding': 26, 'text-max-width': 330,
          'background-opacity': 0.32, 'border-width': 3, 'underlay-opacity': 0.4, 'underlay-padding': 16 } },
      { selector: 'node.card.hover', style: { 'background-opacity': 0.34 } },
      { selector: 'node[kind = "head"]', style: { 'shape': 'rectangle', 'width': 1, 'height': 1, 'background-opacity': 0, 'border-width': 0,
          'label': 'data(label)', 'text-valign': 'center', 'text-max-width': 400, 'font-size': 18, 'font-weight': 700, 'color': '#a9b6d8',
          'text-outline-width': 0, 'text-transform': 'uppercase', 'min-zoomed-font-size': 0, 'events': 'no' } },
      { selector: 'edge[rel].focus', style: { 'opacity': 0.9, 'width': 2, 'curve-style': 'straight', 'arrow-scale': 1,
          'label': 'data(short)', 'font-size': 16, 'color': '#fff4cf', 'text-wrap': 'wrap', 'text-max-width': 190,
          'text-background-color': '#0b1433', 'text-background-opacity': 0.92, 'text-background-padding': 5,
          'text-background-shape': 'round-rectangle', 'text-outline-width': 0, 'min-zoomed-font-size': 0, 'z-index': 25 } }
    ];
  }

  function checked(group) {
    return Array.prototype.map.call(document.querySelectorAll('.map-sidebar input[data-group="' + group + '"]:checked'),
      function(i) { return i.value; });
  }
  function visible(n) { return n.style('display') !== 'none'; }
  function overlaps(a, b) { return a.some(function(x) { return b.indexOf(x) >= 0; }); }

  // The whole map: each family a region, its analyses on a sunflower
  // spiral inside it, and the regions packed round the middle.
  var SPACING = 150;
  function earth() {
    var pos = {}, placed = [];
    cy.nodes('[kind = "family"]').filter(visible).forEach(function(f, i) {
      var members = cy.nodes('[kind = "endpoint"]').filter(function(n) { return n.data('family') === f.data('family') && visible(n); });
      var k = members.length;
      var r = SPACING * Math.sqrt(k) * 0.62 + 150;
      var a = i * 2.39996, d = 0, x = 0, y = 0;
      for (var tries = 0; tries < 400; tries++) {
        x = d * Math.cos(a); y = d * Math.sin(a);
        if (placed.every(function(p) { return Math.hypot(p.x - x, p.y - y) >= p.r + r + 90; })) break;
        d += 30;
      }
      placed.push({ x: x, y: y, r: r });
      pos[f.id()] = { x: x, y: y };
      f.data('size', 2 * r);
      members.forEach(function(n, j) {
        var rr = k === 1 ? 0 : SPACING * 0.62 * Math.sqrt(j + 0.5), aa = j * 2.39996 + i;
        pos[n.id()] = { x: x + rr * Math.cos(aa), y: y + rr * Math.sin(aa) };
      });
    });
    var shown = cy.nodes().filter(function(n) { return pos[n.id()]; });
    run(shown.layout({ name: 'preset', positions: function(n) { return pos[n.id()]; }, animate: !first && !reduceMotion(),
      animationDuration: 650, animationEasing: 'ease-in-out-cubic', fit: false }), afterEarth);
  }
  function run(layout, then) {
    if (running) running.stop();
    running = layout;
    if (then) running.one('layoutstop', then);
    running.run();
  }
  // After the whole map is laid out: the first time, swoop in from far
  // away; after that, show the search matches or everything.
  function afterEarth() {
    var all = cy.nodes('[kind = "family"]').filter(visible);
    if (first) {
      first = false;
      cy.zoom(cy.minZoom());
      cy.center(all);
      fitTo(all, 1, 1600);
      return;
    }
    var hits = cy.nodes('.hit');
    fitTo(hits.length ? hits : all, 1.1);
  }

  // Fit some nodes into the part of the map the panels leave free. A long
  // move pulls out first and then dives in, like a globe.
  function frame(eles, zoomCap, box) {
    var wide = window.innerWidth > 800;
    var side = el('map-sidebar');
    var left = side && !side.classList.contains('closed') && wide ? side.offsetWidth + 24 : 0;
    var details = el('map-details');
    var right = details && !details.hidden && wide ? details.offsetWidth + 24 : 0;
    var bottom = details && !details.hidden && !wide ? Math.min(details.offsetHeight, cy.height() * 0.5) + 10 : 70;
    var top = 100;
    var w = Math.max(cy.width() - left - right - 80, 120), h = Math.max(cy.height() - top - bottom - 30, 120);
    var bb = box || eles.boundingBox({ includeLabels: true, includeUnderlays: false });
    var z = Math.min(w / Math.max(bb.w, 1), h / Math.max(bb.h, 1), zoomCap || 1.2);
    z = Math.max(z, cy.minZoom());
    return { zoom: z, pan: { x: left + 40 + w / 2 - z * (bb.x1 + bb.w / 2), y: top + 15 + h / 2 - z * (bb.y1 + bb.h / 2) } };
  }
  function fitTo(eles, zoomCap, duration) {
    if (!eles || !eles.length) return;
    var target = frame(eles, zoomCap);
    cy.stop();
    if (reduceMotion()) { cy.viewport(target); scaleNames(); return; }
    var ext = cy.extent(), cx = (ext.x1 + ext.x2) / 2, cyy = (ext.y1 + ext.y2) / 2;
    var bb = eles.boundingBox({ includeLabels: false, includeUnderlays: false });
    var dist = Math.hypot(bb.x1 + bb.w / 2 - cx, bb.y1 + bb.h / 2 - cyy) * target.zoom / Math.max(cy.width(), 1);
    if (dist > 1.2 && !duration) {
      var mid = Math.max(Math.min(cy.zoom(), target.zoom) * 0.45, cy.minZoom());
      cy.animate({ zoom: { level: mid, position: { x: (cx + bb.x1 + bb.w / 2) / 2, y: (cyy + bb.y1 + bb.h / 2) / 2 } } },
        { duration: 450, easing: 'ease-in-out-cubic', complete: function() {
          cy.animate(frame(eles, zoomCap), { duration: 750, easing: 'ease-in-out-cubic' });
        } });
    } else {
      cy.animate(target, { duration: duration || 700, easing: 'ease-in-out-cubic' });
    }
  }
  window.pkMapFit = function() {
    if (!cy) return;
    if (focusId) { fitTo(cy.nodes('.card, [kind = "head"]'), 1.1); return; }
    fitTo(cy.nodes('[kind = "family"]').filter(visible));
  };
  window.pkMapZoom = function(f) {
    if (!cy) return;
    cy.stop();
    var ext = cy.extent();
    cy.animate({ zoom: { level: Math.min(Math.max(cy.zoom() * f, cy.minZoom()), cy.maxZoom()),
      position: { x: (ext.x1 + ext.x2) / 2, y: (ext.y1 + ext.y2) / 2 } } }, { duration: 250 });
  };
  // Far away, a family's name sits in its region at a steady size on
  // screen; close up, it moves to the region's edge and the analyses'
  // names come out.
  function scaleNames() {
    if (!cy || focusId) return;
    var z = cy.zoom(), far = z < 0.42;
    cy.nodes('[kind = "family"]').forEach(function(n) {
      var size = n.data('size') || 400;
      n.style(far ? { 'font-size': Math.min(15 / z, size / 5), 'text-max-width': size * 0.9, 'text-valign': 'center', 'text-margin-y': 0 }
        : { 'font-size': 30, 'text-max-width': size, 'text-valign': 'top', 'text-margin-y': -14 });
    });
    cy.nodes('[kind = "endpoint"]').style({ 'font-size': 12, 'text-max-width': 150 });
  }

  // Colour by the test, the family or the status, with the key along the
  // bottom; clicking a key entry hides or shows those analyses.
  window.pkMapColour = function(by) {
    if (by) colour = by;
    if (!cy) return;
    cy.nodes('[kind = "endpoint"]').forEach(function(n) {
      n.data('col', colour === 'family' ? n.data('cFamily') : colour === 'status' ? n.data('cStatus') : n.data('cTest'));
    });
    document.querySelectorAll('.map-colour button').forEach(function(b) {
      b.setAttribute('aria-pressed', b.getAttribute('data-colour') === colour ? 'true' : 'false');
    });
    legend();
  };
  function legend() {
    var box = el('map-key'); if (!box || !cy) return;
    var items = [];
    if (colour === 'test') {
      document.querySelectorAll('.map-sidebar input[data-group="test"]').forEach(function(i) {
        var t = tests[i.value] || {};
        items.push({ group: 'test', value: i.value, label: t.label || i.value, colour: t.colour, on: i.checked, title: t.text });
      });
    } else if (colour === 'status') {
      ['runs', 'soon', 'not'].forEach(function(k) {
        var i = document.querySelector('.map-sidebar input[data-group="status"][value="' + k + '"]');
        items.push({ group: 'status', value: k, label: statusText[k], colour: statusColour[k], on: !i || i.checked });
      });
    }
    // Coloured by family, the regions are the key.
    box.hidden = items.length === 0;
    box.innerHTML = items.map(function(it) {
      return '<button type="button" aria-pressed="' + (it.on ? 'true' : 'false') + '" data-group="' + it.group + '" data-value="' + esc(it.value) + '"' +
        (it.title ? ' title="' + esc(it.title) + '"' : '') + '><span class="dot" style="background:' + esc(it.colour) + '"></span>' +
        esc(it.label) + '</button>';
    }).join('');
  }
  document.addEventListener('click', function(e) {
    var b = e.target.closest && e.target.closest('#map-key button');
    if (!b) return;
    var i = document.querySelector('.map-sidebar input[data-group="' + b.getAttribute('data-group') + '"][value="' + b.getAttribute('data-value') + '"]');
    if (i) i.checked = !i.checked;
    pkMapFilter();
  });

  // An analysis is on the map when it matches every filter.
  window.pkMapFilter = function() {
    if (!cy) return;
    if (focusId) leaveFocus();
    var rq = checked('rq'), outcome = checked('outcome'), times = checked('times'), status = checked('status'), test = checked('test');
    var shown = cy.collection();
    cy.batch(function() {
      cy.nodes('[kind = "endpoint"]').forEach(function(n) {
        var d = n.data();
        var ok = !!d.family && overlaps(d.rq, rq) && overlaps(d.outcome, outcome) && overlaps(d.times, times) &&
          status.indexOf(d.status) >= 0 && test.indexOf(d.test) >= 0;
        n.style('display', ok ? 'element' : 'none');
        if (ok) shown = shown.union(n);
      });
      cy.nodes('[kind = "family"]').forEach(function(n) {
        n.style('display', shown.some(function(x) { return x.data('family') === n.data('family'); }) ? 'element' : 'none');
      });
    });
    var count = el('map-count'), total = cy.nodes('[kind = "endpoint"]').filter(function(n) { return n.data('family'); }).length;
    if (count) count.textContent = shown.length === total ? total + ' analyses' : shown.length + ' of ' + total + ' analyses';
    legend();
    highlight(false);
    earth();
  };
  window.pkMapLayout = window.pkMapFilter;

  // Search: suggestions under the box as you type, and the matches lit up
  // on the whole map.
  function matches(q) {
    if (!q) return [];
    var words = q.toLowerCase().split(/\s+/).filter(Boolean), out = [];
    cy.nodes('[kind = "endpoint"]').forEach(function(n) {
      var d = n.data();
      var text = (d.plain + ' ' + d.standard + ' ' + ((tests[d.test] || {}).label || '') + ' ' + (d.familyLabel || '')).toLowerCase();
      if (!words.every(function(w) { return text.indexOf(w) >= 0; })) return;
      var name = (d.plain + ' ' + d.standard).toLowerCase();
      out.push({ n: n, score: (name.indexOf(words[0]) >= 0 ? 0 : 1) + (d.status === 'runs' ? 0 : 0.5) });
    });
    out.sort(function(a, b) { return a.score - b.score; });
    return out.map(function(x) { return x.n; });
  }
  function highlight(fly) {
    var q = (value('map_search', '') || '').trim();
    var hits = q ? matches(q).filter(visible) : cy.collection();
    cy.batch(function() {
      cy.elements().removeClass('dim hit');
      if (q && !focusId) {
        cy.collection(hits).addClass('hit');
        cy.nodes('[kind = "endpoint"], [kind = "family"]').not('.hit').addClass('dim');
      }
    });
    scaleNames();
    if (fly && q && hits.length && !focusId) fitTo(cy.collection(hits), 1.1);
    if (fly && !q && !focusId) pkMapFit();
  }
  function suggest() {
    var box = el('map-suggest'), q = (value('map_search', '') || '').trim();
    if (!box) return;
    var list = q ? matches(q).slice(0, 7) : [];
    suggestAt = -1;
    if (!q) { box.hidden = true; box.innerHTML = ''; return; }
    box.innerHTML = list.length ? list.map(function(n, i) {
      var d = n.data(), t = tests[d.test] || {};
      return '<li role="option" id="map-sug-' + i + '" data-id="' + esc(d.id) + '"><span class="dot" style="background:' + esc(t.colour || '#9aa7c7') + '"></span>' +
        '<span class="sug-name">' + esc(d.plain) + '</span><span class="sug-meta">' + esc(t.label || '') +
        (d.status === 'runs' ? '' : ' · ' + esc(d.statusText)) + '</span></li>';
    }).join('') : '<li class="sug-none">No analysis matches “' + esc(q) + '”.</li>';
    box.hidden = false;
  }
  window.pkMapSearch = function() {
    if (!cy) return;
    suggest();
    clearTimeout(searchTimer);
    searchTimer = setTimeout(function() { highlight(true); }, 350);
  };
  window.pkMapSearchKey = function(e) {
    var box = el('map-suggest'), items = box ? box.querySelectorAll('li[data-id]') : [];
    if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
      if (!items.length) return;
      e.preventDefault();
      suggestAt = (suggestAt + (e.key === 'ArrowDown' ? 1 : items.length - 1)) % items.length;
      items.forEach(function(li, i) { li.classList.toggle('on', i === suggestAt); li.setAttribute('aria-selected', i === suggestAt ? 'true' : 'false'); });
      e.target.setAttribute('aria-activedescendant', 'map-sug-' + suggestAt);
    } else if (e.key === 'Enter') {
      e.preventDefault();
      var li = items[Math.max(suggestAt, 0)];
      if (li) pick(li.getAttribute('data-id'));
    } else if (e.key === 'Escape') {
      e.stopPropagation();
      if (box) box.hidden = true;
    }
  };
  function pick(id) {
    var box = el('map-suggest'); if (box) box.hidden = true;
    var s = el('map_search'); if (s) { s.value = ''; s.blur(); }
    highlight(false);
    pkMapGo(id);
  }
  window.pkMapFirstHit = function() { var hits = matches((value('map_search', '') || '').trim()); if (hits.length) pick(hits[0].id()); };
  document.addEventListener('mousedown', function(e) {
    var li = e.target.closest && e.target.closest('#map-suggest li[data-id]');
    if (li) { e.preventDefault(); pick(li.getAttribute('data-id')); return; }
    var box = el('map-suggest');
    if (box && !box.hidden && !(e.target.closest && e.target.closest('.map-search'))) box.hidden = true;
  });

  window.pkMapNames = function() {
    if (!cy) return;
    var standard = value('map_names', 'plain') === 'standard';
    cy.nodes('[kind = "endpoint"]').forEach(function(n) {
      n.data('label', standard && n.data('standard') ? n.data('standard') : n.data('plain'));
    });
  };
  window.pkMapReset = function() {
    document.querySelectorAll('.map-sidebar input[type=checkbox]').forEach(function(i) { i.checked = true; });
    var s = el('map_search'); if (s) s.value = '';
    pkMapClose();
    pkMapFilter();
  };
  window.pkMapPanel = function() {
    var p = el('map-sidebar'), b = document.querySelector('.map-panel-toggle');
    var closed = p.classList.toggle('closed');
    if (b) b.setAttribute('aria-expanded', closed ? 'false' : 'true');
    if (!closed) { var f = p.querySelector('select, input'); if (f) f.focus(); }
  };

  // The answers on the shortest route to an analysis through the design
  // finder's questions.
  function route(n) {
    var graph = cy.elements().not('edge[rel]').not('[kind = "family"]').not('[kind = "head"]');
    var path = graph.dijkstra({ root: cy.$id('root'), directed: true }).pathTo(n), steps = [];
    path.forEach(function(x) {
      if (x.isEdge()) { if (x.data('label')) steps.push(x.data('label')); }
      else if (x.data('kind') === 'hub') steps.push(x.data('label'));
    });
    return steps;
  }
  // The analyses an analysis comes from, and the ones it leads to.
  function relatives(n) {
    var from = [], to = [];
    cy.edges('[rel]').forEach(function(e) {
      if (e.source().id() === n.id()) to.push({ other: e.target(), edge: e });
      else if (e.target().id() === n.id()) from.push({ other: e.source(), edge: e });
    });
    return { from: from, to: to };
  }

  // Focus on an analysis: it goes to the middle, the analyses that lead to
  // it on an arc to its left and the ways to change it on an arc to its
  // right, each joined by a line that says what changes.
  var ARC = 600;
  function arc(list, centre, pos) {
    var k = list.length; if (!k) return null;
    var step = k > 1 ? Math.min(24, 150 / (k - 1)) : 0, start = centre - step * (k - 1) / 2;
    var ys = [];
    list.forEach(function(r, i) {
      var a = (start + step * i) * Math.PI / 180;
      pos[r.other.id()] = { x: ARC * Math.cos(a), y: ARC * Math.sin(a) };
      ys.push(pos[r.other.id()].y);
    });
    return Math.min.apply(null, ys);
  }
  function focusOn(n) {
    var rels = relatives(n), pos = {};
    var seen = {}; seen[n.id()] = 1;
    rels.to = rels.to.filter(function(r) { if (seen[r.other.id()]) return false; seen[r.other.id()] = 1; return true; });
    rels.from = rels.from.filter(function(r) { if (seen[r.other.id()]) return false; seen[r.other.id()] = 1; return true; });
    // With nothing on one side, the other's arc stays where it is, so
    // left always means "leads here" and right "ways to change it".
    pos[n.id()] = { x: 0, y: 0 };
    var topTo = arc(rels.to, 0, pos), topFrom = arc(rels.from, 180, pos);
    var cards = n.union(cy.collection(rels.to.concat(rels.from).map(function(r) { return r.other; })));
    var lines = cy.collection(rels.to.concat(rels.from).map(function(r) { return r.edge; }));
    cy.remove('node[kind = "head"]');
    var heads = [];
    if (topTo !== null) heads.push({ group: 'nodes', data: { id: 'head-to', kind: 'head', label: 'Ways to change it' }, position: { x: ARC + 20, y: Math.min(topTo, -40) - 80 } });
    if (topFrom !== null) heads.push({ group: 'nodes', data: { id: 'head-from', kind: 'head', label: 'Leads here' }, position: { x: -ARC - 20, y: Math.min(topFrom, -40) - 80 } });
    cy.batch(function() {
      cy.elements().removeClass('card centre focus path hit dim hover').addClass('away');
      cards.removeClass('away').addClass('card').style('display', 'element');
      n.addClass('centre');
      lines.removeClass('away').addClass('focus');
      cards.style({ 'font-size': '', 'text-max-width': '' });
    });
    var h = cy.add(heads);
    h.addClass('away');
    focusId = n.id();
    var stage = el('map-stage'); if (stage) stage.classList.add('focusing');
    var layout = cards.layout({ name: 'preset', positions: function(x) { return pos[x.id()]; }, fit: false,
      animate: !reduceMotion(), animationDuration: 700, animationEasing: 'ease-in-out-cubic' });
    details(n, rels);
    // The view moves with the cards, to where they will be.
    var xs = [], ys = [];
    Object.keys(pos).forEach(function(k) { xs.push(pos[k].x); ys.push(pos[k].y); });
    h.forEach(function(x) { xs.push(x.position('x')); ys.push(x.position('y')); });
    var box = { x1: Math.min.apply(null, xs) - 170, x2: Math.max.apply(null, xs) + 170, y1: Math.min.apply(null, ys) - 60, y2: Math.max.apply(null, ys) + 60 };
    box.w = box.x2 - box.x1; box.h = box.y2 - box.y1;
    var target = frame(cards, 1.05, box);
    cy.stop();
    run(layout, function() { h.removeClass('away'); });
    if (reduceMotion()) cy.viewport(target); else cy.animate(target, { duration: 700, easing: 'ease-in-out-cubic' });
    drawTrail();
  }
  function leaveFocus() {
    focusId = null;
    var stage = el('map-stage'); if (stage) stage.classList.remove('focusing');
    trail = [];
    cy.remove('node[kind = "head"]');
    cy.elements().removeClass('card centre focus away path');
    cy.nodes('[kind = "endpoint"]').style({ 'font-size': '', 'text-max-width': '' });
    drawTrail();
  }
  window.pkMapWhole = function(keepClosed) {
    if (!cy) return;
    var wasFocus = !!focusId;
    if (keepClosed !== true) showStart();
    if (wasFocus) pkMapFilter(); else pkMapFit();
  };
  window.pkMapGo = function(id, keepTrail) {
    if (!cy) return;
    var n = cy.$id(id); if (!n.length || n.data('kind') !== 'endpoint') return;
    hideStart();
    var at = trail.indexOf(id);
    if (at >= 0) trail = trail.slice(0, at + 1);
    else if (keepTrail === false) trail = [id];
    else trail.push(id);
    focusOn(n);
  };
  window.pkMapBack = function() {
    if (trail.length > 1) { trail.pop(); pkMapGo(trail[trail.length - 1]); }
    else pkMapWhole();
  };
  function drawTrail() {
    var box = el('map-trail'); if (!box) return;
    if (!focusId) { box.hidden = true; box.innerHTML = ''; return; }
    var items = ['<button type="button" onclick="pkMapWhole()">All analyses</button>'];
    trail.forEach(function(id, i) {
      var n = cy.$id(id); if (!n.length) return;
      items.push(i === trail.length - 1 ? '<span aria-current="location">' + esc(n.data('label')) + '</span>'
        : '<button type="button" data-id="' + esc(id) + '" onclick="pkMapGo(this.dataset.id)">' + esc(n.data('label')) + '</button>');
    });
    // A long trail keeps its start and its last steps.
    if (items.length > 5) items = items.slice(0, 1).concat(['<span>…</span>'], items.slice(-3));
    box.innerHTML = items.join('<span class="sep" aria-hidden="true">›</span>');
    box.hidden = false;
  }

  function relList(list, title, from) {
    if (!list.length) return '';
    return '<h5>' + title + '</h5><ul class="map-rel">' + list.map(function(r) {
      var t = tests[r.other.data('test')] || {};
      return '<li><button type="button" data-id="' + esc(r.other.id()) + '" onclick="pkMapGo(this.dataset.id)">' +
        '<span class="rel-change">' + esc(from ? r.other.data('label') + ', ' + r.edge.data('label') + ' this' : 'This, ' + r.edge.data('label') + '…') + '</span>' +
        (from ? '' : '<span class="rel-name"><span class="dot" style="background:' + esc(t.colour || '#9aa7c7') + '"></span>' + esc(r.other.data('label')) + '</span>') +
        '</button></li>';
    }).join('') + '</ul>';
  }
  function details(n, rels) {
    var box = el('map-details'); if (!box) return;
    var d = n.data(), html = '<button type="button" class="map-close" aria-label="Close" onclick="pkMapClose()">×</button>';
    if (d.kind === 'endpoint') {
      var t = tests[d.test] || {}, steps = route(n);
      rels = rels || relatives(n);
      html += '<div class="map-tags"><span class="map-tag test" style="--test:' + esc(t.colour || '#9aa7c7') + '"><span class="dot"></span>' + esc(t.label || '') + '</span>' +
        '<span class="map-tag ' + d.status + '">' + esc(d.statusText) + '</span></div>' +
        '<h4>' + esc(d.plain) + '</h4>' +
        (d.standard && d.standard !== d.plain ? '<p class="map-usual">Usually called <strong>' + esc(d.standard) + '</strong></p>' : '') +
        (d.familyLabel ? '<p class="map-family">In ' + esc(d.familyLabel) + '</p>' : '') +
        '<div class="map-actions">' +
        (d.status === 'not' ? '' : '<button type="button" class="btn btn-info btn-sm" data-id="' + esc(d.id) + '" onclick="pkMapPlan(this.dataset.id)">Plan this study</button>') +
        '<button type="button" class="btn btn-outline-light btn-sm" data-id="' + esc(d.id) + '" onclick="pkMapOpen(this.dataset.id)">Read about it</button></div>' +
        '<h5>The test</h5><div class="map-test" style="--test:' + esc(t.colour || '#9aa7c7') + '">' + esc(t.text || '') + '</div>' +
        relList(rels.to, 'Ways to change it', false) +
        relList(rels.from, 'Leads here', true) +
        '<details class="map-route"><summary>How “Help me choose” gets here</summary>' +
        (steps.length ? '<ol>' + steps.map(function(s) { return '<li>' + esc(s) + '</li>'; }).join('') + '</ol>'
          : '<p class="small mb-0">It isn\'t reached by the questions: choose it by name, in “I know my analysis”.</p>') + '</details>';
      box.innerHTML = html;
      box.hidden = false;
      box.classList.remove('is-start');
      box.scrollTop = 0;
      return;
    }
    if (d.kind === 'family') {
      var members = cy.nodes('[kind = "endpoint"]').filter(function(x) { return x.data('family') === d.family && visible(x); });
      var runs = members.filter(function(x) { return x.data('status') === 'runs'; }).length;
      html += '<h4>' + esc(d.label) + '</h4><p class="small">' + members.length + ' analyses; powerkit calculates ' + runs + ' of them. Choose one to see what it is and what it is next to.</p>' +
        '<ul class="map-rel">' + members.map(function(x) {
          var t = tests[x.data('test')] || {};
          return '<li><button type="button" data-id="' + esc(x.id()) + '" onclick="pkMapGo(this.dataset.id, false)"><span class="rel-name">' +
            '<span class="dot" style="background:' + esc(t.colour || '#9aa7c7') + '"></span>' + esc(x.data('label')) + '</span>' +
            '<span class="rel-change">' + esc(t.label || '') + (x.data('status') === 'runs' ? '' : ' · ' + esc(x.data('statusText'))) + '</span></button></li>';
        }).join('') + '</ul>';
      box.innerHTML = html;
      box.hidden = false;
      box.classList.remove('is-start');
      box.scrollTop = 0;
      fitTo(members.union(n), 1.0);
    }
  }
  // With nothing chosen, the panel offers ways to start.
  var startHtml = null;
  function showStart() {
    var b = el('map-details'); if (!b || startHtml === null) return;
    b.innerHTML = startHtml; b.hidden = false; b.scrollTop = 0; b.classList.add('is-start');
  }
  window.pkMapClose = function() {
    var b = el('map-details'); if (!b) return;
    if (cy) cy.edges().removeClass('path');
    if (b.classList.contains('is-start') || focusId) { b.hidden = true; if (focusId) pkMapWhole(true); return; }
    showStart();
  };
  // An analysis's card opens under the map, so full screen closes first.
  window.pkMapOpen = function(id) {
    pkMapFull(false);
    Shiny.setInputValue('map_endpoint', id, { priority: 'event' });
    setTimeout(function() {
      var p = el('map-page');
      if (p) { p.scrollIntoView({ block: 'start' }); p.focus({ preventScroll: true }); }
    }, 400);
  };
  // Planning starts on "Plan a power analysis", at the analysis's card.
  window.pkMapPlan = function(id) {
    pkMapFull(false);
    Shiny.setInputValue('map_plan', id, { priority: 'event' });
  };

  function hideStart() {}

  // Full screen: the map covers the window; Esc or the button leaves.
  window.pkMapFull = function(on) {
    var stage = el('map-stage'); if (!stage) return;
    var full = on === undefined ? !stage.classList.contains('map-full') : !!on;
    stage.classList.toggle('map-full', full);
    document.body.classList.toggle('map-full-open', full);
    var b = el('map-full-btn'); if (b) b.textContent = full ? 'Exit full screen' : 'Full screen';
    if (!started) { pkMapShown(); return; }
    if (cy) setTimeout(function() { cy.resize(); pkMapFit(); }, 60);
    if (full && b) b.focus({ preventScroll: true });
  };
  document.addEventListener('keydown', function(e) {
    if (e.key !== 'Escape') return;
    var stage = el('map-stage');
    if (!stage || !stage.classList.contains('map-full')) return;
    if (focusId) { pkMapBack(); return; }
    var details = el('map-details');
    if (details && !details.hidden) { pkMapClose(); return; }
    pkMapFull(false);
  });

  function start() {
    var box = el('map-canvas');
    if (!box || !window.cytoscape || !load()) return false;
    cy = cytoscape({ container: box, elements: elements(), style: style(), wheelSensitivity: 0.3, minZoom: 0.03, maxZoom: 2.5,
      layout: { name: 'preset' } });
    window.pkMapGraph = cy;
    var d0 = el('map-details'); if (d0) startHtml = d0.innerHTML;
    cy.on('tap', 'node[kind = "endpoint"]', function(e) { pkMapGo(e.target.id(), !focusId ? false : undefined); });
    cy.on('tap', 'node[kind = "family"]', function(e) { hideStart(); details(e.target); });
    cy.on('tap', function(e) { if (e.target === cy && !focusId) showStart(); });
    cy.on('mouseover', 'node[kind = "endpoint"], node[kind = "family"]', function(e) {
      e.target.addClass('hover'); box.style.cursor = 'pointer';
      if (!focusId && e.target.data('kind') === 'endpoint') e.target.connectedEdges('[rel]').filter(function(x) {
        return visible(x.source()) && visible(x.target());
      }).addClass('path');
    });
    cy.on('mouseout', 'node', function(e) {
      e.target.removeClass('hover'); box.style.cursor = '';
      if (!focusId) e.target.connectedEdges('[rel]').removeClass('path');
    });
    // The stars drift a little as the map moves.
    cy.on('viewport', function() { var p = cy.pan(); box.style.backgroundPosition = (p.x * 0.12) + 'px ' + (p.y * 0.12) + 'px'; });
    cy.on('zoom', scaleNames);
    pkMapColour();
    pkMapFilter();
    return true;
  }
  // The map can only measure itself once it is on screen. Opening the map
  // from Labs (window.pkMapWantFull) makes it full screen at once.
  window.pkMapShown = function() {
    var box = el('map-canvas'); if (!box || box.offsetParent === null) return;
    if (window.pkMapWantFull) {
      window.pkMapWantFull = false;
      var stage = el('map-stage');
      if (stage && !stage.classList.contains('map-full')) {
        stage.classList.add('map-full'); document.body.classList.add('map-full-open');
        var b = el('map-full-btn'); if (b) b.textContent = 'Exit full screen';
      }
    }
    if (!started) { started = start(); } else if (cy) { cy.resize(); }
  };
})();
