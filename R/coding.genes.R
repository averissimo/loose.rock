#' Retrive coding genes from known databases
#'
#' @return a table with gene information
#' @export
#'
coding.genes <- function ()
{
  ensembl <- biomaRt::useMart("ensembl")
  dataset <- biomaRt::useDataset("hsapiens_gene_ensembl", mart = ensembl)
  protein.coding <- biomaRt::getBM(attributes = c("ensembl_gene_id","external_gene_name","description", 'ccds'),
                                    filters    = 'biotype',
                                    values     = c('protein_coding'),
                                    mart       = dataset)


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

  coding <- biomaRt::getBM(attributes = c("ensembl_gene_id","external_gene_name","description", 'ccds'),
                           filters    = 'external_gene_name',
                           values     = c(biomart.genes, ccds.extra.genes),
                           mart       = dataset)

  futile.logger::flog.info('Coding genes from biomaRt: %d', nrow(protein.coding))
  futile.logger::flog.info('   Coding genes from CCDS: %d', nrow(ccds))
  futile.logger::flog.info('        Unique in biomaRt: %d', sum(!ccds.genes %in% biomart.genes))
  futile.logger::flog.info('           Unique in CCDS: %d', sum(!biomart.genes %in% ccds.genes))
  return(coding)
}
