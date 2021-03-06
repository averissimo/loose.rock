% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/coding.genes.R
\name{search.genes.internal}
\alias{search.genes.internal}
\title{Search genes in biomaRt}
\usage{
search.genes.internal(filters, values, mart, useCache = TRUE, verbose = FALSE)
}
\arguments{
\item{filters}{see biomaRt::getBM}

\item{values}{see biomaRt::getBM}

\item{mart}{see biomaRt::getBM}

\item{useCache}{see biomaRt::getBM}

\item{verbose}{see biomaRt::getBM}
}
\value{
data table with attributes as columns
}
\description{
Search genes in biomaRt
}
\examples{
\donttest{
  mart <- loose.rock:::getHsapiensMart.internal()
  loose.rock:::search.genes.internal(
    'entrezgene_accession', 'HHLA3', mart, useCache = FALSE
  )
  loose.rock:::search.genes.internal(
    'external_gene_name', 'BRCA2', mart, useCache = FALSE
  )
}
}
