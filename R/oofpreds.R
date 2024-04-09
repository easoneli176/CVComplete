#' Adds a field of out of fold predictions to the data
#'
#' @param data the dataset
#' @param target the target variable for the model
#' @param stratify the name of the field in the dataset which we wish to use to stratify the cv folds
#' @param preds the predictors for the model
#' @param modelfunc a function that takes the target and dataset with only predictors and creates a model in the desired format. The user is responsible for writing this function and ensuring it outputs the model in the desired format.
#' @param numfolds the number of desired folds for cross validation
#' @return a dataset
#' @examples
#' mock_data <- data.frame(preds1 = rep(1:4,10),preds2 = rep(1:10,4),target=rep(1:5,8),strat=rep(1:2,20))
#' model function:
#' model_function<-function(target,data){
#' targnum<-which(colnames(data) == target)
#' moddat<-data[,-targnum]
#' targ<-data[,targnum]
#' set.seed(123)
#' mod<-lm(targ~.,data=moddat)
#' mod
#' }
#' test function:
#' model_function("target",mock_data)
#' compare to:
#' lm(target~.,data=mock_data)
#' finally, test function:
#' data2<-oofpreds(mock_data,"target","strat",c("preds1","preds2"),model_function,3)
#' check that right model predicted right row:
#' mymods<-buildcvmods(mock_data,"target","strat",c("preds1","preds2"),model_function,3)
#' predict(mymods[[data2$fold[2]]],data2[2,],type="response")
#' should match oofpred field in 2nd row of data

oofpreds<-function(data,target,stratify,preds,modelfunc,numfolds){
  newdat<-fold_field(data,numfolds,stratify)
  mods<-buildcvmods(data,target,stratify,preds,modelfunc,numfolds)
  newdat$oofpred<-999
  model<-mods[[1]]

  for (i in 1:dim(newdat)[1]){
    newdat$oofpred[i]<-predict(mods[[newdat$fold[i]]],newdat[i,],type="response")
  }
  newdat
}
