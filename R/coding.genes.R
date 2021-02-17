#' Retrive coding genes from known databases
#'
#' It retrieves from NCBI and ensembl
#'
#' @param verbose show messages with number of genes retrieved
#' @param useCache Boolean indicating whether the results cache
#' should be used. Setting to FALSE will disable reading and
#' writing of the cache. This argument is likely to disappear
#' after the cache functionality has been tested more thoroughly.
#' @param extra.verbose This will make all function calls
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
  verbose = TRUE, useCache = TRUE, extra.verbose = FALSE
) {
  # if biomaRt is installed it retrieves from 2 sources, otherwise defaults
  #  only to NCBI
  biomartInstalled <- requireNamespace("biomaRt", quietly = TRUE)

  # initialize as empty array in case biomaRt is not installed or fails
  protein.coding <- NULL
  mart           <- NULL

  if (biomartInstalled) {
    result <- coding.genes.ensembl(verbose = extra.verbose, useCache = useCache)
    #
    mart             <- result$mart
    protein.coding   <- result$protein.coding
    biomartInstalled <- biomartInstalled && result$biomartInstalled
  } else {
    message('biomaRt is not installed, only using genes from NCBI (CCDS)')
  }

  # Get CCDS genes
  ccds.genes <- ccds.genes.internal()

  # Join both
  coding <- join.ensembl.and.ccds(
    ensembl.genes = protein.coding,
    ccds.genes    = ccds.genes,
    mart          = mart,
    verbose       = extra.verbose,
    useCache      = useCache
  )

  if (verbose) {
    message('Coding genes from biomaRt: ', nrow(protein.coding))
    message('   Coding genes from CCDS: ', length(unique(ccds.genes$gene)))
    message('            added by CCDS: ', nrow(coding) - nrow(protein.coding))
    message('-------------------------------')
    message('    genes with ensembl_id: ', nrow(coding))
  }

  return(coding)
}

#' Workaround for bug with curl when fetching specific ensembl mirror
#'
#' https://github.com/grimbough/biomaRt/issues/39
#'
#' @param expr expression
#' @param verbose if expression fails, then activates verbose on next
#' call to curl.
#'
#' @return result of expression
#'
#' @examples
#' \donttest{
#'   loose.rock:::curl.workaround({
#'       biomaRt::useMart(
#'           biomart = "ensembl",
#'           dataset = 'hsapiens_gene_ensembl')
#'   })
#' }
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
        "ssl_verifypeer to FALSE", "\n\n\t error: ", result$message,
        call. = FALSE)
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
            warning(w, call. = FALSE)
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

#' Get hsapiens mart from biomaRt
#'
#' @param verbose add extra information in messages
#' @param useCache use run.cache to speed up multiple calls
#'
#' @return biomaRt hsapiens mart
#'
#' @examples
#' \donttest{
#'   loose.rock:::getHsapiensMart.internal()
#'   loose.rock:::getHsapiensMart.internal(verbose = TRUE, useCache = FALSE)
#' }
getHsapiensMart.internal <- function(verbose = FALSE, useCache = TRUE) {

  inside.fun <- function(verbose) {
    #
    # Uses hsapiens from query
    mart <- tryCatch({
      curl.workaround({
        biomaRt::useEnsembl(
          biomart = "genes",
          dataset = 'hsapiens_gene_ensembl',
          host = 'https://www.ensembl.org',
          verbose = verbose
        )
      })
    }, error = function(err) {
      #
      #
      # Legacy code so that it is compatible with earlier versions of R
      if(grepl('(Incorrect BioMart name)|(curl_fetch)', err)) {

        ensembl <- curl.workaround({
          biomaRt::useMart(
            "ensembl",
            host = 'http://www.ensembl.org',
            verbose = verbose)
        })

        tryCatch({
          curl.workaround({
            biomaRt::listDatasets(ensembl, verbose = verbose) %>%
              dplyr::filter(grepl('hsapien', !!as.name('dataset'))) %>%
              dplyr::select(!!as.name('dataset')) %>%
              dplyr::first() %>%
              biomaRt::useDataset(mart = ensembl, verbose = verbose)
          })
        }, error = function(err2) {
          stop('Couldn\'t retrieve mart.\n\n  ', err2$message)
        })
      } else {
        # else if error is not handled
        stop('Couldn\'t retrieve mart.\n\n  ', err$messsage)
      }
    })
    return(mart)
  }

  return(
    tryCatch(
      {
        if (useCache) {
          run.cache(
            inside.fun, verbose,
            base.dir = file.path(tempdir(), 'hsapiens'),
            show.message = FALSE
          )
        } else {
          inside.fun(verbose)
        }
      },
      error = function(err) {
        message('Couldn\'t retrieve mart.\n\n  ', err$message)
      }
    )
  )
}

