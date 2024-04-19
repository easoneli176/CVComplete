#' Adds a field of out of fold predictions to the data. If the dataset has a column named "fold" that will be used for CV, otherwise folds will be created by the function.
#'
#' @param data the dataset
#' @param target the target variable for the model
#' @param stratify optional: the name of the field in the dataset which we wish to use to stratify the cv folds
#' @param preds the predictors for the model
#' @param modelfunc a function that takes the target and dataset with only predictors and creates a model in the desired format. The user is responsible for writing this function and ensuring it outputs the model in the desired format.
#' @param weights the weights to be used in model building if desired. This must be a field in the dataframe and a column of 1s can be added if no weights are desired.
#' @param numfolds optional: the number of desired folds for cross validation if folds are not provided
#' @return a dataset
#' @examples
#' mock_data <- data.frame(preds1 = rep(1:4,10),preds2 = rep(1:10,4),target=rep(1:5,8),strat=rep(1:2,20),weights = rep(c(2,1),20))
#' model function:
#' model_function<-function(target,data,weights){
#' targnum<-which(colnames(data) == target)
#' weightnum<-which(colnames(data) == weights)
#' moddat<-data[,-c(targnum,weightnum)]
#' targ<-data[,targnum]
#' weights<-data[,weightnum]
#' set.seed(123)
#' mod<-lm(targ~.,data=moddat,weights=weights)
#' mod
#' }
#' test function:
#' model_function("target",mock_data,"weights")
#' compare to:
#' mock_data2 <- mock_data[,-which(colnames(mock_data) == "weights")]
#' lm(target~.,data=mock_data2,weights=mock_data$weights)
#' finally, test function:
#' data2<-oofpreds(mock_data,"target","strat",c("preds1","preds2"),model_function,"weights",3)
#' check that right model predicted right row:
#' mymods<-buildcvmods(mock_data,"target","strat",c("preds1","preds2"),model_function,"weights",3)
#' predict(mymods[[data2$fold[2]]],data2[2,],type="response")
#' should match oofpred field in 2nd row of data
#' test with pre-defined folds:
#' mock_data2<-fold_field(mock_data,3)
#' data3<-oofpreds(mock_data2,"target",preds=c("preds1","preds2"),modelfunc=model_function,weights="weights")

oofpreds<-function(data,target,stratify,preds,modelfunc,weights,numfolds){

  if(!"fold" %in% colnames(data)){
    newdat<-fold_field(data,numfolds,stratify)

  }else {
    newdat<-data
    numfolds<-length(unique(data[,which(colnames(data) == "fold")]))
    }

  mods<-buildcvmods(newdat,target,stratify,preds,modelfunc,weights,numfolds)

  newdat$oofpred<-999

  model<-mods[[1]]

  for (i in 1:dim(newdat)[1]){
    newdat$oofpred[i]<-predict(mods[[newdat$fold[i]]],newdat[i,],type="response")
  }
  newdat
}
