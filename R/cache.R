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
#' runCache(c, 1, 2, 3, 4) # should get result from cache
setGeneric("runCache", function(fun, ..., base.dir = tempdir(), cache.prefix = 'generic_cache', force.recalc = FALSE) {
  cat('Wrong arguments, first argument must be a path and second a function!\n')
  cat('  Usage: run(tmpBaseDir, functionName, 1, 2, 3, 4, 5)\n')
  cat('  Usage: run(tmpBaseDir, functionName, 1, 2, 3, 4, 5, cache.prefix = \'someFileName\', force.recalc = TRUE)\n')
})

setMethod('runCache',
          signature('function'),
          function(fun,
                   ...,
                   base.dir = tempdir(),
                   cache.prefix = 'generic_cache',
                   force.recalc = FALSE) {
  args <- list(...)
  path <- file.path(base.dir, sprintf('%s-H_%s.RData', cache.prefix, digest::sha1(args)))
  if (file.exists(path) && !force.recalc) {
    cat(sprintf('Loading from cache (not calculating): %s\n', path))
    load(path)
  } else {
    result <- fun(...)
    save(result, file = path)
  }
  return(result)
})
