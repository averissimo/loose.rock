context("coding.genes")

mart <- loose.rock:::getHsapiensMart.internal()

test_that("curl_workarund tests with ssl_verifypeer FALSE", {
  expect_error(
    expect_warning(
      loose.rock:::curl.workaround({stop('me')}, verbose = TRUE),
      'There was an problem, calling the function with ssl_verifypeer to FALSE'
    ),
    'me'
  )
})

test_that("getBM.internal", {
  expect_error(getBM.internal(), "You must provide a valid Mart object")
  expect_warning(
    expect_error(
      getBM.internal(mart = mart, verbose = TRUE),
      "Argument 'attributes' must be specified"
    ),
    "Argument 'attributes' must be specified"
  )
})

test_that("coding genes retrieves some genes", {
  # Suppress warnings, as with R <3.6.3 will produce warnings
  #  with biomaRt failing
  genes <- if (R.Version()$major >= 4) {
    coding.genes(verbose = TRUE)
  } else {
    suppressWarnings(coding.genes(verbose = TRUE))
  }
  expect_true(
    all(
      c(
        'BRCA1', 'BRCA2', 'CHADL', 'BTBD8', 'BCAS2', 'AGAP1'
      ) %in% genes$external_gene_name
    )
  )
})

test_that("getBM internal gets the same as biomaRt::getBM", {
  if (R.Version()$major >= 4) {
    expect_identical(
      loose.rock:::getBM.internal(
        attributes = c("ensembl_gene_id","external_gene_name"),
        filters    = 'biotype',
        values     = c('protein_coding'),
        mart       = mart
      ),
      biomaRt::getBM(
        attributes = c("ensembl_gene_id","external_gene_name"),
        filters    = 'biotype',
        values     = c('protein_coding'),
        mart       = mart
      )
    )
  }
})

