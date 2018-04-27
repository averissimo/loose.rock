context("ggplot")

# load a dataset to be used here
data(ovarian, package = 'survival')

test_that("Calculates kaplan-meier data", {
  result <- draw.kaplan(c(age = 1), ovarian$age, data.frame(time = ovarian$futime, status = ovarian$fustat))

  expect_lt(result$pvalue - 0.0518148, 1e-2)
})

test_that("Saves kaplan-meier to disk", {
  result <- draw.kaplan(c(age = 1), ovarian$age, data.frame(time = ovarian$futime, status = ovarian$fustat),
                        save.plot = TRUE)

  expect_true(file.exists(file.path('output', 'kaplan-meier', 'pdf', 'km_SurvivalCurves.pdf')))
  expect_true(file.exists(file.path('output', 'kaplan-meier', 'png', 'km_SurvivalCurves.png')))

  result <- draw.kaplan(c(age = 1), ovarian$age, data.frame(time = ovarian$futime, status = ovarian$fustat),
                        save.plot = TRUE, filename ='test1')

  expect_true(file.exists(file.path('output', 'kaplan-meier', 'pdf', 'km_test1.pdf')))
  expect_true(file.exists(file.path('output', 'kaplan-meier', 'png', 'km_test1.png')))
})

test_that('Only one group in kaplan.meier gives error', {
  expect_error(draw.kaplan(c(age = 0), ovarian$age, data.frame(time = ovarian$futime, status = ovarian$fustat)))
})

test_that('All combinations of parameters possible for draw.kapan', {
  xdata <- ovarian[,c('age', 'resid.ds')]
  ydata <- data.frame(time = ovarian$futime, status = ovarian$fustat)

  # list, data.frame, data.frame
  expect_silent(draw.kaplan(list(c(1,0)), xdata, ydata))
  # list, matrix, data.frame
  expect_silent(draw.kaplan(list(c(1,0)), as.matrix(xdata), ydata))

  # list, numeric, data.frame
  expect_silent(draw.kaplan(list(c(1)), xdata$age, ydata))
  # list, numeric, data.frame
  expect_silent(draw.kaplan(1, xdata$age, ydata))

  # numeric, data.frame, data.frame
  expect_silent(draw.kaplan(c(1,0), xdata, ydata))
  # numeric, matrix, data.frame
  expect_silent(draw.kaplan(c(1,0), as.matrix(xdata), ydata))
})

test_that('Some bad arguments for draw.kaplan', {
  xdata <- ovarian[,c('age', 'resid.ds')]
  ydata <- data.frame(time = ovarian$futime, status = ovarian$fustat)

  # list, data.frame, data.frame
  expect_error(draw.kaplan(list(c(1,0), c(0,1,2)), xdata, ydata))
  # list, matrix, data.frame
  expect_error(draw.kaplan(list(c(1,0)), as.matrix(xdata), ydata[1:10,]))

  # list, numeric, data.frame
  expect_error(draw.kaplan(list(c(1,0)), xdata$age, ydata))
  # list, numeric, data.frame
  expect_error(draw.kaplan(c(1,2), xdata$age, ydata))

  # numeric, data.frame, data.frame
  expect_error(draw.kaplan(c(1,0,1), xdata, ydata))
  # numeric, matrix, data.frame
  expect_error(draw.kaplan(c(1,0), t(as.matrix(xdata)), ydata))
})

test_that('Save ggplot to disk', {
  # Generate some sample data, then compute mean and standard deviation
  # in each group
  df <- data.frame(
    gp = factor(rep(letters[1:3], each = 10)),
    y = rnorm(30)
  )
  ds <- plyr::ddply(df, "gp", plyr::summarise, mean = mean(y), sd = sd(y))

  # The summary data frame ds is used to plot larger red points on top
  # of the raw data. Note that we don't need to supply `data` or `mapping`
  # in each layer because the defaults from ggplot() are used.
  g <- ggplot2::ggplot(df, ggplot2::aes_(quote(gp), quote(y))) +
    ggplot2::geom_point() +
    ggplot2::geom_point(data = ds, ggplot2::aes_(y = quote(mean)), colour = 'red', size = 3)

  save.ggplot(filename = 'test.me', base.directory = 'test.figures', my.plot = g)

  expect_true(file.exists(file.path('test.figures', 'png', 'test.me.png')))
  expect_true(file.exists(file.path('test.figures', 'pdf', 'test.me.pdf')))

  save.ggplot(filename = 'test.me', base.directory = 'test.figures2', my.plot = g, out.format = 'pdf')

  expect_false(file.exists(file.path('test.figures2', 'png', 'test.me.png')))
  expect_true(file.exists(file.path('test.figures2', 'pdf', 'test.me.pdf')))

  save.ggplot(filename = 'test.me', base.directory = 'test.figures3', my.plot = g, separate.directory = F)

  expect_true(file.exists(file.path('test.figures3', 'test.me.png')))
  expect_true(file.exists(file.path('test.figures3', 'test.me.pdf')))
})
