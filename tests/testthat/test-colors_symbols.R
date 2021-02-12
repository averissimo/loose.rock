context("colors_symbols")

test_that("Can generate plots with colors", {
  for (ix in sample(seq(100), 20)) {
    expect_silent(plot(seq(10), seq(10), col = my.colors(ix)))
    dev.off()
  }
})

test_that("Can generate plots with colors", {
  for (ix in sample(seq(100), 20)) {
    expect_silent(plot(seq(10), seq(10), pch = my.symbols(ix)))
    dev.off()
  }
})
