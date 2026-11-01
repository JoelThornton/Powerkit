# The "About" tab: what powerkit does, that it's a prototype, which
# end points calculate, how to report problems, and credits for the tools
# it is built on. The lists come from tree.yaml and forms.yaml, so they stay
# in step with the app; credits come from each package's own citation()
# (CLAUDE.md: citations only from refs.bib or citation()).

# The packages powerkit is built on (docs/coverage-roadmap.md, "Foundation
# tools"), then the software doing real work underneath them (as in the
# engine's citations export, supporting_software()), then R and Shiny.
about_foundation_tools <- list(
  list(package = "pwr", role = "formulas for the t-tests, the correlation and the chi-square test of independence, and Cohen's h for two proportions if you choose it"),
  list(package = "pwrss", role = "the z test for two proportions in unequal groups, Fisher's exact test, Welch's t-test by formula, ANOVA and ANCOVA from partial eta-squared, regression, one proportion, McNemar's test, the goodness-of-fit test, comparing correlations and non-inferiority tests"),
  list(package = "Spower", role = "simulation for the rank tests, Welch's tests, the variance test in the same people, MANOVA and the meta-analysis's Hartung-Knapp test, and for the basic tests when you choose it"),
  list(package = "Superpower", role = "the one-way, factorial, repeated-measures and mixed ANOVAs from means, planned contrasts and pairwise comparisons"),
  list(package = "InteractionPoweR", role = "interactions in regression"),
  list(package = "power4mome", role = "mediation, moderated mediation and the whole-study simulation"),
  list(package = "powertools", role = "cluster-randomised, multisite and group treatment trials"),
  list(package = "semPower", role = "model fit, measurement invariance, factor correlations and latent paths in SEM"),
  list(package = "TOSTER", role = "equivalence tests"),
  list(package = "bfpwr", role = "Bayes factor t-tests and the Bayes factor test of one proportion"),
  list(package = "BayesFactor", role = "the Bayes factor test of a correlation (the same Bayes factor as JASP's)"),
  list(package = "metapower", role = "the planned meta-analysis's z test"),
  list(package = "simr", role = "participants responding to many items (mixed models)"),
  list(package = "PUMP", role = "joint power for several outcomes in a study plan")
)
about_supporting_tools <- list(
  list(package = "SimDesign", role = "which runs Spower's simulations"),
  list(package = "afex", role = "which fits Superpower's ANOVAs"),
  list(package = "MASS", role = "which Superpower uses to generate data"),
  list(package = "lavaan", role = "which power4mome uses to fit each simulated data set"),
  list(package = "manymome", role = "which power4mome uses for indirect effects and their confidence intervals"),
  list(package = "metafor", role = "which fits each simulated meta-analysis"),
  list(package = "lme4", role = "which fits simr's mixed models"),
  list(package = "effectsize", role = "which converts published effect sizes"),
  list(package = "psych", role = "which converts published t and F statistics, and gives safeguard power's interval"),
  list(package = "SuppDists", role = "which gives the exact distribution of a sample correlation, for the correlation Bayes factor"),
  list(package = "base", label = "R", role = "in which everything runs; its power.prop.test() gives the z test for two proportions in equal groups, and its chi-square and F distributions the variance tests of one or two groups"),
  list(package = "shiny", role = "which draws this app")
)

# A package's own citation() as plain text, or a note if it isn't installed.
# citation() reads the installed package's files, so the package isn't
# loaded: loading the backends here took about 2.5 of the 3 seconds a new
# app process needs before it can show the first page.
about_citation_text <- function(package) {
  if (!identical(package, "base") && !nzchar(system.file(package = package))) {
    return(sprintf("Not installed on this computer; see citation(\"%s\") in R.", package))
  }
  text <- tryCatch(format(utils::citation(package), style = "text"), error = function(e) character())
  if (!length(text)) return(sprintf("See citation(\"%s\") in R.", package))
  # Plain text: drop the markdown-style emphasis format() adds.
  gsub("[*_]{1,2}([^*_]+)[*_]{1,2}", "\\1", text)
}

about_credit_ui <- function(tool) {
  label <- tool$label %||% tool$package
  div(
    class = "about-credit",
    HTML(sprintf("<strong>%s</strong> <span class=\"about-credit-role\">%s</span>",
      htmltools::htmlEscape(label), htmltools::htmlEscape(tool$role))),
    tags$details(class = "about-cite",
      tags$summary("How to cite"),
      tags$ul(class = "about-citation small", lapply(about_citation_text(tool$package), tags$li)))
  )
}

