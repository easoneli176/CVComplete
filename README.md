
<!-- README.md is generated from README.Rmd. Please edit that file -->

# CVComplete

<!-- badges: start -->
<!-- badges: end -->

The goal of CVComplete is to package all the functions Lizzie has had to
build on her own when working with cross validation. It harnesses
functions from a myriad of other packages, and tailors their powers to
perform CV and output the metrics Lizzie often needs for her work.

Cross validation is used to determine the effectiveness of a particular
modeling method. In k-fold cross validation, rather than a single simple
train-test split, we harness the power of the entire dataset to
determine how the method performs on unseen data by iteratively applying
the method to different subsets of the data and testing it on the unseen
subset. The metrics calculated from k-fold cross validation are averaged
across the k-folds and assumed to apply to the modeling method itself.
Thus, once the predictive power of the method has been established
through k-fold cross validation, typically we re-fit the final model
using the method on the full dataset. There is some controversy over
this refitting step as sometimes the size of a dataset can change
predictive power, but this is the general practice.

Typically, data scientists are interested in calculating performance
metrics on the out of fold predictions from cross validation and using
them to determine model predictive power. However, Lizzie has found
there is often more to consider than metrics such as the AIC, BIC, RMSE,
R^2, etc. Particularly in the case of linear models, we can evaluate the
stability of linear coefficients across models created from different
segments of data. Further, we can consider how often models overfit the
data across folds, or how often a certain coefficient was statistically
significant. That’s where this package comes into play. This package
automates coefficient comparison across folds, and gives the user
easy-to-work-with fields for folds and out of fold predictions, which
allow the user to calculate their own creative metrics if they so
desire.

## Installation

You can install the development version of CVComplete from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("easoneli176/CVComplete")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(CVComplete)
#> Loading required package: caret
#> Warning: package 'caret' was built under R version 4.2.3
#> Loading required package: ggplot2
#> Warning: package 'ggplot2' was built under R version 4.2.3
#> Loading required package: lattice

mock_data <- data.frame(preds = rep(1:4,10),target=rep(1:5,8),strat=rep(1:2,20))

#new data set:
newdat<-fold_field(mock_data,3,"strat")

#check that stratification worked:
table(newdat$fold,newdat$strat)
#>    
#>     1 2
#>   1 7 7
#>   2 7 6
#>   3 6 7

#other 3 functions:
#create mock dataframe
mock_data <- data.frame(preds1 = rep(1:4,10),preds2 = rep(1:10,4),target=rep(1:5,8),strat=rep(1:2,20),weights = rep(c(2,1),20))
#model function:
model_function<-function(target,data,weights){
 targnum<-which(colnames(data) == target)
 weightnum<-which(colnames(data) == weights)
 moddat<-data[,-c(targnum,weightnum)]
 targ<-data[,targnum]
 weights<-data[,weightnum]
 set.seed(123)
 mod<-lm(targ~.,data=moddat,weights=weights)
 mod
 }
#test function:
summary(model_function("target",mock_data,"weights"))
#> 
#> Call:
#> lm(formula = targ ~ ., data = moddat, weights = weights)
#> 
#> Weighted Residuals:
#>    Min     1Q Median     3Q    Max 
#> -2.121 -1.414  0.000  1.000  2.828 
#> 
#> Coefficients:
#>               Estimate Std. Error t value Pr(>|t|)   
#> (Intercept)  2.000e+00  7.071e-01   2.828  0.00760 **
#> preds1       1.880e-16  2.041e-01   0.000  1.00000   
#> preds2       2.500e-01  7.217e-02   3.464  0.00139 **
#> strat       -2.500e-01  4.841e-01  -0.516  0.60873   
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
#> 
#> Residual standard error: 1.581 on 36 degrees of freedom
#> Multiple R-squared:   0.25,  Adjusted R-squared:  0.1875 
#> F-statistic:     4 on 3 and 36 DF,  p-value: 0.01479
#compare to:
mock_data2 <- mock_data[,-which(colnames(mock_data) == "weights")]
summary(lm(target~.,data=mock_data2,weights=mock_data$weights))
#> 
#> Call:
#> lm(formula = target ~ ., data = mock_data2, weights = mock_data$weights)
#> 
#> Weighted Residuals:
#>    Min     1Q Median     3Q    Max 
#> -2.121 -1.414  0.000  1.000  2.828 
#> 
#> Coefficients:
#>               Estimate Std. Error t value Pr(>|t|)   
#> (Intercept)  2.000e+00  7.071e-01   2.828  0.00760 **
#> preds1       1.880e-16  2.041e-01   0.000  1.00000   
#> preds2       2.500e-01  7.217e-02   3.464  0.00139 **
#> strat       -2.500e-01  4.841e-01  -0.516  0.60873   
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
#> 
#> Residual standard error: 1.581 on 36 degrees of freedom
#> Multiple R-squared:   0.25,  Adjusted R-squared:  0.1875 
#> F-statistic:     4 on 3 and 36 DF,  p-value: 0.01479

