#' Questions to ask when calling devtools::release()
#' 
#' This should be done when submitting to cran
#'
#' @return vector of questions
release_questions <- function() {
  c(
    "Have you followed the howto at the end of cran-comments.md ?",
    "Have you run revdepcheck?",
    "Is there a clean build from github actions?",
    "Was rhub called without problems? (mac, solaris, ubuntu, fedora and windows)"
  )
}
