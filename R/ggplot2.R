#' Save ggplots to file in multiple formats
#'
#' @param filename name of file to save
#' @param my.plot plot to save
#' @param base.directory base folder to save plot
#' @param out.format format
#' @param width width of image
#' @param height height of image
#' @param separate.directory separate formats by directory
#'
#' @export
#'
save.ggplot <- function(filename,
                        base.directory,
                        my.plot            = ggplot2::last_plot(),
                        out.format         = c('pdf', 'png'),
                        width              = 6,
                        height             = 4,
                        separate.directory = TRUE) {
  # duplicate the device and save
  for (out.device in out.format) {
    tryCatch({
      fun.call <- get(out.device)
      if (separate.directory) {
        # output directory separates formats in own format
        output.directory <- file.path(base.directory, out.device)

        if (!dir.exists(file.path(output.directory)))
          dir.create(output.directory, recursive = TRUE)
      } else {
        # output directory is the same as given
        output.directory <- base.directory
        #
        if (!dir.exists(base.directory))
          dir.create(base.directory)
      }

      my.width  <- width
      my.height <- height
      if (out.device == 'png' && (my.width < 100 || my.height < 100) ) {
        #my.width  <- my.width * 10
        #my.height <- my.height * 10
      }
      my.plot
      ggplot2::ggsave(file.path(output.directory, paste0(filename, '.', out.device)), plot = my.plot,
             device = out.device, width = my.width, height = my.height)#, units = 'cm', limitsize = F)
    }, error = function(e){
      print(paste0('Error in ', out.device, ': ', e))
    })
  }
}



