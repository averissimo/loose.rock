#' Retrive coding genes from known databases
#'
#' It retrieves from NCBI and
#'
#' @param verbose show messages with number of genes retrieved
#'
#' @return a table with gene information
#' @export
#' @examples
#' coding.genes()
coding.genes <- function (verbose = TRUE)
{
  ensembl <- biomaRt::useMart("ensembl")
  dataset <- biomaRt::useDataset("hsapiens_gene_ensembl", mart = ensembl)
  protein.coding <- biomaRt::getBM(attributes = c("ensembl_gene_id","external_gene_name"),
                                   filters    = 'biotype',
                                   values     = c('protein_coding'),
                                   mart       = dataset,
                                   verbose    = FALSE)



  ccds <- utils::read.table(url("ftp://ftp.ncbi.nih.gov/pub/CCDS/current_human/CCDS.current.txt"),
                            sep = "\t", header = T, comment.char = "|", stringsAsFactors = FALSE)

  ccds.genes <- ccds$gene
  if (any(ccds.genes == '' || is.na(ccds.genes))) {
    warning('Some genes from ccds have empty gene_name, skipping those')
    ccds.genes <- ccds.genes[ccds.genes == '' || is.na(ccds.genes)]
  }
  #
  biomart.genes    <- sort(unique(protein.coding$external_gene_name))
  ccds.extra.genes <- sort(ccds.genes[(!ccds.genes %in% biomart.genes)])

  coding <- biomaRt::getBM(attributes = c("ensembl_gene_id","external_gene_name"),
                           filters    = 'external_gene_name',
                           values     = c(biomart.genes, ccds.extra.genes),
                           mart       = dataset)
  if (verbose) {
    cat('Coding genes from biomaRt:', nrow(protein.coding),'\n')
    cat('   Coding genes from CCDS:', nrow(ccds), '\n')
    cat('        Unique in biomaRt:', sum(!ccds.genes %in% biomart.genes), '\n')
    cat('           Unique in CCDS:', sum(!biomart.genes %in% ccds.genes), '\n')
    cat('-------------------------------\n')
    cat('                    genes:', nrow(coding), '\n')
  }

  return(coding)
}
