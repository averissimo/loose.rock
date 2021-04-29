context("Balanced CV folds from vector")

set.seed(1985)
set1 <- sample(c(rep(TRUE, 10), rep(FALSE, 10)), 20)
set1.1 <- c(set1, rep(TRUE, 12))

set3 <- sample(c(1, 2, 3), 30, replace = TRUE)
set4 <- sample(c('aa', 'bb', 'cc'), 30, replace = TRUE)
set5 <- factor(sample(c('aa', 'bb', 'cc'), 29, replace = TRUE))

test_that("Only one set", {
  result <- balanced.cv.folds.from.vector(set1, nfolds = 2)

  expect_false(is.list(result$train))
  expect_false(is.list(result$test))
})

test_that("Only one set and join", {
  result <- balanced.cv.folds.from.vector(set1, nfolds = 2, join.all = TRUE)

  expect_true(all(unique(result) %in% c(1, 2)))
  expect_equal(length(result), length(set1))
  expect_equal(sum(result == 1), 10)
  expect_equal(sum(result == 2), 10)

  result.1 <- balanced.cv.folds.from.vector(set1.1, nfolds = 2, join.all = TRUE)

  expect_true(all(unique(result.1) %in% c(1, 2)))
  expect_equal(length(result.1), length(set1.1))
  expect_equal(sum(result.1 == 1), 16)
  expect_equal(sum(result.1 == 2), 16)

  expect_equal(sum(set1.1[result.1 == 1] == TRUE), sum(set1.1[result.1 == 2] == TRUE))
  expect_equal(sum(set1.1[result.1 == 1] == FALSE), sum(set1.1[result.1 == 2] == FALSE))

  expect_lt(sum(set1.1[result.1 == 1] == FALSE), sum(set1.1[result.1 == 1] == TRUE))
})

test_that('Creates nice cv folds', {

  result <- balanced.cv.folds(set3, 1:3, nfolds = 2)
  #
  result.c <- table(result$output[[1]])
  expect_equal(length(result.c), 2)
  expect_equal(as.vector(result.c), c(15,15))
  #
  result.c <- table(result$output[[2]])
  expect_equal(length(result.c), 2)
  expect_equal(as.vector(result.c), c(2,1))
  #
  #
  result <- balanced.cv.folds(set4, 1:3, nfolds = 3)
  #
  result.c <- table(result$output[[1]])
  expect_equal(length(result.c), 3)
  expect_equal(as.vector(result.c), c(10,10,10))
  #
  result.c <- table(result$output[[2]])
  expect_equal(length(result.c), 3)
  expect_equal(as.vector(result.c), c(1,1,1))
  #
  expect_warning(balanced.cv.folds.from.vector(set5, nfolds = 10), 'Number of elements in vector [(][0-9]+[)] is less than \'nfolds\' [(][0-9]+[)]')
})

