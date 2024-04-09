#' Outputs a list of models built without the ith fold
#'
#' @param data the dataset
#' @param target the target variable for the model
#' @param stratify the name of the field in the dataset which we wish to use to stratify the cv folds
#' @param preds the predictors for the model
#' @param modelfunc a function that takes the target and dataset with only predictors and creates a model in the desired format. The user is responsible for writing this function and ensuring it outputs the model in the desired format.
#' @param numfolds the number of desired folds for cross validation
#' @return a list of numfolds models
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
#' buildcvmods(mock_data,"target","strat",c("preds1","preds2"),model_function,3)

buildcvmods<-function(data,target,stratify,preds,modelfunc,numfolds){
  modellist<-list()

  newdata<-fold_field(data,numfolds,stratify)

  newdata<-newdata[,which(colnames(newdata) %in% c(target,preds,"fold"))]

  for (i in 1:numfolds){
    newtrain<-newdata[!newdata$fold == i,]
    newtrain<-newtrain[,-which(colnames(newtrain) == "fold")]
    modellist[[i]]<-modelfunc(target,newtrain)
  }

  modellist
}