# How each analysis that calculates gets its answer, for its label on the
# About page: "now" (in a second or two), "background" (with a progress
# bar), "full" (a preview, then the full run here) or "script" (a preview,
# then an R script to run on your computer).
about_endpoint_how <- function(forms) {
  instant <- unlist(forms$calculates)
  sims <- forms$simulations$endpoints %||% list()
  background <- names(forms$background %||% list())
  how <- c(
    stats::setNames(ifelse(instant %in% background, "background", "now"), instant),
    vapply(sims, function(s) if ("power" %in% unlist(s$full_run)) "full" else "script", "")
  )
  how
}

about_how_words <- c(
  now = "Calculates here",
  background = "Calculates here, in the background, with a progress bar",
  full = "A preview here, then the full analysis here (several minutes); sample size by an R script",
  script = "A preview here, then an R script to run the full analysis on your computer"
)
about_how_tag <- c(now = NA, background = "In the background", full = "Simulated", script = "Preview + R script")

# Every analysis that calculates, by family (tree.yaml's
# analysis_families), each a button that opens its card.
about_plans_ui <- function(tree, forms) {
  how <- about_endpoint_how(forms)
  families <- tree$analysis_families %||% list()
  placed <- unlist(lapply(families, `[[`, "endpoints"))
  rest <- setdiff(names(how), placed)
  if (length(rest)) families <- c(families, list(list(id = "more", label = "More", endpoints = rest)))
  chip <- function(id) {
    ep <- tree$endpoints[[id]]
    tag <- about_how_tag[[how[[id]]]]
    tags$button(type = "button", class = paste("about-ep", paste0("how-", how[[id]])), `data-endpoint` = id,
      title = paste0(about_how_words[[how[[id]]]], ". Click to plan it."),
      onclick = "pkAboutPlan(this.dataset.endpoint)",
      tags$span(class = "about-ep-name", ep$plain_name),
      tags$span(class = "about-ep-doc", ep$doc_name),
      if (!is.na(tag)) tags$span(class = "about-ep-tag", tag))
  }
  groups <- lapply(families, function(f) {
    ids <- intersect(unlist(f$endpoints), names(how))
    if (!length(ids)) return(NULL)
    # Open on a wide screen; on a phone about_js folds them, so the list
    # of families fits on a screen or two.
    tags$details(class = "about-family", open = NA,
      tags$summary(class = "about-family-head", tags$h4(f$label), tags$span(class = "about-family-count",
        sprintf("%d of %d", length(ids), length(intersect(unlist(f$endpoints), names(tree$endpoints)))))),
      div(class = "about-ep-list", lapply(ids, chip)))
  })
  tagList(
    div(class = "about-key",
      tags$span(class = "about-key-item how-now", "Calculates in a second or two"),
      tags$span(class = "about-key-item how-background", "In the background, with a progress bar"),
      tags$span(class = "about-key-item how-full", "Simulated: a preview, then the full run here"),
      tags$span(class = "about-key-item how-script", "A preview, then an R script for your computer")),
    div(class = "about-families", groups)
  )
}

# powerkit's version, from the engine package, so the About page, the
# exported scripts and every result's provenance all quote the same number
# (docs/adding-a-test.md, "Version numbers").
powerkit_version <- function() {
  version <- tryCatch(as.character(utils::packageVersion("powerkit")), error = function(e) NULL)
  if (is.null(version)) NULL else version
}


about_section <- function(id, title, ...) {
  tags$section(class = "about-section", id = id, tags$h3(class = "about-h", title), ...)
}

