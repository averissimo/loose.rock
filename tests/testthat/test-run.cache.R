context("run.cache")

cache0 <- file.path('.', 'run-cache')
cache1 <- file.path('.','run-cache-changed1')
cache2 <- file.path('.','run-cache-changed2')

test_that('digest cache is consistent', {
  word <- '1234567'
  expect_equal(digest.cache(word), digest::digest(word, algo = 'sha256'))
  # taken manually at 2018.04.27
  expect_equal(digest.cache(word), '300a4687518d6e58377f814df9eb8a40f5befd3634de48c0fe893e47e127dbb3')
})

test_that('tempdir is correct', {
  expect_equal(tempdir.cache(), file.path('.', 'run-cache'))
})

test_that("run.cache saves to local directory", {
  output <- capture_output(run.cache(sum, 1, 2, 3, 4, 5, force.recalc = T, show.message = TRUE))
  expect_true(grepl(file.path('.', 'run-cache'), output))
})

test_that("run.cache uses cache", {
  run.cache(sum, 1, 2, 3, 4, 5, force.recalc = T, show.message = FALSE)
  output <- capture_output(run.cache(sum, 1, 2, 3, 4, 5, force.recalc = F, show.message = TRUE))
  expect_true(grepl('Loading from cache', output))
})

test_that("run.cache show.message option works", {
  show.message(TRUE)
  output <- capture_output(run.cache(sum, 1, 2, 3, 4, 5, force.recalc = TRUE))
  expect_true(grepl('Saving in cache', output))
  output <- capture_output(run.cache(sum, 1, 2, 3, 4, 5, force.recalc = TRUE, show.message = FALSE))
  expect_true(output == '')
  show.message(FALSE)
  output <- capture_output(run.cache(sum, 1, 2, 3, 4, 5, force.recalc = TRUE))
  expect_true(output == '')
  output <- capture_output(run.cache(sum, 1, 2, 3, 4, 5, force.recalc = TRUE, show.message = TRUE))
  expect_true(grepl('Saving in cache', output))
})

test_that("run.cache base.dir option works", {
  output <- capture_output(run.cache(sum, 1, 2, 3, 4, 5, force.recalc = F, show.message = TRUE))
  expect_true(grepl(cache0, output))
  output <- capture_output(run.cache(sum, 1, 2, 3, 4, 5, force.recalc = F, show.message = TRUE, base.dir = cache1))
  expect_true(grepl(cache1, output))
  output <- capture_output(run.cache(sum, 1, 2, 3, 4, 5, force.recalc = F, show.message = TRUE))
  expect_true(grepl(cache0, output))
  base.dir(cache2)
  output <- capture_output(run.cache(sum, 1, 2, 3, 4, 5, force.recalc = F, show.message = TRUE))
  expect_true(grepl(cache2, output))
})

