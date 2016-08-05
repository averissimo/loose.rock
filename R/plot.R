#' Draw empty plot.
#'
#' Very useful when trying to create new combination of plots
#'
#' @param xlim
#' @param ylim
#' @param xaxs
#' @param yaxs
#' @param border.color
#' @param small.grid
#' @param title
#' @param xlab
#' @param ylab
#' @param sub
#'
#' @return
#' @export
#'
#' @examples draw.empty.plot(c(0,0.5), c(0,10))
draw.empty.plot <- function(xlim, ylim, xaxs = 'i', yaxs = 'i', border.color = 'gray25', small.grid = T,
                            title = '',xlab = '', ylab = '', sub = '') {
  plot.new()
  plot.window(xlim, ylim, yaxs = yaxs, xaxs = xaxs)
  title(main = title, xlab = xlab, ylab = ylab, sub = '')
  #
  small.grid.len <- function(side) {
    len <- length(axTicks(side))
    if (len %% 2 == 0) {
      len <- len * 2 - 2
    } else {
      len <- len * 2 - 1
    }
    return(len)
  }
  #
  if (small.grid) {
    grid(lty = 3,
         nx = small.grid.len(1),
         ny = small.grid.len(2))
  } else {
    grid()
  }
  #
  box(col = border.color, lwd = 1)
  axis(1, col = border.color, lwd = 1)
  axis(2, col = border.color, lwd = 1)
}

#' Function to save plots to multiple formats
#'
#' @param filename
#' @param base.directory
#' @param out.format
#' @param width
#' @param height
#' @param separate.directory
#'
#' @return
#' @export
#'
#' @examples
my.save.plot <- function(filename, base.directory, out.format = c('pdf', 'png'), width = 10, height = 7, separate.directory = T) {
  # duplicate the device and save
  for (out.device in out.format) {
    tryCatch({
      fun.call <- get(out.device)
      if (separate.directory) {
        # output directory separates formats in own format
        output.directory <- file.path(base.directory, out.device)
        if (!dir.exists(base.directory))
          dir.create(base.directory)

        if (!dir.exists(file.path(output.directory)))
          dir.create(output.directory)
      } else {
        # output directory is the same as given
        output.directory <- base.directory
      }
      my.width  <- width
      my.height <- height
      if (out.device == 'png' && (my.width < 100 || my.height < 100) ) {
        my.width  <- my.width * 100
        my.height <- my.height * 100
      }
      dev.copy(fun.call, file.path(output.directory, paste0(filename, '.', out.device)), width = my.width, height = my.height)
      dev.off()
    }, error = function(e){
      print(paste0('Error in ', out.device, ': ', e))
    })
  }
}

#' Plot multiple residuals
#'
#' @param my.residuals
#' @param prefix
#' @param my.ylim
#' @param my.xlim
#' @param filename
#' @param title
#'
#' @return
#' @export
#'
#' @examples
my.plot.residuals <- function(my.residuals, prefix,
                              my.ylim  = NULL, my.xlim = NULL,
                              filename = NULL, title   = '',
                              base.directory = file.path('output', 'residuals')) {
  #
  len <- length(my.residuals)
  #
  rmse <- c()
  #
  #
  original_prefix <- prefix
  prefix <- paste0(prefix)
  my.coords <- list()
  for (ix in 1:len) {
    my.coords[[ix]] <- density(my.residuals[[ix]])
    rmse <- c(rmse, calc_rmse(my.residuals[[ix]]))
  }
  #
  draw.empty.plot(my.xlim, my.ylim, yaxs='i', xaxs = 'i')
  title(xlab = paste0('Residuals (N = ', my.coords[[1]]$n, ')'),
        ylab = 'Density')
  #
  cols <- c('tomato3', 'steelblue2', 'forestgreen', 'orange')
  cols_shade <- col2rgb(cols, alpha = T) / 255
  cols_shade['alpha',] <- .15
  #
  for (ix in 1:len) {
    polygon(c(rev(my.coords[[ix]]$x),my.coords[[ix]]$x),c(array(0, length(my.coords[[ix]]$y)), my.coords[[ix]]$y),
            col = rgb(cols_shade[1,ix],cols_shade[2,ix],cols_shade[3,ix],cols_shade[4,ix]), border = NA)
    lines(my.coords[[ix]]$x, my.coords[[ix]]$y, lwd = 3, lty = 2, col = cols[ix])
  }

  abline(v = 0, col = "gray44", lty = 3)

  leg.str <- paste0(prefix, ' rmse = ', format(rmse, digits = 8))
  #leg.wid <- strwidth(leg.str) / 1
  legend('topright', leg.str, lty = array(2,len), lwd = array(3, len), col = cols[1:len]
  )
  #      ,text.width = leg.wid)

  #
  my.save.plot(filename, base.directory)
  return(NULL)
}

