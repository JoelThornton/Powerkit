# Extracted from test-forms.R:46

# prequel ----------------------------------------------------------------------
form_ids <- names(forms$forms)
validate <- engine_validator(file.path(repo_dir, "engine"))
skip_without_engine <- function() skip_if(is.null(validate), "powerkit's engine isn't available here")
values_for <- function(ep) form_examples[[ep]]
fields_for <- function(ep, k = 2) form_fields(form_groups(forms, ep, k))

# test -------------------------------------------------------------------------
for (ep in form_ids) {
    groups <- form_groups(forms, ep)
    effect <- Filter(function(f) isTRUE(f$effect), form_fields(groups))
    expect_gt(length(effect), 0, label = ep)
    for (f in effect) {
      expect_null(f$default, label = paste(ep, f$id))
      html <- as.character(field_ui(f, f$default))
      expect_match(html, 'value=""', fixed = TRUE, label = paste(ep, f$id))
      expect_match(html, "(required; starts empty)", fixed = TRUE)
      expect_match(html, 'aria-required="true"', fixed = TRUE)
    }
    problems <- form_problems(form_fields(groups), list())
    for (f in effect) expect_true(any(grepl(f$label, problems, fixed = TRUE)), label = paste(ep, f$id))
    expect_true(any(grepl("powerkit doesn't fill in effect sizes", problems, fixed = TRUE)))
  }