#finally, if those match, test functions:
mymods<-buildcvmods(mock_data,"target","strat",c("preds1","preds2"),model_function,"weights",3)

datwpreds<-oofpreds(mock_data,"target","strat",c("preds1","preds2"),model_function,"weights",3)

datwpreds
#>    preds1 preds2 target strat weights fold  oofpred
#> 1       1      1      1     1       2    1 1.654592
#> 2       2      2      2     2       1    3 2.295071
#> 3       3      3      3     1       2    3 2.331605
#> 4       4      4      4     2       1    2 2.958620
#> 5       1      5      5     1       2    1 2.593441
#> 6       2      6      1     2       1    3 3.296202
#> 7       3      7      2     1       2    2 3.608283
#> 8       4      8      3     2       1    1 3.537071
#> 9       1      9      4     1       2    1 3.532289
#> 10      2     10      5     2       1    2 4.257946
#> 11      3      1      1     1       2    2 2.111405
#> 12      4      2      2     2       1    3 1.867574
#> 13      1      3      3     1       2    1 2.124016
#> 14      2      4      4     2       1    2 2.761068
#> 15      3      5      5     1       2    2 3.109324
#> 16      4      6      1     2       1    2 3.457579
#> 17      1      7      2     1       2    3 3.760233
#> 18      2      8      3     2       1    1 3.377408
#> 19      3      9      4     1       2    1 3.691952
#> 20      4     10      5     2       1    3 3.869834
#> 21      1      1      1     1       2    2 1.913853
#> 22      2      2      2     2       1    3 2.295071
#> 23      3      3      3     1       2    2 2.610364
#> 24      4      4      4     2       1    1 2.598223
#> 25      1      5      5     1       2    1 2.593441
#> 26      2      6      1     2       1    3 3.296202
#> 27      3      7      2     1       2    2 3.608283
#> 28      4      8      3     2       1    2 3.956539
#> 29      1      9      4     1       2    3 4.260798
#> 30      2     10      5     2       1    1 3.846832
#> 31      3      1      1     1       2    3 1.831040
#> 32      4      2      2     2       1    3 1.867574
#> 33      1      3      3     1       2    2 2.412813
#> 34      2      4      4     2       1    1 2.438560
#> 35      3      5      5     1       2    3 2.832170
#> 36      4      6      1     2       1    2 3.457579
#> 37      1      7      2     1       2    1 3.062865
#> 38      2      8      3     2       1    1 3.377408
#> 39      3      9      4     1       2    3 3.833301
#> 40      4     10      5     2       1    1 4.006495

coeffdat<-coeffcomp(mock_data,"target","strat",c("preds1","preds2"),model_function,"weights",3)

coeffdat
#>              mod1Coeff  mod2Coeff  mod3Coeff  meanCoeff  stdevCoeff CoeffSwitch
#> (Intercept) 1.34004884 1.56559777  2.2220038  1.7092168 0.458182250           N
#> preds1      0.07983143 0.09877588 -0.2137487 -0.0117138 0.175223579           Y
#> preds2      0.23471205 0.24947966  0.2502825  0.2448248 0.008767054           N
#>             mod1CoeffPval mod2CoeffPval mod3CoeffPval ConstSigPval SigPval
#> (Intercept)    0.12416648   0.033702035   0.002954297            N       Y
#> preds1         0.75777602   0.649764424   0.359885381            N       N
#> preds2         0.01702092   0.005067283   0.013610588            Y       Y
```
