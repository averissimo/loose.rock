#' Plot covariance heatmap from matrix
#'
#' @param my.matrix matrix to calculate the covariance
#'
#' @return a ggplot2
#' @export
#'
#' @examples
#' ggplot.cov.matrix(matrix(rnorm(100), ncol = 10))
#' ggplot.cov.matrix(gen.synth.xdata(10, 10, .2))
ggplot.cov.matrix <- function(my.matrix, fun = cov, ...) {
  cov.matrix           <- fun(my.matrix, ...)
  rownames(cov.matrix) <- colnames(cov.matrix)
  cov.matrix           <- data.frame(cov.matrix)
  cov.df               <- cbind(x = colnames(cov.matrix), cov.matrix)
  cov.melt             <- reshape2::melt(cov.df, id.vars = c('x'), variable.name = 'y', value.name = 'Values')

  #
  return(
    ggplot2::ggplot(cov.melt, ggplot2::aes(x, y, fill = Values)) +
      ggplot2::geom_raster() +
      ggplot2::scale_fill_continuous(low='#56B1F7', high = '#132B43') +
      ggplot2::theme_minimal() +
      ggplot2::theme(axis.title = ggplot2::element_blank())
    )
}
