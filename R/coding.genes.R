#' Workaround for bug with curl when fetching specific ensembl mirror
#'
#' https://github.com/grimbough/biomaRt/issues/39
#'
#' @param expr expression
#' @param verbose if expression fails, then activates verbose on next
#' call to curl.
#'
#' @return result of expression
#' @export
#'
#' @examples
#' loose.rock:::curl.workaround({
#'     biomaRt::useMart(
#'         biomart = "ensembl",
#'         dataset = 'hsapiens_gene_ensembl')
#' })
curl.workaround <- function(expr, verbose = FALSE) {
  result <- tryCatch(
    {expr},
    error = function(err) {
      err
    }
  )

  verbose.flag <- if (verbose) {
    1L
  } else {
    0L
  }

  if (inherits(result, 'error') || is.null(result)) {
    if (verbose) {
      warning(
        "There was an problem, calling the function with ",
        "ssl_verifypeer to FALSE", "\n\n\t error: ", result$message)
    }
    # httr::set_config(httr::config(
    #    ssl_verifypeer = 0L,
    #    ssl_verifyhost = 0L,
    #    verbose = 0L))
    result <- httr::with_config(
      config = httr::config(
        ssl_verifypeer = 0L,
        ssl_verifyhost = 0L,
        verbose = verbose.flag
      ),
      withCallingHandlers(
        expr,
        warning = function(w) {
          if (grepl('restarting interrupted promise evaluation', w$message)) {
            invokeRestart("muffleWarning")
          } else {
            warning(w)
            invokeRestart("muffleWarning")
          }
        },
        error = function(err) {
          stop(err)
        }
      ),
      override = FALSE
    )
  }

  return(result)
}

#' Ensembl coding genes, local function
#'
#' @param verbose show messages with number of genes retrieved
#' @param useCache Boolean indicating whether the results cache
#' should be used. Setting to FALSE will disable reading and
#' writing of the cache. This argument is likely to disappear
#' after the cache functionality has been tested more thoroughly.
#'
#' @return a list with coding genes, mart and whether biomaRt had
#' a problem, indicating that it shouldn't be used.
#'
#' @examples
#' \donttest{
#'   res <- loose.rock:::coding.genes.ensembl(TRUE, TRUE)
#'   nrow(res)
#'   head(res)
#' }
coding.genes.ensembl <- function(verbose = TRUE, useCache = TRUE)
{
  mart <- NULL
  tryCatch({
    #
    # Uses hsapies from query
    mart <- tryCatch({
      curl.workaround({
        biomaRt::useEnsembl(
          biomart = "genes",
          dataset = 'hsapiens_gene_ensembl',
          host = 'https://www.ensembl.org',
          verbose = FALSE
        )
      })
    }, error = function(err) {
      #
      #
      # Legacy code so that it is compatible with earlier versions of R
      if(grepl('(Incorrect BioMart name)|(curl_fetch)', err)) {

        ensembl <- curl.workaround({
          biomaRt::useMart("ensembl", host = 'http://www.ensembl.org')
        })

        tryCatch({
          curl.workaround({
            biomaRt::listDatasets(ensembl) %>%
            dplyr::filter(grepl('hsapien', !!as.name('dataset'))) %>%
            dplyr::select(!!as.name('dataset')) %>%
            dplyr::first() %>%
            biomaRt::useDataset(mart = ensembl)
          })
        }, error = function(err2) {
          message('Couldn\'t rescue this.\n\n  ', err2)
        })
      } else {
        message('Couldn\'t recover from error.\n\n  ', err)
      }
    })
    #
    protein.coding <- tryCatch({
      curl.workaround({
        biomaRt::getBM(
          attributes = c("ensembl_gene_id","external_gene_name"),
          filters    = 'biotype',
          values     = c('protein_coding'),
          mart       = mart,
          verbose    = FALSE,
          useCache   = useCache
        )}
    )}, error = function(err) {
      if (useCache && verbose) {
        warning(
          'There was a problem getting the genes,',
          ' trying without a cache.',
          '\n\t',
          err
        )
        err
      } else if (useCache) {
        err
      } else {
        stop('There was a problem with biomaRt::getBM()', '\n\t', err)
      }
    })

    if ((inherits(protein.coding, 'error') ||
         is.null(protein.coding)) && useCache) {
      # retrying without cache
      return(coding.genes.ensembl(verbose = verbose, useCache = FALSE))
    }
  }, error = function(err) {
    warning('biomaRt call failed\n', err$message)
  })
  biomartInstalled <- TRUE
  if (is.null(mart)) {
    biomartInstalled <- FALSE
  }
  return(
    list(
      protein.coding   = protein.coding,
      biomartInstalled = biomartInstalled,
      mart             = mart
    )
  )
}

