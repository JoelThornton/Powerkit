# Independent checks of confirmed integer N, separate from all search/check draws.
# Run from the repository root with the candidate engine installed.
library(powerkit)
source("engine/tests/testthat/helper-corrected-counts.R")
options(powerkit.cores = 1)
check_corrected_sample_sizes <- function(output = "docs/validation/2026-11-11-corrected-sample-size.json") {
  definitions <- list(
    proportions_balanced = list(name = "two_proportions_corrected", p1 = .5, p2 = .65, ratio = 1),
    proportions_imbalanced = list(name = "two_proportions_corrected", p1 = .05, p2 = .2, ratio = 3),
    table_moderate = list(name = "chi_square_independence_corrected", P = matrix(c(.25,.25,.175,.325), 2, byrow=TRUE)),
    table_sparse = list(name = "chi_square_independence_corrected", P = matrix(c(.7,.1,.1,.1), 2, byrow=TRUE)))
  cases <- list()
  for (i in seq_along(definitions)) {
    d <- definitions[[i]]
    s <- unclass(read_spec(file.path("engine/inst/specs", paste0(d$name, ".json")), validate=FALSE))
    s$goal <- list(type="sample_size", power=.8)
    s$options$nrep <- 5000L; s$options$seed <- 2026111060L + i
    if (!is.null(d$p1)) {
      s$population$p1 <- d$p1; s$population$p2 <- d$p2; s$options$allocation_ratio <- d$ratio
    } else s$population$probabilities <- lapply(seq_len(2), function(j) as.list(d$P[j,]))
    result <- run_spec(s)
    stopifnot(!is.null(result$n_required$verification), result$n_required$power_lower >= .8)
    n <- result$n_required$n
    if (!is.null(d$p1)) {
      n1 <- n/(1+d$ratio); n2 <- n-n1
      reference <- corrected_prop_reference(n1, n2, d$p1, d$p2)
      reference_nrep <- NULL; interval <- c(reference, reference); failures <- 0L
    } else {
      set.seed(2026111070L + i)
      p <- suppressWarnings(replicate(20000L, stats::chisq.test(
        matrix(rmultinom(1, n, as.vector(d$P)), 2), correct=TRUE)$p.value))
      successes <- sum(is.finite(p) & p < .05)
      reference <- successes/length(p); reference_nrep <- length(p)
      interval <- unname(stats::binom.test(successes,length(p))$conf.int)
      failures <- sum(!is.finite(p))
    }
    cases[[names(definitions)[i]]] <- list(spec=s, n_required=result$n_required,
      independent_power=reference, reference_interval=interval, reference_nrep=reference_nrep,
      reference_failures=failures, reference_seed=if(is.null(d$p1)) 2026111070L+i else NULL,
      simulations=result$provenance$simulations, provenance=result$provenance)
    cat(names(definitions)[i], "N=", n, "independent power=", reference, "\n")
    stopifnot(interval[1] >= .8)
  }
  sources <- c("engine/R/confirm-count-search.R", "engine/R/continuity-correction.R", "scripts/check-corrected-sample-size.R")
  archive <- list(date="2026-11-11", scope="Four selected confirmation-search cases only. Finite binomial enumeration or fresh independent multinomial draws; not evidence of a minimum-N guarantee, universal coverage or valid population assumptions. Failed analyses remain unsuccessful attempts.",
    source_sha256 = setNames(lapply(sources, function(p) digest::digest(file=p,algo="sha256")), sources),
    R=R.version.string, cases=cases)
  jsonlite::write_json(archive, output,
    pretty=TRUE,auto_unbox=TRUE,digits=NA,null="null")
  invisible(archive)
}
check_corrected_sample_sizes()
