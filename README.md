
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

Further, occasionally the method to be tested with cross validation goes
beyond modeling alone, and feature engineering is also part of the cross
validation method to be tested. For example, imputation methods often
use the mean of the column, which should be re-calculated for each new
fold combination. The function featengcv makes this process
significantly easier.

## Installation

You can install the development version of CVComplete from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("easoneli176/CVComplete")
```

## Example

The first step to cross validation is designating the folds. The
function created in this package appends a field to the data called
“fold” that assigns each observation to a fold. This process can be done
with stratification or without. For example:

``` r
library(CVComplete)
#> Loading required package: caret
#> Warning: package 'caret' was built under R version 4.2.3
#> Loading required package: ggplot2
#> Warning: package 'ggplot2' was built under R version 4.2.3
#> Loading required package: lattice

mock_data <- data.frame(preds = rep(1:4,10),target=rep(1:5,8),strat=rep(1:2,20))

#with stratification
newdat<-fold_field(mock_data,3,"strat")

#without stratification
newdat2<-fold_field(mock_data,3)

#check that stratification worked:
table(newdat$fold,newdat$strat)
#>    
#>     1 2
#>   1 7 7
#>   2 7 6
#>   3 6 7

#check that stratification did not occur:
table(newdat2$fold,newdat$strat)
#>    
#>     1 2
#>   1 6 6
#>   2 9 5
#>   3 5 9

#All functions from this point on can be given a dataset that has already been assigned folds, 
#or it will assign the folds themselves.

#Buildcvmods automates the building of cv models and outputs the models into a list. 
#This is handy if the user wants to evaluate each model in some way outside 
#this package's capabilities. 

#create mock dataframe
mock_data <- data.frame(preds1 = rep(1:4,10),preds2 = rep(1:10,4), 
                        target=rep(1:5,8),strat=rep(1:2,20),weights = rep(c(2,1),20))

#The user must create their own modeling function that intakes a dataset 
#and outputs the model built in the desired methodology. 
#While this is tedious, it is necessary to be able to work with a 
#myriad of modeling methodologies.

#model function:
model_function<-function(data){
 targnum<-which(colnames(data) == "target")
 weightnum<-which(colnames(data) == "weights")
 moddat<-data[,-c(targnum,weightnum)]
 targ<-data[,targnum]
 weights<-data[,weightnum]
 set.seed(123)
 mod<-lm(targ~.,data=moddat,weights=weights)
 mod
 }
#test function:
summary(model_function(mock_data))
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
mymods<-buildcvmods(mock_data,3,modelfunc=model_function)

datwpreds<-oofpreds(mock_data,3,modelfunc=model_function)

datwpreds
#>    preds1 preds2 target strat weights fold  oofpred
#> 1       1      1      1     1       2    3 2.110177
#> 2       2      2      2     2       1    1 2.129124
#> 3       3      3      3     1       2    1 2.364113
#> 4       4      4      4     2       1    2 2.200802
#> 5       1      5      5     1       2    2 3.104968
#> 6       2      6      1     2       1    3 3.252458
#> 7       3      7      2     1       2    1 3.433141
#> 8       4      8      3     2       1    3 3.668562
#> 9       1      9      4     1       2    2 4.238300
#> 10      2     10      5     2       1    3 4.110019
#> 11      3      1      1     1       2    3 2.097500
#> 12      4      2      2     2       1    3 2.382222
#> 13      1      3      3     1       2    2 2.538301
#> 14      2      4      4     2       1    2 2.084799
#> 15      3      5      5     1       2    3 2.955061
#> 16      4      6      1     2       1    3 3.239782
#> 17      1      7      2     1       2    1 3.543730
#> 18      2      8      3     2       1    1 3.732666
#> 19      3      9      4     1       2    2 4.354303
#> 20      4     10      5     2       1    1 4.156590
#> 21      1      1      1     1       2    2 1.971635
#> 22      2      2      2     2       1    3 2.394898
#> 23      3      3      3     1       2    3 2.526280
#> 24      4      4      4     2       1    1 2.553049
#> 25      1      5      5     1       2    1 3.009216
#> 26      2      6      1     2       1    1 3.198152
#> 27      3      7      2     1       2    2 3.787637
#> 28      4      8      3     2       1    3 3.668562
#> 29      1      9      4     1       2    2 4.238300
#> 30      2     10      5     2       1    2 3.784798
#> 31      3      1      1     1       2    1 1.829599
#> 32      4      2      2     2       1    3 2.382222
#> 33      1      3      3     1       2    3 2.538957
#> 34      2      4      4     2       1    3 2.823678
#> 35      3      5      5     1       2    1 2.898627
#> 36      4      6      1     2       1    1 3.087563
#> 37      1      7      2     1       2    2 3.671634
#> 38      2      8      3     2       1    2 3.218131
#> 39      3      9      4     1       2    2 4.354303
#> 40      4     10      5     2       1    2 3.900800

coeffdat<-coeffcomp(mock_data,3,modelfunc=model_function)

