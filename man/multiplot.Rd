% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/multiplot.R
\name{multiplot}
\alias{multiplot}
\title{Multiple plot}
\usage{
multiplot(..., plotlist = NULL, ncol = 1, layout = NULL)
}
\arguments{
\item{...}{ggplot objects}

\item{plotlist}{ggplot objects (alternative)}

\item{ncol}{Number of columns in layout}

\item{layout}{A matrix specifying the layout. If present, 'ncol' is ignored

If the layout is something like matrix(c(1,2,3,3), nrow=2, byrow=TRUE),}
}
\value{
nothing
}
\description{
Not mine, taken from
http://www.cookbook-r.com/Graphs/Multiple_graphs_on_one_page_(ggplot2)/
}
\examples{
# First plot
library(ggplot2)
p1 <- ggplot(ChickWeight, aes(x=Time, y=weight, colour=Diet, group=Chick)) +
  geom_line() +
  ggtitle("Growth curve for individual chicks")
# Second plot
p2 <- ggplot(ChickWeight, aes(x=Time, y=weight, colour=Diet)) +
  geom_point(alpha=.3) +
  geom_smooth(alpha=.2, size=1) +
  ggtitle("Fitted growth curve per diet")
multiplot(p1, p2, ncol = 2)
}
