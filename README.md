
<!-- README.md is generated from README.Rmd. Please edit that file -->
Verissimo r-package
===================

With personal functions I like to reuse everytime!

Proper
------

One of such is a proper function that capitalizes a string.

``` r
x <- "OnE oF sUcH iA a proPer function that capitalizes a string."
proper(x)
#> [1] "One Of Such Ia A Proper Function That Capitalizes A String."
```

my.colors & my.symbols
----------------------

`my.colors()` and `my.symbols()` can be used to improve plot readability.

``` r
xdata <- -10:10
draw.empty.plot(xlim = c(-10,10), ylim = c(0,23))
for (ix in 1:22) {
  points(xdata, 1/10 * xdata * xdata + ix, pch = my.symbols(ix), col = my.colors(ix), cex = .9)
}
```

![](README-mycolors-1.png)

draw.kaplan
-----------

``` r
suppressPackageStartupMessages(library(survival))
suppressPackageStartupMessages(library(plyr))
suppressPackageStartupMessages(library(ggfortify))
suppressPackageStartupMessages(library(gridExtra))
data(flchain)
ydata <- data.frame( time = flchain$futime, status = flchain$death)
xdata <- cbind(flchain$age, as.numeric(flchain$sex == 'M'))
page <- draw.kaplan(list(Age= c(1,0)), xdata = xdata, ydata = ydata)$plot
psex <- draw.kaplan(list(Age= c(0,1)), xdata = xdata, ydata = ydata)$plot
grid.arrange(page, psex, ncol = 2)
```

![](README-draw.kaplan-1.png)

``` r
#
draw.kaplan(list(Age= c(1,0), Sex = c(0,1)), xdata = xdata, ydata = ydata)$plot
```

![](README-draw.kaplan-2.png)
