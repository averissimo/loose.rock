context("Balanced data")

set1 <- rep(1, 18)
set2 <- rep(2, 6)
set3 <- sample(c(set1, set2), length(set1) + length(set2))
set4 <- sample(c(set1, rep(2, 2)), length(set1) + 2)

test_that("train/test same size", {
  expect_warning(
    balanced.train.and.test.from.vector(
      set3, train.perc = 1-.999999999, join.all = TRUE
    ),
    'One of the sets is empty with train.perc'
  )
})

test_that("train/test wrong train perc", {
  expect_error(balanced.train.and.test.from.vector(set3, train.perc = -1, join.all = FALSE), 'train.perc argument must be between \\[1,0\\[')
  expect_error(balanced.train.and.test.from.vector(set3, train.perc = 1.1, join.all = FALSE), 'train.perc argument must be between \\[1,0\\[')
})

test_that("train perct == 1", {
  result <- balanced.train.and.test.from.vector(set3, train.perc = 1, join.all = FALSE)

  expect_equal(length(result$train[[1]]), 18)
  expect_equal(length(result$train[[2]]), 6)
  expect_equal(length(result$test[[1]]), 18)
  expect_equal(length(result$test[[2]]), 6)
})

test_that("train/test mixed indexes", {
  result <- balanced.train.and.test.from.vector(set4, train.perc = .9, join.all = FALSE)

  expect_equal(length(result$train[[1]]), 16)
  expect_equal(length(result$train[[2]]), 1)
  expect_equal(length(result$test[[1]]), 2)
  expect_equal(length(result$test[[2]]), 1)
})

test_that("train/test mixed indexes (join)", {
  result <- balanced.train.and.test.from.vector(set4, train.perc = .9, join.all = TRUE)

  expect_equal(length(result$train), 17)
  expect_equal(length(result$test), 3)
})

test_that("train/test numeric indexes", {
  set1 <- c(1,2,3,5,6,7,8,9,10,11,12,13,14,15,17,18,19,20) %>% length() %>% rep('vv', .)
  set2 <- c(4,16) %>% length() %>% rep('asd', .)
  result <- balanced.train.and.test.from.vector(c(set1, set2), train.perc = .9, join.all = FALSE)

  expect_equal(length(result$train[[1]]), 16)
  expect_equal(length(result$train[[2]]), 1)
  expect_equal(length(result$test[[1]]), 2)
  expect_equal(length(result$test[[2]]), 1)
})

test_that("train/test numeric indexes (join)", {
  set1 <- c(1,2,3,5,6,7,8,9,10,11,12,13,14,15,17,18,19,20) %>% length() %>% rep(TRUE, .)
  set2 <- c(4,16) %>% length() %>% rep('vv', .)
  result <- balanced.train.and.test.from.vector(c(set1, set2), train.perc = .9, join.all = TRUE)

  expect_equal(length(result$train), 17)
  expect_equal(length(result$test), 3)
})

test_that("train/test logical indexes (join)", {
  set1 <- rep(TRUE, 17)
  set2 <- rep(FALSE, 3)

  result <- balanced.train.and.test.from.vector(c(set1, set2), train.perc = .9, join.all = TRUE)

  expect_equal(length(result$train), 17)
  expect_equal(length(result$test), 3)
})

