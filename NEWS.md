## version 1.2.0

- adds functions for generating balanced training/test sets and cross-validation folds that accepts a single vector
    - From the vector it determines all existing classes and divides the data accordingly

## version 1.1.2

- Supports R versions down to R 3.4.0 _(was failing with R <=3.5.2 or any that used Bioconductor 3.9 or below)_
- Test more R versions in github actions

(this release was not published)

## version 1.1.1

- Corrects problem with CRAN macosx oldrel by accounting for a new fringe scenario
- Maintains compatibility with older versions of R
- Refactors the README and Overview vignette _(no more manual hacks to build github's readme)_
- Further simplifies getBM.internal function that serves as a proxy to biomaRt's getBM
    - Extra robustness to when getBM doesn't recognize one argument _(fringe scenario)_
- Adds NEWS.md file

---

### verion 1.1.0

- Better support for R version <4.0.0 by adding additional fault tolerance to biomaRt calls
- run.cache had a severe bug that failed on getting a signature on some functions
- adds many more unit tests to account for all this
- adds fault tolerant download calls
