context("coding.genes")

loose.rock::show.message(FALSE)
loose.rock::run.cache(coding.genes, verbose = FALSE)

test_that("coding genes retrieves some genes", {
  genes <- loose.rock::run.cache(coding.genes, verbose = FALSE)
  expect_true(all(c('BRCA1', 'BRCA2', 'CHADL', 'BTBD8', 'BCAS2', 'AGAP1') %in% genes$external_gene_name))
})