about_ui <- function(tree, forms) {
  version <- powerkit_version()
  how <- about_endpoint_how(forms)
  statuses <- vapply(names(how), function(id) tree$endpoints[[id]]$status %||% "", "")
  n_validated <- sum(statuses == "runs_validated")
  div(
    class = "about about-page",
    div(class = "about-hero",
      tags$h2("About powerkit"),
      p(class = "about-lead",
        "powerkit plans the sample size for a study. You describe your study, it finds the power analysis ",
        "that fits and asks for the numbers it needs, and an established R package does the calculation."),
      div(class = "about-status",
        tags$span(class = "about-status-pill", paste(c("Prototype", if (!is.null(version)) paste0("v", version)), collapse = " \u00b7 ")),
        tags$span(tags$strong("This is a prototype. "),
          "Its results are not yet fully validated, and screens, wording and defaults will change. ",
          "Please don't use it to plan a real study yet.")),
      tags$nav(class = "about-toc", `aria-label` = "On this page",
        tags$a(href = "#about-how", "How it works"),
        tags$a(href = "#about-plans", "What it can plan"),
        tags$a(href = "#about-trust", "Can you trust it?"),
        tags$a(href = "#about-feedback", "Feedback"),
        tags$a(href = "#about-credits", "Credits"))),

    about_section("about-how", "How it works",
      tags$ol(class = "about-steps",
        tags$li(tags$strong("Describe your study."),
          tags$span("\"Help me choose\" asks plain questions about your design, or pick the analysis by name under \"I know my analysis\".")),
        tags$li(tags$strong("Give the numbers."),
          tags$span("The analysis asks only what it needs, and helps you say where your effect size comes from.")),
        tags$li(tags$strong("Get the answer."),
          tags$span("An established R package calculates it. You get a write-up, the citations, and an R script that reruns it without powerkit."))),
      p(class = "about-note", "powerkit never does the statistics itself: every number comes from one of the packages under Credits."),
      tags$button(type = "button", class = "btn btn-primary about-start", onclick = "pkAboutTab('Plan a power analysis')",
        "Start planning")),

    about_section("about-plans", "What it can plan",
      p(sprintf("%d of the %d analyses calculate in the app. Click one to plan it. ", length(how), length(tree$endpoints)),
        "The other cards say which analysis fits a study and point to a tool that does it."),
      about_plans_ui(tree, forms)),

    about_section("about-trust", "Can you trust it?",
      div(class = "about-cards",
        div(class = "about-card",
          tags$h4("Where the numbers come from"),
          p("Each analysis is handed to the established R package that already does it. ",
            "Where powerkit's settings differ from that package's or from G*Power's usual ones, the result screen says so ",
            "and explains it. The result's R script reruns it with the package alone, so anyone can check it without powerkit.")),
        div(class = "about-card",
          tags$h4("How far along it is"),
          p(sprintf("%d of the %d analyses that calculate have passed their published checks; the rest say \"validation in progress\" on their card. ",
              n_validated, length(how)),
            "Several have been compared with G*Power and with published examples. ",
            "It won't be released until a statistician has checked it."),
          if (!is.null(version)) p(class = "about-small",
            sprintf("This is powerkit %s. ", version),
            "Every result and every R script you download says this version, so a number you quote can be traced back to it. ",
            "Version 1.0 will be the first release. ",
            tags$a(href = "#", onclick = "pkAboutTab('Updates'); return false;", "See the updates."))),
        div(class = "about-card about-card-wide",
          tags$h4("What it doesn't do"),
          tags$ul(
            tags$li(tags$strong("It doesn't choose your effect size. "), "It asks where yours comes from and helps you explain it, ",
              "but the number and the reasoning are yours."),
            tags$li(tags$strong("It doesn't collect or analyse your data. "), "It plans a study; it doesn't run one."),
            tags$li(tags$strong("It doesn't use AI to calculate or to write anything you see. "), "Every number comes from the R packages below, ",
              "and the write-up is fixed wording filled in with your numbers."),
            tags$li(tags$strong("It doesn't replace a statistician for unusual designs. "), "If no card fits your study, ",
              "or a card gives guidance only, ask someone who knows your design."))))),

    about_section("about-feedback", "Reporting a problem or giving feedback",
      div(class = "about-card about-feedback",
        p(HTML(paste0(
          "Use the <strong>Feedback</strong> tab for bugs, questions, suggestions and any other comments. ",
          "It fills in where you are in powerkit for you and shows the whole message before you send it. ",
          "Every card also has a <strong>Something doesn&#39;t fit?</strong> link at the bottom that leads there."))),
        p(class = "about-small", "Nothing is sent from this app without you: the only thing it ever sends is a feedback message, ",
          "when you click Send, and everything else you enter stays on your computer."),
        tags$button(type = "button", class = "btn btn-outline-primary", onclick = "pkAboutTab('Feedback')", "Give feedback"))),

    about_section("about-credits", "Credits",
      p("powerkit is built on these R packages. Please cite the package that calculated your result ",
        "(the result screen's Citations button lists it); each one's own citation is under \"How to cite\"."),
      div(class = "about-credits", lapply(about_foundation_tools, about_credit_ui)),
      tags$h4(class = "about-subh", "And the software they run on"),
      div(class = "about-credits about-credits-small", lapply(about_supporting_tools, about_credit_ui))),

    tags$script(HTML(about_js))
  )
}

