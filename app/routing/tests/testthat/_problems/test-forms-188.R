# Extracted from test-forms.R:188

# prequel ----------------------------------------------------------------------
form_ids <- names(forms$forms)
validate <- engine_validator(file.path(repo_dir, "engine"))
skip_without_engine <- function() skip_if(is.null(validate), "powerkit's engine isn't available here")
values_for <- function(ep) form_examples[[ep]]
fields_for <- function(ep, k = 2) form_fields(form_groups(forms, ep, k))

# test -------------------------------------------------------------------------
s <- setting_by_key(tree, "effect_size_inputs")
expect_null(s$value)
expect_true("form" %in% unlist(s$shown_at))
html <- as.character(form_ui(tree, forms, "E1", form_groups(forms, "E1")))
