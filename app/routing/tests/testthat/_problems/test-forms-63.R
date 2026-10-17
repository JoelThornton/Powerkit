# Extracted from test-forms.R:63

# prequel ----------------------------------------------------------------------
form_ids <- names(forms$forms)
validate <- engine_validator(file.path(repo_dir, "engine"))
skip_without_engine <- function() skip_if(is.null(validate), "powerkit's engine isn't available here")
values_for <- function(ep) form_examples[[ep]]
fields_for <- function(ep, k = 2) form_fields(form_groups(forms, ep, k))

# test -------------------------------------------------------------------------
alpha <- function(ep) Filter(function(f) f$id == "alpha", fields_for(ep))[[1]]
for (ep in form_ids) {
    f <- alpha(ep)
    expect_equal(f$default, 0.05, label = ep)
    expect_match(f$default_source, forms$forms[[ep]]$tool, fixed = TRUE, label = ep)
    html <- as.character(field_ui(f, f$default))
    expect_match(html, 'value="0.05"', fixed = TRUE)
    expect_match(html, "Starts at 0.05:", fixed = TRUE)
  }
