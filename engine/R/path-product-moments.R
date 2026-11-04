# Exact population moments for a mediator which appears in a later product.
# The variables are polynomials in independent standardised X, W and e_M;
# correlated normal X/W are represented by a linear transformation. Normal
# moments follow Isserlis (1918), doi:10.1093/biomet/12.1-2.134. Binary
# moments are the weighted sum over their two standardised values.
path_poly_add <- function(...) {
  terms <- unlist(list(...), use.names = TRUE)
  if (!length(terms)) return(numeric())
  sums <- tapply(unname(terms), names(terms), sum)
  out <- stats::setNames(as.numeric(sums), names(sums))
  out[out != 0]
}

path_poly_multiply <- function(a, b) {
  if (!length(a) || !length(b)) return(numeric())
  powers_a <- lapply(names(a), function(k) as.integer(strsplit(k, ",", fixed = TRUE)[[1]]))
  powers_b <- lapply(names(b), function(k) as.integer(strsplit(k, ",", fixed = TRUE)[[1]]))
  terms <- lapply(seq_along(a), function(i) {
    stats::setNames(a[i] * unname(b), vapply(powers_b, function(p) paste(powers_a[[i]] + p, collapse = ","), ""))
  })
  do.call(path_poly_add, terms)
}

path_poly_monomial <- function(i) {
  powers <- integer(3)
  powers[i] <- 1L
  stats::setNames(1, paste(powers, collapse = ","))
}

path_poly_mean <- function(poly, binary_prob) {
  if (!length(poly)) return(0)
  moment <- function(k, p) {
    if (k == 0) return(1)
    if (!is.na(p)) {
      return(((1 - p) * (-p)^k + p * (1 - p)^k) / (p * (1 - p))^(k / 2))
    }
    if (k %% 2L) return(0)
    prod(seq(1, k - 1, by = 2))
  }
  moments <- vapply(names(poly), function(key) {
    powers <- as.integer(strsplit(key, ",", fixed = TRUE)[[1]])
    prod(mapply(moment, powers, binary_prob))
  }, numeric(1))
  sum(unname(poly) * moments)
}

path_product_moments <- function(spec, model) {
  rho <- correlation_lookup(spec)("X", "W")
  binary_prob <- vapply(c("X", "W"), function(v) {
    if (identical(spec$variables[[v]]$type, "binary")) {
      spec$population[[paste0(tolower(v), "_prob")]] %||% 0.5
    } else NA_real_
  }, numeric(1))
  binary_prob <- c(binary_prob, NA_real_)
  cov_poly <- function(a, b) {
    path_poly_mean(path_poly_multiply(a, b), binary_prob) -
      path_poly_mean(a, binary_prob) * path_poly_mean(b, binary_prob)
  }
  polynomials <- list(X = path_poly_monomial(1),
    W = path_poly_add(rho * path_poly_monomial(1), sqrt(1 - rho^2) * path_poly_monomial(2)))
  polynomials$XW <- path_poly_multiply(polynomials$X, polynomials$W)
  predicted <- function(outcome) {
    terms <- lapply(model$equations[[outcome]], function(v) {
      as.numeric(spec$population$paths[[paste0(v, "->", outcome)]]) * polynomials[[v]]
    })
    do.call(path_poly_add, terms)
  }
  covariance <- function() {
    out <- outer(names(polynomials), names(polynomials), Vectorize(function(a, b) {
      cov_poly(polynomials[[a]], polynomials[[b]])
    }))
    dimnames(out) <- list(names(polynomials), names(polynomials))
    out
  }
  m_hat <- predicted("M")
  r_squared <- c(M = cov_poly(m_hat, m_hat))
  if (r_squared[["M"]] >= 1 - 1e-8) return(list(r_squared = r_squared, cov = covariance()))
  polynomials$M <- path_poly_add(m_hat, sqrt(1 - r_squared[["M"]]) * path_poly_monomial(3))
  polynomials$MW <- path_poly_multiply(polynomials$M, polynomials$W)
  y_hat <- predicted("Y")
  r_squared <- c(r_squared, Y = cov_poly(y_hat, y_hat))
  s <- covariance()
  if (r_squared[["Y"]] < 1 - 1e-8) {
    covs <- vapply(polynomials, function(p) cov_poly(y_hat, p), numeric(1))
    s <- grow_cov(s, "Y", covs, 1)
  }
  list(r_squared = r_squared, cov = s)
}
