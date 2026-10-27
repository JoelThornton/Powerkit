# The "About" tab: what powerkit does, that it's a prototype, which
# end points calculate, how to report problems, and credits for the tools
# it is built on. The lists come from tree.yaml and forms.yaml, so they stay
# in step with the app; credits come from each package's own citation()
# (CLAUDE.md: citations only from refs.bib or citation()).

# The packages powerkit is built on (docs/coverage-roadmap.md, "Foundation
# tools"), then the software doing real work underneath them (as in the
# engine's citations export, supporting_software()), then R and Shiny.
about_foundation_tools <- list(
  list(package = "pwr", role = "formulas for the t-tests, the correlation and the chi-square test (E1 to E4, E6), and Cohen's h for two proportions if you choose it"),
  list(package = "pwrss", role = "the z test for two proportions in unequal groups and Fisher's exact test (E5), Welch's t-test by formula (E2), one-way ANCOVA (E23), multiple regression (E24), one proportion (E25) and McNemar's test (E26)"),
  list(package = "Spower", role = "simulation for the basic tests when you choose it, and for Welch's t-test (E2)"),
  list(package = "Superpower", role = "the 2 x 2 designs (E7, E8) and the one-way ANOVA (E18)"),
  list(package = "InteractionPoweR", role = "interactions in regression (E9)"),
  list(package = "power4mome", role = "mediation and moderated mediation (E10 to E14)")
)
about_supporting_tools <- list(
  list(package = "SimDesign", role = "which runs Spower's simulations"),
  list(package = "afex", role = "which fits Superpower's ANOVAs"),
  list(package = "MASS", role = "which Superpower uses to generate data"),
  list(package = "lavaan", role = "which power4mome uses to fit each simulated data set"),
  list(package = "manymome", role = "which power4mome uses for indirect effects and their confidence intervals"),
  list(package = "base", label = "R", role = "in which everything runs; its power.prop.test() gives the z test for two proportions in equal groups (E5)"),
  list(package = "shiny", role = "which draws this app")
)

# A package's own citation() as plain text, or a note if it isn't installed.
about_citation_text <- function(package) {
  if (!identical(package, "base") && !requireNamespace(package, quietly = TRUE)) {
    return(sprintf("Not installed on this computer; see citation(\"%s\") in R.", package))
  }
  text <- tryCatch(format(utils::citation(package), style = "text"), error = function(e) character())
  if (!length(text)) return(sprintf("See citation(\"%s\") in R.", package))
  # Plain text: drop the markdown-style emphasis format() adds.
  gsub("[*_]{1,2}([^*_]+)[*_]{1,2}", "\\1", text)
}

about_credit_ui <- function(tool) {
  label <- tool$label %||% tool$package
  tags$li(
    class = "about-credit",
    HTML(sprintf("<strong>%s</strong>, %s.", htmltools::htmlEscape(label), htmltools::htmlEscape(tool$role))),
    tags$ul(class = "about-citation small", lapply(about_citation_text(tool$package), tags$li))
  )
}

# One line per end point that calculates, with how it calculates.
about_endpoint_lines <- function(tree, forms) {
  instant <- unlist(forms$calculates)
  sims <- forms$simulations$endpoints %||% list()
  background <- names(forms$background %||% list())
  line <- function(id, how) {
    ep <- tree$endpoints[[id]]
    # One string, so no stray spaces appear around the punctuation.
    tags$li(HTML(sprintf("<strong>%s</strong>: %s (%s). %s", id,
      htmltools::htmlEscape(ep$plain_name), htmltools::htmlEscape(ep$doc_name), htmltools::htmlEscape(how))))
  }
  c(
    lapply(instant, function(id) {
      line(id, if (id %in% background) "Calculates here, in the background, with a progress bar." else "Calculates here, straight away.")
    }),
    lapply(names(sims), function(id) {
      full <- "power" %in% unlist(sims[[id]]$full_run)
      line(id, paste(
        "Power: a rough preview here, then",
        if (full) "the full analysis here (it takes several minutes)." else "an R script to run the full analysis on your computer.",
        "Sample size: an R script to run on your computer."
      ))
    })
  )
}

# powerkit's version, from the engine package, so the About page, the
# exported scripts and every result's provenance all quote the same number
# (docs/adding-a-test.md, "Version numbers").
powerkit_version <- function() {
  version <- tryCatch(as.character(utils::packageVersion("powerkit")), error = function(e) NULL)
  if (is.null(version)) NULL else version
}

