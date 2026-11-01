# typical beginner mistakes read clearly

    Code
      validate_spec(spec)
    Condition
      Error:
      ! This design spec has 3 problems:
      * The spec is missing 'effect_justification'. Every power analysis needs a reason for its effect size: give its type (smallest_effect_of_interest, meta_analysis, prior_study, pilot_study, own_study_result, or none if no effect size can be justified) and, where you can, its source.
      * 'design' must be one of 'basic_test', 'factorial_anova', 'regression_interaction', 'mediation', 'moderated_mediation', 'multiple_regression', 'logistic_regression', 'poisson_regression', 'generic_test', 'equivalence_test', 'cluster_trial', 'sem', 'ordinal_regression', 'mixed_model', 'meta_analysis' or 'dyadic'; you wrote 'moderated mediation'. Did you mean 'moderated_mediation'?
      * 'goal > power' must be less than 1; you wrote 80. Write power as a proportion: 80% is 0.8.

---

    Code
      validate_spec(spec)
    Condition
      Error:
      ! This design spec has 3 problems:
      * 'population > d' should be a number, but it is text ('medium').
      * The spec is missing 'target_test'.
      * 'target' is not a recognised field in the spec. Allowed here: spec_version, design, template, variables, population, effect_justification, target_test, goal, options.

# impossible populations read clearly

    Code
      validate_spec(spec)
    Condition
      Error:
      ! This design spec has a problem:
      * The paths into Perceived threat (M) are impossible together: they would explain 101% of its variance (R-squared = 1.01), but R-squared must be below 1. Make one or more of these paths smaller: 'X->M', 'W->M' or 'XW->M'.

---

    Code
      validate_spec(spec)
    Condition
      Error:
      ! This design spec has a problem:
      * These correlations are impossible together: they imply that Daily stress (X), Social support (W) and their interaction explain 111.7% of the variance in Sleep quality (Y) (R-squared = 1.117), but R-squared must be below 1. Make one or more of r_X_Y, r_W_Y and r_XW_Y smaller, or change r_X_W.

---

    Code
      validate_spec(spec)
    Condition
      Error:
      ! This design spec has a problem:
      * 'population > probabilities' must add up to 1, but they add up to 1.15. Each cell is the proportion of the population with that combination of X and Y.

# model-structure mistakes read clearly

    Code
      validate_spec(spec)
    Condition
      Error:
      ! This design spec has 3 problems:
      * 'population > paths' is missing 'X->Y'. Give every path in the model a value (use 0 for no effect).
      * 'population > paths' has 'M1->M2', which is not a path in PROCESS model 4. Paths between mediators belong in serial mediation (template 'process_6').
      * 'target_test > path' is 'X->M1->M2->Y', which isn't an indirect path in this model. Choose one of 'X->M1->Y' or 'X->M2->Y'.

---

    Code
      validate_spec(spec)
    Condition
      Error:
      ! This design spec has a problem:
      * 'goal > n' must split into 4 equal cells for a 2x2 between-participants design; 150 doesn't. The nearest that do: 148 and 152.

# file problems read clearly

    Code
      read_spec("my-study.json")
    Condition
      Error:
      ! This design spec has a problem:
      * Couldn't find the spec file 'my-study.json'. Check the file name and folder.

---

    Code
      read_spec("{'design': 'mediation'}")
    Condition
      Error:
      ! This design spec has a problem:
      * The spec isn't valid JSON, so it can't be read. Common causes are a missing or extra comma, a missing closing bracket, or single quotes where JSON needs double quotes. The JSON reader said: lexical error: invalid char in json text. {'design': 'mediation'} (right here) ------^