coeffdat
#>               mod1Coeff   mod2Coeff    mod3Coeff    meanCoeff stdevCoeff
#> (Intercept)  1.75125200  2.42513778  1.825455120  2.000614966 0.36951487
#> preds1      -0.05529454  0.05800136 -0.006338112 -0.001210431 0.05682174
#> preds2       0.26725696  0.28333312  0.214390080  0.254993385 0.03607051
#> strat       -0.02302649 -0.79483704  0.076669431 -0.247064699 0.47699657
#>             CoeffSwitch mod1CoeffPval mod2CoeffPval mod3CoeffPval ConstSigPval
#> (Intercept)           N   0.029279529    0.01908140    0.07551395            N
#> preds1                Y   0.808618163    0.83883103    0.98131937            N
#> preds2                N   0.001434062    0.02149341    0.04037468            Y
#> strat                 Y   0.966457121    0.22883472    0.90845941            N
#>             SigPval
#> (Intercept)       Y
#> preds1            N
#> preds2            Y
#> strat             N

#Note that if the folds are predefined, we do not need the numfolds argument. 
#These objects should match the ones above since all of these functions call foldfield:

newdat2<-fold_field(mock_data,3)

mymods2<-buildcvmods(newdat2,modelfunc=model_function)

datwpreds2<-oofpreds(newdat2,modelfunc=model_function)

datwpreds2
#>    preds1 preds2 target strat weights fold  oofpred
#> 1       1      1      1     1       2    3 2.110177
#> 2       2      2      2     2       1    1 2.129124
#> 3       3      3      3     1       2    1 2.364113
#> 4       4      4      4     2       1    2 2.200802
#> 5       1      5      5     1       2    2 3.104968
#> 6       2      6      1     2       1    3 3.252458
#> 7       3      7      2     1       2    1 3.433141
#> 8       4      8      3     2       1    3 3.668562
#> 9       1      9      4     1       2    2 4.238300
#> 10      2     10      5     2       1    3 4.110019
#> 11      3      1      1     1       2    3 2.097500
#> 12      4      2      2     2       1    3 2.382222
#> 13      1      3      3     1       2    2 2.538301
#> 14      2      4      4     2       1    2 2.084799
#> 15      3      5      5     1       2    3 2.955061
#> 16      4      6      1     2       1    3 3.239782
#> 17      1      7      2     1       2    1 3.543730
#> 18      2      8      3     2       1    1 3.732666
#> 19      3      9      4     1       2    2 4.354303
#> 20      4     10      5     2       1    1 4.156590
#> 21      1      1      1     1       2    2 1.971635
#> 22      2      2      2     2       1    3 2.394898
#> 23      3      3      3     1       2    3 2.526280
#> 24      4      4      4     2       1    1 2.553049
#> 25      1      5      5     1       2    1 3.009216
#> 26      2      6      1     2       1    1 3.198152
#> 27      3      7      2     1       2    2 3.787637
#> 28      4      8      3     2       1    3 3.668562
#> 29      1      9      4     1       2    2 4.238300
#> 30      2     10      5     2       1    2 3.784798
#> 31      3      1      1     1       2    1 1.829599
#> 32      4      2      2     2       1    3 2.382222
#> 33      1      3      3     1       2    3 2.538957
#> 34      2      4      4     2       1    3 2.823678
#> 35      3      5      5     1       2    1 2.898627
#> 36      4      6      1     2       1    1 3.087563
#> 37      1      7      2     1       2    2 3.671634
#> 38      2      8      3     2       1    2 3.218131
#> 39      3      9      4     1       2    2 4.354303
#> 40      4     10      5     2       1    2 3.900800

coeffdat2<-coeffcomp(newdat2,modelfunc=model_function)

coeffdat2
#>               mod1Coeff   mod2Coeff    mod3Coeff    meanCoeff stdevCoeff
#> (Intercept)  1.75125200  2.42513778  1.825455120  2.000614966 0.36951487
#> preds1      -0.05529454  0.05800136 -0.006338112 -0.001210431 0.05682174
#> preds2       0.26725696  0.28333312  0.214390080  0.254993385 0.03607051
#> strat       -0.02302649 -0.79483704  0.076669431 -0.247064699 0.47699657
#>             CoeffSwitch mod1CoeffPval mod2CoeffPval mod3CoeffPval ConstSigPval
#> (Intercept)           N   0.029279529    0.01908140    0.07551395            N
#> preds1                Y   0.808618163    0.83883103    0.98131937            N
#> preds2                N   0.001434062    0.02149341    0.04037468            Y
#> strat                 Y   0.966457121    0.22883472    0.90845941            N
#>             SigPval
#> (Intercept)       Y
#> preds1            N
#> preds2            Y
#> strat             N

#Finally, we showcase the feature engineering function, which is the most complex.

mock_data <- data.frame(col1 = as.numeric(c(rep(1:4,9), rep("NA",4))), 
                        col2 = as.numeric(c(rep("NA",4),rep(1:9,4))),strat=rep(c(1,2),20))
#> Warning in data.frame(col1 = as.numeric(c(rep(1:4, 9), rep("NA", 4))), col2 =
#> as.numeric(c(rep("NA", : NAs introduced by coercion
#> Warning in data.frame(col1 = as.numeric(c(rep(1:4, 9), rep("NA", 4))), col2 =
#> as.numeric(c(rep("NA", : NAs introduced by coercion

