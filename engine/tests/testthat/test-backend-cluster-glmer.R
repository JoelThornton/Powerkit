# Clustered trials with a yes/no outcome, simulated with glmer() (E34's
# "glmer_simulation" method), beside powertools' formulas (the default).

glmer_spec <- function(name = "cluster_randomised_binary", goal = list(type = "power", n = 480), nrep = 200, ...) {
  spec <- read_spec(system.file("specs", paste0(name, ".json"), package = "powerkit"))
  spec$target_test$method <- "glmer_simulation"
  spec$goal <- goal
  spec$options <- list(seed = 7, nrep = nrep)
  changes <- list(...)
  for (field in names(changes)) spec$population[[field]] <- changes[[field]]
  spec
}

test_that("the simulation route is chosen only for the yes/no method, and the formula stays the default", {
  formula <- read_spec(system.file("specs", "cluster_randomised_binary.json", package = "powerkit"))
  expect_false(cluster_glmer_test(formula))
  expect_true(cluster_glmer_test(glmer_spec()))
  expect_true(cluster_glmer_test(glmer_spec("multisite_binary")))
  backend <- cluster_glmer_backend(validate_quietly(glmer_spec()))
  expect_identical(backend$name, "Spower")
  expect_identical(backend$n_step, powertools_backend(validate_quietly(formula))$n_step)
  expect_match(backend$functions[["simulation"]], "glmer(y ~ cond + (1 | cluster)", fixed = TRUE)
  expect_match(cluster_glmer_backend(validate_quietly(glmer_spec("multisite_binary")))$functions[["simulation"]],
    "(0 + cond | cluster)", fixed = TRUE)
})

test_that("a run gives power with a check run that recovers the inputs, for both designs", {
  for (name in c("cluster_randomised_binary", "multisite_binary")) {
    result <- run_quietly(glmer_spec(name, list(type = "power", n = 400), nrep = 100))
    expect_identical(result$provenance$backend, "Spower", info = name)
    expect_true(result$curve$power > 0.3 && result$curve$power <= 1, info = name)
    expect_true(all(result$check_run$ok), info = name)
  }
})

test_that("the data are drawn from powertools' models", {
  data <- with_seed(3, cluster_glmer_data(400 * 50, 50, 0.3, 0.45, 0.3, multisite = FALSE))
  expect_equal(nlevels(data$cluster), 400)
  # Half the groups in each condition, whole groups only.
  expect_true(all(tapply(data$cond, data$cluster, function(x) length(unique(x))) == 1))
  expect_equal(mean(data$cond), 0.5)
  site <- with_seed(3, cluster_glmer_data(21 * 10, 21, 0.3, 0.45, 0.3, multisite = TRUE))
  # Every group has both conditions, 11 and 10 of 21.
  expect_equal(as.vector(table(site$cond[site$cluster == "1"])), c(11, 10))
})

test_that("the one-sided test runs in the direction the spec gives", {
  data <- with_seed(1, cluster_glmer_data(40 * 20, 20, 0.3, 0.45, 0.3, multisite = FALSE))
  two <- cluster_glmer_p(data, FALSE, 0L)
  expect_equal(cluster_glmer_p(data, FALSE, 1L), two / 2, tolerance = 1e-8)
  expect_equal(cluster_glmer_p(data, FALSE, -1L), 1 - two / 2, tolerance = 1e-8)
  expect_identical(cluster_glmer_inputs(glmer_spec(p1 = 0.45, p2 = 0.3))$direction, 0L)
  spec <- glmer_spec(p1 = 0.45, p2 = 0.3)
  spec$target_test$alternative <- "less"
  expect_identical(cluster_glmer_inputs(spec)$direction, -1L)
})

test_that("without powertools' factor 1.2, simulation and formula agree (Known difference 16)", {
  skip_unless_full_validation()
  # The formula without the factor needs 24 groups for 80% power (28 with
  # it) for a cluster-randomised trial; 1,000 simulated trials at 24 groups
  # should give its power, 80.9%, within Monte Carlo error.
  pc <- 0.3; pt <- 0.45; m <- 20; su <- 0.3
  gamma <- qlogis(pt) - qlogis(pc)
  ssq <- (1 / (pc * (1 - pc)) + 1 / (pt * (1 - pt))) / 2
  crt <- function(J) pnorm(gamma / sqrt(4 * (ssq + m * su^2) / (m * J)) - qnorm(0.975))
  result <- run_quietly(glmer_spec(goal = list(type = "power", n = 24 * m), nrep = 1000))
  expect_lt(abs(result$curve$power - crt(24)), 3 * sqrt(crt(24) * (1 - crt(24)) / 1000))
  expect_lt(result$curve$power, powertools::crt.parallel.bin(m = m, J = 28, pc = pc, pt = pt, sigma.u = su))
})

test_that("the R script reproduces the run", {
  skip_unless_scripts_can_run()
  for (name in c("cluster_randomised_binary", "multisite_binary")) {
    spec <- glmer_spec(name, list(type = "power", n = 200), nrep = 100)
    run <- expect_script_reproduces_power(spec, run_quietly(spec))
    expect_true(any(grepl("glmer(", run$script, fixed = TRUE)), info = name)
  }
})
