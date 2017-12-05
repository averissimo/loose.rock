#' draw.kaplan
#'
#' Mega function that draws multiple kaplan meyer survival curves (or just 1)
#'
#' @param chosen.btas list of testing coefficients to calculate prognostic indexes, for example ``list(Age = some_vector)``
#' @param xdata n x m matrix with n observations and m variables
#' @param ydata Survival object
#' @param probs How to separate high and low risk patients 50\%-50\% is the default, but for top and bottom 40\% -> c(.4,.6)
#' @param filename Name of file if save.plot is TRUE
#' @param save.plot TRUE plots everything and save, FALSE only calculates p-valeu
#' @param xlim Optional argument to limit the x-axis view
#' @param ylim Optional argument to limit the y-axis view
#' @param base.directory Initial directory where to store files
#' @param legend.outside If TRUE legend will be outside plot, otherwise inside
#'
#' @return
#'
#' A list with plot, p-value and kaplan-meier object
#'
#' @export
#'
#' @examples
#' data('ovarian', package = 'survival')
#' draw.kaplan(c(age = 1), ovarian$age, data.frame(time = ovarian$futime, status = ovarian$fustat))
#' draw.kaplan(c(age = 1), c(1,0,1,0,1,0), data.frame(time = runif(6), status = rbinom(6, 1, .5)))
draw.kaplan <- function(chosen.btas, xdata, ydata,
                        probs = c(.5, .5), filename = 'SurvivalCurves', save.plot = F,
                        xlim = NULL, ylim = NULL, expand.yzero = F,
                        base.directory = file.path('output', 'kaplan-meier'),
                        legend.outside = T) {
  #
  # creates a matrix from list of chosen.btas
  chosen.btas.mat <- sapply(chosen.btas, function(e){as.vector(e)})
  # calculate prognostic indexes for each patient and btas
  prognostic.index <- as.matrix(xdata) %*% chosen.btas.mat
  colnames(prognostic.index) <- names(chosen.btas)
  prognostic.index.df <- data.frame(time = c(), status = c(), group = c())
  # populate a data.frame with all patients (multiple rows per patients if has multiple btas)
  # already calculate high/low risk groups

  for (ix in 1:(dim(prognostic.index)[2])) {
    # threshold
    #
    #
    temp.group <- array(-1, dim(prognostic.index)[1])
    pi.thres <- quantile(prognostic.index[,ix], probs = c(probs[1], probs[2]))

    if (sum(prognostic.index[,ix] <=  pi.thres[1]) == 0 ||
        sum(prognostic.index[,ix] >  pi.thres[2]) == 0) {
      pi.thres[1] <- median(unique(prognostic.index))
      flog.info('median %g', pi.thres[1])
      pi.thres[2] <- pi.thres[1]
    }

    # low risk
    temp.group[prognostic.index[,ix] <=  pi.thres[1]] <- (2 * ix) - 1
    # high risk
    temp.group[prognostic.index[,ix] > pi.thres[2]] <- (2 * ix)
    #
    valid_ix <- temp.group != -1
    #
    prognostic.index.df <- rbind(prognostic.index.df,
                                 data.frame(pi     = prognostic.index[valid_ix,ix],
                                            time   = ydata$time[valid_ix],
                                            status = ydata$status[valid_ix],
                                            group  = temp.group[valid_ix]))
  }
  # factor the group
  prognostic.index.df$group <- factor(prognostic.index.df$group)
  # rename the factor to low / high risk
  new.factor.str            <- as.vector(sapply(names(chosen.btas), function(e){paste0(c('Low risk - ', 'High risk - '),e)}))
  prognostic.index.df$group <- factor(plyr:::mapvalues(prognostic.index.df$group, from = 1:(2*length(chosen.btas)), to = new.factor.str))
  #
  # Generate the Kaplan-Meier survival object
  km        <- survival::survfit(Surv(time, status) ~ group,  data = prognostic.index.df)
  # Calculate the logrank test p-value
  surv.prob <- survival::survdiff(Surv(time, status) ~ group,  data = prognostic.index.df)
  p_value   <- 1 - stats::pchisq(surv.prob$chisq, df = 1)
  #
  # Plot survival curve
  #
  # remove group= from legend
  names(km$strata) <- gsub('group=','',names(km$strata))
  # if there are more than 1 btas then lines should have transparency
  if (length(chosen.btas) > 1) {
    my.alpha <- .5
  } else {
    my.alpha <- 1
  }
  # plot using ggfortify library's autoplot.survfit
  p1 <- ggfortify:::autoplot.survfit(km, conf.int = FALSE,
                                     xlab = 'Time', ylab = 'Cumulative Survival',
                                     surv.size = 1, censor.alpha = .8, surv.alpha = my.alpha)
  # generate title name
  titlename <- gsub('_', ' ', filename)
  titlename <- gsub("(^|[[:space:]])([[:alpha:]])", "\\1\\U\\2", titlename, perl=TRUE)
  #
  # add light theme (that has a white grid)
  p1 <- p1 + ggplot2::theme_light()
  # change legend options in ggplot
  p1 <- p1 + ggplot2::theme(legend.key = ggplot2::element_blank(), legend.title = ggplot2::element_text(colour = "grey10", size = 10),
                   legend.background = ggplot2::element_rect(colour = "gray"))
  # make sure the 0% is shown
  if (expand.yzero)
    p1 <- p1 + ggplot2::expand_limits(y=.047)
  # limit the x axis if needed
  if (!is.null(xlim))
    p1 <- p1 + ggplot2::coord_cartesian(xlim=xlim, ylim = ylim)
  if (!is.null(ylim))
    p1 <- p1 + ggplot2::coord_cartesian(ylim=ylim, xlim = xlim)
  #
  # colors for the lines
  #  if more than one btas then paired curves (low and high) should have the same color
  #  otherwise, red and green!
  if (length(chosen.btas) > 1) {
    p1 <- p1 + ggplot2::scale_colour_manual(values = c(my.colors()[c(1,2,4,3,10,6,12,9,5,7,8,11,13,14,15,16,17)]))
    p1 <- p1 + ggplot2::theme(legend.title = element_blank())
    width <- 6
    height <- 4
  } else {
    p1 <- p1 + ggplot2::scale_colour_manual(values = c('seagreen', 'indianred2'))
    p1 <- p1 + ggplot2::labs(colour = paste0("p-value = ", format(p_value)))
    width <- 6
    height <- 4
  }
  if (legend.outside == T)
    p1 <- p1 + ggplot2::theme(legend.key.size = ggplot2::unit(20,"points"))
  else
    p1 <- p1 + ggplot2::theme(legend.position = c(1,1), legend.justification = c(1, 1), legend.key.size = ggplot2::unit(20,"points"))
  # save to file
  #
  if (save.plot) {
    my.save.ggplot(paste0('km_', filename), my.plot = p1, base.directory = base.directory,
                   width = width, height = height)
  }
  # after saving, show title in R plot
  if (length(chosen.btas) == 1) {
    p1 <- p1 + ggplot2::ggtitle(paste0(gsub('_', ' ', filename),'\np_value = ',p_value))
  } else {
    p1 <- p1 + ggplot2::ggtitle(paste0(gsub('_', ' ', filename)))
  }
  # return p-value, plot and km object
  return(list(pvalue = p_value, plot = p1, km = km))
}


#' Save ggplots to file in multiple formats
#'
#' @param filename
#' @param my.plot
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
my.save.ggplot <- function(filename, my.plot = last_plot(), base.directory, out.format = c('pdf', 'png'),
                           width = 6, height = 4, separate.directory = T) {
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



