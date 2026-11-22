## 2026-11-22 · The factorial logistic regression offers the likelihood-ratio test

The factorial logistic regression card (E47) ran the Wald test of the
effect's coefficients only, the test Spower's `p_glm()` runs. R's usual
commands for this model, `car::Anova()` and `anova(test = "LRT")`, report
the likelihood-ratio test, so researchers commonly run it. The card now
offers it, as the type III test of the same hypothesis
(`car::Anova(type = 3, test.statistic = "LR")`), and preselects it; the
Wald test stays an option. With sparse cells the Wald test loses power
the likelihood-ratio test keeps (17% against 30% in a 2 x 2 example with
20 per cell), while the likelihood-ratio test runs a little above alpha
(about 7% at 0.05 there, where Wald's ran at 0.4% to 2.4%); the form's
help says both (docs/conventions.md, "Choices each card makes for the
researcher").
