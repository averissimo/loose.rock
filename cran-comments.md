_note to self_: check howto in the bottom

## version 1.2.1

This build protects the test against errors and maintenance on biomaRt.

It builds on r-devel 4.2.0 without warning or checks

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
