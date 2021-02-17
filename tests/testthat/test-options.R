context("options")

test_that("compression", {
  expect_equal(loose.rock.options('compression'), cache.compression())

  expect_failure(
    expect_equal(loose.rock.options('compression'), "bzip2")
  )

  cache.compression("bzip2")
  expect_equal(loose.rock.options('compression'), "bzip2")
})

test_that("base.dir", {
  expect_equal(loose.rock.options('base.dir'), base.dir())

  expect_failure(
    expect_equal(loose.rock.options('base.dir'), tempdir())
  )

  base.dir(tempdir())
  expect_equal(loose.rock.options('base.dir'), tempdir())
})


test_that("show.message", {
  expect_equal(loose.rock.options('show.message'), show.message())

  show.message(FALSE)
  expect_equal(loose.rock.options('show.message'), FALSE)

  expect_failure(
    expect_equal(loose.rock.options('show.message'), TRUE)
  )
})
