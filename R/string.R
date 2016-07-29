#' Capitalizes all words in string
#'
#' @param x String
#'
#' @return a capitalized string (all words)
#' @export
#'
#' @examples
#' proper('i saw a dEaD parrot')
proper <- function(x) {
  return(gsub("(?<=\\b)([a-z])", "\\U\\1", tolower(x), perl=TRUE))
}
