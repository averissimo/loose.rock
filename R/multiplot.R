#' Multiple plot
#'
#' Not mine, taken from
#' http://www.cookbook-r.com/Graphs/Multiple_graphs_on_one_page_(ggplot2)/
#'
#' @param ... ggplot objects
#' @param plotlist ggplot objects (alternative)
#' @param ncol Number of columns in layout
#' @param layout A matrix specifying the layout. If present, 'ncol' is ignored
#'
#' If the layout is something like matrix(c(1,2,3,3), nrow=2, byrow=TRUE),
# then plot 1 will go in the upper left, 2 will go in the upper right, and
# 3 will go all the way across the bottom.
#'
#' @return nothing
#' @export
#'
#' @examples
#' # First plot
#' library(ggplot2)
#' p1 <- ggplot(ChickWeight, aes(x=Time, y=weight, colour=Diet, group=Chick)) +
#'   geom_line() +
#'   ggtitle("Growth curve for individual chicks")
#' # Second plot
#' p2 <- ggplot(ChickWeight, aes(x=Time, y=weight, colour=Diet)) +
#'   geom_point(alpha=.3) +
#'   geom_smooth(alpha=.2, size=1) +
#'   ggtitle("Fitted growth curve per diet")
#' multiplot(p1, p2, ncol = 2)
multiplot <- function(..., plotlist=NULL, ncol = 1, layout=NULL) {
  # Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)

  numPlots = length(plots)

  # If layout is NULL, then use 'ncol' to determine layout
  if (is.null(layout)) {
    # Make the panel
    # ncol: Number of columns of plots
    # nrow: Number of rows needed, calculated from # of ncol
    layout <- matrix(seq(1, ncol * ceiling(numPlots/ncol)),
                     ncol = ncol, nrow = ceiling(numPlots/ncol))
  }

  if (numPlots==1) {
    print(plots[[1]])

  } else {
    # Set up the page
    grid::grid.newpage()
    grid::pushViewport(
      grid::viewport(layout = grid::grid.layout(nrow(layout), ncol(layout)))
    )

    # Make each plot, in the correct location
    for (i in seq(numPlots)) {
      # Get the i,j matrix positions of the regions that contain this subplot
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))

      print(plots[[i]], vp = grid::viewport(layout.pos.row = matchidx$row,
                                      layout.pos.col = matchidx$col))
    }
  }
}
