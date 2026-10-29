# A simulated data set: one sample of n participants drawn from the
# population a spec describes, by the same generator the backend uses
# (Spower's gen_*() functions, Superpower's ANOVA_design(),
# InteractionPoweR's generate_interaction() and power4mome's power4test()).
# It is for writing and checking analysis code before the real data
# arrive, never evidence or a pilot. The data are built by R code that
# simulated_data_code() writes; simulated_data() runs that code and the R
# script (simulated_data_section()) prints it, so both give the same data
# for the same seed. Every row is marked as simulated, in the first column.

#' A simulated data set for a design
#'
#' Draws one data set of `n` participants from the population in a
#' design specification, with the generator the power analysis uses. It
#' is for writing and checking the analysis code (in R, SPSS, JASP,
#' jamovi or Python) before the real data arrive: it is not evidence, not
#' a pilot, and not a substitute for the analysis plan. The first column,
#' `SIMULATED_NOT_REAL_DATA`, marks every row as simulated, and the
#' columns are named after the variables' labels.
#'
#' Available for the basic tests of means, correlations, proportions,
#' variances and cross-tabulations (not the rank tests), the ANOVA designs
#' on Superpower and Welch's one-way ANOVA, regression interactions, and
#' mediation and moderated mediation; `simulated_data_available()` says
#' whether a spec is covered.
#'
#' @param spec A design specification (see [read_spec()]).
#' @param n Total sample size.
#' @param seed Random seed (1 if missing); the same seed gives the same
#'   data, here and in the R script from [export_script()].
#' @param file Optional path; if given, the data are written there as CSV.
#' @return A data frame (invisibly when `file` is given).
#' @export
simulated_data <- function(spec, n, seed = 1, file = NULL) {
  spec <- validate_spec(spec)
  if (!is.numeric(n) || length(n) != 1 || is.na(n) || n < 1) {
    abort_run("'n' should be a single positive number of participants.")
  }
  if (!is.numeric(seed) || length(seed) != 1 || is.na(seed)) {
    seed <- 1
  }
  code <- simulated_data_code(spec, as.integer(ceiling(n)), seed)
  if (is.null(code)) {
    abort_not_available("A simulated data set isn't available for this design yet.")
  }
  env <- new.env(parent = baseenv())
  call_backend("The data generator", with_seed(seed, quietly(
    eval(parse(text = code), envir = env)
  )))
  data <- env$simulated
  if (is.null(file)) {
    return(data)
  }
  utils::write.csv(data, file, row.names = FALSE, fileEncoding = "UTF-8")
  invisible(data)
}

#' @rdname simulated_data
#' @export
simulated_data_available <- function(spec) {
  spec <- validate_spec(spec)
  !is.null(simulated_data_code(spec, 100L, 1L))
}

# R code that builds `simulated` (a data frame) from the spec's
# population, or NULL when the design has no generator here yet. The code
# names its packages (pkg::fun) so it runs without powerkit.
simulated_data_code <- function(spec, n, seed) {
  if (rank_test(spec)) {
    return(NULL)
  }
  superpower <- c(
    "oneway_between", "oneway_within", "2x2_between", "2x2_mixed", "mixed",
    "factorial_between", "factorial_within", "factorial_three"
  )
  body <- switch(
    spec$design,
    basic_test = sim_basic_code(spec, n),
    factorial_anova = if (welch_anova(spec)) {
      sim_basic_code(spec, n)
    } else if (spec$template %in% superpower) {
      sim_superpower_code(spec, n)
    },
    regression_interaction = if (identical(spec$template, "two_way")) sim_interaction_code(spec, n),
    mediation = ,
    moderated_mediation = sim_power4mome_code(spec, n, seed),
    NULL
  )
  if (is.null(body)) {
    return(NULL)
  }
  c(
    body,
    "simulated <- data.frame(",
    "  SIMULATED_NOT_REAL_DATA = \"simulated by powerkit\",",
    "  participant = seq_len(nrow(simulated)),",
    "  simulated, check.names = FALSE, row.names = NULL",
    ")"
  )
}

# A column name that SPSS, JASP, jamovi, Python and R all accept: letters,
# digits and underscores, starting with a letter, at most 60 characters.
csv_name <- function(x) {
  x <- gsub("^_+|_+$", "", gsub("[^A-Za-z0-9]+", "_", as.character(x)))
  x <- ifelse(nzchar(x) & grepl("^[A-Za-z]", x), x, paste0("v_", x))
  substr(x, 1, 60)
}

sim_label <- function(spec, role) csv_name(spec$variables[[role]]$label %||% role)

sim_levels <- function(spec, role) {
  levels <- as.character(unlist(spec$variables[[role]]$levels))
  if (length(levels)) levels else paste0(role, seq_len(2))
}

# One "name = value" argument line per element, for a call in the code.
sim_args <- function(args) {
  values <- vapply(args, r_code, character(1))
  paste0("  ", names(args), " = ", values, c(rep(",", length(values) - 1), ""))
}

