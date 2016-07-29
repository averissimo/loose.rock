#' draw.kaplan
#'
#' Mega function that draws multiple kaplan meyer survival curves (or just 1)
#'
#' @param filename name of file to save the plot
#' @param chosen.btas list of testing coefficients to calculate prognostic indexes
#' @param xdata n x m matrix with n observations and m variables
#' @param ydata Survival object
#' @param sep How to separate high and low risk patients 50\%-50\% is the default, but for top and bottom 40\% -> c(.4,.6)
#' @param save.plot TRUE plots everything and save, FALSE only calculates p-valeu
#' @param xlim Optional argument to limit the x-axis view
#'
#' @return
#'
#' A list with plot, p-value and kaplan-meier object
#'
#' @export
#'
#' @examples
#'
draw.kaplan <- function(filename = 'kaplan', chosen.btas, xdata, ydata, sep = c(.5, .5),
                                 save.plot = T, xlim = NULL) {''
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
    temp.group <- array(-1, dim(prognostic.index)[1])
    pi.thres <- quantile(prognostic.index[,ix], probs = c(sep[1], sep[2]))
    # low risk
    temp.group[prognostic.index[,ix] <  pi.thres[1]] <- (2 * ix) - 1
    # high risk
    temp.group[prognostic.index[,ix] >= pi.thres[2]] <- (2 * ix)
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
  prognostic.index.df$group <- factor(dplyr:::mapvalues(prognostic.index.df$group, from = 1:(2*length(chosen.btas)), to = new.factor.str))
  #
  # Generate the Kaplan-Meier survival object
  km        <- survival::survfit(Surv(time, status) ~ group,  data = prognostic.index.df)
  # Calculate the logrank test p-value
  surv.prob <- survival::survdiff(Surv(time, status) ~ group,  data = prognostic.index.df)
  p_value   <- 1 - stats::pchisq(surv.prob$chisq, df = 1)
  #
  # if p-value is all that is wanted, return it, otherwise plot survival curves
  #
  if (!save.plot)
    return(list(pvalue = p_value, km = km))
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
  p1 <- ggplot2::autoplot(km, conf.int = FALSE,
                 xlab = 'Time (month)', ylab = 'Cumulative Survival',
                 surv.size = 1, censor.alpha = .8, surv.alpha = my.alpha)
  # generate title name
  titlename <- gsub('_', ' ', filename)
  titlename <- gsub("(^|[[:space:]])([[:alpha:]])", "\\1\\U\\2", titlename, perl=TRUE)
  #
  # add light theme (that has a white grid)
  p1 <- p1 + ggplot2::theme_light()
  # change legend options in ggplot
  p1 <- p1 + ggplot2::theme(legend.key = element_blank(), legend.title = element_text(colour = "grey10", size = 10),
                   legend.background = element_rect(colour = "gray"))
  # make sure the 0% is shown
  p1 <- p1 + ggplot2::expand_limits(y=.047)
  # limit the x axis if needed
  if (!is.null(xlim))
    p1 <- p1 + ggplot2::coord_cartesian(xlim=c(0,115))
  #
  # colors for the lines
  #  if more than one btas then paired curves (low and high) should have the same color
  #  otherwise, red and green!
  if (length(chosen.btas) > 1) {
    p1 <- p1 + ggplot2::scale_colour_manual(values = rep(my.colors()[1:length(chosen.btas)],2))
    p1 <- p1 + ggplot2::theme(legend.title = element_blank())
    width <- 8
    height <- 4
  } else {
    p1 <- p1 + ggplot2::scale_colour_manual(values = c('indianred2','seagreen'))
    p1 <- p1 + ggplot2::labs(colour = paste0("p-value = ", format(p_value)))
    p1 <- p1 + ggplot2::theme(legend.position = c(1,1),legend.justification = c(1, 1))
    width <- 6
    height <- 4
  }
  # save to file
  my.save.ggplot(paste0('km_', filename), my.plot = p1, base.directory = file.path('output', 'kaplan-meier'),
                 width = width, height = height)
  # after saving, show title in R plot
  p1 <- p1 + ggplot2::ggtitle(paste0(gsub('_', ' ', filename),'\np_value = ',p_value))
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



