#' Default digest method
#'
#' Sets a default caching algorithm to use with run.cache
#'
#' @param val object to calculate hash over
#'
#' @return a hash of the sha256
#' @export
#'
#' @examples
#' digest.cache(c(1,2,3,4,5))
#' digest.cache('some example')
digest.cache <- function(val) {
  digest::digest(val, algo = 'sha256')
}

#' Temporary directory for runCache
#'
#' @return a path to a temporary directory used by runCache
tempdir.cache <- function() {
  base.dir <- '.'
  return(file.path(dirname(base.dir), 'run-cache'))
}

#' Run function and save cache
#'
#' This method saves the function that's being called
#'
#' @param base.dir directory where data is stored
#' @param fun function call name
#' @param ... parameters for function call
#' @param seed when function call is random, this allows to set seed beforehand
#' @param cache.prefix prefix for file name to be generated from parameters (...)
#' @param cache.digest cache of the digest for one or more of the parameters
#' @param show.message show message that data is being retrieved from cache
#' @param force.recalc force the recalculation of the values
#' @param add.to.hash something to add to the filename generation
#'
#' @return the result of fun(...)
#' @export
#'
#' @examples
#' # [optional] save cache in a temporary directory
#' # otherwise it writes to the current directory
#' # to folder named run-cache
#' base.dir(tempdir())
#' #
#' run.cache(c, 1, 2, 3, 4)
#' #
#' # next three should use the same cache
#' #  note, the middle call should be a little faster as digest is not calculated
#' #   for the first argument
#' run.cache(c, 1, 2, 3, 4)
#' run.cache(c, 1, 2, 3, 4, cache.digest = list(digest.cache(1)))
#' run.cache(c, a=1, 2, c= 3, 4)
setGeneric("run.cache", function(fun,
                                 ...,
                                 seed = NULL,
                                 base.dir = NULL,
                                 cache.prefix = 'generic_cache',
                                 cache.digest = list(),
                                 show.message = NULL,
                                 force.recalc = FALSE,
                                 add.to.hash = NULL) {
  message('Wrong arguments, first argument must be a path and second a function!\n')
  message('  Usage: run(tmpBaseDir, functionName, 1, 2, 3, 4, 5)\n')
  message('  Usage: run(tmpBaseDir, functionName, 1, 2, 3, 4, 5, cache.prefix = \'someFileName\', force.recalc = TRUE)\n')
  stop('Arguments not supported.')
})

#' Run function and save cache
#'
#' @inheritParams run.cache
#' @inherit run.cache return examples details
#' @export
setMethod('run.cache',
          signature('function'),
          function(fun,
                   ...,
                   seed          = NULL,
                   base.dir      = NULL,
                   cache.prefix  = 'generic_cache',
                   cache.digest = list(),
                   show.message  = NULL,
                   force.recalc  = FALSE,
                   add.to.hash   = NULL) {
            #
            # base.dir
            if (is.null(base.dir)) { base.dir <- loose.rock.options('base.dir') }
            if (is.null(show.message)) { show.message <- loose.rock.options('show.message') }
            #
            #
            args <- list(...)
            if (!is.null(seed)) {
              args[['runCache.seed']] <- seed
              set.seed(seed)
            }
            if (!is.null(add.to.hash)) {
              args[['runCache.add.to.hash']] <- add.to.hash
            }
            #
            args <- lapply(seq_along(args), function(ix) {
              if (length(cache.digest) >= ix && !is.null(cache.digest[[ix]])) {
                return(cache.digest[[ix]])
              }
              digest.cache(args[[ix]])
            })
            if (methods::is(fun, 'standardGeneric')) {
              aaa <- methods::findMethods(fun)
              args[['cache.fun']] <- digest.cache(vapply(names(aaa), function(ix) { digest.cache(toString(attributes(aaa[[ix]])$srcref)) }, 'string'))
            } else if (methods::is(fun, 'function')) {
              args[['cache.fun']] <- digest.cache(toString(attributes(fun)$srcref))
            } else {
              args[['cache.fun']] <- digest.cache(fun)
            }

            dir.create(base.dir, showWarnings = FALSE)

            my.digest   <- digest.cache(args)
            filename    <- sprintf('cache-%s-H_%s.RData', cache.prefix, my.digest)
            parent.path <- strtrim(my.digest, width = 4)
            #

            if (!dir.exists(base.dir)) {
              warning(sprintf('Could not create cache base folder at %s.. trying to use current working directory', base.dir))
              base.dir <- file.path(getwd(), 'run-cache')
              dir.create(base.dir, showWarnings = FALSE)
            }
            parent.dir <- file.path(base.dir, parent.path)
            dir.create(parent.dir, showWarnings = FALSE)

            if (!dir.exists(parent.dir)) {
              warning(sprintf('Could not create cache folder inside base.dir at %s.. trying to use current working directory', base.dir))
              base.dir   <- file.path(getwd(), 'run-cache')
              parent.dir <- file.path(base.dir, parent.path)
              dir.create(parent.dir, showWarnings = FALSE, recursive = TRUE)
            }

            if (dir.exists(parent.dir)) {
              path <- file.path(base.dir, parent.path, filename)
              #
              if (file.exists(path) && !force.recalc) {
                if (show.message) {
                  cat(sprintf('Loading from cache (not calculating): %s\n', path))
                }
                tryCatch({load(path)}, error = function(err) {
                  cat(sprintf('WARN:: %s -- file: %s.\n  -> Calculating again.\n', err, path))
                  result <- fun(...)
                  if (show.message) {
                    cat(sprintf('Saving in cache: %s\n', path))
                  }
                  save(result, file = path)
                })
              } else {
                result <- fun(...)
                if (show.message) {
                  cat(sprintf('Saving in cache: %s\n', path))
                }
                save(result, file = path)
              }
            } else {
              warning(sprintf('Could not save cache, possibly cannot create directory: %s or %s', base.dir, file.path(base.dir, parent.path)))
              result <- fun(...)
            }
            return(result)
          })
