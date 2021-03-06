% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/coding.genes.R
\name{curl.workaround}
\alias{curl.workaround}
\title{Workaround for bug with curl when fetching specific ensembl mirror}
\usage{
curl.workaround(expr, verbose = FALSE)
}
\arguments{
\item{expr}{expression}

\item{verbose}{if expression fails, then activates verbose on next
call to curl.}
}
\value{
result of expression
}
\description{
https://github.com/grimbough/biomaRt/issues/39
}
\examples{
\dontrun{
  loose.rock:::curl.workaround({
      biomaRt::useMart(
          biomart = "ensembl",
          dataset = 'hsapiens_gene_ensembl')
  })
}
}