#The user must write their own engineering function which performs all necessary 
#feature engineering to be done on each CV run, and critically this function 
#must output the model that repeats that process on the out of fold data. 
#This is tricky to write, but it is needed to provide user flexibility, 
#and our example helps:

#engineer function:
eng_function<-function(data){
 col1<-data[,which(colnames(data) == "col1")]
 col2<-data[,which(colnames(data) == "col2")]
 val1<-mean(col1,na.rm=TRUE)
 val2<-median(col2,na.rm=TRUE)
 mod<-function(data){
 col1<-data[,which(colnames(data) == "col1")]
 col2<-data[,which(colnames(data) == "col2")]
 data[,which(colnames(data) == "col1")]<-ifelse(is.na(col1),val1,col1)
 data[,which(colnames(data) == "col2")]<-ifelse(is.na(col2),val2,col2)
 data
 }
 mod
}

#test function:
impfunc<-eng_function(mock_data)
impfunc(mock_data)
#>    col1 col2 strat
#> 1   1.0    5     1
#> 2   2.0    5     2
#> 3   3.0    5     1
#> 4   4.0    5     2
#> 5   1.0    1     1
#> 6   2.0    2     2
#> 7   3.0    3     1
#> 8   4.0    4     2
#> 9   1.0    5     1
#> 10  2.0    6     2
#> 11  3.0    7     1
#> 12  4.0    8     2
#> 13  1.0    9     1
#> 14  2.0    1     2
#> 15  3.0    2     1
#> 16  4.0    3     2
#> 17  1.0    4     1
#> 18  2.0    5     2
#> 19  3.0    6     1
#> 20  4.0    7     2
#> 21  1.0    8     1
#> 22  2.0    9     2
#> 23  3.0    1     1
#> 24  4.0    2     2
#> 25  1.0    3     1
#> 26  2.0    4     2
#> 27  3.0    5     1
#> 28  4.0    6     2
#> 29  1.0    7     1
#> 30  2.0    8     2
#> 31  3.0    9     1
#> 32  4.0    1     2
#> 33  1.0    2     1
#> 34  2.0    3     2
#> 35  3.0    4     1
#> 36  4.0    5     2
#> 37  2.5    6     1
#> 38  2.5    7     2
#> 39  2.5    8     1
#> 40  2.5    9     2

#Notice col2 had 5 imputed and col1 had 2.5. 
#Now, we create a new dataset where the names of the columns are the same,
#but the means/medians will be different.

mock_data2 <- data.frame(col2 = as.numeric(c(rep(1:4,9),rep("NA",4))),
                         col1 = as.numeric(c(rep("NA",4),rep(1:9,4))))
#> Warning in data.frame(col2 = as.numeric(c(rep(1:4, 9), rep("NA", 4))), col1 =
#> as.numeric(c(rep("NA", : NAs introduced by coercion
#> Warning in data.frame(col2 = as.numeric(c(rep(1:4, 9), rep("NA", 4))), col1 =
#> as.numeric(c(rep("NA", : NAs introduced by coercion

impfunc(mock_data2)
#>    col2 col1
#> 1     1  2.5
#> 2     2  2.5
#> 3     3  2.5
#> 4     4  2.5
#> 5     1  1.0
#> 6     2  2.0
#> 7     3  3.0
#> 8     4  4.0
#> 9     1  5.0
#> 10    2  6.0
#> 11    3  7.0
#> 12    4  8.0
#> 13    1  9.0
#> 14    2  1.0
#> 15    3  2.0
#> 16    4  3.0
#> 17    1  4.0
#> 18    2  5.0
#> 19    3  6.0
#> 20    4  7.0
#> 21    1  8.0
#> 22    2  9.0
#> 23    3  1.0
#> 24    4  2.0
#> 25    1  3.0
#> 26    2  4.0
#> 27    3  5.0
#> 28    4  6.0
#> 29    1  7.0
#> 30    2  8.0
#> 31    3  9.0
#> 32    4  1.0
#> 33    1  2.0
#> 34    2  3.0
#> 35    3  4.0
#> 36    4  5.0
#> 37    5  6.0
#> 38    5  7.0
#> 39    5  8.0
#> 40    5  9.0

#Critically, col1 still had 2.5 imputed and col2 had 5 imputed 
#even though those are not the means/medians of those columns. 
#This indicates the function will work for out of fold data.

#Now, we test the real function

test1<-featengcv(mock_data,5,"strat",eng_function)
#We now test the imputation

testdat<-fold_field(mock_data,5,"strat")

#fold 5 has a missing value for col2, so it should be the median of col2 in folds 1-4:

median(testdat[!testdat$fold == 5,]$col2,na.rm=TRUE)
#> [1] 5

#Indeed, in test1, fold 5, we see the value 5 in what was originally row 2. It works!!!
#Now, we can perform regular modeling cross validation on this data,
#and the current fold structure will be maintained, so the full "method" we would
#be testing if we harnessed featengcv along with buildcvmods would be
#both the engineering and the modeling methodology.
```
