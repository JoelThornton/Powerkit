# Short labels for the replication planner with explanations off (19
# November 2026). The plain labels say what each field means; with
# explanations off a researcher who knows the terms sees these instead,
# through name_swap() (both are in the page, so switching needs no redraw).
# One table, applied to the finished planner by replication_shorten(), so
# the fields themselves are written once.

# Field and question labels, by input id. Short is not terse: each keeps
# full words, so it still says what it asks, and only the parts that
# explain (examples, reasons, units already given elsewhere) are dropped.
# No symbols in place of words. Labels that are already short have none.
replication_short_labels <- c(
  rep_study = "The original study",
  rep_levels_a = "Levels of the first factor (between-subjects, in a mixed design)",
  rep_levels_b = "Levels of the second factor (within-subjects, in a mixed design)",
  rep_eta = "Its partial eta-squared", rep_df_error = "Its error degrees of freedom (df2)",
  rep_epsilon = "Sphericity correction, epsilon (optional)", rep_bf = "Its Bayes factor, BF10",
  rep_bf_both = "Its Bayes factor, BF10 (optional)", rep_prior_scale = "Its Cauchy prior's scale",
  rep_effect = "Its effect, with its sign", rep_effect_r = "Correlation between the two measurements",
  rep_cri_lower = "Credible interval, lower end", rep_cri_upper = "Credible interval, upper end",
  rep_n1 = "People in group 1", rep_n2 = "People in group 2", rep_n = "People (or pairs) in total",
  rep_published = "Did publication depend on significance?",
  rep_goal = "Main criterion (sets the sample size)",
  rep_smallest = "Smallest effect that would matter (d, d_z or r)",
  rep_assurance = "Assurance (how sure to be of reaching the power)",
  rep_anova_smallest = "Optional: smallest effect that would matter (partial eta-squared)",
  rep_tau = "Variation in the true effect between studies (SD in d)",
  rep_tau_r = "Variation in the true correlation between studies (SD on Fisher's z)",
  rep_tau_value = "Variation in the true effect between studies (optional SD, on its scale)",
  rep_alpha = "Significance level", rep_sided = "Two-sided or one-sided test?",
  rep_power = "Chance of success (power)",
  rep_n_at = "Optional: a sample size to check (in total)", rep_ratio = "Optional: group 2's size over group 1's",
  rep_attrition = "Optional: proportion expected to drop out",
  rep_diff_people = "The people, and how they differ from the original sample",
  rep_diff_materials = "The materials and measures that change",
  rep_rel_original = "Optional: the original measure's reliability",
  rep_rel_replication = "The replication measure's reliability",
  rep_diff_procedure = "The procedure and setting", rep_diff_analysis = "The analysis, and anything added or changed",
  rep_diff_checks = "Checks that the changed study still tests the same thing")

goal_short <- c(significance = "Significant, in the original's direction",
  pooled = "Significant when pooled with the original",
  agreement = "Agrees with the original, within the smallest effect that matters",
  small_telescopes = "Small telescopes: the original was too small to detect it",
  negligible = "Equivalence test: the effect is too small to matter",
  bf_replication = "Replication Bayes factor", bf_sceptical = "Sceptical Bayes factor",
  bf_repeat = "Bayes factor t-test, for an effect", bf_null = "Bayes factor t-test, for no effect")

# Choices, by input id and value.
replication_short_choices <- list(
  rep_design = c(two_groups = "Two separate groups (Cohen's d)", paired = "The same people measured twice (d_z)",
    one_sample = "One group against a fixed value (Cohen's d)", correlation = "A correlation (r)",
    anova = "An ANOVA effect (F or partial eta-squared)", generic = "Another design: one estimate with its uncertainty"),
  rep_analysis = c(test = "A significance test", both = "A significance test and a Bayes factor",
    pooled = "A pooled estimate (several studies or a meta-analysis)"),
  rep_effect_type = c(d = "Its d (d_z for pairs)", d_rm = "For pairs: d_rm or d_av, with the correlation"),
  rep_original_prior = c(default = "A default prior (such as Cauchy, scale 0.707)", informative = "An informative prior"),
  rep_published = c(unknown = "Unknown: compare both", any = "No"),
  rep_purpose = c(either = "Whether the effect is there or not",
    absent = "That the effect is absent or too small to matter"),
  rep_goal = c(auto = "The one your answer above suggests", goal_short),
  rep_also = c(absence = "A criterion that could show the effect is absent", goal_short),
  rep_sided = c(two.sided = "Two-sided (the usual)", one.sided = "One-sided, in the original's direction"),
  rep_keeps = c(close = "A close replication: everything it can is kept",
    extension = "A replication with an extension: something is added",
    conceptual = "A conceptual replication: the idea, in changed conditions",
    new = "A new study: it asks a different question"))
rm(goal_short)

# Card titles, by their plain title: none need one.
replication_short_titles <- character(0)

# The text of a tag's children, or NULL if they aren't all plain text.
replication_plain_text <- function(children) {
  kids <- unlist(children, recursive = TRUE, use.names = FALSE)
  if (!length(kids) || !all(vapply(kids, is.character, logical(1))) || any(vapply(kids, inherits, logical(1), "html"))) return(NULL)
  trimws(paste(kids, collapse = ""))
}

replication_swap <- function(children, short) {
  text <- replication_plain_text(children)
  if (is.null(text) || is.null(short) || is.na(short) || identical(text, short)) return(children)
  list(name_swap(text, short))
}

replication_shorten <- function(x, labels = replication_short_labels, choices = replication_short_choices,
  titles = replication_short_titles) {
  walk <- function(x) {
    if (inherits(x, "shiny.tag")) {
      a <- x$attribs
      for_id <- a[["for"]]
      if (identical(x$name, "label") && !is.null(for_id) && for_id %in% names(labels)) {
        x$children <- replication_swap(x$children, labels[[for_id]])
      } else if (identical(x$name, "legend")) {
        text <- replication_plain_text(x$children)
        if (!is.null(text) && text %in% names(titles)) x$children <- replication_swap(x$children, titles[[text]])
      } else if (identical(x$name, "label") && length(x$children) >= 2 && inherits(x$children[[1]], "shiny.tag") &&
        identical(x$children[[1]]$name, "input")) {
        # A radio button or check box: <label><input name value><span>text</span></label>
        ia <- x$children[[1]]$attribs
        short <- choices[[ia$name %||% ""]]
        if (!is.null(short) && !is.null(ia$value) && ia$value %in% names(short) && inherits(x$children[[2]], "shiny.tag")) {
          x$children[[2]]$children <- replication_swap(x$children[[2]]$children, short[[ia$value]])
        }
      } else if (identical(x$name, "select") && !is.null(a$id) && !is.null(choices[[a$id]])) {
        # A select's options are one HTML string: each listed option gets
        # its short text as data-short, swapped in by pkSyncExplanations.
        short <- choices[[a$id]]
        x$children <- lapply(x$children, function(k) {
          if (!inherits(k, "html")) return(k)
          s <- as.character(k)
          for (v in names(short)) s <- sub(sprintf("<option value=\"%s\"", v),
            sprintf("<option value=\"%s\" data-short=\"%s\"", v, htmltools::htmlEscape(short[[v]], attribute = TRUE)), s, fixed = TRUE)
          HTML(s)
        })
        return(x)
      }
      x$children <- lapply(x$children, walk)
      return(x)
    }
    if (is.list(x) && !inherits(x, "html")) {
      cls <- class(x)
      x <- lapply(x, walk)
      class(x) <- cls
    }
    x
  }
  walk(x)
}
