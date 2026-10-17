# Extracted from test-forms.R:29

# prequel ----------------------------------------------------------------------
form_ids <- names(forms$forms)
validate <- engine_validator(file.path(repo_dir, "engine"))
skip_without_engine <- function() skip_if(is.null(validate), "powerkit's engine isn't available here")
values_for <- function(ep) form_examples[[ep]]
fields_for <- function(ep, k = 2) form_fields(form_groups(forms, ep, k))

# test -------------------------------------------------------------------------
for (ep in form_ids) {
    groups <- form_groups(forms, ep)
    html <- as.character(form_ui(tree, forms, ep, groups))
    for (f in form_fields(groups)) {
      expect_match(html, sprintf('<label class="control-label" id="f_%s-label" for="f_%s">', f$id, f$id), fixed = TRUE, label = paste(ep, f$id))
    }
    for (g in groups) for (h in if (!is.null(g$input)) glossary_for(tree, g$input) else list()) {
      expect_match(html, sprintf("<dfn>%s</dfn>", htmltools::htmlEscape(h$term)), fixed = TRUE, label = paste(ep, h$term))
    }
  }
