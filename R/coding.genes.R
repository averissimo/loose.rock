#' Retrive coding genes from known databases
#'
#' It retrieves from NCBI and
#'
#' @param verbose show messages with number of genes retrieved
#'
#' @return a table with gene information
#' @export
#' @examples
#' # This can take a few minutes depending on the connection
#' \dontrun{
#'     coding.genes()
#' }
coding.genes <- function (verbose = TRUE)
{

  # if biomaRt is installed it retrieves from 2 sources, otherwise defaults
  #  only to NCBI
  biomartInstalled = requireNamespace("biomaRt", quietly = TRUE)

  protein.coding <- c() # initialize as empty array in case biomaRt is not installed or fails
  if (biomartInstalled) {
    ensembl <- NULL
    tryCatch({
      ensembl <- biomaRt::useMart("ensembl", host = 'http://www.ensembl.org')

      #
      # Uses hsapies from query
      dataset <- biomaRt::listDatasets(ensembl) %>%
        dplyr::filter(grepl('hsapien', dataset)) %>%
        dplyr::select(dataset) %>%
        dplyr::first() %>%
        biomaRt::useDataset(mart = ensembl)

      #
      protein.coding <- biomaRt::getBM(attributes = c("ensembl_gene_id","external_gene_name"),
                                       filters    = 'biotype',
                                       values     = c('protein_coding'),
                                       mart       = dataset,
                                       verbose    = FALSE)
    }, error = function(err) {
      warning('biomaRt call failed\n', err$message)
    })
    if (is.null(ensembl)) {
      biomartInstalled <- FALSE
    }
  } else {
    message('biomaRt is not installed, only using genes from NCBI (CCDS)')
  }

  ccds <- NULL # initialize in case download from NCBI fails
  tryCatch ({
    ccds <- utils::read.table(url("https://ftp.ncbi.nih.gov/pub/CCDS/current_human/CCDS.current.txt"),
                              sep = "\t", header = TRUE, comment.char = "|", stringsAsFactors = FALSE)

  }, error = function(err) {
    tryCatch({
      ccds <- utils::read.table(url("ftp://ftp.ncbi.nih.gov/pub/CCDS/current_human/CCDS.current.txt"),
                              sep = "\t", header = TRUE, comment.char = "|", stringsAsFactors = FALSE)
    }, error = function(err2) {
      warning('Could not retrieve list from NCBI, try again later for this datasource.')
    })
  })

  ccds.genes <- c() # initialize as empty array in case ccds is not retrieved from NCBI
  if (!is.null(ccds)) {
    ccds$ccds_status <- factor(proper(ccds$ccds_status))

    # Remove with ccds_status == Withdrawn
    ccds       <- ccds %>% dplyr::filter(!grepl('Withdrawm', !!(as.name('ccds_status'))))
    ccds.genes <- unique(ccds$gene)

    if (any(ccds.genes == '' | is.na(ccds.genes))) {
      warning('Some genes from ccds have empty gene_name, skipping those')
      ccds.genes <- ccds.genes[ccds.genes == '' || is.na(ccds.genes)]
    }
    #
  }

  biomart.genes    <- sort(unique(protein.coding$external_gene_name))
  ccds.extra.genes <- sort(ccds.genes[(!ccds.genes %in% biomart.genes)])

  if (biomartInstalled) {
    coding <- biomaRt::getBM(attributes = c("ensembl_gene_id","external_gene_name"),
                           filters    = 'external_gene_name',
                           values     = c(biomart.genes, ccds.extra.genes),
                           mart       = dataset)
  } else {
    coding <- data.frame(ensembl_gene_id = ccds.extra.genes, external_gene_name = ccds.extra.genes)
  }

  if (verbose) {
    cat('Coding genes from biomaRt:', nrow(protein.coding),'\n')
    cat('   Coding genes from CCDS:', length(ccds.genes), '\n')
    cat('        Unique in biomaRt:', sum(!ccds.genes %in% biomart.genes), '\n')
    cat('           Unique in CCDS:', sum(!biomart.genes %in% ccds.genes), '\n')
    cat('-------------------------------\n')
    cat('                    genes:', nrow(coding), '\n')
  }

  return(coding)
}
