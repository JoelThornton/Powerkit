// The methods map in Labs (R/map.R builds the data and the page). Draws the
// map with Cytoscape.js, filters it, flies about and shows an analysis's
// details. Three views: the families (the default: analyses grouped by what
// they are, joined to related tests), the aims (analyses around what a study
// wants to show) and the questions (every route of "Help me choose", left to
// right). Nothing here is calculated.
(function() {
  var cy = null, data = null, started = false, running = null, first = true;
  var hues = ['#7c9cff', '#ff7eb6', '#4fe0b6', '#ffd166', '#c792ea', '#5cc8ff', '#ff9f68', '#9be15d', '#f78fb3', '#b0c4de',
              '#6ee7f9', '#fca5a5', '#a5b4fc', '#fde68a', '#86efac'];
  var statusColour = { runs: '#5cc8ff', soon: '#ffb347', not: '#9aa7c7' };
  var statusText = { runs: 'Calculates in powerkit', soon: 'Coming', not: 'Not in powerkit yet' };
  var tests = {}, familyHue = {}, familyLabel = {};

  function load() {
    if (data) return data;
    var d = document.getElementById('map-data'); if (!d) return null;
    data = JSON.parse(d.textContent);
    (data.tests || []).forEach(function(t) { tests[t.id] = t; });
    (data.families || []).forEach(function(f, i) { familyHue[f.id] = hues[i % hues.length]; familyLabel[f.id] = f.label; });
    return data;
  }
  function esc(s) { var d = document.createElement('div'); d.textContent = s == null ? '' : s; return d.innerHTML; }
  function el(id) { return document.getElementById(id); }
  function value(id, fallback) { var e = el(id); return e ? e.value : fallback; }
  function view() { return value('map_layout', 'earth'); }
  function colourBy() { return value('map_colour', 'test'); }
  function relationsOn() { var e = el('map_relations'); return !e || e.checked; }

  function elements() {
    var d = load(), els = [], hubs = {}, h = 0;
    els.push({ data: { id: 'root', label: 'Your study', kind: 'root' } });
    d.nodes.forEach(function(n) {
      var x = Object.assign({}, n);
      if (n.kind === 'hub') { x.hue = hues[h++ % hues.length]; hubs[n.rq] = n.id; }
      if (n.kind === 'family') { x.hue = familyHue[n.family] || '#7c9cff'; }
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
    d.edges.forEach(function(e) { els.push({ data: Object.assign({}, e) }); });
    // In the aims view each analysis is joined straight to what it shows.
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
      { selector: 'node', style: { 'label': 'data(label)', 'text-wrap': 'wrap', 'text-max-width': 150, 'font-size': 12,
          'font-family': 'Inter, system-ui, sans-serif', 'color': '#e8eefc', 'text-outline-color': '#050a1f', 'text-outline-width': 2,
          'text-valign': 'bottom', 'text-margin-y': 6, 'min-zoomed-font-size': 7, 'z-index': 10 } },
      { selector: 'node[kind = "endpoint"]', style: { 'width': 22, 'height': 22, 'background-color': 'data(col)',
          'underlay-color': 'data(col)', 'underlay-opacity': 0.3, 'underlay-padding': 8, 'underlay-shape': 'ellipse',
          'border-width': 2, 'border-color': '#ffffff', 'border-opacity': 0.6, 'transition-property': 'background-color, underlay-color',
          'transition-duration': 400 } },
      { selector: 'node[kind = "endpoint"][status = "runs"]', style: { 'width': 28, 'height': 28 } },
      { selector: 'node[kind = "endpoint"][status = "not"]', style: { 'border-style': 'dashed', 'background-opacity': 0.65 } },
      { selector: 'node[kind = "family"]', style: { 'shape': 'ellipse', 'width': 'data(size)', 'height': 'data(size)',
          'background-color': 'data(hue)', 'background-opacity': 0.07, 'border-width': 2, 'border-color': 'data(hue)', 'border-opacity': 0.28,
          'underlay-color': 'data(hue)', 'underlay-opacity': 0.12, 'underlay-padding': 40, 'underlay-shape': 'ellipse',
          'label': 'data(label)', 'text-valign': 'top', 'text-margin-y': -14, 'font-size': 30, 'font-weight': 700,
          'color': 'data(hue)', 'text-outline-width': 0, 'text-max-width': 520, 'min-zoomed-font-size': 0, 'z-index': 0,
          'text-background-color': '#050a1f', 'text-background-opacity': 0.0 } },
      { selector: 'node[kind = "hub"]', style: { 'width': 96, 'height': 96, 'background-color': 'data(hue)',
          'border-width': 6, 'border-color': '#ffffff', 'border-opacity': 0.35,
          'underlay-color': 'data(hue)', 'underlay-opacity': 0.35, 'underlay-padding': 26, 'underlay-shape': 'ellipse',
          'font-size': 24, 'font-weight': 700, 'text-max-width': 300, 'text-margin-y': 14, 'color': '#ffffff', 'text-outline-width': 3,
          'min-zoomed-font-size': 0 } },
      { selector: 'node[kind = "root"]', style: { 'shape': 'round-rectangle', 'width': 'label', 'height': 'label', 'padding': 12,
          'background-color': '#14284B', 'text-valign': 'center', 'text-margin-y': 0, 'font-weight': 700 } },
      { selector: 'node[kind = "question"]', style: { 'shape': 'round-rectangle', 'width': 'label', 'height': 'label', 'padding': 9,
          'background-color': '#16224d', 'border-width': 1, 'border-color': '#6f86c9', 'text-valign': 'center', 'text-margin-y': 0,
          'font-size': 12, 'text-outline-width': 0, 'color': '#dfe7ff' } },
      { selector: 'node[kind = "orbit"]', style: { 'shape': 'ellipse', 'width': 'data(size)', 'height': 'data(size)',
          'background-opacity': 0, 'border-width': 1.2, 'border-color': 'data(hue)', 'border-opacity': 0.22, 'border-style': 'dashed',
          'label': '', 'events': 'no', 'z-index': 0 } },
      { selector: 'edge', style: { 'width': 1, 'line-color': '#8ea6e8', 'opacity': 0.35, 'curve-style': 'bezier',
          'target-arrow-shape': 'triangle', 'target-arrow-color': '#8ea6e8', 'arrow-scale': 0.6, 'z-index': 1 } },
      { selector: 'edge[shortcut]', style: { 'target-arrow-shape': 'none', 'opacity': 0.12, 'width': 1, 'curve-style': 'straight' } },
      { selector: 'edge[rel]', style: { 'curve-style': 'unbundled-bezier', 'control-point-distances': 60, 'control-point-weights': 0.5,
          'line-color': '#ffe8a3', 'target-arrow-color': '#ffe8a3', 'opacity': 0, 'width': 1.6, 'arrow-scale': 0.7, 'events': 'no',
          'label': '', 'font-size': 11, 'color': '#fff4cf', 'text-rotation': 'autorotate', 'text-outline-color': '#050a1f', 'text-outline-width': 2,
          'min-zoomed-font-size': 8 } },
      { selector: 'edge[rel].all', style: { 'opacity': 0.22 } },
      { selector: 'edge.far', style: { 'line-style': 'dashed', 'opacity': 0.08 } },
      { selector: '.dim', style: { 'opacity': 0.12 } },
      { selector: 'node[kind = "family"].dim', style: { 'opacity': 0.35 } },
      { selector: 'node.hover', style: { 'font-size': 15, 'z-index': 30, 'min-zoomed-font-size': 0 } },
      { selector: 'node[kind = "family"].hover', style: { 'border-opacity': 0.6, 'background-opacity': 0.12, 'font-size': 30 } },
      { selector: 'node.hit, node:selected', style: { 'border-color': '#ffe08a', 'border-width': 4, 'border-opacity': 1,
          'underlay-opacity': 0.6, 'min-zoomed-font-size': 0, 'z-index': 30 } },
      { selector: 'node[kind = "family"]:selected', style: { 'border-width': 3 } },
      { selector: 'edge.path', style: { 'line-color': '#ffe08a', 'target-arrow-color': '#ffe08a', 'opacity': 0.95, 'width': 3, 'z-index': 20 } },
      { selector: 'edge[rel].path', style: { 'opacity': 0.95, 'width': 2.6 } }
    ];
  }

  function checked(group) {
    return Array.prototype.map.call(document.querySelectorAll('.map-sidebar input[data-group="' + group + '"]:checked'),
      function(i) { return i.value; });
  }
  function visible(n) { return n.style('display') !== 'none'; }

  // The families: each family a region, its analyses on a sunflower spiral
  // inside it, and the regions packed round the middle like continents.
  var SPACING = 150;
  function earth() {
    cy.remove('node[kind = "orbit"]');
    var pos = {}, placed = [];
    var families = cy.nodes('[kind = "family"]').filter(visible);
    families.forEach(function(f, i) {
      var members = cy.nodes('[kind = "endpoint"]').filter(function(n) { return n.data('family') === f.data('family') && visible(n); });
      var k = members.length;
      var inner = SPACING * Math.sqrt(k) * 0.62 + 40;
      var r = inner + 110;
      // Place the region: the first in the middle, each next on a golden
      // spiral, moved outwards until it meets no other.
      var a = i * 2.39996, d = 0, x = 0, y = 0;
      for (var tries = 0; tries < 400; tries++) {
        x = d * Math.cos(a); y = d * Math.sin(a);
        var clear = placed.every(function(p) { return Math.hypot(p.x - x, p.y - y) >= p.r + r + 90; });
        if (clear) break;
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
    run(shown.layout({ name: 'preset', positions: function(n) { return pos[n.id()]; }, animate: !first, animationDuration: 700, fit: false }));
  }

  // The aims: each star's analyses on rings around it, far enough apart
  // that no two labels meet, and the stars spread on a wide circle.
  var R0 = 250, GAP = 150, STEP = 230;
  function cosmos() {
    cy.remove('node[kind = "orbit"]');
    var hubs = cy.nodes('[kind = "hub"]').filter(visible);
    var placed = {}, systems = [];
    hubs.forEach(function(h) {
      var planets = h.outgoers('edge[shortcut]').targets().filter(function(n) { return visible(n) && !placed[n.id()]; });
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
    cy.nodes('[kind = "orbit"]').lock();
    var shown = cy.nodes().filter(function(n) { return pos[n.id()]; });
    run(shown.layout({ name: 'preset', positions: function(n) { return pos[n.id()]; }, animate: !first, animationDuration: 700, fit: false }));
  }
  function tree() {
    cy.remove('node[kind = "orbit"]');
    run(cy.elements(':visible').not('edge[rel]').layout({ name: 'dagre', rankDir: 'LR', nodeSep: 18, rankSep: 140, animate: !first,
      animationDuration: 600, fit: false }));
  }
  function run(layout) {
    if (running) running.stop();
    running = layout;
    running.one('layoutstop', focus);
    running.run();
  }

  // After a layout: fly to the search matches, or show everything. The
  // first time, the map swoops in from far away.
  function focus() {
    var hits = cy.nodes('.hit');
    if (first) {
      first = false;
      var all = cy.nodes(':visible').not('[kind = "orbit"]');
      var bb = all.boundingBox();
      cy.zoom(cy.minZoom());
      cy.center(all);
      fitTo(all, 1, 1600);
      return;
    }
    if (hits.length) fitTo(hits, 1.1);
    else pkMapFit();
  }
  // Fit some nodes into the part of the map the panels leave free. A long
  // move pulls out first and then dives in, like a globe.
  function frame(eles, zoomCap) {
    var side = el('map-sidebar');
    var left = side && !side.classList.contains('closed') && window.innerWidth > 800 ? side.offsetWidth + 24 : 0;
    var details = el('map-details');
    var right = details && !details.hidden && window.innerWidth > 800 ? details.offsetWidth + 24 : 0;
    var top = 70, bottom = 70;
    var w = Math.max(cy.width() - left - right - 120, 120), h = Math.max(cy.height() - top - bottom - 60, 120);
    var bb = eles.boundingBox({ includeLabels: false, includeUnderlays: false });
    var z = Math.min(w / Math.max(bb.w, 1), h / Math.max(bb.h, 1), zoomCap || 1.2);
    z = Math.max(z, cy.minZoom());
    return { zoom: z, pan: { x: left + 60 + w / 2 - z * (bb.x1 + bb.w / 2), y: top + 30 + h / 2 - z * (bb.y1 + bb.h / 2) } };
  }
  function fitTo(eles, zoomCap, duration) {
    if (!eles || !eles.length) return;
    var target = frame(eles, zoomCap);
    var reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    cy.stop();
    if (reduce) { cy.viewport(target); return; }
    // How far the view must travel, in screen widths at the end's zoom.
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
    fitTo(cy.nodes(':visible').not('[kind = "orbit"]'));
  };
  window.pkMapZoom = function(f) {
    if (!cy) return;
    cy.stop();
    cy.animate({ zoom: { level: Math.min(Math.max(cy.zoom() * f, cy.minZoom()), cy.maxZoom()),
      position: { x: (cy.extent().x1 + cy.extent().x2) / 2, y: (cy.extent().y1 + cy.extent().y2) / 2 } } }, { duration: 250 });
  };
  // Region and star names stay readable from far away.
  function scaleNames() {
    var z = cy.zoom();
    var f = Math.min(90, Math.max(24, 15 / z));
    cy.nodes('[kind = "hub"]').style({ 'font-size': f, 'text-max-width': 12 * f });
    // Far away, a family's name sits in its region at a steady size on
    // screen; close up, it moves to the region's edge.
    var far = z < 0.42;
    cy.nodes('[kind = "family"]').forEach(function(n) {
      var size = n.data('size') || 400;
      n.style(far ? { 'font-size': Math.min(15 / z, size / 5), 'text-max-width': size * 0.9, 'text-valign': 'center', 'text-margin-y': 0,
          'text-background-opacity': 0 }
        : { 'font-size': 30, 'text-max-width': size, 'text-valign': 'top', 'text-margin-y': -14 });
    });
    cy.nodes('[kind = "endpoint"]').style({ 'font-size': 12, 'text-max-width': 150 });
    var picked = cy.nodes('[kind = "endpoint"].hit').union(cy.nodes('[kind = "endpoint"]:selected'));
    var pf = Math.max(13, 13 / z);
    picked.style({ 'font-size': pf, 'text-max-width': 14 * pf });
    var hint = el('map-hint'); if (hint && z > 0.5) hint.classList.add('gone');
  }
  function overlaps(a, b) { return a.some(function(x) { return b.indexOf(x) >= 0; }); }

  // Colours by the test, the family or the status, with the key along the
  // bottom; clicking a key entry hides or shows those analyses.
  window.pkMapColour = function() {
    if (!cy) return;
    var by = colourBy();
    cy.nodes('[kind = "endpoint"]').forEach(function(n) {
      n.data('col', by === 'family' ? n.data('cFamily') : by === 'status' ? n.data('cStatus') : n.data('cTest'));
    });
    legend();
  };
  function legend() {
    var box = el('map-legend'); if (!box || !cy) return;
    var by = colourBy(), items = [];
    if (by === 'test') {
      var groupBoxes = document.querySelectorAll('.map-sidebar input[data-group="test"]');
      Array.prototype.forEach.call(groupBoxes, function(i) {
        var t = tests[i.value] || {};
        items.push({ group: 'test', value: i.value, label: t.label || i.value, colour: t.colour, on: i.checked, title: t.text });
      });
    } else if (by === 'status') {
      ['runs', 'soon', 'not'].forEach(function(k) {
        var i = document.querySelector('.map-sidebar input[data-group="status"][value="' + k + '"]');
        items.push({ group: 'status', value: k, label: statusText[k], colour: statusColour[k], on: !i || i.checked });
      });
    }
    // Coloured by family, the regions are the key.
    box.hidden = items.length === 0;
    box.innerHTML = items.map(function(it) {
      return '<button type="button" aria-pressed="' + (it.on ? 'true' : 'false') + '" data-group="' + it.group + '" data-value="' + esc(it.value) + '"' +
        (it.title ? ' title="' + esc(it.title) + '"' : '') + '><span class="dot" style="background:' + esc(it.colour) + ';box-shadow:0 0 6px ' + esc(it.colour) + '"></span>' +
        esc(it.label) + '</button>';
    }).join('');
  }
  var hiddenFamilies = [];
  document.addEventListener('click', function(e) {
    var b = e.target.closest && e.target.closest('#map-legend button');
    if (!b) return;
    var group = b.getAttribute('data-group'), v = b.getAttribute('data-value');
    if (group === 'family') {
      var at = hiddenFamilies.indexOf(v);
      if (at >= 0) hiddenFamilies.splice(at, 1); else hiddenFamilies.push(v);
    } else {
      var i = document.querySelector('.map-sidebar input[data-group="' + group + '"][value="' + v + '"]');
      if (i) i.checked = !i.checked;
    }
    pkMapFilter();
  });

  // An analysis shows when it matches every filter. The families view
  // shows the regions and the lines between related tests; the aims view
  // its stars; the questions view the design finder's questions.
  window.pkMapFilter = function() {
    if (!cy) return;
    var rq = checked('rq'), outcome = checked('outcome'), times = checked('times'), status = checked('status'), test = checked('test');
    var q = (value('map_search', '') || '').trim().toLowerCase();
    var v = view(), isTree = v === 'tree', isEarth = v === 'earth', rel = relationsOn() && !isTree;
    var shown = cy.collection();
    cy.batch(function() {
      cy.elements().removeClass('dim hit path');
      cy.nodes('[kind = "endpoint"]').forEach(function(n) {
        var d = n.data();
        var ok = overlaps(d.rq, rq) && overlaps(d.outcome, outcome) && overlaps(d.times, times) && status.indexOf(d.status) >= 0 &&
          test.indexOf(d.test) >= 0 && hiddenFamilies.indexOf(d.family) < 0 && (!isEarth || d.family);
        n.style('display', ok ? 'element' : 'none');
        if (ok) shown = shown.union(n);
        var words = (d.plain + ' ' + d.standard + ' ' + ((tests[d.test] || {}).label || '') + ' ' + (d.familyLabel || '')).toLowerCase();
        if (ok && q && words.indexOf(q) >= 0) n.addClass('hit');
      });
      cy.nodes('[kind = "family"]').forEach(function(n) {
        var has = shown.filter(function(x) { return x.data('family') === n.data('family'); }).length > 0;
        n.style('display', isEarth && has ? 'element' : 'none');
      });
      cy.nodes('[kind = "hub"]').forEach(function(n) {
        var has = n.outgoers('edge[shortcut]').targets().intersection(shown).length > 0;
        n.style('display', v === 'cosmos' && rq.indexOf(n.data('rq')) >= 0 && has ? 'element' : 'none');
      });
      cy.nodes('[kind = "question"], [kind = "root"]').forEach(function(n) {
        var leads = isTree && (n.data('kind') === 'root' || n.successors('node[kind = "endpoint"]').intersection(shown).length > 0);
        n.style('display', leads ? 'element' : 'none');
      });
      if (isTree) cy.nodes('[kind = "hub"]').forEach(function(n) {
        if (rq.indexOf(n.data('rq')) >= 0 && n.successors('node[kind = "endpoint"]').intersection(shown).length) n.style('display', 'element');
      });
      cy.edges().forEach(function(e) {
        var on;
        // Lines between related tests: all of them when asked for, and
        // always those of the analysis hovered or chosen.
        if (e.data('rel')) { on = !isTree && shown.contains(e.source()) && shown.contains(e.target()); e.toggleClass('all', rel); }
        else if (e.data('shortcut')) on = v === 'cosmos';
        else on = isTree;
        e.style('display', on ? 'element' : 'none');
      });
      if (q) {
        var hits = cy.nodes('.hit');
        cy.elements().not('[kind = "orbit"]').addClass('dim');
        hits.removeClass('dim');
        hits.connectedEdges().removeClass('dim');
        if (!isEarth) hits.incomers('node').removeClass('dim');
        if (isTree) hits.predecessors().removeClass('dim');
      }
    });
    var count = el('map-count');
    var total = cy.nodes('[kind = "endpoint"]').filter(function(n) { return !isEarth || n.data('family'); }).length;
    if (count) count.textContent = shown.length + ' of ' + total + ' analyses' +
      (q ? ' · ' + cy.nodes('.hit').length + ' match “' + q + '”' : '');
    legend();
    scaleNames();
    if (isTree) tree(); else if (isEarth) earth(); else cosmos();
  };
  window.pkMapLayout = window.pkMapFilter;
  window.pkMapFirstHit = function() {
    if (!cy) return;
    var hit = cy.nodes('.hit').first();
    if (hit.length) { cy.nodes().unselect(); hit.select(); scaleNames(); details(hit); }
  };
  // Analyses named in plain words, or by the test's usual name.
  window.pkMapNames = function() {
    if (!cy) return;
    var standard = value('map_names', 'plain') === 'standard';
    cy.nodes('[kind = "endpoint"]').forEach(function(n) {
      n.data('label', standard && n.data('standard') ? n.data('standard') : n.data('plain'));
    });
  };
  window.pkMapReset = function() {
    document.querySelectorAll('.map-sidebar input[type=checkbox]').forEach(function(i) { i.checked = true; });
    hiddenFamilies = [];
    var s = el('map_search'); if (s) s.value = '';
    pkMapClose();
    pkMapFilter();
  };
  window.pkMapPanel = function() {
    var p = el('map-sidebar'), b = document.querySelector('.map-panel-toggle');
    var closed = p.classList.toggle('closed');
    if (b) b.setAttribute('aria-expanded', closed ? 'false' : 'true');
  };

  // The answers on the shortest route to an analysis through the design
  // finder's questions.
  function route(n) {
    var graph = cy.elements().not('edge[shortcut]').not('edge[rel]').not('[kind = "orbit"]').not('[kind = "family"]');
    var path = graph.dijkstra({ root: cy.$id('root'), directed: true }).pathTo(n), steps = [];
    path.forEach(function(x) {
      if (x.isEdge()) { if (view() === 'tree') x.addClass('path'); if (x.data('label')) steps.push(x.data('label')); }
      else if (x.data('kind') === 'hub') steps.push(x.data('label'));
    });
    return steps;
  }
  function relatives(n) {
    var out = [];
    cy.edges('[rel]').forEach(function(e) {
      if (e.source().id() === n.id()) out.push({ text: 'This, ' + e.data('label') + ' ', other: e.target(), edge: e });
      else if (e.target().id() === n.id()) out.push({ text: '', after: ' ' + e.data('label') + ' this', other: e.source(), edge: e });
    });
    return out;
  }
  function details(n) {
    var box = el('map-details'); if (!box) return;
    cy.edges().removeClass('path');
    var d = n.data(), html = '<button type="button" class="map-close" aria-label="Close" onclick="pkMapClose()">×</button>';
    if (d.kind === 'endpoint') {
      var t = tests[d.test] || {}, steps = route(n), rels = relatives(n);
      n.connectedEdges('[shortcut]').addClass('path');
      rels.forEach(function(r) { r.edge.addClass('path'); });
      html += '<h4>' + esc(d.label) + '</h4>' +
        '<span class="map-tag ' + d.status + '">' + esc(d.statusText) + '</span>' +
        (d.familyLabel ? '<span class="map-tag fam">' + esc(d.familyLabel) + '</span>' : '') +
        (d.standard && d.standard !== d.label ? '<p class="small mb-1">Usual name: <strong>' + esc(d.standard) + '</strong></p>' : '') +
        (d.plain !== d.label ? '<p class="small mb-1">What it does: <strong>' + esc(d.plain) + '</strong></p>' : '') +
        '<h5>The test</h5><div class="map-test" style="--test:' + esc(t.colour || '#9aa7c7') + '"><strong>' + esc(t.label || '') + '.</strong> ' + esc(t.text || '') + '</div>' +
        (rels.length ? '<h5>Related tests</h5><ul class="map-rel">' + rels.map(function(r) {
          var name = esc(r.other.data('label'));
          var link = '<button type="button" data-id="' + esc(r.other.id()) + '" onclick="pkMapGo(this.dataset.id)">' + name + '</button>';
          return '<li>' + (r.text ? '<span class="map-rel-text">' + esc(r.text) + '</span>' + link : link + '<span class="map-rel-text">' + esc(r.after) + '</span>') + '</li>';
        }).join('') + '</ul>' : '') +
        (steps.length ? '<h5>One way here in “Help me choose”</h5><ol>' +
          steps.map(function(s) { return '<li>' + esc(s) + '</li>'; }).join('') + '</ol>' :
          '<h5>How to find it</h5><p class="small">Chosen by name, in “I know my analysis”.</p>') +
        '<button type="button" class="btn btn-info btn-sm mt-2" data-id="' + esc(d.id) + '" onclick="pkMapOpen(this.dataset.id)">Read about this analysis</button>';
      box.innerHTML = html;
      box.hidden = false;
      var near = n.union(rels.map(function(r) { return r.other; }).reduce(function(a, b) { return a.union(b); }, cy.collection()));
      fitTo(rels.length ? near : n, 1.15);
      return;
    }
    if (d.kind === 'family') {
      var members = cy.nodes('[kind = "endpoint"]').filter(function(x) { return x.data('family') === d.family && visible(x); });
      var runs = members.filter(function(x) { return x.data('status') === 'runs'; }).length;
      var kinds = {};
      members.forEach(function(x) { var l = (tests[x.data('test')] || {}).label; if (l) kinds[l] = (kinds[l] || 0) + 1; });
      html += '<h4>' + esc(d.label) + '</h4><p class="small mb-1">' + members.length + ' analyses here; powerkit calculates ' + runs + ' of them.</p>' +
        '<h5>Their tests</h5><ul>' + Object.keys(kinds).map(function(k) { return '<li>' + esc(k) + ': ' + kinds[k] + '</li>'; }).join('') + '</ul>' +
        '<p class="small mb-0">Click an analysis to read about it.</p>';
      box.innerHTML = html;
      box.hidden = false;
      fitTo(members.union(n), 1.0);
      return;
    }
    if (d.kind === 'hub') {
      var planets = n.outgoers('edge[shortcut]').targets().filter(visible);
      var nearby = n.outgoers('edge[shortcut]').not('.far').targets().filter(visible);
      html += '<h4>' + esc(d.label) + '</h4><p class="small mb-0">' + planets.length + ' analyses shown for this' +
        (planets.length > nearby.length ? ' (' + (planets.length - nearby.length) + ' of them orbit another star too; the dashed lines lead to them)' : '') +
        '. Click one to read about it.</p>';
      box.innerHTML = html;
      box.hidden = false;
      fitTo(n.union(nearby));
      return;
    }
    var under = n.successors('node[kind = "endpoint"]').filter(visible);
    route(n);
    html += '<h4>' + esc(d.label) + '</h4><p class="small mb-0">' + under.length + ' of the analyses shown lie beyond this question.</p>';
    box.innerHTML = html;
    box.hidden = false;
  }
  window.pkMapGo = function(id) {
    if (!cy) return;
    var n = cy.$id(id); if (!n.length) return;
    if (!visible(n)) { pkMapReset(); n = cy.$id(id); }
    cy.nodes().unselect(); n.select(); scaleNames(); details(n);
  };
  window.pkMapClose = function() {
    var b = el('map-details'); if (b) b.hidden = true;
    if (cy) { cy.edges().removeClass('path'); cy.nodes().unselect(); }
  };
  // An analysis's page opens under the map, so full screen closes first.
  window.pkMapOpen = function(id) {
    pkMapFull(false);
    Shiny.setInputValue('map_endpoint', id, { priority: 'event' });
    setTimeout(function() {
      var p = el('map-page');
      if (p) { p.scrollIntoView({ block: 'start' }); p.focus({ preventScroll: true }); }
    }, 400);
  };

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
    cy.on('tap', 'node', function(e) { if (e.target.data('kind') !== 'orbit') { setTimeout(scaleNames, 0); details(e.target); } });
    cy.on('tap', function(e) { if (e.target === cy) pkMapClose(); });
    cy.on('dbltap', 'node[kind = "endpoint"]', function(e) { pkMapOpen(e.target.id()); });
    cy.on('mouseover', 'node', function(e) {
      e.target.addClass('hover'); box.style.cursor = 'pointer';
      if (e.target.data('kind') === 'endpoint') e.target.connectedEdges('[rel]').addClass('path');
    });
    cy.on('mouseout', 'node', function(e) {
      e.target.removeClass('hover'); box.style.cursor = '';
      if (e.target.data('kind') === 'endpoint' && !e.target.selected()) {
        var keep = cy.nodes(':selected');
        e.target.connectedEdges('[rel]').filter(function(x) { return !keep.length || !x.connectedNodes().intersection(keep).length; }).removeClass('path');
      }
    });
    // The stars drift a little as the map moves.
    cy.on('viewport', function() { var p = cy.pan(); box.style.backgroundPosition = (p.x * 0.12) + 'px ' + (p.y * 0.12) + 'px'; });
    cy.on('zoom', scaleNames);
    if (window.innerWidth <= 800) { var p = el('map-sidebar'); if (p) p.classList.add('closed'); }
    pkMapColour();
    pkMapFilter();
    scaleNames();
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
