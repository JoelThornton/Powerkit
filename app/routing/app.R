# powerkit app: the design finder (docs/decision-tree.md), the input
# screens and the results.
#
# The routes and cards come from tree.yaml in this folder, the input screens
# from forms.yaml. The app never computes power itself: an input screen
# builds a design spec, checks it with the engine's validate_spec() and
# passes it to the engine's run_spec() (R/results.R, R/simulations.R).
#
# Run: source("run_routing_prototype.R") from the project folder, or open
# this file in RStudio and click "Run App". See docs/routing-prototype.md.

library(shiny)

options(shiny.sanitize.errors = TRUE)

source(file.path("R", "tree.R"), local = TRUE)
source(file.path("R", "ui.R"), local = TRUE)
source(file.path("R", "forms.R"), local = TRUE)
source(file.path("R", "forms_ui.R"), local = TRUE)
source(file.path("R", "feedback.R"), local = TRUE)
source(file.path("R", "results.R"), local = TRUE)
source(file.path("R", "simulations.R"), local = TRUE)
source(file.path("R", "whole-study.R"), local = TRUE)
source(file.path("R", "project.R"), local = TRUE)
source(file.path("R", "study-plan.R"), local = TRUE)
source(file.path("R", "about.R"), local = TRUE)
source(file.path("R", "labs.R"), local = TRUE)
source(file.path("R", "map.R"), local = TRUE)

tree <- load_tree("tree.yaml")
forms <- load_forms("forms.yaml")
whats_new <- load_whats_new("whats-new.yaml")
# Cards for end points that calculate (or preview, E10-E14) don't say "No
# numbers are calculated".
tree$calculates <- c(unlist(forms$calculates), names(forms$simulations$endpoints))
options(powerkit.routing_dir = getwd())

