#' Get a balanced test and train dataset
#'
#' @param ... vectors of index (could be numeric or logical)
#' @param train.perc percentage of dataset to be training set
#' @param join.all join all index in the end in two vectors (train and test vectors)
#'
#' @return train and test index vectors (two lists if `join.all = FALSE`, two vectors otherwise)
#' @export
#'
#' @examples
#' set1 <- seq(20)
#' balanced.train.and.test(set1, train.perc = .9)
#' ####
#' set.seed(1985)
#' set1 <- rbinom(20, prob = 3/20, size = 1) == 1
#' balanced.train.and.test(set1, train.perc = .9)
#' ####
#' set1 <- c(TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,FALSE,
#' TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,FALSE,TRUE)
#' set2 <- !set1
#' balanced.train.and.test(set1, set2, train.perc = .9)
balanced.train.and.test <- function(..., train.perc = .9, join.all = TRUE) {
  # get arguments as list
  input.list <- list(...)
  # stop execution if train.perc is not between 1 and 0 (excluding 0)
  if (train.perc <= 0 || train.perc > 1) {
    stop('train.perc argument must be between [1,0[')
  }
  # initialize train set
  train.set <- list()
  test.set  <- list()
  # iterate on elipsis
  for (my.set in input.list) {
    # check if is vector of logical or numeric indexes
    if (is.vector(my.set) && (is.numeric(my.set) || is.logical(my.set))) {
      # make user ixs is a numbered index vector
      if (is.logical(my.set)) {
        ixs    <- seq_len(length(my.set))[my.set]
        max.ix <- length(my.set)
      } else {
        ixs    <- seq_len(max(my.set))[my.set]
        max.ix <- max(my.set)
      }
      # sample size to use
      sample.size  <- floor(train.perc * length(ixs))
      temp.set <- sample(ixs, size = sample.size)
      if ((length(temp.set) == length(my.set) && train.perc < 1) ||
          (length(temp.set) == 0) && train.perc > 0) {
        warning('One of the sets is empty with train.perc = ', train.perc)
      }
      temp.set <- seq_len(max.ix) %in% temp.set
      #
      train.set <- c(train.set, list(sort(which(temp.set))))

      if (train.perc == 1) {
        test.set  <- train.set
      } else {
        test.temp.set <- !temp.set
        test.temp.set[-ixs] <- FALSE
        test.set <- c(test.set, list(which(test.temp.set)))
      }

    } else {
      stop('Arguments must be either a logical or numeric vector, see help for more information.')
    }
  }
  if (join.all) {
    len <- length(train.set[[1]])
    master.train <- c()
    master.test <- c()
    for(ix in seq(train.set)) {
      master.train <- c(master.train, train.set[[ix]])
      master.test <- c(master.test, test.set[[ix]])
    }
    return(list(train = sort(master.train), test = sort(master.test)))
  }
  return(list(train = train.set, test = test.set))
}

#' Create balanced folds for cross validation
#'
#' @param ... vectors representing data
#' @param nfolds number of folds to be created
#'
#' @return list with given input, nfolds and result. The result is a list matching the input with foldid attributed to each position.
#' @export
#'
#' @examples
#' balanced.cv.folds(1:10, 11:15, nfolds = 2)
#' balanced.cv.folds(1:10, 11:13, nfolds = 10) # will give a warning
#' balanced.cv.folds(1:100, 101:133, nfolds = 10)
balanced.cv.folds <- function(..., nfolds = 10) {
  input.list <- list(...)
  output.list <- list()
  if (any(vapply(input.list, function(vec) {length(vec) < nfolds}, TRUE))) {
    warning('Number of elements in vector (', length(unlist(input.list)), ') is less than \'nfolds\' (', nfolds, ')')
  }
  for (my.set in input.list) {
    #
    # count previous bins and order sequence on increasing count
    if (length(output.list) == 0) {
      my.sample <- rep(seq(nfolds),length = length(my.set))
    } else {
      my.tmp <- c()
      for(ix in seq(output.list)) {
        my.tmp <- c(my.tmp, output.list[[ix]])
      }
      my.count <- graphics::hist(my.tmp, plot = FALSE, breaks = 0:nfolds)$counts
      my.sample <- rep(seq(nfolds)[sort(my.count, index.return = TRUE)$ix], length = length(my.set))
    }
    #
    output.list <- c(output.list, list(sample(my.sample)))
  }
  if (length(output.list) == 1) {
    output.list = output.list[[1]]
    input.list = input.list[[1]]
  }
  return(list(input = input.list, output = output.list, nfolds = nfolds))
}