# Basic tests and Welch's ANOVA, from Spower's generators with the
# arguments the backend passes (spower_inputs()), reshaped to one row per
# participant. Scores are in SD units, as Spower draws them.
sim_basic_code <- function(spec, n) {
  templates <- c(
    "one_sample_t", "independent_t", "paired_t", "correlation", "two_proportions",
    "chi_square_independence", "one_variance", "two_variances", "paired_variances",
    "oneway_between"
  )
  if (!spec$template %in% templates) {
    return(NULL)
  }
  pop <- spec$population
  if (spec$template == "paired_variances") {
    # The paired scores themselves (pitman_morgan_scores() before it takes
    # their sum and difference).
    levels <- sim_levels(spec, "X")
    return(c(
      sprintf("z1 <- stats::rnorm(%d)", n),
      sprintf("z2 <- %s * z1 + sqrt(1 - %s^2) * stats::rnorm(%d)", r_code(pop$r), r_code(pop$r), n),
      "simulated <- data.frame(",
      sprintf("  %s = sqrt(%s) * z1,", csv_name(paste(sim_label(spec, "Y"), levels[1])), r_code(pop$var1)),
      sprintf("  %s = sqrt(%s) * z2", csv_name(paste(sim_label(spec, "Y"), levels[2])), r_code(pop$var2)),
      ")"
    ))
  }
  inputs <- spower_inputs(spec)
  args <- inputs$args(n)
  args <- args[setdiff(names(args), c("var.equal", "correct", "method"))]
  call <- c(sprintf("sim <- Spower::%s(", inputs$generator), sim_args(args), ")")
  y <- sim_label(spec, "Y")
  tidy <- switch(
    spec$template,
    one_sample_t = sprintf("simulated <- data.frame(%s = sim[[1]])", y),
    one_variance = sprintf("simulated <- data.frame(%s = sim$DV)", y),
    independent_t = c(
      "simulated <- data.frame(",
      sprintf("  %s = rep(%s, lengths(sim)),", sim_label(spec, "X"), r_code(sim_levels(spec, "X"))),
      sprintf("  %s = unlist(sim, use.names = FALSE)", y),
      ")"
    ),
    paired_t = c(
      "simulated <- data.frame(",
      sprintf("  %s = sim[[1]],", csv_name(paste(y, sim_levels(spec, "X")[1]))),
      sprintf("  %s = sim[[2]]", csv_name(paste(y, sim_levels(spec, "X")[2]))),
      ")"
    ),
    correlation = sprintf("simulated <- data.frame(%s = sim[, 1], %s = sim[, 2])", sim_label(spec, "X"), y),
    # gen_prop.test() returns counts: "yes" (the second level of Y) in row
    # 1 and the group sizes in row 2; one row per participant, in random
    # order within each group.
    two_proportions = c(
      "simulated <- data.frame(",
      sprintf("  %s = rep(%s, sim[2, ]),", sim_label(spec, "X"), r_code(sim_levels(spec, "X"))),
      sprintf(
        "  %s = unlist(lapply(1:2, function(g) sample(rep(%s, c(sim[1, g], sim[2, g] - sim[1, g])))))",
        y, r_code(rev(sim_levels(spec, "Y")))
      ),
      ")"
    ),
    # gen_chisq.test() returns the table of counts, X's levels in rows.
    chi_square_independence = c(
      sprintf(
        "cells <- expand.grid(%s = %s, %s = %s, stringsAsFactors = FALSE)",
        sim_label(spec, "X"), r_code(sim_levels(spec, "X")), y, r_code(sim_levels(spec, "Y"))
      ),
      "simulated <- cells[sample(rep(seq_len(nrow(cells)), as.vector(sim))), ]"
    ),
    two_variances = sprintf(
      "simulated <- data.frame(%s = %s[match(sim$group, c(\"G1\", \"G2\"))], %s = sim$DV)",
      sim_label(spec, "G"), r_code(sim_levels(spec, "G")), y
    ),
    oneway_between = sprintf(
      "simulated <- data.frame(%s = %s[as.integer(sim$group)], %s = sim$DV)",
      sim_label(spec, "A"), r_code(sim_levels(spec, "A")), y
    )
  )
  c(call, tidy)
}

