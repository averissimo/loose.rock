context("coding.genes")

mart <- loose.rock:::getHsapiensMart.internal()

test_that("coding genes retrieves some genes", {
  genes <- coding.genes(verbose = FALSE)
  expect_true(all(c('BRCA1', 'BRCA2', 'CHADL', 'BTBD8', 'BCAS2', 'AGAP1') %in% genes$external_gene_name))
})

test_that("getBM internal gets the same as biomaRt::getBM", {
  expect_identical(
    loose.rock:::getBM.internal(
      attributes = c("ensembl_gene_id","external_gene_name"),
      filters    = 'biotype',
      values     = c('protein_coding'),
      mart       = mart,
    ),
    biomaRt::getBM(
      attributes = c("ensembl_gene_id","external_gene_name"),
      filters    = 'biotype',
      values     = c('protein_coding'),
      mart       = mart,
    )
  )
})
