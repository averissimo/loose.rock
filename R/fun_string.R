#'
#'
#' Proper capitalizes all words in string
#'
proper <- function(x) {
  return(gsub("(?<=\\b)([a-z])", "\\U\\1", tolower(x), perl=TRUE))
}
