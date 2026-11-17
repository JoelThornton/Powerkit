# Kenward and Roger's degrees of freedom beside Satterthwaite's on the
# mixed-model cards (17 November 2026): asked with a score, not with a
# yes/no outcome; Satterthwaite's stays the default (Departure 16).

mixed_df_cards <- c(E33 = "outcome_type", E63 = "outcome_type", E67 = "outcome_type",
  E68 = "three_outcome", E41 = "two_outcome", E62 = "two_outcome")

test_that("each mixed-model card asks which degrees of freedom the test uses, with a score only", {
  for (ep in names(mixed_df_cards)) {
    fields <- form_fields(form_groups(forms, ep))
    df <- Filter(function(f) identical(f$id, "df_method"), fields)
    expect_length(df, 1)
    df <- df[[1]]
    expect_setequal(names(df$choices), c("satterthwaite", "kenward_roger"))
    expect_identical(df$default, "satterthwaite", label = ep)
    expect_identical(df$path, "target_test.df_method", label = ep)
    score <- setNames(list("continuous"), mixed_df_cards[[ep]])
    yes_no <- setNames(list("binary"), mixed_df_cards[[ep]])
    expect_true(field_applies(df, score), label = ep)
    expect_false(field_applies(df, yes_no), label = ep)
  }
})

test_that("choosing Kenward-Roger reaches the spec, and the write-up names it", {
  fields <- form_fields(form_groups(forms, "E33"))
  values <- modifyList(form_examples$E33, list(df_method = "kenward_roger"))
  spec <- build_spec(forms, "E33", fields, values)
  expect_identical(spec$target_test$df_method, "kenward_roger")
  expect_identical(spec$target_test$method, "satterthwaite_t")
  fields63 <- form_fields(form_groups(forms, "E63"))
  spec63 <- build_spec(forms, "E63", fields63, modifyList(form_examples$E63, list(df_method = "kenward_roger")))
  expect_identical(spec63$target_test$df_method, "kenward_roger")
  # The default stays Satterthwaite's.
  plain <- build_spec(forms, "E33", fields, form_examples$E33)
  expect_identical(plain$target_test$df_method %||% "satterthwaite", "satterthwaite")
})