#' Retrive coding genes from known databases
#'
#' It retrieves from NCBI and ensembl
#'
#' @param verbose show messages with number of genes retrieved
#' @param useCache Boolean indicating whether the results cache
#' should be used. Setting to FALSE will disable reading and
#' writing of the cache. This argument is likely to disappear
#' after the cache functionality has been tested more thoroughly.
#' @param sub.call.verbose This will make all function calls
#' verbose, which could be a lot of information.
#'
#' @return a table with gene information
#' @export
#' @examples
#' # This can take a few minutes depending on the connection
#' \donttest{
#'   res <- coding.genes()
#'   nrow(res)
#'   head(res)
#' }
coding.genes <- function(
  verbose = FALSE, useCache = TRUE, sub.call.verbose = FALSE
) {
  # if biomaRt is installed it retrieves from 2 sources, otherwise defaults
  #  only to NCBI
  biomartInstalled <- requireNamespace("biomaRt", quietly = TRUE)

  # initialize as empty array in case biomaRt is not installed or fails
  protein.coding <- NULL
  dataset        <- NULL

  if (biomartInstalled) {
    result <- coding.genes.ensembl(
      verbose = sub.call.verbose, useCache = useCache
    )
    dataset <- result$mart
    protein.coding <- result$protein.coding

    if (!result$biomartInstalled) {
      biomartInstalled <- result$biomartInstalled
    }
  } else {
    message('biomaRt is not installed, only using genes from NCBI (CCDS)')
  }

  ccds <- NULL # initialize in case download from NCBI fails
  tryCatch ({
    ccds <- utils::read.table(
      url("https://ftp.ncbi.nih.gov/pub/CCDS/current_human/CCDS.current.txt"),
      sep = "\t",
      header = TRUE,
      comment.char = "|",
      stringsAsFactors = FALSE
    )
  })

  if (is.null(ccds)) {
    tryCatch({
      ccds <- utils::read.table(
        url("ftp://ftp.ncbi.nih.gov/pub/CCDS/current_human/CCDS.current.txt"),
        sep = "\t",
        header = TRUE,
        comment.char = "|",
        stringsAsFactors = FALSE
      )
    }, error = function(err2) {
      warning(
        'Could not retrieve list from NCBI, try again later ',
        'for this datasource.'
      )
    })
  }

  # initialize as empty array in case ccds is not retrieved from NCBI
  ccds.genes <- c()
  if (!is.null(ccds)) {
    ccds$ccds_status <- factor(proper(ccds$ccds_status))

    # Remove with ccds_status == Withdrawn
    ccds <- ccds %>%
      dplyr::filter(!grepl('Withdrawm', !!(as.name('ccds_status'))))
    ccds.genes <- unique(ccds$gene)

    if (any(ccds.genes == '' | is.na(ccds.genes))) {
      warning('Some genes from ccds have empty gene_name, skipping those')
      ccds.genes <- ccds.genes[ccds.genes == '' || is.na(ccds.genes)]
    }
    #
  }

  biomart.genes <- c()
  if (!is.null(protein.coding)) {
    biomart.genes    <- unique(protein.coding$external_gene_name)
  }
  ccds.extra.genes <- sort(ccds.genes[(!ccds.genes %in% biomart.genes)])

  coding <- NULL
  if (!is.null(dataset) && biomartInstalled) {

    ccds.extra.genes.add <- tryCatch({
      curl.workaround(
        biomaRt::getBM(
          attributes = c("ensembl_gene_id","external_gene_name"),
          filters    = 'external_gene_name',
          values     = ccds.extra.genes,
          mart       = dataset,
          verbose    = sub.call.verbose,
          useCache   = useCache
        )
      )
    }, error = function(err) {
      # Trying without cache
      curl.workaround(
        biomaRt::getBM(
          attributes = c("ensembl_gene_id","external_gene_name"),
          filters    = 'external_gene_name',
          values     = ccds.extra.genes,
          mart       = dataset,
          verbose    = sub.call.verbose,
          useCache   = FALSE
        )
      )
    })

    coding <- tryCatch({
      rbind(protein.coding, ccds.extra.genes.add)
    }, error = function(err) {
      cat('Could not get external gene names from biomart. ', err$message, '\n')
      # warning('Could not get external gene names from biomart.')
      NULL
    })
    if  (is.null(coding)) {
      coding <- rbind(data.frame(ensembl_gene_id    = ccds.genes,
                                 external_gene_name = ccds.genes),
                      protein.coding)
    }
  } else {
    cat('Skipping getBM', !is.null(dataset), biomartInstalled)
    coding <- data.frame(
      ensembl_gene_id = ccds.extra.genes,
      external_gene_name = ccds.extra.genes
    )
  }
  coding <- coding %>% dplyr::arrange(!!as.name('external_gene_name'))

  if (verbose) {
    message('Coding genes from biomaRt:', nrow(biomart.genes))
    message('   Coding genes from CCDS:', length(ccds.genes))
    message('        Unique in biomaRt:', sum(!ccds.genes %in% biomart.genes))
    message('           Unique in CCDS:', sum(!biomart.genes %in% ccds.genes))
    message('-------------------------------')
    message('                    genes:', nrow(coding))
  }

  return(coding)
}
