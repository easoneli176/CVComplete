#' Adds a field to a dataframe which encodes potentially stratified folds
#'
#' @param data the dataset
#' @param numfolds the number of desired folds
#' @param stratify optional: the name of the field in the dataset which we wish to use to stratify the folds
#' @return a dataset with a field called "fold"
#' @examples
#' mock_data <- data.frame(preds = rep(1:4,10),target=rep(1:5,8),strat=rep(1:2,20))
#' new data set:
#' newdat<-fold_field(mock_data,3,"strat")
#' check that stratification worked:
#' table(newdat$fold,newdat$strat)
#' check that folds work without stratification:
#' newdat<-fold_field(mock_data,3)
#' table(newdat$fold,newdat$strat)

fold_field<-function(data,numfolds,stratify){

  if(missing(stratify)){
    set.seed(123)
    folds<-createFolds(1:dim(data)[1],k=numfolds, list=TRUE, returnTrain=FALSE)
    }else{

  stratnum<-which(colnames(data) == stratify)
  strat<-data[,stratnum]

  set.seed(123)
  folds<-createFolds(strat, k=numfolds, list=TRUE, returnTrain=FALSE)
    }

  data$fold<-1

  for (i in 1:dim(data)[1]){
    for (j in 2:numfolds){
      data$fold[i]<-ifelse(i %in% folds[[j]],j,data$fold[i])
    }
  }
  data
}