about_js <- "
  // On a phone the analysis families start folded.
  (function() {
    var fold = function() {
      if (!window.matchMedia || !window.matchMedia('(max-width: 767px)').matches) return;
      document.querySelectorAll('details.about-family[open]').forEach(function(d) { d.removeAttribute('open'); });
    };
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', fold); else fold();
  })();
  window.pkAboutTab = function(name) {
    var a = document.querySelector('#tabs a[data-value=\"' + name + '\"]');
    if (a) { a.click(); window.scrollTo(0, 0); }
  };
  window.pkAboutPlan = function(id) {
    if (window.Shiny && Shiny.setInputValue) Shiny.setInputValue('map_plan', id, {priority: 'event'});
    window.scrollTo(0, 0);
  };
  document.addEventListener('click', function(e) {
    var a = e.target.closest && e.target.closest('.about-toc a');
    if (!a) return;
    var t = document.querySelector(a.getAttribute('href'));
    if (t) { e.preventDefault(); t.scrollIntoView({behavior: 'smooth', block: 'start'}); }
  });
"

# "Updates" (called "What's new" until November 2026): dated changes in plain words, newest first, from
# whats-new.yaml (one entry per change users would notice). The latest days
# are open; older ones fold by month. It opens as a timeline of titles,
# each opening its description, with "Full details" showing them all. A search box filters them, and the
# browser remembers the newest change you have seen, so changes since your
# last visit are marked (and the tab shows a dot until you look).
load_whats_new <- function(path) {
  entries <- yaml::read_yaml(path, fileEncoding = "UTF-8")$entries
  dates <- as.Date(vapply(entries, `[[`, "", "date"))
  entries[order(dates, decreasing = TRUE)]
}

whats_new_day_label <- function(day) {
  paste(as.integer(format(as.Date(day), "%d")), format(as.Date(day), "%B %Y"))
}

whats_new_ui <- function(entries, open_days = 1) {
  dates <- vapply(entries, `[[`, "", "date")
  days <- unique(dates)
  changes <- function(n) if (n == 1) "1 change" else sprintf("%d changes", n)
  day_ui <- function(day) {
    items <- entries[dates == day]
    tags$section(class = "wn-day", `data-date` = day,
      tags$h3(class = "wn-day-head", whats_new_day_label(day), tags$span(class = "wn-day-count", changes(length(items)))),
      div(class = "wn-entries", lapply(items, function(e) {
        tags$article(class = "wn-entry", `data-date` = e$date,
          tags$h4(class = "wn-title",
            tags$button(type = "button", class = "wn-toggle", `aria-expanded` = "false", onclick = "pkUpdatesOpen(this)",
              tags$span(class = "wn-new", "New"), e$title)),
          p(class = "wn-text", e$text))
      })))
  }
  recent <- utils::head(days, open_days)
  older <- setdiff(days, recent)
  months <- unique(format(as.Date(older), "%Y-%m"))
  div(
    class = "about whats-new-page wn-simple",
    `data-latest` = if (length(days)) days[[1]] else "",
    tags$h2("Updates"),
    p(class = "about-lead", "Changes to powerkit you would notice, newest first. ",
      "Click a change to read more, or show every description with Full details. ",
      "The online app updates itself each time a change is approved."),
    div(class = "wn-since", id = "wn-since", hidden = NA),
    div(class = "wn-tools",
      tags$input(type = "search", id = "wn-search", class = "form-control", placeholder = "Search the changes, e.g. ANOVA or Labs",
        `aria-label` = "Search the changes", oninput = "pkWhatsNewSearch(this.value)"),
      tags$span(class = "wn-count", id = "wn-count", `aria-live` = "polite", sprintf("%d changes", length(entries))),
      div(class = "wn-view btn-group", role = "group", `aria-label` = "How much to show",
        tags$button(type = "button", class = "btn btn-sm btn-outline-primary active", `data-view` = "simple",
          `aria-pressed` = "true", onclick = "pkUpdatesView('simple')", "Timeline"),
        tags$button(type = "button", class = "btn btn-sm btn-outline-primary", `data-view` = "full",
          `aria-pressed` = "false", onclick = "pkUpdatesView('full')", "Full details"))),
    div(class = "wn-timeline", lapply(recent, day_ui),
      lapply(months, function(m) {
        in_month <- older[format(as.Date(older), "%Y-%m") == m]
        n <- sum(dates %in% in_month)
        tags$details(class = "wn-month",
          tags$summary(format(as.Date(paste0(m, "-01")), "%B %Y"), tags$span(class = "wn-day-count", changes(n))),
          lapply(in_month, day_ui))
      })),
    p(class = "wn-none", id = "wn-none", hidden = NA, "No changes match. Try a shorter word."),
    tags$script(HTML(whats_new_js))
  )
}

