# Welch populations use a fixed effect denominator across allocations:
# sqrt((SD1^2 + SD2^2) / 2), not a sample-size-dependent pooled SD.
# Equal SDs recover the existing Cohen's d population exactly.
welch_population_sds <- function(spec) {
  ratio <- spec$population$sd_ratio %||% 1
  c(1, ratio) / sqrt((1 + ratio^2) / 2)
}

unequal_welch <- function(spec) {
  identical(spec$template, "independent_t") && identical(spec$target_test$method, "welch_t") &&
    !isTRUE(all.equal(spec$population$sd_ratio %||% 1, 1))
}

# pwrss 1.3.3's Welch formula standardises its population by the expected
# sample-size-weighted pooled SD. Its own converter performs this change
# of units at each actual allocation. The underlying mean/SDs stay fixed.
welch_backend_d <- function(spec, n1, n2) {
  if (!unequal_welch(spec)) return(spec$population$d)
  sds <- welch_population_sds(spec)
  suppressWarnings(pwrss::means.to.d(mu1 = spec$population$d, mu2 = 0,
    sd1 = sds[1], sd2 = sds[2], n.ratio = n1 / n2, n2 = n2, verbose = 0))$d
}
