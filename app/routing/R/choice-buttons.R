# A choice that decides the rest of the form, shown as a row of buttons
# rather than a drop-down (12 November 2026): "What do you want to find
# out?" and the test's direction were "Choose one" menus of long
# sentences, so the question that shapes the screen was the hardest to
# see. A select field with `buttons: true` keeps its <select> as the
# value Shiny reads (hidden, but labelled), and the buttons are built in
# the browser from its options, so a choice hidden by `choices_shown_if`
# disappears from the buttons too. `button_labels` gives each choice a
# short title; the option's full wording is the line under it.

choice_buttons_ui <- function(f) {
  id <- field_input_id(f)
  div(class = "pk-choice-buttons", id = paste0(id, "_buttons"), `data-target` = id, role = "radiogroup",
    `aria-labelledby` = paste0(id, "-label"),
    `data-titles` = as.character(jsonlite::toJSON(f$button_labels %||% list(), auto_unbox = TRUE)))
}

choice_buttons_css <- "
  .pk-choice-buttons { display: grid; grid-template-columns: repeat(auto-fit, minmax(13rem, 1fr)); gap: 0.5rem; margin: 0.25rem 0 0.5rem; }
  .pk-choice-buttons button { text-align: left; background: #fff; border: 1px solid var(--pk-line); border-radius: var(--pk-radius); padding: 0.6rem 0.85rem;
    color: var(--pk-navy); display: flex; flex-direction: column; gap: 0.15rem; min-height: 44px; }
  .pk-choice-buttons button:hover { border-color: var(--pk-blue); }
  .pk-choice-buttons button[aria-checked=true] { border: 2px solid var(--pk-blue); background: #eef4fa; padding: calc(0.6rem - 1px) calc(0.85rem - 1px); }
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
    var opts = Array.prototype.filter.call(sel.options, function(o) { return o.value && !o.hidden && !o.disabled; });
    var key = opts.map(function(o) { return o.value; }).join('|') + '#' + sel.value;
    if (box.pkKey === key) return;
    box.pkKey = key;
    box.innerHTML = '';
    opts.forEach(function(o) {
      var b = document.createElement('button');
      b.type = 'button'; b.setAttribute('role', 'radio'); b.setAttribute('aria-checked', sel.value === o.value ? 'true' : 'false');
      b.setAttribute('data-value', o.value);
      var title = titles[o.value];
      if (title) { var t = document.createElement('span'); t.className = 'pk-cb-title'; t.textContent = title; b.appendChild(t); }
      var s = document.createElement('span'); s.className = title ? 'pk-cb-text' : 'pk-cb-title'; s.textContent = o.text; b.appendChild(s);
      b.addEventListener('click', function() {
        sel.value = o.value;
        if (window.jQuery) jQuery(sel).trigger('change'); else sel.dispatchEvent(new Event('change', { bubbles: true }));
        refresh();
      });
      box.appendChild(b);
    });
  }
  // A link to the hidden menu (an error message's) goes to its buttons.
  document.addEventListener('click', function(e) {
    var a = e.target.closest && e.target.closest('a'), href = a ? a.getAttribute('href') || '' : '';
    var box = href.indexOf('#f_') === 0 && document.getElementById(href.slice(1) + '_buttons');
    if (!box || !box.firstElementChild) return;
    e.preventDefault();
    var b = box.querySelector('[aria-checked=true]') || box.firstElementChild;
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
