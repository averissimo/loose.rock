_note to self_: check howto in the bottom

## version 1.1.1

This build corrects errors on MacOSX oldrel in https://cloud.r-project.org/web/checks/check_results_loose.rock.html

It also covers more tests and simplifies some of the code logic.

(adds NEWS.md and submits using devtools::release() instead of devtools::submit_cran())

### Code coverage

79% -- https://codecov.io/github/averissimo/loose.rock?branch=master

### Test environments

* Local Ubuntu Hirsute R (4.0.0, 3.6.3 and devel)
* Github actions:
    * windows-latest (release)
    * macOS-latest (devel)
    * macOS-latest (release)
    * macOS-latest (oldrel)
    * ubuntu-20.04 (release)
    * ubuntu-20.04 (devel)
    * ubuntu-20.04 (oldrel)
* rhub::check_for_cran(platforms= c('windows-x86_64-oldrel'))
    * R_COMPILE_AND_INSTALL_PACKAGES = "always" needed as utf8 fails in windows


### R CMD check results _(release: 4.0.0)_

── R CMD check results ─────────────────────────────────── loose.rock 1.1.1 ────

Duration: 5m 26.1s

0 errors ✓ | 0 warnings ✓ | 0 notes ✓

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
```
