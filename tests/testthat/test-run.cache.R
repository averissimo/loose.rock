context("run.cache")

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
  expect_true(grepl(file.path('.', 'run-cache'), output))
  output <- capture_output(run.cache(sum, 1, 2, 3, 4, 5, force.recalc = F, show.message = TRUE, base.dir = file.path('.','run-cache-changed1')))
  expect_true(grepl(file.path('.', 'run-cache-changed1'), output))
  output <- capture_output(run.cache(sum, 1, 2, 3, 4, 5, force.recalc = F, show.message = TRUE))
  expect_true(grepl(file.path('.', 'run-cache'), output))
  base.dir(file.path('.', 'run-cache-changed2'))
  output <- capture_output(run.cache(sum, 1, 2, 3, 4, 5, force.recalc = F, show.message = TRUE))
  expect_true(grepl(file.path('.', 'run-cache-changed2'), output))
})


