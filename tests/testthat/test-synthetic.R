context("synthetic")

test_that("Covariance matrix is respected", {
  for(ix in 1:10) {
    n.vars <- ceiling(runif(1, min = 10, max = 99))
    diagonal.of.ones <-diag(cov(gen.synth.xdata(n.obs = 100, n.vars = n.vars, rho = runif(1))))
    expect_equal(diagonal.of.ones, rep(1, n.vars))
  }
})

test_that("Covariance matrix is not respected due to more variables than observations", {
  for(n.vars in 1:10) {
    n.obs <- ceiling(runif(1, min = 10, max = 99))
    expect_warning(xdata <- gen.synth.xdata(n.obs = n.obs, n.vars = 100, rho = runif(1)))
    #
    diagonal.of.ones <-diag(cov(xdata))
    expect_failure(expect_equal(diagonal.of.ones, rep(1, n.vars)))
  }
})
