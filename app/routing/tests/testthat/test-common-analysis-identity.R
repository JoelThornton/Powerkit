test_that("common form choices reach their intended analysis and preserve fixed N", {
  cases <- list(
    list(id="E1",change=list(method="t_test"),backend="pwr",method="t_test"),
    list(id="E2",change=list(method="welch_t"),backend="pwrss",method="welch_t"),
    list(id="E2",change=list(method="student_t"),backend="pwr",method="student_t"),
    list(id="E3",change=list(method="t_test"),backend="pwr",method="t_test"),
    list(id="E4",change=list(method="pearson"),backend="pwrss",method="pearson"),
    list(id="E5",change=list(method="z_test"),backend="stats",method="z_test"),
    list(id="E6",change=list(method="pearson_chi_square"),backend="pwr",method="pearson_chi_square"),
    list(id="E7",change=list(test_version="anova_f",method="exact"),backend="Superpower",method="anova_f"),
    list(id="E8",change=list(test_version="anova_f",method="exact"),backend="Superpower",method="anova_f"),
    list(id="E9",change=list(interaction_metric="r2_change",r2_change=".02",r2_main=".1"),backend="pwrss",method="ols_t"),
    list(id="E24",change=list(question="r2_increase"),backend="pwrss",method="f_test"))
  for (case in cases) {
    fields <- form_fields(form_groups(forms,case$id))
    defaults <- setNames(lapply(fields,function(f) f[["default"]] %||% ""),vapply(fields,function(f) f$id,""))
    values <- modifyList(defaults,modifyList(form_examples[[case$id]],modifyList(list(goal="power",n="120",alpha=".05"),case$change)))
    expect_length(form_problems(fields,values),0)
    spec <- build_spec(forms,case$id,fields,values)
    expect_identical(spec$target_test$method,case$method)
    expect_equal(spec$goal$n,120)
    expect_equal(spec$target_test$alpha,.05)
    if(case$id %in% c("E1","E2","E3","E4")) expect_null(spec$population$tau)
    result <- suppressWarnings(powerkit::run_spec(spec))
    expect_identical(result$provenance$backend,case$backend)
    expect_equal(result$curve$n,120)
    expect_true(is.finite(result$curve$power))
  }
})
