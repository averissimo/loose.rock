_note to self_: check howto in the bottom

## version 1.2.0

This build corrects errors on past release before R 3.6.3 and BioC <=3.9 _(down to the R 3.4.0)_

It also covers more tests and simplifies some of the code logic.

(adds NEWS.md and submits using devtools::release() instead of devtools::submit_cran())

### Code coverage

79.24% (from 78.66%) -- https://codecov.io/github/averissimo/loose.rock?branch=master

### Test environments

* Local Ubuntu Hirsute R _(4.0.4, 3.6.3 and devel)_
* Github actions: _(devel environments are currently not building as R devel is too recent for BioConductor)_
    * windows-latest _(release, oldrel and devel)_
    * macOS-latest _(release, oldrel and devel)_
    * ubuntu-20.04 _(release, oldrel and devel)_
    * All version from 3.4.0 and up _(mixing macOS, ubuntu and windows machines)_
* rhub::check_for_cran(platforms= "see below for arguments")
    * R_COMPILE_AND_INSTALL_PACKAGES = "always" needed as utf8 fails in windows

### R CMD check results _(release: 4.1.0)_

── R CMD check results ─────────────────────────────────────────────────────────────────────────────────────────────────────────── loose.rock 1.2.0 ────
Duration: 3m 11.3s

0 errors ✓ | 0 warnings ✓ | 0 notes ✓

### revdepcheck results

We checked 1 reverse dependencies (0 from CRAN + 1 from Bioconductor), comparing R CMD check results across CRAN and dev versions of this package.

 * We saw 0 new problems
 * We failed to check 0 packages

## HOWTO

```
# check https://github.com/averissimo/loose.rock/actions
devtools::check()

# BiocManager::install('r-lib/revdepcheck')
revdepcheck::revdep_check(num_workers = 4)

rhub::check_for_cran(platforms= c('windows-x86_64-oldrel'))
rhub::check_for_cran(
  platforms = c(
    'macos-highsierra-release-cran',
    'solaris-x86-patched',
    'ubuntu-gcc-release',
    'windows-x86_64-devel',
    'windows-x86_64-release',
    'fedora-gcc-devel'
  )
)

devtools::release() 
```