# ANOVA designs, from Superpower's ANOVA_design(), which draws one sample
# of the requested size (n per between-participants group). Its long data
# (one row per participant per condition) are turned wide when there is a
# within-participants factor: one row per participant, one column per
# condition, as SPSS, JASP and jamovi expect for repeated measures.
sim_superpower_code <- function(spec, n) {
  inputs <- superpower_inputs(spec)
  per_group <- if (is.null(inputs$cell_ratio)) ceiling(n / inputs$groups) else round(superpower_cell_n(inputs, n))
  roles <- intersect(c("A", "B", "C"), names(spec$variables))
  factor_of <- c(A = "a", B = "b", C = "c")
  within <- vapply(roles, function(v) identical(spec$variables[[v]]$type, "within_factor"), logical(1))
  y <- sim_label(spec, "Y")
  level_of <- function(v, safe = FALSE) {
    levels <- sim_levels(spec, v)
    sprintf("%s[level(long$%s)]", r_code(if (safe) csv_name(levels) else levels), factor_of[[v]])
  }
  call <- c(
    "design <- Superpower::ANOVA_design(",
    sim_args(list(design = inputs$design, n = per_group, mu = inputs$mu, sd = inputs$sd, r = inputs$r, plot = FALSE)),
    ")",
    "long <- design$dataframe",
    if (!is.null(inputs$cell_ratio)) c(
      "# ANOVA_design() builds every cell at the largest size; keep each cell's own n.",
      "cell_n <- stats::setNames(design$n, unique(long$cond))",
      "long <- long[stats::ave(seq_along(long$cond), long$cond, FUN = seq_along) <= cell_n[long$cond], ]"
    ),
    "level <- function(x) as.integer(sub(\"^.*[a-z]\", \"\", as.character(x)))"
  )
  between <- roles[!within]
  if (!any(within)) {
    columns <- c(
      vapply(between, function(v) sprintf("  %s = %s,", sim_label(spec, v), level_of(v)), character(1)),
      sprintf("  %s = long$y", y)
    )
    return(c(call, "simulated <- data.frame(", columns, ")"))
  }
  cell <- paste(c(r_code(y), vapply(roles[within], level_of, character(1), safe = TRUE)), collapse = ", ")
  c(
    call,
    sprintf("long$cell <- paste(%s, sep = \"_\")", cell),
    "people <- unique(long$subject)",
    "simulated <- data.frame(row.names = seq_along(people))",
    vapply(between, function(v) {
      sprintf("simulated$%s <- %s[match(people, long$subject)]", sim_label(spec, v), level_of(v))
    }, character(1)),
    "for (cell in unique(long$cell)) {",
    "  rows <- long$cell == cell",
    "  simulated[[cell]] <- long$y[rows][match(people, long$subject[rows])]",
    "}"
  )
}

# Regression interactions, from InteractionPoweR's generate_interaction()
# with the backend's correlations and reliabilities: observed scores, with
# measurement error when a reliability is below 1. The product term is
# left out; the analysis makes it.
sim_interaction_code <- function(spec, n) {
  inputs <- interactionpower_inputs(spec)
  c(
    "sim <- InteractionPoweR::generate_interaction(",
    sim_args(c(list(N = n), inputs[c("r.x1.y", "r.x2.y", "r.x1x2.y", "r.x1.x2", "rel.x1", "rel.x2", "rel.y")])),
    ")",
    sprintf(
      "simulated <- data.frame(%s = sim$x1, %s = sim$x2, %s = sim$y)",
      sim_label(spec, "X"), sim_label(spec, "W"), sim_label(spec, "Y")
    )
  )
}

# Mediation and moderated mediation, from power4mome's generator (the
# backend's model and population values, no test run). Product terms are
# left out; the analysis makes them.
sim_power4mome_code <- function(spec, n, seed) {
  inputs <- power4mome_inputs(spec)
  roles <- names(spec$variables)
  c(
    "sim <- power4mome::power4test(",
    sim_args(list(
      nrep = 1L, model = inputs$model, pop_es = inputs$pop_es, n = n,
      do_the_test = FALSE, iseed = seed, parallel = FALSE, progress = FALSE
    )),
    ")",
    "pooled <- as.data.frame(power4mome::pool_sim_data(sim))",
    "simulated <- data.frame(",
    paste0(
      "  ", vapply(roles, function(v) sim_label(spec, v), character(1)), " = pooled[[", r_code_each(roles), "]]",
      c(rep(",", length(roles) - 1), "")
    ),
    ")"
  )
}

r_code_each <- function(x) vapply(x, r_code, character(1), USE.NAMES = FALSE)

# The R script's section that builds the same data set and writes it as
# CSV, for designs with a generator.
simulated_data_section <- function(spec, n, seed) {
  if (is.null(n)) {
    return(NULL)
  }
  if (!is.numeric(seed) || length(seed) != 1 || is.na(seed)) {
    seed <- 1
  }
  code <- simulated_data_code(spec, as.integer(ceiling(n)), seed)
  if (is.null(code)) {
    return(NULL)
  }
  c(
    "",
    "# ---- A simulated data set (NOT real data) ----------------------------------",
    "# One data set of the planned size, drawn from the population above. It is",
    "# for writing and checking your analysis code before the real data arrive:",
    "# not evidence, not a pilot, and not a substitute for your analysis plan.",
    "# Every row is marked as simulated in the column SIMULATED_NOT_REAL_DATA.",
    "# To write it as a CSV file, remove the # before write.csv().",
    sprintf("set.seed(%s)", r_code(seed)),
    code,
    sprintf("# write.csv(simulated, %s, row.names = FALSE)", r_code(simulated_data_file_name(spec)))
  )
}

simulated_data_file_name <- function(spec) {
  sprintf("SIMULATED-not-real-data-%s.csv", gsub("_", "-", spec$template))
}

# The planned n: the required n for a sample-size goal (when one was
# found), otherwise the n the spec gives.
simulated_data_n <- function(spec, result) {
  n <- if (identical(spec$goal$type, "sample_size")) result$n_required$n else spec$goal$n
  if (is.numeric(n) && length(n) == 1 && !is.na(n)) n
}