#' Internal call to biomaRt::getBM
#'
#' Depending on R version (<4.0.0) then it needs to have a special call
#'
#' @param ... Paramters for biomaRt::getBM
#' @param useCache biomaRt::getBM parameter to use local cache or not. We use it
#' to try again without cache in case of an error
#' @param verbose show more verbose
#'
#' @return result of the biomaRt::getBM call
#'
#' @examples
#' \donttest{
#'   mart <- loose.rock:::getHsapiensMart.internal()
#'   res <- loose.rock:::getBM.internal(
#'     attributes = c("ensembl_gene_id","external_gene_name"),
#'     filters    = 'biotype',
#'     values     = c('protein_coding'),
#'     mart       = mart,
#'   )
#'   nrow(res)
#'   head(res)
#' }
getBM.internal <- function(..., useCache = TRUE, verbose = FALSE) {
  # Call getBM with curl.workaround wrapper to failback in case of problem
  #  with sslpeer check.
  # It also fallbacks to don't use cache in getBM
  result <- tryCatch(
    {
      curl.workaround({biomaRt::getBM(...)})
    },
    error = function(err) {
      if (useCache && verbose) {
        warning(
          'There was a problem getting the genes, trying without a cache.',
          '\n\t',
          err,
          call. = FALSE
        )
        NULL
      } else if (useCache) {
        NULL
      } else if (grepl("no applicable method for 'filter_'", err$message)) {
        stop(
          simpleError(
            paste0(
              "There was a problem with biomaRt call, ",
              "please consider updating R version to a newer release.\n\n  ",
              err$message
            )
          )
        )
        NULL
      } else {
        stop(err)
      }
    }
  )

  if ((inherits(result, 'error') || is.null(result)) && useCache) {
    # retrying without cache
    args <- list(...)
    args[['useCache']] <- FALSE
    return(do.call(getBM.internal, args))
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
coding.genes.ensembl <- function(verbose = FALSE, useCache = TRUE)
{
  mart <- NULL
  protein.coding <- NULL
  biomartInstalled <- isNamespaceLoaded('biomaRt')

  if (biomartInstalled) {
    if (verbose) { message('Retrieving hsapiens mart...') }
    #
    # Uses hsapies from query
    mart <- tryCatch(
      {getHsapiensMart.internal(verbose)},
      error = function(err) {
        warning('biomaRt call failed\n', err$message, call. = FALSE)
        NULL
      }
    )
    if (!is.null(mart)) {
      if (verbose) {
        message('Downloading protein coding genes from ensembl...')
      }
      protein.coding <-  tryCatch(
        {
          getBM.internal(
            attributes = c("ensembl_gene_id","external_gene_name"),
            filters    = 'biotype',
            values     = c('protein_coding'),
            mart       = mart,
            verbose    = verbose,
            useCache   = useCache
          )
        },
        error = function(err) {
          warning('biomaRt call failed\n', err$message, call. = FALSE)
          NULL
        }
      )
    }
  }

  return(
    list(
      protein.coding   = protein.coding,
      biomartInstalled = biomartInstalled && !is.null(mart),
      mart             = mart
    )
  )
}

#' Download coding genes from CCDS
#'
#' https://ftp.ncbi.nih.gov/pub/CCDS/current_human/CCDS.current.txt
#'
#' @return vector of coding genes
#'
#' @examples
#' \donttest{
#'   loose.rock:::ccds.genes.internal()
#' }
ccds.genes.internal <- function() {

  # Internal function used twice
  download.ccds <- function(my.url, error = function(err) { } ) {
    return(tryCatch({
      utils::read.csv(
        url(my.url),  sep = "\t", header = TRUE,
        comment.char = "|",  stringsAsFactors = FALSE
      )}, error = error
    ))
  }

  ccds <- download.ccds(
    "https://ftp.ncbi.nih.gov/pub/CCDS/current_human/CCDS.current.txt"
  )

  if (is.null(ccds)) {
    ccds <- download.ccds(
      "ftp://ftp.ncbi.nih.gov/pub/CCDS/current_human/CCDS.current.txt",
      error = function(err2) {
        warning(
          'Could not retrieve list from NCBI, try again later ',
          'for this datasource.',
          call. = FALSE
        )
        return(NULL)
    })
  }

  # initialize as empty array in case ccds is not retrieved from NCBI
  if (!is.null(ccds)) {
    # Remove with ccds_status == Withdrawn
    ccds <- ccds %>%
      dplyr::mutate(
        ccds_status = factor(tolower(!!as.name('ccds_status'))),
        ccds_id_no_version = gsub('[.][0-9]+$', '', !!as.name('ccds_id'))
      ) %>%
      dplyr::filter(!grepl('withdrawn', !!(as.name('ccds_status')))) %>%
      dplyr::distinct()
    #
  }
  return(ccds)
}

#' Search genes in biomaRt
#'
#' @param filters see biomaRt::getBM
#' @param values see biomaRt::getBM
#' @param mart see biomaRt::getBM
#' @param useCache see biomaRt::getBM
#' @param verbose see biomaRt::getBM
#'
#' @return data table with attributes as columns
#'
#' @examples
#' \donttest{
#'   mart <- loose.rock:::getHsapiensMart.internal()
#'   loose.rock:::search.genes.internal('entrezgene_accession', 'HHLA3', mart)
#'   loose.rock:::search.genes.internal('external_gene_name', 'BRAC2', mart)
#' }
search.genes.internal <- function(
  filters, values, mart, useCache = TRUE, verbose = FALSE
) {
  return(
    getBM.internal(
      attributes = unique(c("ensembl_gene_id", "external_gene_name", filters )),
      filters = filters,
      values  = values,
      #
      mart = mart, verbose = verbose, useCache = useCache
    )
  )
}

#' Join genes from ensembl and ccds in a single table
#'
#' [INTERNAL]
#' Finds the ensembl ids of genes from ccds
#'
#' @param ensembl.genes protein coding genes from ensembl
#' @param ccds.genes protein coding genes from ccds
#' @param mart biomaRt dataset to use
#' @param useCache should biomart use cache
#' @param verbose show extra messages
#'
#' @return table with ensembl_gene_id and external_gene_name columns
join.ensembl.and.ccds <- function(
  ensembl.genes, ccds.genes, mart, useCache = TRUE, verbose = FALSE
) {

  # Find all unique external names in ensembl set of protein coding genes
  biomart.genes <- unique(ensembl.genes$external_gene_name)

  # filter out from ccds (if ensembl is empty, then this does nothing)
  ccds.filter <- ccds.genes %>%
    dplyr::filter(!(!!as.name('gene') %in% biomart.genes)) %>%
    dplyr::filter(!grepl('withdrawn$', !!as.name('ccds_status'))) %>%
    dplyr::tibble()

  # Setup up empty variables
  ccds.coding <- NULL
  coding      <- NULL

  biomartInstalled <- isNamespaceLoaded('biomaRt')
  if (is.null(mart) && biomartInstalled) {
    # tries to get biomaRt
    mart <- getHsapiensMart.internal()
  }

  if (!is.null(mart) && biomartInstalled) {
    # Find ENSEMBL ids of genes in ccds

    # this list structures the search matching col in ccds
    #  to filter in biomaRT::getBM
    search.list <- list(
      list(col = 'gene', filter = "external_gene_name"),
      list(col = 'gene', filter = "external_synonym"),
      list(col = 'ccds_id_no_version', filter = "ccds"),
      list(col = 'gene_id', filter = "entrezgene_id"),
      list(col = 'gene', filter = "entrezgene_accession")
    )

    ccds.coding <- tryCatch(
      {
        add.table <- data.frame()
        # iterate on every element of search.list
        for (ix in seq_along(search.list)) {
          ix.el <- search.list[[ix]] # get the element of the list
          # search genes in biomaRt to a temporary table
          add.table.tmp <- search.genes.internal(
            filters = ix.el$filter,
            values = ccds.filter[[ix.el$col]],
            #
            mart = mart, useCache = useCache, verbose = verbose
          )

          # if table is empty, no point in doing anything else
          if (is.null(add.table.tmp) || nrow(add.table.tmp) == 0) {
            next
          }

          # re-filter the ccds table removing the elements that were found
          ccds.filter <- ccds.filter %>%
            dplyr::filter(
              !(!!as.name(ix.el$col) %in% add.table.tmp[, ix.el$filter])
            )

          # adds to the table the new rows
          add.table <- dplyr::bind_rows(
            add.table,
            add.table.tmp %>%
              dplyr::select("ensembl_gene_id","external_gene_name")
          )
        }

        # keep only distinct rows
        add.table %>% dplyr::distinct()
      },
      error = function(err) {
        warning(
          'Could not get ccds gene names from biomart.',
          call. = FALSE
        )
        NULL
      }
    )

    # join with ensembl.genes
    coding <- dplyr::bind_rows(ensembl.genes, ccds.coding)
  } else {
    message(
      'Skipping getBM',
      ' (is mart valid?: ', !is.null(mart), ' -- ',
      'is biomaRt installed?: ', isNamespaceLoaded('biomaRt'),
      ')'
    )
  }

  if (is.null(coding) || nrow(coding) == 0) {
    coding <- data.frame(
      ensembl_gene_id = ccds.genes$gene,
      external_gene_name = ccds.genes$gene
    )
  }

  return(
    coding %>%
      dplyr::arrange(!!as.name('external_gene_name')) %>%
      dplyr::distinct()
  )
}

