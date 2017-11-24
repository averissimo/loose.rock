#' Run function and save cache
#'
#' @param base.dir
#' @param fun
#' @param ...
#' @param cache.prefix
#' @param force.recalc
#'
#' @return the result of fun(...)
#' @export
#'
#' @examples
#' runCache(c, 1, 2, 3, 4)
#' runCache(c, a=1, 2, c=3, 4) # should get result from cache
#' cache = list(digest::digest(1, algo = 'sha256'))
#' runCache(c, 1, 2, 3, 4, cache.digest = cache)
setGeneric("runCache", function(fun,
                                ...,
                                seed = NULL,
                                base.dir = tempdir(),
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
                   base.dir      = tempdir(),
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
    digest::digest(args[[ix]], algo = 'sha256')
  })

  dir.create(base.dir, showWarnings = FALSE)
  my.digest   <- digest::digest(args, algo = 'sha256')
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
    save(result, file = path)
  }
  return(result)
})
