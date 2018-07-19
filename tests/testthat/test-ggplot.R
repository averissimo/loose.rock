context("ggplot")

# load a dataset to be used here
data(ovarian, package = 'survival')

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