app_css <- "
  body { background: #f7f8fa; }
  .app-main { max-width: 980px; margin: 0 auto 3rem auto; }
  .choices { display: flex; flex-direction: column; gap: 0.6rem; margin: 1rem 0 1.5rem 0; }
  .choice { text-align: left; padding: 0.75rem 1rem; white-space: normal; }
  .choice .choice-label { display: block; font-weight: 600; }
  .choice .choice-help { display: block; font-size: 0.85rem; margin-top: 0.15rem; color: #3d4852; }
  .choice:hover .choice-help, .choice:focus .choice-help, .choice:active .choice-help { color: #fff; }
  .trail { margin-bottom: 1rem; }
  .trail-title { display: block; font-size: 0.85rem; color: #555; margin-bottom: 0.35rem; }
  .chip { border: 1px solid #b8c2d3; background: #e8f0fb; color: #14284b; border-radius: 1.4rem;
          padding: 0.45rem 0.9rem; margin: 0 0.35rem 0.5rem 0; font-size: 0.85rem;
          min-height: 44px; min-width: 44px; } /* touch target at least 44 x 44 px (WCAG 2.5.5) */
  .question-id, .card-eid { font-size: 0.8rem; color: #545b62; text-transform: uppercase; letter-spacing: 0.04em; }
  .nav-buttons { display: flex; flex-wrap: wrap; gap: 0.75rem; margin-top: 1rem; }
  .placeholders { margin-top: 1rem; }
  .placeholder { border: 2px dashed #9a9a9a; background: #f2f2f2; color: #333; border-radius: 0.5rem; padding: 0.75rem 1rem; margin-bottom: 0.75rem;
                 opacity: 1; cursor: auto; display: block; min-height: 0; vertical-align: baseline; } /* overrides Bootstrap's loading-placeholder style */
  .placeholder .text-muted, .placeholder .ref { color: #4d4d4d !important; }
  .no-numbers { color: #545b62 !important; }
  [tabindex='-1']:focus { outline: none; }
  .placeholder-label { font-weight: 700; text-transform: uppercase; font-size: 0.8rem; letter-spacing: 0.04em; margin-bottom: 0.35rem; }
  .placeholder .ref, .decided .ref { font-weight: 400; text-transform: none; margin-left: 0.5rem; color: #555; }
  .decided { border-left: 4px solid #2e7d4f; background: #ddf2e3; padding: 0.5rem 0.75rem; margin-bottom: 0.75rem; }
  .endpoint-card { margin: 1rem 0; border-radius: 0.6rem; }
  .endpoint-card.compact { margin: 0.5rem 0 0 0; }
  .standard-name { color: #444; }
  .status { border-radius: 0.4rem; padding: 0.6rem 0.9rem; margin: 0.5rem 0 1rem 0; }
  .status-runs { background: #ddf2e3; border: 1px solid #2e7d4f; }
  .status-in-progress { background: #e8f0fb; border: 1px solid #3b6fb6; }
  .badge-progress { display: inline-block; background: #3b6fb6; color: #fff; border-radius: 1rem; padding: 0.05rem 0.6rem;
                    font-size: 0.75rem; font-weight: 600; margin-right: 0.5rem; vertical-align: 1px; }
  .status-soon { background: #fff0d1; border: 1px solid #b97a00; }
  .badge-soon { display: inline-block; background: #7a4f00; color: #fff; border-radius: 1rem; padding: 0.05rem 0.6rem;
                font-size: 0.75rem; font-weight: 600; margin-right: 0.5rem; vertical-align: 1px; }
  .status-not { background: #f2f2f2; border: 1px dashed #9a9a9a; }
  .no-numbers { font-size: 0.8rem; margin: 0.75rem 0 0 0; }
  .placeholder-inline { display: inline-block; border: 1.5px dashed #9a9a9a; background: #f2f2f2; color: #333; border-radius: 0.35rem;
                        padding: 0.1rem 0.5rem; margin: 0.25rem 0 0.35rem 0; font-size: 0.82rem; }
  .decided-inline { display: inline-block; border-left: 3px solid #2e7d4f; background: #ddf2e3; padding: 0.1rem 0.5rem; margin: 0.25rem 0; font-size: 0.82rem; }
  .engine-placeholder { border: 2px dashed #3b6fb6; background: #fff; color: #14284b; border-radius: 0.5rem; padding: 0.75rem 1rem; margin: 0.5rem 0 1rem 0; font-style: italic; }
  .analysis-row { background: #fff; border: 1px solid #dde2ea; border-radius: 0.5rem; padding: 0.75rem 1rem 0.25rem 1rem; margin-bottom: 0.75rem; }
  .choice-safety { border-style: dashed; }
  .hint { font-size: 0.85rem; color: #4a4a4a; margin: 0.1rem 0 0.25rem 0; }
  .hint dfn { font-style: normal; font-weight: 600; }
  .card-points { margin-bottom: 1rem; }
  .form-group-box { background: #fff; border: 1px solid #dde2ea; border-radius: 0.6rem; padding: 0.75rem 1rem 0.25rem 1rem; margin-bottom: 1rem; }
  .progress-steps ol { display: flex; flex-wrap: wrap; gap: 0.25rem 1.25rem; list-style: none; padding: 0; margin: 0 0 1rem 0; font-size: 0.9rem; }
  .progress-steps li { display: flex; align-items: center; gap: 0.4rem; color: #545b62; }
  .progress-steps .step-num { display: inline-flex; align-items: center; justify-content: center; width: 1.6rem; height: 1.6rem; border-radius: 50%;
                              border: 1.5px solid #8a929a; font-weight: 600; font-size: 0.8rem; background: #fff; }
  .progress-steps .done .step-num { background: #ddf2e3; border-color: #2e7d4f; color: #1d5434; }
  .progress-steps .current { color: #14284b; font-weight: 600; }
  .progress-steps .current .step-num { background: #0a5a8c; border-color: #0a5a8c; color: #fff; }
  .card-more { margin-top: 0.75rem; }
  .card-more > summary { cursor: pointer; color: #0a5a8c; text-decoration: underline; min-height: 44px; display: flex; align-items: center; }
  .field-help { font-size: 0.85rem; color: #4a4a4a; margin-top: 0.2rem; }
  .field-problem { font-size: 0.9rem; color: #8a1f1f; border-left: 3px solid #a12a2a; background: #fbeaea; padding: 0.2rem 0.5rem; margin-top: 0.3rem; }
  [aria-invalid='true'] { border-color: #a12a2a !important; }
  .form-terms { margin: 0 0 0.5rem 0; font-size: 0.9rem; }
  .form-terms > summary { cursor: pointer; color: #0a5a8c; min-height: 32px; }
  .effect-unsure { background: #eef3fa; border-radius: 0.5rem; padding: 0.6rem 0.9rem; margin-bottom: 0.75rem; }
  .effect-help { background: #fff; border: 1px solid #dde2ea; border-radius: 0.6rem; padding: 0.5rem 1rem; margin-bottom: 0.75rem; }
  .effect-help > summary { cursor: pointer; color: #0a5a8c; font-weight: 600; min-height: 44px; display: flex; align-items: center; }
  .effect-help dt { margin-top: 0.5rem; }
  .form-section { margin-bottom: 0.5rem; }
  @media (min-width: 768px) { .form-group-names { display: grid; grid-template-columns: 1fr 1fr; column-gap: 1rem; }
    .form-group-names > legend, .form-group-names > .hint, .form-group-names > .group-note { grid-column: 1 / -1; } }
  .form-section-title { margin: 1.25rem 0 0.6rem 0; }
  .form-section-effect > .form-group-box { border-color: #0a5a8c; border-width: 2px; }
  .form-settings, .form-guess { background: #fff; border: 1px solid #dde2ea; border-radius: 0.6rem; padding: 0.6rem 1rem; margin: 1rem 0; }
  .form-settings > summary, .form-guess > summary { cursor: pointer; min-height: 44px; padding: 0.3rem 0; }
  .form-settings-title { font-weight: 600; color: #0a5a8c; text-decoration: underline; }
  .form-settings[open] > summary { margin-bottom: 0.5rem; }
  .setting-item { white-space: normal; }
  .form-group-box legend { float: none; width: auto; padding: 0 0.25rem; margin-bottom: 0.25rem; font-weight: 600; }
  .form-field { margin-bottom: 0.75rem; }
  .form-field .form-control, .form-field .form-select { min-height: 44px; }
  .default-source { font-size: 0.85rem; color: #4a4a4a; margin-top: -0.35rem; }
  .form-problems { border-left: 4px solid #a12a2a; background: #fbeaea; padding: 0.75rem 1rem; margin: 1rem 0; }
  .not-wired { margin-top: 1rem; }
  .spec-json { white-space: pre-wrap; font-size: 0.8rem; background: #f4f6f9; padding: 0.5rem; border-radius: 0.4rem; }
  #copy-status { margin-top: 0.5rem; font-size: 0.9rem; }
  .mismatch { margin-top: 1.25rem; border-top: 1px solid #dde2ea; padding-top: 0.75rem; }
  .mismatch summary { color: #0a5a8c; text-decoration: underline; cursor: pointer; min-height: 44px; display: flex; align-items: center; }
  .mismatch-text { font-size: 0.85rem; font-family: monospace; }
  .copy-status { margin-top: 0.5rem; font-size: 0.9rem; }
  .about { max-width: 46rem; }
  .about-endpoints li, .about-credit { margin-bottom: 0.4rem; }
  .about-citation { color: #3d4852; margin-top: 0.15rem; }
  .whats-new li { margin-bottom: 0.6rem; }
  .plan-result { margin: 0.5rem 0; }
  .whole-study-lead { background: #fff; border: 2px solid #0A5A8C; border-radius: 0.6rem; padding: 1rem 1.25rem; margin-bottom: 1.25rem; }
  .plan-separate > summary { cursor: pointer; margin: 1rem 0; }
  .plan-more > summary { cursor: pointer; color: #0A5A8C; margin: 0.5rem 0; }
  .plan-design { margin: 0.25rem 0 0.5rem; }
  .plan-item { background: #fff; border: 1px solid #dde2ea; border-radius: 0.6rem; padding: 0.75rem 1rem; margin-bottom: 1rem; }
  .labs-notice { border-left: 4px solid #b26b00; background: #fff6e5; padding: 0.6rem 0.9rem; margin-bottom: 1rem; }
  .labs-sde { margin-top: 0.75rem; }
  .labs-sde summary { font-weight: 600; color: #0a5a8c; cursor: pointer; }
  .observed-power-warning { font-size: 0.9rem; border-left: 4px solid #a12a2a; background: #fbeaea; border-radius: 0.4rem; padding: 0.4rem 0.75rem; margin: -0.25rem 0 0.75rem 0; }
  .labs-tool-card { background: #fff; border: 1px solid #dde2ea; border-radius: 0.6rem; padding: 0.9rem 1rem; margin-bottom: 0.75rem; }
  .labs-back { padding-left: 0; margin-bottom: 0.5rem; }
  .labs-return { font-size: 0.9rem; background: #eef3fa; border-left: 4px solid #0a5a8c; border-radius: 0.4rem; padding: 0.5rem 0.75rem; margin-bottom: 1rem; }
  .labs-signpost { font-size: 0.9rem; background: #eef3fa; border-radius: 0.4rem; padding: 0.4rem 0.75rem; margin: -0.25rem 0 0.75rem 0; }
  .labs-hint-hidden .labs-signpost { display: none; }

  /* A cleaner, card-based look (26 October 2026). */
  :root { --pk-navy: #14284b; --pk-blue: #0a5a8c; --pk-amber: #b97a00; --pk-line: #e3e7ee; --pk-bg: #f5f7fa;
          --pk-radius: 14px; --pk-shadow: 0 1px 2px rgba(20,40,75,.06), 0 4px 16px rgba(20,40,75,.06); }
  body { background: var(--pk-bg); color: #1d2733; font-family: system-ui, -apple-system, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; }
  h2 { font-weight: 650; color: var(--pk-navy); letter-spacing: -0.01em; font-size: 1.75rem; }
  .lead { font-size: 1.05rem; color: #44505e; }
  .topbar { background: var(--pk-navy); color: #fff; margin: 0 -12px 0 -12px; padding: 0.6rem 12px 0.5rem 12px; }
  .topbar-inner { max-width: 70rem; margin: 0 auto; display: flex; align-items: center; justify-content: space-between; gap: 0.75rem; flex-wrap: wrap; }
  .share-page { display: flex; align-items: center; gap: 0.5rem; }
  /* Explanations off (terms_js): technical names first, and the
     plain-English hints of terms hidden; the help under each field,
     notes, assumptions, departures and known differences stay. */
  .topbar-tools { display: flex; align-items: center; flex-wrap: wrap; gap: 0.5rem; }
  .terms-toggle { display: flex; align-items: center; gap: 0.35rem; color: #fff; font-size: 0.9rem; margin: 0 0.75rem 0 0; cursor: pointer; }
  .name-tech, .name-plain-alt { display: none; }
  .terms-mode .name-tech, .terms-mode .name-plain-alt { display: inline; }
  .terms-mode .name-plain, .terms-mode .name-tech-alt { display: none; }
  .terms-mode .hint, .terms-mode .form-terms, .terms-mode .also-called,
  .terms-mode .standard-name { display: none; }
  .share-page-btn { color: #fff; border: 1px solid rgba(255,255,255,.55); background: transparent; }
  .share-page-btn:hover, .share-page-btn:focus { color: var(--pk-navy); background: #fff; }
  .share-page-status { font-size: 0.85rem; color: #fff; }
  .brand { font-size: 1.35rem; font-weight: 700; letter-spacing: -0.02em; margin: 0; color: #fff; display: flex; align-items: center; gap: 0.6rem; }
  .brand .badge-proto { text-transform: none; letter-spacing: 0; font-size: 0.75rem; }
  .prototype-banner { font-size: 0.95rem; color: #44505e; background: #fff6e5; border-left: 4px solid var(--pk-amber); border-radius: 8px; padding: 0.6rem 0.9rem; margin: 0 0 1rem 0; }
  .badge-proto { display: inline-block; background: #f2b84b; color: #2b1d00; border-radius: 1rem; padding: 0.02rem 0.55rem;
                 font-size: 0.72rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.04em; }
  .app-main { max-width: 70rem; margin: 0 auto 6rem auto; overflow-wrap: break-word; }
  /* Larger text on large screens, so the page doesn't look zoomed out there.
     Sizes are in rem, so the whole layout scales with it, and zooming in
     reflows the page instead of making it scroll sideways. */
  @media (min-width: 1400px) { html { font-size: 106.25%; } }
  @media (min-width: 1700px) { html { font-size: 112.5%; } }
  @media (min-width: 2100px) { html { font-size: 118.75%; } }
  /* Long unbroken text (the spec hash, web addresses) wraps instead of
     widening the page. */
  .result-panel li, .result-panel p, .about li, .about p { overflow-wrap: anywhere; }
  .app-main > .tabbable > .nav-tabs { border-bottom: 1px solid var(--pk-line); margin-top: 0.5rem; gap: 0.25rem; }
  .app-main > .tabbable > .nav-tabs .nav-link { border: 0; border-bottom: 3px solid transparent; border-radius: 0; color: #44505e; font-weight: 500; padding: 0.7rem 0.9rem; }
  .app-main > .tabbable > .nav-tabs .nav-link.active { background: transparent; color: var(--pk-blue); border-bottom-color: var(--pk-blue); }
  .progress-steps ol { margin: 0.25rem 0 1rem 0; }
  .screen-nav { display: flex; justify-content: space-between; align-items: center; margin: -0.25rem 0 0.5rem 0; }
  .screen-nav .btn-link { padding: 0.35rem 0; text-decoration: none; font-weight: 500; min-height: 44px; }
  .screen-nav .back-link { color: var(--pk-blue); }
  .screen-nav .restart-link { color: #5a6573; margin-left: auto; }
  .screen-nav .btn-link:hover { text-decoration: underline; }
  .choices { display: grid; grid-template-columns: 1fr; gap: 0.75rem; }
  @media (min-width: 768px) { .choices:not(.list) { grid-template-columns: 1fr 1fr; } .route-choices { grid-template-columns: repeat(3, 1fr) !important; } }
  .choice { background: #fff; border: 1px solid var(--pk-line); border-radius: var(--pk-radius); box-shadow: var(--pk-shadow);
            padding: 1rem 1.15rem; color: var(--pk-navy); transition: transform .08s ease, box-shadow .12s ease, border-color .12s ease; }
  .choice .choice-label { font-size: 1.02rem; }
  .choice:hover, .choice:focus { background: #fff; color: var(--pk-navy); border-color: var(--pk-blue); transform: translateY(-1px);
                                  box-shadow: 0 2px 4px rgba(20,40,75,.08), 0 8px 24px rgba(20,40,75,.10); }
  .choice:hover .choice-help, .choice:focus .choice-help, .choice:active .choice-help { color: #3d4852; }
  .choice:active { background: #eef4fa; color: var(--pk-navy); }
  .choice-safety { background: transparent; box-shadow: none; border: 1.5px dashed #a9b3c1; }
  .route-choices .choice { padding: 1.25rem; min-height: 7.5rem; }
  .route-choices .choice-label { font-size: 1.15rem; color: var(--pk-blue); margin-bottom: 0.25rem; }
  .start-grid { display: grid; grid-template-columns: 1fr; gap: 1rem; }
  @media (min-width: 992px) { .start-grid { grid-template-columns: repeat(3, 1fr); } }
  .start-question { background: #fff; border: 1px solid var(--pk-line); border-radius: var(--pk-radius); box-shadow: var(--pk-shadow); padding: 1rem 1.15rem 0.25rem 1.15rem; }
  .start-question .control-label .h5 { font-weight: 650; color: var(--pk-navy); }
  .start-question .radio { margin-bottom: 0.4rem; }
  .start-question .option-help { display: block; margin-top: 0.15rem; }
  /* Each option's help shows under the chosen option only; the others keep it for screen readers. */
  .start-question .radio label:not(:has(input:checked)) .option-help { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; }
  .saved-projects { margin-top: 1.5rem; background: #fff; border: 1px solid var(--pk-line); border-radius: var(--pk-radius); padding: 0.4rem 1.15rem; }
  .saved-projects > summary { cursor: pointer; color: var(--pk-blue); font-weight: 500; min-height: 44px; display: flex; align-items: center; }
  .saved-projects-grid { display: grid; grid-template-columns: 1fr; gap: 1rem; padding-bottom: 0.5rem; }
  @media (min-width: 768px) { .saved-projects-grid { grid-template-columns: 1fr 1fr; } .saved-projects-grid .mt-4 { margin-top: 0.5rem !important; } }
  .endpoint-card { border: 1px solid var(--pk-line); border-radius: var(--pk-radius); box-shadow: var(--pk-shadow); }
  .endpoint-card > .card-body { padding: 1.5rem 1.75rem; }
  .endpoint-card .card-title { color: var(--pk-navy); font-weight: 650; }
  .status { border-radius: 10px; font-size: 0.92rem; }
  .card-effect { background: var(--pk-bg); border-radius: 10px; padding: 0.75rem 1rem 0.25rem 1rem; margin-bottom: 0.75rem; font-size: 0.95rem; }
  .card-effect h3, .card-effect h4 { font-weight: 650; color: var(--pk-navy); }
  .card-effect ul { margin-bottom: 0.5rem; }
  .form-group-box, .form-settings, .form-guess, .effect-help, .analysis-row, .plan-item, .labs-tool-card { border-radius: var(--pk-radius); border-color: var(--pk-line); box-shadow: var(--pk-shadow); }
  .form-section-effect > .form-group-box { border-color: var(--pk-blue); }
  .form-section-title { color: var(--pk-navy); font-weight: 650; }
  .trail-title { font-size: 0.8rem; }
  .chip { background: #fff; border-color: var(--pk-line); }
  .result-panel { margin-top: 1.5rem; }
  #form_result [tabindex] { scroll-margin-top: 1rem; }
  .result-card { background: #fff; border: 1px solid var(--pk-line); border-radius: var(--pk-radius); box-shadow: var(--pk-shadow); padding: 1.25rem 1.5rem; margin-bottom: 1rem; }
  .result-card h3, .result-card h4 { color: var(--pk-navy); font-weight: 650; }
  .result-main { border-top: 5px solid var(--pk-blue); }
  .result-main .result-headline { font-size: 1.4rem; font-weight: 600; color: var(--pk-navy); line-height: 1.35; }
  .result-more { margin: 0.75rem 0 0 0; }
  .result-more > summary { cursor: pointer; color: var(--pk-blue); min-height: 44px; display: flex; align-items: center; }
  /* The screen's next step, pinned to the bottom of the window. */
  .action-bar { position: sticky; bottom: 0; z-index: 10; justify-content: flex-end; background: rgba(255,255,255,.96);
                backdrop-filter: blur(6px); border-top: 1px solid var(--pk-line); margin: 1.5rem 0 0 0; padding: 0.75rem 1rem;
                box-shadow: 0 -4px 16px rgba(20,40,75,.06); border-radius: var(--pk-radius) var(--pk-radius) 0 0; }
  .action-bar .btn { min-height: 44px; padding-left: 1.25rem; padding-right: 1.25rem; border-radius: 10px; font-weight: 600; }
  .btn-primary { background: var(--pk-blue); border-color: var(--pk-blue); }
  /* The analysis list for 'I know my analysis' (1 November 2026): a large search box with a live
     count, common starting points, and each group as a card whose
     analyses sit in an even grid, with their status as a small label. */
  .known-search { margin: 0.5rem 0 0.75rem 0; }
  .known-search .form-label { font-weight: 600; color: var(--pk-navy); }
  .known-search-box { position: relative; }
  .known-search-icon { position: absolute; left: 0.9rem; top: 50%; transform: translateY(-50%); color: #5a6573; pointer-events: none; }
  .known-search-box .form-control { min-height: 52px; padding-left: 2.6rem; font-size: 1.05rem; border-radius: 12px;
                                    border: 1.5px solid #c6cfdb; box-shadow: var(--pk-shadow); }
  .known-search-box .form-control:focus { border-color: var(--pk-blue); box-shadow: 0 0 0 0.2rem rgba(10,90,140,.18); }
  .known-count-line { font-size: 0.88rem; color: #5a6573; margin: 0.4rem 0 0 0; }
  .known-none { background: #fff; border: 1.5px dashed #a9b3c1; border-radius: var(--pk-radius); padding: 0.75rem 1rem; }
  .known-inline-link { padding: 0; vertical-align: baseline; border: 0; }
  .known-section-title { font-size: 1rem; font-weight: 650; color: var(--pk-navy); text-transform: none; margin: 0; }
  .known-shortcuts { margin: 1.25rem 0 1.5rem 0; }
  .known-shortcut-list { display: flex; flex-wrap: wrap; gap: 0.5rem; margin-top: 0.6rem; }
  .known-shortcut { background: #fff; border: 1px solid var(--pk-line); border-radius: 999px; color: var(--pk-navy); font-size: 0.92rem;
                    font-weight: 500; padding: 0.5rem 0.95rem; min-height: 44px; box-shadow: 0 1px 2px rgba(20,40,75,.06); text-align: left; }
  .known-shortcut:hover, .known-shortcut:focus { border-color: var(--pk-blue); color: var(--pk-blue); }
  .known-groups-head { display: flex; align-items: center; justify-content: space-between; gap: 0.5rem; margin: 0.5rem 0 0.6rem 0; }
  .known-open-all { font-size: 0.9rem; min-height: 44px; padding: 0 0.25rem; }
  .known-family { background: #fff; border: 1px solid var(--pk-line); border-radius: var(--pk-radius); box-shadow: var(--pk-shadow); margin-bottom: 0.6rem; }
  .known-family > summary { list-style: none; cursor: pointer; display: flex; align-items: center; gap: 0.75rem; min-height: 56px;
                            padding: 0.7rem 1.1rem; font-size: 1.05rem; font-weight: 600; color: var(--pk-navy); border-radius: var(--pk-radius); }
  .known-family > summary::-webkit-details-marker { display: none; }
  .known-family > summary::after { content: ''; width: 0.55rem; height: 0.55rem; border-right: 2px solid #5a6573; border-bottom: 2px solid #5a6573;
                                   transform: rotate(45deg); margin: -0.2rem 0.2rem 0 0; transition: transform .12s ease; flex: none; }
  .known-family[open] > summary::after { transform: rotate(225deg); margin-top: 0.2rem; }
  .known-family > summary:hover { background: #f8fafc; }
  .known-family > summary:hover .known-family-label { color: var(--pk-blue); }
  .known-family-label { flex: 1 1 auto; }
  .known-family-count { flex: none; background: #eef3fa; color: var(--pk-blue); border-radius: 999px; font-size: 0.8rem; font-weight: 600;
                        padding: 0.1rem 0.6rem; white-space: nowrap; }
  .known-family[open] > summary { border-bottom: 1px solid var(--pk-line); border-radius: var(--pk-radius) var(--pk-radius) 0 0; }
  .known-family-items { display: grid; grid-template-columns: 1fr; gap: 0.6rem; padding: 0.9rem 1rem 1rem 1rem; }
  @media (min-width: 768px) { .known-family-items { grid-template-columns: 1fr 1fr; } }
  .known-item { display: flex; }
  .known-item[hidden] { display: none; }
  .known-choice { width: 100%; box-shadow: none; border: 1px solid var(--pk-line); padding: 0.8rem 1rem;
                  display: flex; flex-direction: column; align-items: flex-start; justify-content: flex-start; }
  .known-choice .choice-label { font-size: 0.98rem; }
  .known-choice-not { background: #f7f8fa; }
  .known-choice-not .choice-label { color: #3d4852; }
  .known-badge { display: inline-block; margin-top: 0.45rem; border-radius: 999px; padding: 0.05rem 0.55rem; font-size: 0.74rem; font-weight: 600; }
  .known-badge-progress { background: #e8f0fb; color: #2c5a99; }
  .known-badge-soon { background: #fff0d1; color: #7a4f00; }
  .known-badge-not { background: #e9ecef; color: #3d4852; }
  @media print { .topbar, .screen-nav, .action-bar, .saved-projects { display: none !important; } }
  @media print { header, .nav-tabs, .nav-buttons, .labs-sde summary + p, .labs-notice { display: none !important; } }
"

# After each screen change, move keyboard and screen-reader focus to the new
# screen's main heading, so users don't have to tab back down from the top.
copy_js <- "
  // Copy text in the browser (nothing is sent to the server or anywhere else).
  window.pkCopyText = function(text, status, failMsg) {
    var done = function(msg) { if (status) { status.textContent = msg; status.classList.remove('visually-hidden'); } };
    var ok = 'Copied. Paste it anywhere: an email, a document or a message to a colleague.';
    var fail = failMsg || 'Couldn\\'t copy automatically. Select the text in the box below and copy it.';
    // Older browsers and some settings block the clipboard API: copy from a
    // hidden text box instead.
    var fallback = function() {
      var box = document.createElement('textarea');
      box.value = text; box.setAttribute('readonly', ''); box.style.position = 'fixed'; box.style.opacity = '0';
      document.body.appendChild(box); box.select();
      var copied = false; try { copied = document.execCommand('copy'); } catch (e) {}
      document.body.removeChild(box);
      done(copied ? ok : fail);
    };
    if (navigator.clipboard && window.isSecureContext) {
      navigator.clipboard.writeText(text).then(function() { done(ok); }, fallback);
    } else {
      fallback();
    }
  };
  window.pkCopy = function(id) {
    var el = document.getElementById(id);
    if (el) pkCopyText(el.value, document.getElementById(id + '-status'));
  };
  Shiny.addCustomMessageHandler('copy_answers', function(text) {
    pkCopyText(text, document.getElementById('copy-status'));
  });
  Shiny.addCustomMessageHandler('copy_labs', function(text) {
    pkCopyText(text, document.getElementById('labs-copy-status'));
  });
  // Bring the check's result to the top of the window and move focus to it,
  // so everyone sees it and keyboard and screen-reader users hear it. The
  // message can arrive before or after the new result is drawn, so this
  // waits briefly for the output's content to change, and shows it then.
  window.pkShowResult = function(id) {
    var el = document.querySelector('#' + id + ' [tabindex]') || document.getElementById(id);
    if (!el) return;
    el.scrollIntoView({ block: 'start' });
    if (el.hasAttribute('tabindex')) el.focus({ preventScroll: true });
  };
  window.pkResultWatch = {};
  Shiny.addCustomMessageHandler('focus_result', function(id) {
    var w = pkResultWatch[id];
    if (!w) {
      var box = document.getElementById(id);
      if (!box) return;
      w = pkResultWatch[id] = { until: 0, timer: null };
      new MutationObserver(function() {
        if (Date.now() > w.until) return;
        clearTimeout(w.timer); w.timer = setTimeout(function() { pkShowResult(id); }, 60);
      }).observe(box, { childList: true });
    }
    w.until = Date.now() + 1500;
    clearTimeout(w.timer); w.timer = setTimeout(function() { pkShowResult(id); }, 400);
  });
  // A background calculation's estimated progress, updated in place.
  Shiny.addCustomMessageHandler('calc_progress', function(m) {
    var bar = document.getElementById('calc-progress-bar');
    var text = document.getElementById('calc-progress-text');
    if (bar) { if (m.value === null) { bar.removeAttribute('value'); } else { bar.value = m.value; } }
    if (text) text.textContent = m.text;
  });
"
focus_js <- "
  $(document).on('shiny:value', function(e) {
    if (e.name !== 'screen') return;
    setTimeout(function() {
      var h = document.querySelector('#screen h2');
      if (h && document.activeElement && document.activeElement !== document.body && !document.getElementById('screen').contains(document.activeElement)) return;
      if (h) { h.setAttribute('tabindex', '-1'); h.focus({ preventScroll: false }); }
    }, 0);
  });
"

# The tabs that are the same for everyone, built once when the app starts
# (About reads every package's citation(), so building it per visitor is
# slow when many people open the app at once).
about_tab <- about_ui(tree, forms)
whats_new_tab <- whats_new_ui(whats_new)
labs_tab <- labs_ui(tree)
feedback_tab <- feedback_tab_ui(tree)
maintainer_tab <- settings_table_ui(tree)

# A function of the request, so the maintainer's tab is only there when
# asked for (maintainer_view_requested(), R/ui.R).
ui <- function(req) fluidPage(
  lang = "en",
  # A darker primary blue than the default, for 4.5:1 contrast on the page
  # background (links, choice buttons, tabs).
  theme = if (requireNamespace("bslib", quietly = TRUE)) bslib::bs_theme(version = 5, primary = "#0a5a8c"),
  tags$head(tags$title("powerkit (prototype)"), tags$style(HTML(app_css)), tags$style(HTML(map_css)), tags$script(HTML(focus_js)), tags$script(HTML(copy_js)), tags$script(HTML(labs_js)), tags$script(HTML(map_js)), tags$script(HTML(feedback_js)), tags$script(HTML(settings_js)), tags$script(HTML(field_problems_js)), tags$script(HTML(effect_unsure_js)), tags$script(HTML(nav_js)), tags$script(HTML(terms_js))),
  # The name, and that it is a prototype with its version; what the
  # prototype can do is on the About tab (prototype_banner()).
  tags$header(class = "topbar",
    div(class = "topbar-inner",
      h1(class = "brand", "powerkit",
        tags$span(class = "badge-proto", paste(c("Prototype", if (!is.null(v <- powerkit_version())) paste0("v", v)), collapse = " \u00b7 "))),
      div(class = "topbar-tools", terms_toggle_ui(), share_page_ui()))
  ),
  tags$main(
    class = "app-main",
    tabsetPanel(
      id = "tabs",
      # The page the address asks for (?page=labs and so on; page_from_query(), R/ui.R).
      selected = page_from_query(req$QUERY_STRING),
      tabPanel("Plan a power analysis", div(class = "pt-3", uiOutput("progress"), uiOutput("screen"))),
      tabPanel("About", div(class = "pt-3", about_tab)),
      tabPanel("What's new", div(class = "pt-3", whats_new_tab)),
      tabPanel(labs_tab_title, div(class = "pt-3", labs_tab)),
      tabPanel("Feedback", div(class = "pt-3", feedback_tab)),
      if (maintainer_view_requested(req$QUERY_STRING)) tabPanel("For the maintainer: undecided settings", div(class = "pt-3", maintainer_tab))
    )
  )
)

server <- function(input, output, session) {
  # Placeholders for undecided settings show only in the maintainer's view.
  session$userData$maintainer_view <- maintainer_view_requested(isolate(session$clientData$url_search))
  state <- reactiveValues(
    screen = "start",        # start | aim | known | node | card | form | g_vars | g_analyses | g_plan
    from_labs = FALSE,       # planning a replication from the pre-replication notes (Labs)
    labs_seed = NULL,        # the notes' words for "Why this effect size?" (labs_seed_reasoning())
    start = list(),          # the aim (and, from a plan or an older project, the claim and situation)
    route = "choose",        # the route chosen on the start screen
    node = NULL,             # current question id (screening or "Help me choose")
    ctx = list(),            # screening answers later questions depend on
    skip_screening = FALSE,  # "I know my analysis": the list is unfiltered
    history = list(),        # list(node, answer, ctx) for each answer given
    endpoint = NULL,         # end point shown on the card screen
    came_from = NULL,        # "known", "node" or "plan", for the back buttons
    form_values = list(),    # input screen: values typed so far (kept when it's redrawn)
    form_k = 2L,             # input screen: number of mediators (parallel and serial mediation)
    calc = NULL,             # input screen: the last calculation (run_calculation()), for the downloads
    long_spec = NULL,        # E10-E14: the checked spec, with its seed, for the full run or the R script
    answers = list(),        # guided route: variable answers
    ticked = character(), primary = character(), asks = list(), rule = "each",
    plan_id = NULL,          # guided route: the analysis whose input screen is open
    plan_results = list(),   # guided route: the last calculation for each analysis, by analysis id
    plan_values = list(),    # guided route: the values last entered for each analysis, by analysis id
    plan_shared = list(),    # guided route: values entered once for several analyses (shared_values)
    plan_filled = character(), # guided route: shared values filled in on the open input screen
    ws_values = list(),      # whole-study simulation: the values typed on its screen
    ws_calc = NULL,          # whole-study simulation: the last run (run_whole_study())
    ws_spec = NULL,          # whole-study simulation: the spec of the last run, for its download
    study_plan = list()      # the study plan any card can join (plan_entry()), kept until "Start a new plan"
  )

  # Keep the guided route's inputs in state as they change.
  save_guided_variables <- function() {
    for (v in tree$guided$variables) {
      value <- input[[paste0("g_", v$id)]]
      if (!is.null(value)) state$answers[[v$id]] <- value
    }
  }
  # The guided rules also use some screening answers (e.g. measured twice).
  routed_answers <- function() guided_answers(tree, state$answers, state$ctx)
  save_guided_analyses <- function() {
    apps <- applicable_analyses(tree, routed_answers())
    ids <- vapply(apps, function(a) a$id, character(1))
    roles <- vapply(ids, function(id) input[[paste0("role_", id)]] %||% "none", character(1))
    state$ticked <- ids[roles %in% c("main", "extra")]
    state$primary <- ids[roles == "main"]
    for (id in ids) {
      a <- input[[paste0("ask_", id)]]
      if (!is.null(a)) state$asks[[id]] <- a
    }
    if (!is.null(input$g_rule)) state$rule <- input$g_rule
  }

  # Go to where an answer leads: a card, a question, or the route's screen
  # after the screening ("list" or "guided").
  go_to <- function(target) {
    if (is_endpoint_id(target)) {
      state$endpoint <- target; state$came_from <- "node"; state$screen <- "card"
    } else if (identical(target, "list")) {
      state$screen <- "known"
    } else if (identical(target, "guided")) {
      state$screen <- "g_vars"
    } else {
      state$node <- target; state$screen <- "node"
    }
  }
  # Return to the question answered last, with the context as it was then.
  step_back <- function() {
    if (length(state$history) == 0) {
      # Before the first screening question is the aim; before the aim,
      # the start screen.
      state$screen <- if (identical(state$screen, "aim") || is.null(state$start$aim)) "start" else "aim"
      return(invisible())
    }
    last <- state$history[[length(state$history)]]
    state$history <- state$history[-length(state$history)]
    state$node <- last$node; state$ctx <- last$ctx; state$screen <- "node"
  }

  # The input screen's fields and the values typed into them.
  # Screen A's answers for the input screen; opened from the plan, a main
  # analysis takes the plan's claim instead (plan_form_start()).
  form_start <- function() {
    if (identical(state$came_from, "plan")) plan_form_start(state$start, state$plan_id, state$primary, state$rule) else state$start
  }
  current_form_fields <- function() form_fields(form_groups(forms, state$endpoint, state$form_k, form_start()))
  current_form_values <- function() {
    fields <- current_form_fields()
    values <- lapply(fields, function(f) input[[field_input_id(f)]])
    names(values) <- vapply(fields, `[[`, "", "id")
    values[!vapply(values, is.null, logical(1))]
  }
  observeEvent(input$pick, {
    pick <- input$pick
    kind <- sub(":.*$", "", pick)
    value <- sub("^[^:]*:", "", pick)
    if (pick == "check_open" && !is.null(state$checked_project)) {
      project <- state$checked_project
      open_in_app(project, restore_from_project(project$route, tree, forms))
      return()
    }
    if (pick == "home") {
      state$screen <- "start"; state$history <- list(); state$node <- NULL; state$ctx <- list(); state$start <- list()
      state$skip_screening <- FALSE
      state$from_labs <- FALSE; state$labs_seed <- NULL
    } else if (kind == "route") {
      state$start <- list()
      state$route <- value; state$history <- list(); state$ctx <- list()
      state$skip_screening <- FALSE
      if (identical(value, "known")) {
        # "I know my analysis" goes straight to the grouped, searchable
        # list (31 October 2026): no aim and no screening questions.
        state$skip_screening <- TRUE
        state$node <- NULL
        state$screen <- "known"
      } else {
        # The aim comes next, on its own screen.
        state$screen <- "aim"
      }
    } else if (kind == "aim") {
      # Estimation and equivalence go to their cards.
      state$start <- list(aim = value)
      # The aim's goal (equivalence) is carried into the screening, which
      # then doesn't ask it again.
      state$history <- list(); state$ctx <- aim_context(tree, state$start)
      exit <- start_exit(tree, state$start)
      if (!is.null(exit)) {
        state$endpoint <- exit; state$came_from <- "node"; state$screen <- "card"
      } else {
        # Every route starts with the screening questions.
        go_to(resolve_target(tree, start_node(tree), state$ctx, state$route))
      }
    } else if (pick == "skip_screening") {
      # The whole list, with no screening answers to filter it by. The
      # answers given so far are dropped, so the trail doesn't show
      # answers that aren't being applied.
      state$skip_screening <- TRUE
      state$history <- list(); state$ctx <- list(); state$node <- NULL
      state$screen <- "known"
    } else if (pick == "screen_me") {
      # From the unfiltered list back to the screening questions.
      state$skip_screening <- FALSE
      state$history <- list(); state$ctx <- aim_context(tree, state$start)
      go_to(resolve_target(tree, start_node(tree), state$ctx, "known"))
    } else if (kind == "opt") {
      option <- visible_options(tree, tree$nodes[[state$node]], state$ctx)[[as.integer(value)]]
      state$history <- c(state$history, list(list(node = state$node, answer = option$label, ctx = state$ctx)))
      state$ctx <- apply_sets(state$ctx, option)
      go_to(resolve_target(tree, option$`next`, state$ctx, state$route))
    } else if (kind == "continue") {
      # From the guided route to "Help me choose", keeping the screening answers.
      state$route <- value
      go_to(resolve_target(tree, "continue", state$ctx, value))
    } else if (pick == "back") {
      if (state$screen == "card" && identical(state$came_from, "known")) {
        state$screen <- "known"
      } else {
        step_back()
      }
    } else if (kind == "trail") {
      i <- as.integer(value)
      state$node <- state$history[[i]]$node
      state$ctx <- state$history[[i]]$ctx
      state$history <- state$history[seq_len(i - 1)]
      state$screen <- "node"
    } else if (pick == "form") {
      # From the pre-replication notes: the user's own words as the reasoning.
      state$form_values <- if (isTRUE(state$from_labs) && !is.null(state$labs_seed)) list(just_source = state$labs_seed) else list()
      state$form_k <- 2L; state$calc <- NULL
      state$screen <- "form"
    } else if (pick == "form_back") {
      state$form_values <- current_form_values()
      if (identical(state$came_from, "plan")) keep_plan_values(state$form_values)
      state$screen <- if (identical(state$came_from, "plan")) "g_plan" else "card"
    } else if (kind == "gform") {
      # An analysis's input screen, opened from the plan.
      a <- analysis_by_id(tree, value)
      res <- resolve_analysis(tree, a, routed_answers(), state$asks[[value]])
      if (!is.null(res$endpoint) && has_form(forms, res$endpoint)) {
        state$endpoint <- res$endpoint; state$came_from <- "plan"; state$plan_id <- value
        start <- plan_form_values(tree, res$endpoint, state$plan_values[[value]], state$plan_shared)
        n <- plan_form_start(state$start, value, state$primary, state$rule)$n_tests
        if (!is.null(n)) start$values$n_tests <- as.character(n)
        state$form_values <- start$values
        state$plan_filled <- start$filled
        state$form_k <- 2L; state$calc <- NULL
        state$screen <- "form"
      }
    } else if (kind == "ep") {
      state$endpoint <- value; state$came_from <- "known"; state$screen <- "card"
    } else if (kind == "guided") {
      if (state$screen == "g_vars") save_guided_variables()
      if (state$screen == "g_analyses") save_guided_analyses()
      if (state$screen == "g_sim") save_whole_study_values()
      if (identical(value, "simulate")) state$ws_calc <- NULL
      state$screen <- switch(value, variables = "g_vars", analyses = "g_analyses", plan = "g_plan", simulate = "g_sim")
    }
  })

  # Values entered on an input screen opened from the plan: kept for that
  # analysis, and the shared ones for the plan's other analyses.
  keep_plan_values <- function(values) {
    if (is.null(state$plan_id)) return(invisible())
    state$plan_values[[state$plan_id]] <- values
    state$plan_shared <- harvest_shared(tree, state$endpoint, values, state$plan_id, state$plan_shared)
  }
  # A calculation made from the plan is kept for the plan's combined
  # sample size (combined_n_ui()).
  observeEvent(state$calc, {
    calc <- state$calc
    if (identical(state$came_from, "plan") && !is.null(state$plan_id) && identical(calc$status, "ok")) {
      goal <- calc$result$goal_type
      state$plan_results[[state$plan_id]] <- list(endpoint = state$endpoint, goal = goal,
        n = if (identical(goal, "sample_size")) calc$result$n_required$n)
      keep_plan_values(isolate(current_form_values()))
    }
  }, ignoreNULL = TRUE)

  # Re-render the analyses screen when a follow-up question appears or is
  # answered (ticking doesn't need a re-render).
  observeEvent(input$g_rule, state$rule <- input$g_rule, ignoreInit = TRUE)

  # Input screen: redraw for a new number of mediators, keeping the values.
  observeEvent(input$f_n_mediators, {
    k <- as.integer(input$f_n_mediators)
    if (!is.na(k) && k != state$form_k) {
      state$form_values <- current_form_values()
      state$form_k <- k
    }
  }, ignoreInit = TRUE)
  # The effect values the reasoning was written for ("does this still
  # apply?"; source_check() in results.R).
  source_record <- reactiveVal(NULL)
  observeEvent(input$source_still_applies, {
    rec <- source_record()
    if (!is.null(rec)) {
      rec$effect <- effect_snapshot(current_form_fields(), current_form_values())
      source_record(rec)
    }
    check_form()
  })
  observeEvent(input$form_check, check_form())
  check_form <- function() {
    fields <- current_form_fields()
    values <- current_form_values()
    start <- form_start()
    # The claim and whether the sample size is fixed are fields on the
    # input screen (from a plan or an older project, they start at what
    # was given then: form_groups()).
    values$claim <- values$claim %||% start$claim %||% "one" # for the result's note
    values$situation <- if (identical(values$situation, "fixed") && isTRUE(values$goal %in% c("power", "sensitivity", "sensitivity_curve"))) "fixed" else "choose" # for the write-up
    src <- source_check(source_record(), state$endpoint, fields, values)
    source_record(src$record)
    values$source_stale <- src$stale
    values$source_was <- src$was
    problems <- form_problems(fields, values)
    # Next to each field too (first problem per field).
    by_field <- problems[nzchar(names(problems) %||% rep("", length(problems)))]
    by_field <- by_field[!duplicated(names(by_field))]
    session$sendCustomMessage("field_problems", as.list(by_field))
    spec <- if (length(problems) == 0) build_spec(forms, state$endpoint, fields, values)
    # The engine's messages name a field by its path; only the fields shown
    # are offered, as two fields can share a path (E54's r and rs).
    check <- if (length(problems) == 0) check_spec(spec, Filter(function(f) field_applies(f, values), fields))
    state$calc <- NULL
    state$long_spec <- NULL
    cancel_job()
    if (identical(check$status, "ok") && runs_long(forms, state$endpoint) &&
        !has_preview(forms, state$endpoint, spec$goal$type)) {
      # E10-E14, required N: no preview; the R script straight away.
      if (is.null(spec$options$seed)) spec$options$seed <- as.integer(forms$default_seed)
      state$long_spec <- spec
      output$form_result <- renderUI(no_preview_ui(forms, state$endpoint, spec))
      session$sendCustomMessage("focus_result", "form_result")
    } else if (identical(check$status, "ok") && runs_long(forms, state$endpoint)) {
      # E10-E14, power: a rough preview first, in a separate R process. The
      # full run or the R script is offered once the preview is shown.
      if (is.null(spec$options$seed)) spec$options$seed <- as.integer(forms$default_seed)
      state$long_spec <- spec
      usual <- preview_seconds(forms, state$endpoint, spec$goal$type)
      output$form_result <- renderUI(calculating_background_ui(usual,
        sprintf("Running a rough preview (%s simulations)\u2026", whole(preview_nrep(forms)))))
      start_job("preview", preview_spec(spec, preview_nrep(forms)), usual,
        list(ep_id = state$endpoint, fields = fields, values = values, advice = check$advice))
    } else if (identical(check$status, "ok") && form_calculates(forms, state$endpoint) && !identical(values$goal, "sensitivity_curve") &&
               runs_in_background(forms, state$endpoint, spec)) {
      # Long runs (E9): a separate R process, polled below, with an estimated
      # progress bar and a Cancel button.
      if (is.null(spec$options$seed)) spec$options$seed <- as.integer(forms$default_seed)
      usual <- usual_seconds(forms, state$endpoint, spec$goal$type)
      output$form_result <- renderUI(calculating_background_ui(usual))
      start_job("calc", spec, usual, list(ep_id = state$endpoint, fields = fields, values = values, advice = check$advice))
    } else if (identical(check$status, "ok") && form_calculates(forms, state$endpoint)) {
      # Show "Calculating" first; the engine runs once that has reached the
      # browser (seconds for these end points).
      output$form_result <- renderUI(calculating_ui())
      ep_id <- state$endpoint
      session$onFlushed(function() {
        calc <- if (identical(values$goal, "sensitivity_curve")) run_sensitivity_curve(spec, seed = forms$default_seed) else run_calculation(spec, seed = forms$default_seed)
        if (identical(calc$status, "ok")) calc$cost_line <- cost_line(calc$spec, calc$result, seed = forms$default_seed, values = values)
        isolate(state$calc <- calc)
        output$form_result <- renderUI(result_panel_ui(tree, forms, ep_id, fields, values, calc, check$advice))
        session$sendCustomMessage("focus_result", "form_result")
      }, once = TRUE)
    } else {
      output$form_result <- renderUI(form_result_ui(tree$endpoints[[state$endpoint]], problems, check, spec))
    }
    session$sendCustomMessage("focus_result", "form_result")
  }
  # The explore panel: power by N for the effect on the slider. It reads the
  # last calculation and never changes the plan.
  output$explore_plot <- renderPlot({
    calc <- state$calc
    req(calc, identical(calc$status, "ok"), input$explore_effect, !is.null(explore_effect(calc$spec)))
    df <- explore_curve(calc$spec, calc$result, input$explore_effect, seed = forms$default_seed)
    par(mar = c(4.5, 4.5, 1, 1))
    plot(df$n, df$power, type = "b", pch = 19, ylim = c(0, 1), xlab = "Participants analysed", ylab = "Power", las = 1)
    abline(h = c(0.8, 0.95), lty = 2, col = "grey50")
    text(min(df$n), c(0.8, 0.95), c("80%", "95%"), pos = 3, cex = 0.8, col = "grey40")
  })

  # Three effects (conservative, the plan's, optimistic): power by N for
  # each, and the N each needs. Reads the last calculation; never changes
  # the plan.
  scenario_inputs <- reactive({
    calc <- state$calc
    req(calc, identical(calc$status, "ok"), !is.null(explore_effect(calc$spec)))
    vals <- c(conservative = input$scenario_conservative %||% NA, optimistic = input$scenario_optimistic %||% NA)
    req(any(!is.na(vals)))
    list(calc = calc, vals = vals)
  }) |> debounce(600)
  scenario_results <- reactive({
    x <- scenario_inputs()
    n <- scenario_n(x$calc$spec, x$calc$result, x$vals[["conservative"]], x$vals[["optimistic"]], seed = forms$default_seed)
    list(spec = x$calc$spec, n = n,
      curves = scenario_curves(x$calc$spec, x$calc$result, x$vals[["conservative"]], x$vals[["optimistic"]], n = n, seed = forms$default_seed))
  })
  output$scenario_plot <- renderPlot({
    df <- scenario_results()$curves
    keys <- intersect(names(scenario_names), unique(df$scenario))
    style <- list(conservative = list(col = "#b45309", lty = 2), expected = list(col = "#14284B", lty = 1), optimistic = list(col = "#0A5A8C", lty = 3))
    par(mar = c(4.5, 4.5, 1, 1))
    plot(NA, xlim = range(df$n), ylim = c(0, 1), xlab = "Participants analysed", ylab = "Power", las = 1)
    for (k in keys) {
      d <- df[df$scenario == k, ]
      lines(d$n, d$power, col = style[[k]]$col, lty = style[[k]]$lty, lwd = 2.5)
    }
    abline(h = c(0.8, 0.95), lty = 2, col = "grey70")
    legend("bottomright", legend = unname(scenario_names[keys]), col = vapply(keys, function(k) style[[k]]$col, ""),
      lty = vapply(keys, function(k) style[[k]]$lty, 0), lwd = 2.5, bty = "n")
  })
  output$scenario_n <- renderUI({
    x <- scenario_results()
    p(class = "small", scenario_sentence(x$spec, x$n))
  })

  # A background calculation: one at a time per session.
  job <- new.env()
  job_running <- reactiveVal(FALSE)
  cancel_job <- function() {
    if (!is.null(job$process) && job$process$is_alive()) job$process$kill()
    job$process <- NULL
    job_running(FALSE)
  }
  # kind: "calc" (E9, or E10-E12's full run) shows the result; "preview"
  # shows the preview panel.
  # Nothing starts while the server is at its limit (background_limit()).
  # `target`: the output the run's result is shown in (the input screen's,
  # or the whole-study simulation's).
  start_job <- function(kind, spec, usual, shown, target = "form_result") {
    if (background_running() >= background_limit(forms)) {
      output[[target]] <- renderUI(busy_ui())
      session$sendCustomMessage("focus_result", target)
      return(invisible(FALSE))
    }
    job$kind <- kind
    job$target <- target
    job$screen <- isolate(state$screen)
    job$process <- register_background(start_background_calculation(spec, seed = forms$default_seed))
    job$started <- Sys.time()
    job$usual <- usual
    job$shown <- shown
    job_running(TRUE)
  }
  session$onSessionEnded(cancel_job)
  observe({
    req(job_running())
    invalidateLater(500)
    elapsed <- as.numeric(difftime(Sys.time(), job$started, units = "secs"))
    if (job$process$is_alive()) {
      value <- progress_estimate(elapsed, job$usual)
      session$sendCustomMessage("calc_progress", list(
        value = if (is.na(value)) NULL else round(100 * value),
        text = progress_text(elapsed, job$usual)))
      return()
    }
    calc <- collect_background_calculation(job$process)
    job$process <- NULL
    job_running(FALSE)
    shown <- job$shown
    if (identical(job$kind, "preview")) {
      # Not a result: nothing to download from it.
      range <- if (identical(calc$status, "ok")) preview_range(calc$result)
      output$form_result <- renderUI(preview_panel_ui(forms, shown$ep_id, calc, state$long_spec, range))
    } else if (identical(job$kind, "whole_study")) {
      state$ws_calc <- calc
      script <- if (identical(calc$status, "ok")) {
        spec <- state$ws_spec
        whole_study_script_ui(forms, isolate(whole_study_screen())$plan, spec$goal$n, spec$claim,
          sum(vapply(spec$analyses, function(a) identical(a$role, "main"), logical(1))))
      }
      output$ws_result <- renderUI(whole_study_result_ui(calc, state$plan_values, departure = forms$departures[["13"]], script = script))
      session$sendCustomMessage("focus_result", "ws_result")
      return()
    } else {
      state$calc <- calc
      output$form_result <- renderUI(result_panel_ui(tree, forms, shown$ep_id, shown$fields, shown$values, calc, shown$advice))
    }
    session$sendCustomMessage("focus_result", "form_result")
  })
  # E10-E12, power: the full run at the app's defaults, after the preview.
  observeEvent(input$full_run, {
    req(state$long_spec)
    spec <- state$long_spec
    usual <- full_seconds(forms, state$endpoint, spec$goal$type)
    output$form_result <- renderUI(calculating_background_ui(usual,
      sprintf("Running the full analysis (%s simulations)\u2026", whole(spec$options$nrep %||% 1000L))))
    start_job("calc", spec, usual, job$shown)
    session$sendCustomMessage("focus_result", "form_result")
  })
  observeEvent(input$calc_cancel, {
    target <- job$target %||% "form_result"
    cancel_job()
    output[[target]] <- renderUI(cancelled_ui())
    session$sendCustomMessage("focus_result", target)
  })
  # Leaving the screen a run was started from stops it.
  observeEvent(state$screen, if (!identical(state$screen, job$screen %||% "form")) cancel_job(), ignoreInit = TRUE)

  # Whole-study simulation (experimental; R/whole-study.R). The plan, the
  # values the engine says the population needs, and the run.
  whole_study_screen <- reactive({
    answers <- routed_answers()
    plan <- whole_study_plan(tree, answers, state$ticked, state$primary, state$asks)
    if (!isTRUE(plan$ok)) return(list(plan = plan))
    labels <- whole_study_labels(plan$roles, state$plan_values)
    skeleton <- whole_study_skeleton(plan, labels)
    parameters <- engine_function("whole_study_parameters")
    params <- if (is.null(parameters)) NULL else tryCatch(parameters(skeleton), error = function(e) NULL)
    list(plan = plan, labels = labels, skeleton = skeleton, params = params)
  })
  save_whole_study_values <- function() {
    ws <- whole_study_screen()
    if (!is.null(ws$params)) state$ws_values <- whole_study_values(input, ws$params)
  }
  observeEvent(input$ws_run, {
    ws <- whole_study_screen()
    req(ws$params)
    values <- whole_study_values(input, ws$params)
    state$ws_values <- values
    built <- whole_study_spec(ws$skeleton, ws$params, values, state$rule %||% "each", nrep = forms$whole_study$quick_nrep)
    problems <- built$problems %||% whole_study_check(built$spec)
    if (length(problems)) {
      output$ws_result <- renderUI(div(class = "form-problems", role = "alert", tabindex = "-1",
        h3(class = "h5", "Please check"), tags$ul(lapply(problems, tags$li))))
      session$sendCustomMessage("focus_result", "ws_result")
      return()
    }
    cancel_job()
    state$ws_calc <- NULL
    state$ws_spec <- built$spec
    usual <- whole_study_seconds(forms, ws$plan, built$spec$options$nrep)
    output$ws_result <- renderUI(calculating_background_ui(usual,
      sprintf("Simulating the whole study (%s simulated studies)\u2026", whole(built$spec$options$nrep))))
    start_job("whole_study", built$spec, usual, list(), target = "ws_result")
    session$sendCustomMessage("focus_result", "ws_result")
  })
  # The R script for the full run, or the sample size search, on the
  # user's computer (export_whole_study_script()).
  output$ws_download_script <- downloadHandler(
    filename = function() if (identical(input$ws_script_goal, "power")) "powerkit-whole-study-full-run.R" else "powerkit-whole-study-sample-size.R",
    content = function(file) {
      export <- engine_function("export_whole_study_script")
      goal <- input$ws_script_goal %||% "sample_size"
      spec <- whole_study_script_spec(state$ws_spec, forms, goal, input$ws_target %||% "0.8")
      export(spec, file = file, run_time = whole_study_script_time(forms, whole_study_screen()$plan, goal))
    }
  )
  output$ws_download_spec <- downloadHandler(
    filename = function() "powerkit-whole-study-spec.json",
    content = function(file) {
      jsonlite::write_json(state$ws_spec, file, auto_unbox = TRUE, pretty = TRUE, digits = NA)
    }
  )

  # The engine's own exports, for the last result.
  output$download_script <- downloadHandler(
    filename = function() sprintf("powerkit-%s-script.R", state$endpoint),
    content = function(file) {
      export <- engine_function("export_script")
      export(state$calc$spec, state$calc$result, file = file)
    }
  )
  output$download_citations <- downloadHandler(
    filename = function() sprintf("powerkit-%s-citations.txt", state$endpoint),
    content = function(file) {
      export <- engine_function("export_citations")
      export(state$calc$result, format = "text", file = file)
    }
  )
  output$download_simulated_data <- downloadHandler(
    filename = function() sprintf("SIMULATED-not-real-data-%s.csv", state$endpoint),
    content = function(file) {
      simulate <- engine_function("simulated_data")
      n <- simulated_data_n_for(state$calc$spec, state$calc$result)
      simulate(state$calc$spec, n, seed = state$calc$result$provenance$seed %||% 1, file = file)
    }
  )
  # E10-E14: the R script that runs the full analysis on the user's computer.
  output$download_run_script <- downloadHandler(
    filename = function() sprintf("powerkit-%s-run-full-analysis.R", state$endpoint),
    content = function(file) {
      export <- engine_function("export_run_script")
      export(state$long_spec, file = file, run_time = script_run_time(forms, state$endpoint, state$long_spec$goal$type))
    }
  )
  # The study plan any card can join (R/study-plan.R).
  output$study_plan_bar <- renderUI({
    calc <- state$calc
    if (is.null(calc) || !identical(calc$status, "ok")) return(NULL)
    hash <- calc$result$provenance$spec_hash
    in_plan <- any(vapply(state$study_plan, function(e) identical(e$result$provenance$spec_hash, hash), logical(1)))
    study_plan_bar_ui(state$study_plan, in_plan)
  })
  observeEvent(input$plan_add, {
    calc <- state$calc
    if (is.null(calc) || !identical(calc$status, "ok")) return()
    route <- project_route(reactiveValuesToList(state), current_form_values())
    state$study_plan <- c(state$study_plan, list(plan_entry(tree, state$endpoint, calc, route)))
  })
  observeEvent(input$plan_view, { cancel_job(); state$screen <- "study_plan" })
  observeEvent(input$plan_clear, state$study_plan <- list())
  observeEvent(input$plan_joint, {
    entries <- state$study_plan
    joint <- engine_function("joint_power")
    rho <- suppressWarnings(as.numeric(input$plan_rho))
    out <- if (is.null(joint)) {
      "Joint power needs powerkit's engine, which isn't installed where this prototype is running."
    } else if (is.na(rho)) {
      "Enter the correlation between the outcomes first."
    } else {
      tryCatch(joint(plan_specs(entries), rho = rho, n = plan_largest_n(entries)), error = function(e) {
        if (inherits(e, "powerkit_error")) conditionMessage(e) else "Joint power couldn't be calculated for this plan."
      })
    }
    output$plan_joint_result <- renderUI(if (is.character(out)) div(class = "form-problems", role = "alert", out) else {
      words <- joint_power_sentence(out, entries)
      div(class = "result-panel mt-2", role = "status", p(tags$strong(words[["headline"]])), p(class = "small", words[["detail"]]))
    })
  })
  observeEvent(input$plan_more, {
    # The next analysis, found by "Help me choose" from the start.
    state$start <- list(); state$route <- "choose"; state$history <- list(); state$ctx <- list()
    state$skip_screening <- FALSE; state$calc <- NULL
    state$screen <- "aim"
  })
  output$download_study_plan <- downloadHandler(
    filename = function() study_plan_file_name(),
    content = function(file) {
      write <- engine_function("write_study_plan")
      write(plan_analyses(state$study_plan), file = file)
    }
  )
  # Project files: the engine writes and reads them (write_project(),
  # read_project()); the app passes the route and puts the screen back.
  output$download_project <- downloadHandler(
    filename = function() project_file_name(state$endpoint),
    content = function(file) {
      write <- engine_function("write_project")
      write(state$calc$spec, state$calc$result,
        route = project_route(reactiveValuesToList(state), current_form_values()), file = file)
    }
  )
  observeEvent(input$open_project, {
    path <- input$open_project$datapath
    # A study plan file opens as the plan; anything else as a project.
    read_plan <- engine_function("read_study_plan")
    plan <- if (!is.null(read_plan)) tryCatch(read_plan(path), error = function(e) NULL)
    if (!is.null(plan)) {
      state$study_plan <- lapply(plan$analyses, function(p) plan_entry_from_project(tree, p))
      state$screen <- "study_plan"
      return()
    }
    read <- engine_function("read_project")
    project <- if (is.null(read)) {
      "Opening a project needs powerkit's engine, which isn't installed where this prototype is running."
    } else {
      tryCatch(read(path), error = function(e) {
        if (inherits(e, "powerkit_error")) conditionMessage(e) else "This file couldn't be opened as a powerkit project."
      })
    }
    restored <- if (is.character(project)) project else restore_from_project(project$route, tree, forms)
    if (is.character(restored)) {
      output$open_project_message <- renderUI(div(class = "alert alert-warning", role = "alert", restored))
      return()
    }
    open_in_app(project, restored)
  })
  open_in_app <- function(project, restored) {
    cancel_job()
    state$from_labs <- FALSE; state$labs_seed <- NULL
    state$calc <- NULL
    state$long_spec <- NULL
    for (name in names(restored)) state[[name]] <- restored[[name]]
    # A file with the whole result shows it straight away, without running
    # it again (decided 31 October 2026); older files are run as before.
    calc <- saved_calc(project)
    if (is.null(calc)) {
      output$form_result <- renderUI(project_opened_ui(project))
      return()
    }
    state$calc <- calc
    ep_id <- state$endpoint
    output$form_result <- renderUI(tagList(
      project_opened_ui(project, shown = TRUE),
      result_panel_ui(tree, forms, ep_id, current_form_fields(), current_form_values(), calc)
    ))
  }
  observeEvent(input$rerun_saved, check_form())
  # The plan checker: the same file, read for a reviewer (nothing is run).
  read_project_file <- function(path) {
    read <- engine_function("read_project")
    if (is.null(read)) return("Opening a project needs powerkit's engine, which isn't installed where this prototype is running.")
    tryCatch(read(path), error = function(e) {
      if (inherits(e, "powerkit_error")) conditionMessage(e) else "This file couldn't be opened as a powerkit project."
    })
  }
  observeEvent(input$check_project, {
    project <- read_project_file(input$check_project$datapath)
    problem <- if (is.character(project)) project else restore_from_project(project$route, tree, forms)
    if (is.character(problem)) {
      output$check_project_message <- renderUI(div(class = "alert alert-warning", role = "alert", problem))
      return()
    }
    state$checked_project <- project
    state$screen <- "check"
  })
  observeEvent(input$form_copy, {
    text <- answers_text(tree, route_by_id(tree, state$route)$label, state$history, state$endpoint, current_form_fields(), current_form_values())
    output$form_copy_text <- renderUI(div(class = "form-field mt-2",
      textAreaInput("copy_text_box", "Your answers as text (select and copy if the button didn't)", value = text, rows = 8, width = "100%")))
    session$sendCustomMessage("copy_answers", text)
  })
  # Labs (experimental): pre-replication notes (R/labs.R). The notes live in
  # the browser tab; the server only reads them to build the download.
  labs_answers <- function() stats::setNames(lapply(labs_fields, function(f) input[[f$id]] %||% ""),
    vapply(labs_fields, `[[`, character(1), "id"))
  labs_sde_calc <- reactiveVal(NULL)
  observeEvent(input$labs_sde_run, {
    labs_sde_calc(NULL)
    if (!nzchar(input$labs_test %||% "")) {
      output$labs_sde_result <- renderUI(div(class = "form-problems", role = "alert", "Choose the original study's test first."))
      return()
    }
    calc <- labs_sde(forms, input$labs_test, input$labs_n, input$labs_power, input$labs_alpha,
      p1 = input$labs_p1, rows = input$labs_rows, cols = input$labs_cols)
    if (identical(calc$status, "problems") || identical(calc$status, "error")) {
      output$labs_sde_result <- renderUI(div(class = "form-problems", role = "alert",
        tags$ul(lapply(calc$problems %||% calc$message, tags$li))))
      return()
    }
    labs_sde_calc(calc)
    smallest <- trimws(input$labs_smallest %||% "")
    output$labs_sde_result <- renderUI(div(class = "result-panel mt-2", role = "status",
      p(tags$strong(labs_sde_sentence(tree, calc, input$labs_power))),
      p(if (nzchar(smallest)) paste0("The smallest effect that matters, from step 2: \u201c", smallest, "\u201d")
        else "Step 2 has no smallest effect that matters yet; writing one there gives this number something to be compared with."),
      p(class = "small", labs_provenance(calc))))
  })
  labs_sde_notes <- function() {
    calc <- labs_sde_calc()
    if (is.null(calc)) return(NULL)
    list(sentence = labs_sde_sentence(tree, calc, calc$spec$goal$power), provenance = labs_provenance(calc))
  }
  # Labs: plan from a published result (R/labs.R). The engine converts and
  # gives the safeguard value; the app only shows them.
  output$pub_from_ui <- renderUI({
    if (!nzchar(input$pub_design %||% "")) return(NULL)
    selectInput("pub_from", "What did the paper report?", choices = published_from_choices(input$pub_design), selectize = FALSE, width = "100%")
  })
  observeEvent(input$pub_run, {
    values <- lapply(stats::setNames(nm = c("pub_design", "pub_from", "pub_value", "pub_df1", "pub_df", "pub_n", "pub_n1", "pub_n2", "pub_protection")),
      function(id) input[[id]])
    out <- published_result(values, engine_function("convert_effect"), engine_function("safeguard_effect"))
    output$pub_result <- renderUI(if (length(out$problems)) {
      div(class = "form-problems", role = "alert", tags$ul(lapply(out$problems, tags$li)))
    } else {
      div(class = "result-panel mt-2", role = "status", lapply(out$lines, p))
    })
  })
  # Labs: the picture of power, from the engine's power_picture().
  picture <- reactive({
    tryCatch(engine_function("power_picture")(as.numeric(input$picture_n %||% 64), as.numeric(input$picture_d %||% 0.5),
      alpha = as.numeric(input$picture_alpha %||% "0.05")), error = function(e) NULL)
  })
  output$picture_plot <- renderPlot({
    req(picture())
    picture_plot(picture())
  }, alt = reactive(if (is.null(picture())) "The picture of power" else
    sprintf("Two t distributions: power is %.1f%% for d = %s with %s participants at alpha = %s.",
      100 * picture()$power, format(picture()$d), format(picture()$n), format(picture()$alpha))))
  output$picture_numbers <- renderUI(if (is.null(picture())) {
    p("The picture needs powerkit's engine.")
  } else picture_numbers(picture()))
  # Labs map: the page of the analysis clicked on the map.
  output$map_page <- renderUI(map_page_ui(tree, input$map_endpoint))
  output$labs_next <- renderUI(labs_next_ui(input$labs_outcome, nzchar(input$labs_test %||% "")))
  labs_text <- function() labs_markdown(labs_answers(), input$labs_outcome, labs_sde_notes())
  output$labs_download <- downloadHandler(
    filename = function() sprintf("pre-replication-notes-%s.md", format(Sys.Date())),
    content = function(file) writeLines(labs_text(), file, useBytes = TRUE)
  )
  observeEvent(input$labs_copy, {
    text <- labs_text()
    output$labs_copy_text <- renderUI(div(class = "form-field mt-2",
      textAreaInput("labs_copy_box", "Your notes as text (select and copy if the button didn't)", value = text, rows = 10, width = "100%")))
    session$sendCustomMessage("copy_labs", text)
  })
  # Step 6: into the main app, on the original's test where there is one.
  # A plan in progress there is only replaced after asking; the notes stay
  # in Labs, and the user's own words go into "Why this effect size?".
  labs_start_plan <- function() {
    test <- input$labs_test %||% ""
    cancel_job()
    state$history <- list(); state$node <- NULL; state$ctx <- list(); state$calc <- NULL
    state$from_labs <- TRUE
    state$labs_seed <- labs_seed_reasoning(labs_answers())
    if (identical(input$labs_outcome, "go") && nzchar(test)) {
      state$endpoint <- test; state$came_from <- "known"; state$screen <- "card"
    } else {
      state$screen <- "start"
    }
    updateTabsetPanel(session, "tabs", selected = "Plan a power analysis")
  }
  plan_in_progress <- function() !identical(state$screen, "start") || length(state$history) > 0
  observeEvent(input$labs_plan, {
    if (plan_in_progress()) showModal(labs_replace_modal()) else labs_start_plan()
  })
  observeEvent(input$labs_plan_confirm, { removeModal(); labs_start_plan() })
  observeEvent(input$labs_back, {
    session$sendCustomMessage("labs_open", "prereplication")
    updateTabsetPanel(session, "tabs", selected = labs_tab_title)
  })
  # The one way in from the main route (labs_signpost_ui()).
  observeEvent(input$go_labs, {
    session$sendCustomMessage("labs_open", "prereplication")
    updateTabsetPanel(session, "tabs", selected = labs_tab_title)
  })
  # The Feedback tab: from the header link, or from "Something doesn't fit?"
  # (which picks "confusing").
  observeEvent(input$go_feedback, {
    if (input$go_feedback %in% names(feedback_kinds)) updateRadioButtons(session, "fb_kind", selected = input$go_feedback)
    updateTabsetPanel(session, "tabs", selected = "Feedback")
  })
  # The Feedback tab's message: where the user is (if they agree), and the
  # values on the input screen.
  feedback_context_now <- reactive({
    if (!isTRUE(input$fb_include_path %||% TRUE)) return(character())
    on_screen <- state$screen %in% c("card", "form")
    feedback_context(tree, feedback_screen_label(state$screen),
      route_label = if (state$screen != "start") route_by_id(tree, state$route)$label,
      history = state$history, endpoint = if (on_screen) state$endpoint,
      values = if (state$screen == "form") tryCatch(current_form_values(), error = function(e) list()) else list(),
      updated = if (length(whats_new)) whats_new[[1]]$date)
  })
  output$fb_preview <- renderUI({
    kind <- input$fb_kind %||% "bug"
    message <- input$fb_message %||% ""
    feedback_preview_ui(feedback_subject(kind, message), feedback_text(kind, message, feedback_context_now()))
  })
  # Send: stored in the feedback database (send_feedback()), at most ten
  # messages per visit.
  feedback_sent <- 0L
  observeEvent(input$fb_send, {
    message <- trimws(input$fb_message %||% "")
    result <- if (nchar(message) < 3) {
      "empty"
    } else if (feedback_sent >= 10L) {
      "limit"
    } else {
      send_feedback(feedback_config(tree), input$fb_kind %||% "other", message,
        context = feedback_context_now(), contact = trimws(input$fb_contact %||% ""),
        meta = list(app_updated = if (length(whats_new)) whats_new[[1]]$date,
          browser = substr(session$request$HTTP_USER_AGENT %||% "", 1, 200)))
    }
    if (identical(result, "ok")) {
      feedback_sent <<- feedback_sent + 1L
      updateTextAreaInput(session, "fb_message", value = "")
    }
    session$sendCustomMessage("fb_status", feedback_result_message(result))
  })
  # The four steps, apart from the screen itself, so that showing a result
  # never redraws the form.
  output$progress <- renderUI({
    has_result <- !is.null(state$calc) && identical(state$calc$status, "ok")
    progress_ui(screen_step(state$screen, has_result))
  })
  # Browser history (nav_js, R/ui.R): an entry for each screen or tab change,
  # and Back or Forward restores the app as it was at that entry.
  nav <- new.env()
  nav$snaps <- list(); nav$pos <- 0L
  nav_snapshot <- function() {
    snap <- lapply(nav_fields, function(f) state[[f]])
    names(snap) <- nav_fields
    snap$tab <- input$tabs
    snap
  }
  observe({
    key <- nav_key(state$screen, state$node, state$endpoint, length(state$history), input$tabs)
    isolate({
      if (nav$pos > 0 && identical(nav$snaps[[nav$pos]]$key, key)) return()
      # Leaving an input screen: keep what was typed with its entry.
      if (nav$pos > 0 && identical(nav$snaps[[nav$pos]]$screen, "form")) {
        typed <- tryCatch(current_form_values(), error = function(e) NULL)
        if (length(typed)) nav$snaps[[nav$pos]]$form_values <- typed
      }
      # A new step after going back drops the steps that were ahead.
      if (nav$pos < length(nav$snaps)) nav$snaps <- nav$snaps[seq_len(nav$pos)]
      snap <- nav_snapshot(); snap$key <- key
      nav$snaps[[nav$pos + 1L]] <- snap
      nav$pos <- nav$pos + 1L
      session$sendCustomMessage("pk_nav", list(pos = nav$pos, replace = nav$pos == 1L, page = page_slug(input$tabs)))
    })
  })
  observeEvent(input$pk_nav_to, {
    to <- as.integer(input$pk_nav_to)
    if (is.na(to) || to < 1L || to > length(nav$snaps) || to == nav$pos) return()
    # Keep what was typed on an input screen, for coming forward again.
    if (identical(state$screen, "form")) nav$snaps[[nav$pos]]$form_values <- current_form_values()
    cancel_job()
    snap <- nav$snaps[[to]]
    nav$pos <- to
    for (f in nav_fields) state[[f]] <- snap[[f]]
    state$calc <- NULL; state$long_spec <- NULL
    if (!identical(input$tabs, snap$tab) && !is.null(snap$tab)) updateTabsetPanel(session, "tabs", selected = snap$tab)
  })
  output$screen <- renderUI({
    switch(
      state$screen,
      aim = aim_ui(tree),
      start = tagList(start_ui(tree, isolate(state$start)),
        tags$details(class = "saved-projects",
          tags$summary("Have a saved project, or one someone shared with you?"),
          div(class = "saved-projects-grid", open_project_ui(), check_project_ui()))),
      check = plan_check_ui(tree, forms, state$checked_project),
      study_plan = tagList(screen_nav_ui(back = NULL), study_plan_ui(state$study_plan)),
      known = known_ui(tree, state$history, if (isTRUE(state$skip_screening)) NULL else state$ctx),
      node = node_ui(tree, state$node, state$history, state$ctx, state$route),
      card = tagList(
        screen_nav_ui(),
        if (isTRUE(state$from_labs)) labs_return_ui(),
        trail_ui(state$history),
        card_ui(tree, state$endpoint, history = state$history),
        card_nav_ui(forms, state$endpoint),
        mismatch_ui("mismatch-path", path_text(tree, route_by_id(tree, state$route)$label, state$history, state$endpoint))
      ),
      form = tagList(
        if (isTRUE(state$from_labs)) labs_return_ui(on_form = TRUE, carried = !is.null(state$labs_seed)),
        form_ui(tree, forms, state$endpoint, form_groups(forms, state$endpoint, state$form_k, form_start()), isolate(state$form_values), state$history,
          from_plan = identical(state$came_from, "plan"),
          carried = if (identical(state$came_from, "plan")) carried_note_ui(tree, state$plan_filled))),
      g_vars = guided_variables_ui(tree, state$answers, state$ctx, state$history),
      g_analyses = guided_analyses_ui(tree, routed_answers(), state$ticked, state$primary, state$asks, isolate(state$rule)),
      g_plan = guided_plan_ui(tree, routed_answers(), state$ticked, state$primary, state$asks, state$rule,
        history = state$history, route_label = route_by_id(tree, state$route)$label, raw_answers = state$answers, forms = forms,
        results = state$plan_results, shared = state$plan_shared),
      g_sim = {
        ws <- whole_study_screen()
        if (!isTRUE(ws$plan$ok) || is.null(ws$params)) {
          tagList(screen_nav_ui("guided:plan", "Back to your plan"), h2("Simulate the whole study"),
            if (!isTRUE(ws$plan$ok)) whole_study_entry_ui(ws$plan)
            else p("The simulation needs powerkit's engine, which isn't installed where this prototype is running."))
        } else {
          isolate(whole_study_ui(forms, ws$plan, ws$params, ws$labels, whole_study_prefill(state$plan_shared),
            whole_study_start_n(state$plan_results, state$primary), state$rule %||% "each",
            values = state$ws_values, path = state$ws_values$path))
        }
      }
    )
  })
}

shinyApp(ui, server)
