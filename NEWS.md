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
