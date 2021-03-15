context("coding.genes")

# Avoid some lifecycle warnings in versions of R < 4
#  this mostly relates to using cache in biomaRt
suppressWarnings({
  dplyr::filter_(dplyr::tibble())
  dplyr::select_(dplyr::tibble())
})

# Make sure cache is clear to avoid corruption
if (R.Version()$major >= 4) {
  # Cache is not used is versions before 4.0.0
  #  Also corrects nagging bug with Mac OSX and R 3.6.2 where biomartCacheClear
  #  has not been included ()
  biomaRt::biomartCacheClear()
}

# Get a mart object
mart <- loose.rock:::getHsapiensMart.internal()

# use a temporary path to store cache
base.dir(file.path(tempdir(), "coding_genes"))

###################################################################################
#
#              _   _    _                 _                __  __            _
#             | | | |  | |               (_)              |  \/  |          | |
#    __ _  ___| |_| |__| |___  __ _ _ __  _  ___ _ __  ___| \  / | __ _ _ __| |_
#   / _` |/ _ \ __|  __  / __|/ _` | '_ \| |/ _ \ '_ \/ __| |\/| |/ _` | '__| __|
#  | (_| |  __/ |_| |  | \__ \ (_| | |_) | |  __/ | | \__ \ |  | | (_| | |  | |_
#   \__, |\___|\__|_|  |_|___/\__,_| .__/|_|\___|_| |_|___/_|  |_|\__,_|_|   \__|
#    __/ |                         | |
#   |___/                          |_|
#
#  getHsapiensMart
##################################################################################
test_that("getHsapiensMart.internal works", {
  expect_identical(mart@biomart, "ENSEMBL_MART_ENSEMBL")
})

###################################################################################
#
#                   _                      _                                   _
#                  | |                    | |                                 | |
#    ___ _   _ _ __| | __      _____  _ __| | ____ _ _ __ ___  _   _ _ __   __| |
#   / __| | | | '__| | \ \ /\ / / _ \| '__| |/ / _` | '__/ _ \| | | | '_ \ / _` |
#  | (__| |_| | |  | |  \ V  V / (_) | |  |   < (_| | | | (_) | |_| | | | | (_| |
#   \___|\__,_|_|  |_|   \_/\_/ \___/|_|  |_|\_\__,_|_|  \___/ \__,_|_| |_|\__,_|
#
#
#
#  curl workaround
##################################################################################
test_that("curl_workarund tests with ssl_verifypeer FALSE", {
  expect_error(
    expect_warning(
      loose.rock:::curl.workaround({stop("me")}, verbose = TRUE),
      "There was an problem, calling the function with ssl_verifypeer to FALSE"
    ),
    "me"
  )
})

###############################################################
#
#                 _ _
#                | (_)
#    ___ ___   __| |_ _ __   __ _   __ _  ___ _ __   ___  ___
#   / __/ _ \ / _` | | '_ \ / _` | / _` |/ _ \ '_ \ / _ \/ __|
#  | (_| (_) | (_| | | | | | (_| || (_| |  __/ | | |  __/\__ \
#   \___\___/ \__,_|_|_| |_|\__, (_)__, |\___|_| |_|\___||___/
#                            __/ |  __/ |
#                           |___/  |___/
#
#  coding.genes
##############################################################
test_that("coding genes retrieves some genes", {
  # Depending on network connectivity or R version, biomaRt or ccds might
  #  fail. So this test surppress warnings (as long as there are some genes)
  #  then the function works (either just from ccds or from both sources)
  genes <- suppressWarnings(coding.genes(verbose = TRUE))
  expect_true(
    all(
      c(
        "BRCA1", "BRCA2", "CHADL", "BTBD8", "BCAS2", "AGAP1"
      ) %in% genes$external_gene_name
    )
  )
})

##########################################################
#
#    _______  _______ .___________..______   .___  ___.
#   /  _____||   ____||           ||   _  \  |   \/   |
#  |  |  __  |  |__   `---|  |----`|  |_)  | |  \  /  |
#  |  | |_ | |   __|      |  |     |   _  <  |  |\/|  |
#  |  |__| | |  |____     |  |     |  |_)  | |  |  |  |
#   \______| |_______|    |__|     |______/  |__|  |__|
#
#
#  getBM
#########################################################
test_that("getBM internal errors and messages", {
  expect_error(getBM.internal(), "You must provide a valid Mart object")
  expect_error(
    getBM.internal(mart = mart, verbose = TRUE),
    "Argument 'attributes' must be specified"
  )
  expect_error(
    getBM.internal(mart = mart, verbose = FALSE),
    "Argument 'attributes' must be specified"
  )
})

test_that("getBM multiple combinations of useCache", {
  args <- list(
    attributes = c("ensembl_gene_id", "external_gene_name"),
    filters    = "external_gene_name",
    values     = c("BRCA1", "BRCA2", "CHADL", "BTBD8", "BCAS2", "AGAP1"),
    mart       = mart,
    useCache   = TRUE
  )

  args.2 <- args
  args.2[['useCache']] <- FALSE

  expect_identical(
    do.call(loose.rock:::getBM.internal, args),
    do.call(loose.rock:::getBM.internal, args.2)
  )

  if (R.Version()$major >= 4) {
    args.3 <- args
    args.3[['useCache']] <- NULL
    args.3[['failNullUseCache']] <- TRUE

    expect_identical(
      do.call(loose.rock:::getBM.internal, args),
      do.call(loose.rock:::getBM.internal, args.3)
    )
  }

  args.4 <- args
  args.4[['useCache']] <- NULL

  expect_identical(
    do.call(loose.rock:::getBM.internal, args),
    do.call(loose.rock:::getBM.internal, args.4)
  )
})

test_that("getBM internal gets the same as biomaRt::getBM", {
  args <- list(
    attributes = c("ensembl_gene_id", "external_gene_name"),
    filters    = "external_gene_name",
    values     = c("BRCA1", "BRCA2", "CHADL", "BTBD8", "BCAS2", "AGAP1"),
    mart       = mart,
    useCache   = TRUE
  )

  if (R.Version()$major >= 4) {
    expect_identical(
      do.call(loose.rock:::getBM.internal, args),
      do.call(biomaRt::getBM, args)
    )
  } else {
    err.msg <- expect_error(do.call(biomaRt::getBM, args))
    args.pre4 <- args

    # In case of Bioconductor version < 3.10 then useCache is not
    #  an argument. getBM.internal handles it, but biomaRt::getBM does not.
    if (grepl('unused argument [(]useCache [=]', err.msg)) {
      args.pre4$useCache <- NULL
    } else {
      args.pre4$useCache <- FALSE
    }

    expect_identical(
      do.call(loose.rock:::getBM.internal, args.pre4),
      do.call(biomaRt::getBM, args.pre4)
    )
  }
})

