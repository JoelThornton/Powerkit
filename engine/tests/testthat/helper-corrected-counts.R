# Independent finite reference: enumerate binomial counts and ask base R
# for every table's decision. No approximation to corrected power is used.
corrected_prop_reference <- function(n1, n2, p1, p2, alpha = .05,
                                     alternative = "two.sided") {
  sum(vapply(0:n1, function(x1) {
    reject <- vapply(0:n2, function(x2) {
      p <- suppressWarnings(stats::prop.test(c(x1, x2), c(n1, n2),
        correct = TRUE, alternative = alternative)$p.value)
      is.finite(p) && p < alpha
    }, logical(1))
    dbinom(x1, n1, p1) * sum(dbinom(0:n2, n2, p2) * reject)
  }, numeric(1)))
}