about_ui <- function(tree, forms) {
  n_endpoints <- length(tree$endpoints)
  version <- powerkit_version()
  div(
    class = "about",
    h2("About powerkit"),
    share_page_ui("about"),
    prototype_banner(tree),
    if (!is.null(version)) {
      p(class = "text-muted",
        sprintf("powerkit %s. ", version),
        "Every result and every R script you download says this version, so a number you quote can be traced back to it. ",
        "Version 1.0 will be the first release.")
    },
    div(class = "alert alert-warning",
      tags$strong("This is a prototype. "),
      "Its results are not yet fully validated, and screens, wording and defaults will change. ",
      "Please don't use it to plan a real study yet."),
    h3(class = "h5", "What it does"),
    p("powerkit helps you plan the sample size for a psychology study. You describe your study, ",
      "it finds the power analysis that fits, asks for the numbers that analysis needs, ",
      "and runs it with an established R package. powerkit never does the statistics itself: ",
      "every number comes from one of the packages credited below, and every full result comes with ",
      "an R script that reproduces it with that package alone, and the citations to use."),
    p(sprintf(
      "Each of the %d cards says which analysis fits a study and which tool covers it. ",
      n_endpoints
    ), "These calculate in the app:"),
    tags$ul(class = "about-endpoints", about_endpoint_lines(tree, forms)),
    p("The other cards give guidance only for now."),
    h3(class = "h5", "What it doesn't do"),
    tags$ul(
      tags$li("It doesn't choose your effect size. It asks where yours comes from and helps you explain it, ",
        "but the number and the reasoning are yours."),
      tags$li("It doesn't collect or analyse your data. It plans a study; it doesn't run one."),
      tags$li("It doesn't use AI to calculate or to write anything you see. Every number comes from the R packages below, ",
        "and the write-up is fixed wording filled in with your numbers."),
      tags$li("It doesn't replace a statistician for unusual designs. If no card fits your study, ",
        "or a card gives guidance only, ask someone who knows your design.")
    ),
    h3(class = "h5", "Where the numbers come from"),
    p("Each analysis is handed to the established R package that already does it (listed under Credits). ",
      "Where powerkit's settings differ from that package's or from G*Power's usual ones, the result screen says so ",
      "and explains it. The result screen's R script reruns your result with the package alone, ",
      "so anyone can check it without powerkit."),
    h3(class = "h5", "How far along it is"),
    p("powerkit is being built and checked now. Several of its analyses have been compared with G*Power and with ",
      "published examples; others haven't been checked yet. ",
      "It won't be released until a statistician has checked it. ",
      "The What's new tab lists what has changed, newest first."),
    h3(class = "h5", "Reporting a problem or giving feedback"),
    p(HTML(paste0(
      "Use the <strong>Feedback</strong> tab for bugs, questions, suggestions and any other comments. ",
      "It fills in where you are in powerkit for you and shows the whole message before you send it. ",
      "Every card also has a <strong>Something doesn&#39;t fit?</strong> link at the bottom that leads there. ",
      "Nothing is sent from this app without you: the only thing it ever sends is a feedback message, ",
      "when you click Send, and everything else you enter stays on your computer."
    ))),
    h3(class = "h5", "Credits"),
    p("powerkit is built on these R packages. Their own citations are below; ",
      "please cite the package that calculated your result (the result screen's Citations button lists it)."),
    tags$ul(class = "about-credits", lapply(about_foundation_tools, about_credit_ui)),
    p("And the software they run on:"),
    tags$ul(class = "about-credits", lapply(about_supporting_tools, about_credit_ui))
  )
}

# "What's new": dated changes in plain words, newest first, from
# whats-new.yaml (one entry per change users would notice).
load_whats_new <- function(path) {
  entries <- yaml::read_yaml(path, fileEncoding = "UTF-8")$entries
  dates <- as.Date(vapply(entries, `[[`, "", "date"))
  entries[order(dates, decreasing = TRUE)]
}

whats_new_ui <- function(entries) {
  dates <- vapply(entries, `[[`, "", "date")
  days <- unique(dates)
  div(
    class = "about",
    h2("What's new"),
    share_page_ui("whats-new"),
    p("Changes to powerkit you would notice, newest first. ",
      "The online app updates itself each time a change is approved."),
    lapply(days, function(day) {
      tagList(
        h3(class = "h5", paste(as.integer(format(as.Date(day), "%d")), format(as.Date(day), "%B %Y"))),
        tags$ul(class = "whats-new", lapply(entries[dates == day], function(e) {
          tags$li(tags$strong(e$title), tags$br(), e$text)
        }))
      )
    })
  )
}
