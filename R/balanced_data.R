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
#' set1 <- c(1,2,3,5,6,7,8,9,10,11,12,13,14,15,17,18,19,20)
#' set2 <- c(F,F,F,T,F,F,F,F,F,F,F,F,F,F,F,T,F,F,F,F)
#' balanced.train.and.test(set1, set2, train.perc = .9, join.all = F)
#' ####
#' set1 <- c(T,T,T,T,T,T,T,T,F,T,T,T,T,T,T,T,T,T,F,T)
#' set2 <- !set1
#' balanced.train.and.test(set1, set2, train.perc = .9, join.all = T)
balanced.train.and.test <- function(..., train.perc = .9, join.all = F) {
  # get arguments as list
  input.list <- list(...)
  # stop execution if train.perc is not between 1 and 0 (excluding 0)
  if (train.perc <= 0 || train.perc > 1) {
    error('train.perc argument must be between [1,0[')
  }
  # initialize train set
  train.set <- list()
  test.set     <- list()
  # iterate on elipsis
  for (my.set in input.list) {
    # check if is vector of logical or numeric indexes
    if (is.vector(my.set) && (is.numeric(my.set) || is.logical(my.set))) {
      # make user ixs is a numbered index vector
      if (is.logical(my.set)) {
        ixs <- seq_len(length(my.set))[my.set]
        max.ix <- length(my.set)
      } else {
        ixs <- seq_len(max(my.set))[my.set]
        max.ix <- max(my.set)
      }
      # sample size to use
      sample.size  <- floor(train.perc * length(ixs))
      temp.set <- sample(ixs, size = sample.size)
      if (length(temp.set) == length(my.set) && train.perc < 1)
        warning('Training set is the same size as test set')
      temp.set <- seq_len(max.ix) %in% temp.set
      #
      train.set <- c(train.set, list(sort(which(temp.set))))
      if (train.perc >= 1) {
        test.set <- c(test.set, list(sort(which(temp.set))))
      } else {
        test.temp.set <- !temp.set
        test.temp.set[-ixs] <- FALSE
        test.set <- c(test.set, list(which(test.temp.set)))
      }
    } else {
      error('Arguments must be either a logical or numeric vector, see help for more information.')
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
#' balanced.cv.folds(1:10, 1:3, nfolds = 2)
#' balanced.cv.folds(1:10, 1:3, nfolds = 10) # will give a warning
#' balanced.cv.folds(1:100, 1:33, nfolds = 10)
balanced.cv.folds <- function(..., nfolds = 10) {
  input.list <- list(...)
  output.list <- list()
  for (my.set in input.list) {
    if (length(my.set) < nfolds) {
      warning('Number of elements in vector (', length(my.set), ') is less than \'nfolds\' (', nfolds, ')')
    }
    output.list <- c(output.list, list(sample(rep(seq(nfolds),length = length(my.set)))))
  }
  return(list(input = input.list, output = output.list, nfolds = nfolds))
}
