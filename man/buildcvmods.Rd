% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/buildcvmods.R
\name{buildcvmods}
\alias{buildcvmods}
\title{Outputs a list of models built without the ith fold. If the dataset already has a column named "fold" then that field will be used for CV, otherwise folds will be created by the function.}
\usage{
buildcvmods(data, numfolds, stratify, modelfunc)
}
\arguments{
\item{data}{the dataset}

\item{numfolds}{optional: the number of desired folds for cross validation if folds are not provided}

\item{stratify}{optional: the name of the field in the dataset which we wish to use to stratify the folds if folds are not provided and stratification is desired}

\item{modelfunc}{a function that takes the dataset as input and creates a model in the desired format. The user is responsible for writing this function and ensuring it outputs the model in the desired format.}
}
\value{
a list of models, each built with one fold of data left out
}
\description{
Outputs a list of models built without the ith fold. If the dataset already has a column named "fold" then that field will be used for CV, otherwise folds will be created by the function.
}
\examples{
mock_data <- data.frame(preds1 = rep(1:4,10),preds2 = rep(1:10,4),target=rep(1:5,8),strat=rep(1:2,20),weights = rep(c(2,1),20))
model function:
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
test function:
model_function(mock_data)
compare to:
mock_data2 <- mock_data[,-which(colnames(mock_data) == "weights")]
lm(target~.,data=mock_data2,weights=mock_data$weights)
finally, test function:
buildcvmods(mock_data,3,"strat",model_function)
test with no stratifying argument
buildcvmods(mock_data,3,modelfunc=model_function)
test with predefined folds, output should match last one
mock_data2<-fold_field(mock_data,3)
buildcvmods(mock_data2,modelfunc=model_function)
}
