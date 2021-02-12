#' Plot covariance heatmap from matrix
#'
#' @param my.matrix matrix to calculate the covariance
#' @param fun function to use
#' @param ... arguments to pass to fun function
#'
#' @return a ggplot2
#' @export
#'
#' @examples
#' draw.cov.matrix(matrix(rnorm(100), ncol = 10))
#' draw.cov.matrix(gen.synth.xdata(10, 10, .2))
draw.cov.matrix <- function(my.matrix, fun = stats::cov, ...) {
  cov.matrix           <- fun(my.matrix, ...)
  rownames(cov.matrix) <- colnames(cov.matrix)

  cov.matrix <- data.frame(cov.matrix)
  cov.df     <- cbind(x = colnames(cov.matrix), cov.matrix)
  cov.melt   <- reshape2::melt(
    cov.df, id.vars = c('x'), variable.name = 'y', value.name = 'Values'
  )

  #
  return(
    ggplot2::ggplot(
      cov.melt, ggplot2::aes_(x = quote(x), y = quote(y), fill = quote(Values))
    ) +
      ggplot2::geom_raster() +
      ggplot2::scale_fill_continuous(low='#56B1F7', high = '#132B43') +
      ggplot2::theme_minimal() +
      ggplot2::theme(axis.title = ggplot2::element_blank())
    )
}