whats_new_js <- "
(function() {
  var KEY = 'powerkit-whats-new-seen';
  function page() { return document.querySelector('.whats-new-page'); }
  function tabLink() { return document.querySelector('#tabs a[data-value=\"Updates\"]'); }
  function stored() { try { return window.localStorage.getItem(KEY); } catch (e) { return null; } }
  function store(v) { try { window.localStorage.setItem(KEY, v); } catch (e) {} }
  function markSeen() {
    var p = page(); if (!p) return;
    store(p.dataset.latest);
    var dot = document.querySelector('.wn-dot'); if (dot) dot.remove();
  }
  function init() {
    var p = page(); if (!p || !p.dataset.latest) return;
    var seen = stored();
    if (!seen) { store(p.dataset.latest); return; }
    if (p.dataset.latest <= seen) return;
    var fresh = p.querySelectorAll('.wn-entry');
    var n = 0;
    fresh.forEach(function(e) { if (e.dataset.date > seen) { e.classList.add('is-new'); n++; } });
    if (!n) return;
    var since = document.getElementById('wn-since');
    var d = new Date(seen + 'T12:00:00');
    since.textContent = (n === 1 ? '1 change' : n + ' changes') + ' since you last looked, on ' +
      d.toLocaleDateString('en-GB', {day: 'numeric', month: 'long'}) + '. They are marked New.';
    since.hidden = false;
    var a = tabLink();
    if (a && !a.querySelector('.wn-dot')) {
      var s = document.createElement('span'); s.className = 'wn-dot'; s.title = n + ' new';
      s.setAttribute('aria-label', n + ' new changes'); a.appendChild(s);
    }
    document.addEventListener('click', function(e) {
      if (e.target.closest && e.target.closest('#tabs a[data-value=\"Updates\"]')) markSeen();
    });
    if (p.offsetParent !== null) markSeen();
  }
  var VIEW = 'powerkit-updates-view';
  window.pkUpdatesView = function(view, quiet) {
    var p = page(); if (!p) return;
    p.classList.toggle('wn-simple', view !== 'full');
    p.querySelectorAll('.wn-view button').forEach(function(b) {
      var on = b.dataset.view === view; b.classList.toggle('active', on); b.setAttribute('aria-pressed', on ? 'true' : 'false');
    });
    if (!quiet) { try { window.localStorage.setItem(VIEW, view); } catch (e) {} }
  };
  window.pkUpdatesOpen = function(btn) {
    var e = btn.closest('.wn-entry'); var open = !e.classList.contains('is-open');
    e.classList.toggle('is-open', open); btn.setAttribute('aria-expanded', open ? 'true' : 'false');
  };
  try { if (window.localStorage.getItem(VIEW) === 'full') document.addEventListener('DOMContentLoaded', function() { pkUpdatesView('full', true); }); } catch (e) {}
  window.pkWhatsNewSearch = function(q) {
    var p = page(); if (!p) return;
    var words = q.toLowerCase().split(/\\s+/).filter(Boolean);
    var shown = 0;
    p.querySelectorAll('.wn-entry').forEach(function(e) {
      var text = e.textContent.toLowerCase();
      var ok = words.every(function(w) { return text.indexOf(w) >= 0; });
      e.hidden = !ok; if (ok) shown++;
    });
    p.querySelectorAll('.wn-day').forEach(function(d) { d.hidden = !d.querySelector('.wn-entry:not([hidden])'); });
    p.querySelectorAll('.wn-month').forEach(function(m) {
      var any = !!m.querySelector('.wn-entry:not([hidden])');
      m.hidden = !any; m.open = words.length > 0 && any;
    });
    document.getElementById('wn-count').textContent = words.length ?
      (shown === 1 ? '1 change matches' : shown + ' changes match') :
      (shown === 1 ? '1 change' : shown + ' changes');
    document.getElementById('wn-none').hidden = shown > 0;
  };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init); else init();
})();
"
