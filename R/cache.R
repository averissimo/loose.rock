#' Default digest method
#'
#' @param val object to calculate hash over
#'
#' @return
#' @export
#'
#' @examples
#' digest.cache(c(1,2,3,4,5))
digest.cache <- function(val) {
  digest::digest(val, algo = 'sha256')
}

#' Temporary directory for runCache
#'
#' @return a path to a temporary directory used by runCache
#'
#' @examples
#' tempdir.cache()
tempdir.cache <- function() {
  base.dir <- tempdir()
  return(file.path(dirname(base.dir), 'runCache'))
}

#' Run function and save cache
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
#' runCache(c, 1, 2, 3, 4)
#' # next three should use the same cache
#' runCache(c, 1, 2, 3, 4)
#' runCache(c, 1, 2, 3, 4, cache.digest = list(digest.cache(1)))
#' runCache(c, a=1, 2, c=3, 4) # should get result from cache
setGeneric("runCache", function(fun,
                                ...,
                                seed = NULL,
                                base.dir = tempdir.cache(),
                                cache.prefix = 'generic_cache',
                                cache.digest = list(),
                                show.message = TRUE,
                                force.recalc = FALSE,
                                add.to.hash = NULL) {
  cat('Wrong arguments, first argument must be a path and second a function!\n')
  cat('  Usage: run(tmpBaseDir, functionName, 1, 2, 3, 4, 5)\n')
  cat('  Usage: run(tmpBaseDir, functionName, 1, 2, 3, 4, 5, cache.prefix = \'someFileName\', force.recalc = TRUE)\n')
})

setMethod('runCache',
          signature('function'),
          function(fun,
                   ...,
                   seed          = NULL,
                   base.dir      = tempdir.cache(),
                   cache.prefix  = 'generic_cache',
                   cache.digest = list(),
                   show.message  = TRUE,
                   force.recalc  = FALSE,
                   add.to.hash   = NULL) {

  warning('DEPRECATED, use run.cache instead! if runCache is called with same arguments but different functions it will save to same cache.')
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

  dir.create(base.dir, showWarnings = FALSE)
  my.digest   <- digest.cache(args)
  filename    <- sprintf('%s-H_%s.RData', cache.prefix, my.digest)
  parent.path <- strtrim(my.digest, width = 4)
  #
  dir.create(file.path(base.dir, parent.path), showWarnings = FALSE)
  path        <- file.path(base.dir, parent.path, filename)
  #
  if (file.exists(path) && !force.recalc) {
    if (show.message) {
      cat(sprintf('Loading from cache (not calculating): %s\n', path))
    }
    load(path)
  } else {
    result <- fun(...)
    if (show.message) {
      cat(sprintf('Saving in cache: %s\n', path))
    }
    save(result, file = path)
  }
  return(result)
})


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
#' runCache(c, 1, 2, 3, 4)
#' # next three should use the same cache
#' runCache(c, 1, 2, 3, 4)
#' runCache(c, 1, 2, 3, 4, cache.digest = list(digest.cache(1)))
#' runCache(c, a=1, 2, c=3, 4) # should get result from cache
setGeneric("run.cache", function(fun,
                                ...,
                                seed = NULL,
                                base.dir = tempdir.cache(),
                                cache.prefix = 'generic_cache',
                                cache.digest = list(),
                                show.message = TRUE,
                                force.recalc = FALSE,
                                add.to.hash = NULL) {
  cat('Wrong arguments, first argument must be a path and second a function!\n')
  cat('  Usage: run(tmpBaseDir, functionName, 1, 2, 3, 4, 5)\n')
  cat('  Usage: run(tmpBaseDir, functionName, 1, 2, 3, 4, 5, cache.prefix = \'someFileName\', force.recalc = TRUE)\n')
})

setMethod('run.cache',
          signature('function'),
          function(fun,
                   ...,
                   seed          = NULL,
                   base.dir      = tempdir.cache(),
                   cache.prefix  = 'generic_cache',
                   cache.digest = list(),
                   show.message  = TRUE,
                   force.recalc  = FALSE,
                   add.to.hash   = NULL) {
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
            if (class(fun) == 'function') {
              args[['cache.fun']] <- digest.cache(toString(attributes(fun)$srcref))
            } else if (class(cov.parallel) == 'standardGeneric') {
              aaa <- findMethods(cov.parallel)
              args[['cache.fun']] <- verissimo::digest.cache(sapply(names(aaa), function(ix) { verissimo::digest.cache(toString(attributes(aaa[[ix]])$srcref)) }))
            } else {
              args[['cache.fun']] <- verissimo::digest.cache(fun)
            }

            dir.create(base.dir, showWarnings = FALSE)
            my.digest   <- digest.cache(args)
            filename    <- sprintf('cache-%s-H_%s.RData', cache.prefix, my.digest)
            parent.path <- strtrim(my.digest, width = 4)
            #
            dir.create(file.path(base.dir, parent.path), showWarnings = FALSE)
            path        <- file.path(base.dir, parent.path, filename)
            #
            if (file.exists(path) && !force.recalc) {
              if (show.message) {
                cat(sprintf('Loading from cache (not calculating): %s\n', path))
              }
              load(path)
            } else {
              result <- fun(...)
              if (show.message) {
                cat(sprintf('Saving in cache: %s\n', path))
              }
              save(result, file = path)
            }
            return(result)
          })
