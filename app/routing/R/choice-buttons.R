# A choice that decides the rest of the form, shown as a row of buttons
# rather than a drop-down (12 November 2026): "What do you want to find
# out?" and the test's direction were "Choose one" menus of long
# sentences, so the question that shapes the screen was the hardest to
# see. A select field with `buttons: true` keeps its <select> as the
# value Shiny reads (hidden, but labelled), and the buttons are built in
# the browser from its options, so a choice hidden by `choices_shown_if`
# disappears from the buttons too. `button_labels` gives each choice a
# short title; the option's full wording is the line under it, unless
# `button_notes` gives a line that adds to the title rather than restating
# it ("Sample size" over "The sample size I need", 22 November 2026).

choice_buttons_ui <- function(f) {
  id <- field_input_id(f)
  div(class = "pk-choice-buttons", id = paste0(id, "_buttons"), `data-target` = id,
    `data-label` = paste0(id, "-label"),
    `data-titles` = as.character(jsonlite::toJSON(f$button_labels %||% list(), auto_unbox = TRUE)),
    `data-notes` = as.character(jsonlite::toJSON(f$button_notes %||% list(), auto_unbox = TRUE)))
}

choice_buttons_css <- "
  .pk-choice-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(min(13rem, 100%), 1fr)); gap: 0.5rem; margin: 0.25rem 0 0.5rem; }
  .pk-choice-followup, .pk-choice-advanced { margin: 0.75rem 0; }
  .pk-choice-advanced summary { color: var(--pk-blue); cursor: pointer; }
  .pk-choice-advanced button { margin-top: 0.35rem; }
  .pk-choice-buttons button { text-align: left; background: #fff; border: 1px solid var(--pk-line); border-radius: var(--pk-radius); padding: 0.6rem 0.85rem;
    color: var(--pk-navy); display: flex; flex-direction: column; gap: 0.15rem; min-height: 44px; }
  .pk-choice-buttons button:hover { border-color: var(--pk-blue); }
  .pk-choice-buttons button[aria-checked=true], .pk-choice-buttons button[aria-pressed=true] { border: 2px solid var(--pk-blue); background: #eef4fa; padding: calc(0.6rem - 1px) calc(0.85rem - 1px); }
  .pk-choice-buttons .pk-cb-title { font-weight: 600; }
  .pk-choice-buttons .pk-cb-text { font-size: 0.82rem; color: #4a5563; line-height: 1.3; }
  .form-group.pk-has-buttons select { position: absolute !important; width: 1px !important; height: 1px !important; overflow: hidden; clip: rect(0 0 0 0); padding: 0 !important; border: 0 !important; }
"

choice_buttons_js <- "
(function() {
  function build(box) {
    var sel = document.getElementById(box.getAttribute('data-target'));
    if (!sel) return;
    var group = sel.closest('.form-group'); if (group) group.classList.add('pk-has-buttons');
    sel.setAttribute('tabindex', '-1');
    var titles = {}; try { titles = JSON.parse(box.getAttribute('data-titles') || '{}'); } catch (e) {}
    var notes = {}; try { notes = JSON.parse(box.getAttribute('data-notes') || '{}'); } catch (e) {}
    var opts = Array.prototype.filter.call(sel.options, function(o) { return o.value && !o.hidden && !o.disabled; });
    var key = opts.map(function(o) { return o.value; }).join('|') + '#' + sel.value;
    if (box.pkKey === key) return;
    box.pkKey = key;
    var focus = document.activeElement;
    var focusId = box.contains(focus) ? focus.id : '';
    var advancedWasOpen = box.querySelector('.pk-choice-advanced[open]') !== null;
    box.innerHTML = '';
    var grid = document.createElement('div');
    grid.className = 'pk-choice-grid';
    grid.setAttribute('role', 'radiogroup');
    grid.setAttribute('aria-labelledby', box.getAttribute('data-label'));
    box.appendChild(grid);

    var goal = sel.id === 'f_goal';
    var range = goal && opts.find(function(o) { return o.value === 'sensitivity_curve'; });
    var paired = range && opts.some(function(o) { return o.value === 'sensitivity'; });
    var advanced = goal && opts.find(function(o) { return o.value === 'justified_alpha'; });

    function addChoice(parent, value, title, description, selected, kind) {
      var b = document.createElement('button');
      b.type = 'button';
      b.id = box.id + '_' + kind + '_' + value;
      b.setAttribute('data-value', value);
      if (kind === 'advanced') b.setAttribute('aria-pressed', String(selected));
      else { b.setAttribute('role', 'radio'); b.setAttribute('aria-checked', String(selected)); }
      if (title && Object.prototype.hasOwnProperty.call(notes, value)) description = notes[value];
      if (title) { var t = document.createElement('span'); t.className = 'pk-cb-title'; t.textContent = title; b.appendChild(t); }
      if (description) {
        var s = document.createElement('span'); s.className = title ? 'pk-cb-text' : 'pk-cb-title'; s.textContent = description; b.appendChild(s);
      }
      b.addEventListener('click', function() {
        sel.value = value;
        if (window.jQuery) jQuery(sel).trigger('change'); else sel.dispatchEvent(new Event('change', { bubbles: true }));
        refresh();
      });
      parent.appendChild(b);
    }

    opts.forEach(function(o) {
      if (o === advanced || (paired && o === range)) return;
      var cluster = paired && o.value === 'sensitivity';
      addChoice(grid, o.value, titles[o.value], cluster ? 'The smallest effect you could detect at your target power' : o.text,
        sel.value === o.value || (cluster && sel.value === range.value), 'main');
    });
    if (paired && (sel.value === 'sensitivity' || sel.value === range.value)) {
      var followup = document.createElement('div');
      followup.className = 'pk-choice-followup';
      var label = document.createElement('div');
      label.className = 'form-label';
      label.id = box.id + '_sizes_label';
      label.textContent = 'Which sample sizes?';
      followup.appendChild(label);
      var sizes = document.createElement('div');
      sizes.className = 'pk-choice-grid';
      sizes.setAttribute('role', 'radiogroup');
      sizes.setAttribute('aria-labelledby', label.id);
      followup.appendChild(sizes);
      addChoice(sizes, 'sensitivity', 'One sample size', '', sel.value === 'sensitivity', 'sizes');
      addChoice(sizes, range.value, 'Compare several sample sizes', '', sel.value === range.value, 'sizes');
      box.appendChild(followup);
    }
    if (advanced) {
      var details = document.createElement('details');
      details.className = 'pk-choice-advanced';
      details.open = advancedWasOpen || sel.value === advanced.value;
      var summary = document.createElement('summary');
      summary.textContent = 'Advanced goals';
      details.appendChild(summary);
      addChoice(details, advanced.value, titles[advanced.value], advanced.text, sel.value === advanced.value, 'advanced');
      box.appendChild(details);
    }
    if (focusId) {
      var replacement = document.getElementById(focusId);
      if (replacement) replacement.focus({ preventScroll: true });
    }
  }
  // A link to the hidden menu (an error message's) goes to its buttons.
  document.addEventListener('click', function(e) {
    var a = e.target.closest && e.target.closest('a'), href = a ? a.getAttribute('href') || '' : '';
    var box = href.indexOf('#f_') === 0 && document.getElementById(href.slice(1) + '_buttons');
    if (!box || !box.firstElementChild) return;
    e.preventDefault();
    var b = box.querySelector('[aria-checked=true], [aria-pressed=true]') || box.querySelector('button');
    if (!b) return;
    b.scrollIntoView({ block: 'center' }); b.focus();
  });
  function refresh() { document.querySelectorAll('.pk-choice-buttons').forEach(build); }
  var pending = false;
  function soon() { if (!pending) { pending = true; setTimeout(function() { pending = false; refresh(); }, 30); } }
  document.addEventListener('change', soon);
  if (window.jQuery) jQuery(document).on('change shiny:value shiny:updateinput', soon);
  new MutationObserver(function(m) { if (m.some(function(r) { return r.addedNodes.length; })) soon(); })
    .observe(document.documentElement, { childList: true, subtree: true });
})();
"
