#' Generate xdata matrix with pre-determined covariance
#'
#' Covariance matrix is created using for each position
#'   cov.matrix[i,j] = rho^|i-j|
#'
#' @param n.obs number of observations
#' @param n.vars number of variables
#' @param rho value used to calculate rho^|i-j| . values between 1 and 0
#' @param my.mean vector of mean variables
#'
#' @return a matrix of xdata
#' @export
#'
#' @examples
#' gen.synth.xdata(100, 8, .75)
#' gen.synth.xdata(1000, 5, .2)
#' cov(gen.synth.xdata(n.obs = 10, n.vars = 10, rho = .2))
gen.synth.xdata <- function(n.obs, n.vars, rho, my.mean = rep(0, n.vars)) {
  #
  # simple function that from an absolute index on matrix
  #  returns |i-j|
  # where i is the row index and j the column index
  ix.me <- function(ix, n.obs, n.vars) {
    ix.col <- ix %% n.vars
    if (ix.col == 0) { ix.col <- n.vars}
    ix.row <- ceiling(ix / n.vars)
    return(abs(ix.row - ix.col))
  }
  #
  # Covariance matrix
  #  -> Matrix that has incremental index by column,
  #       starting in 1 and ending at n.vas * n.vars
  sigma <- matrix(seq(n.vars^2), nrow = n.vars, ncol = n.vars, byrow = TRUE)
  # Calculate covariance matrix based on rho^|i-j|
  cov.matrix <- rho ^ apply(
    sigma, c(1,2),
    function(ix, n.obs, n.vars) {
      ix.me(ix, n.obs, n.vars)
    }, n.obs, n.vars # extra arguments for function
  )
  # Generate using multivariate normal distribution
  tentative.matrix <- MASS::mvrnorm(
    max(n.obs, n.vars + 1), my.mean, cov.matrix, empirical = TRUE
  )
  if(nrow(tentative.matrix) > n.obs) {
    warning(
      'Cannot guarantee covariance matrix as ',
      'there are more (or the same) observations than variables.'
    )
  }
  return(tentative.matrix[seq(n.obs),])
}
