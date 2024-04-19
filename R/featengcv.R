#' When feature engineering such as imputation is part of your cross validation process, you'll need to perform that engineering in a CV manner before building your models. This function will perform that engineering and output a dataset with out of fold engineering.
#'
#' @param data the dataset
#' @param stratify optional: the name of the field in the dataset which we wish to use to stratify the cv folds
#' @param cols the fields which require engineering
#' @param engfunc a function that takes the cols and transforms them as desired and outputs this process to be used on the out of fold data. The user is responsible for writing this function and ensuring it outputs the data in the desired format.
#' @param numfolds optional: the number of desired folds for cross validation if folds are not provided
#' @return a dataframe with out of fold engineered fields
#' @examples
#' mock_data <- data.frame(col1 = as.numeric(c(rep(1:4,9),rep("NA",4))),col2 = as.numeric(c(rep("NA",4),rep(1:9,4))),strat=rep(c(1,2),20))
#' engineer function:
#' eng_function<-function(data,cols){
#' col1<-data[,which(colnames(data) == cols[1])]
#' col2<-data[,which(colnames(data) == cols[2])]
#' val1<-mean(col1,na.rm=TRUE)
#' val2<-mean(col2,na.rm=TRUE)
#' mod<-function(data,cols){
#' col1<-data[,which(colnames(data) == cols[1])]
#' col2<-data[,which(colnames(data) == cols[2])]
#' data[,which(colnames(data) == cols[1])]<-ifelse(is.na(col1),val1,col1)
#' data[,which(colnames(data) == cols[2])]<-ifelse(is.na(col2),val2,col2)
#' data
#' }
#' mod
#' }
#' test function:
#' impfunc<-eng_function(mock_data,c("col1","col2"))
#' View(impfunc(mock_data,c("col1","col2")))
#' Notice col2 had 5 imputed and col1 had 2.5. Now, we create a new dataset where the names of the columns are the same but the means will be different.
#' mock_data2 <- data.frame(col2 = as.numeric(c(rep(1:4,9),rep("NA",4))),col1 = as.numeric(c(rep("NA",4),rep(1:9,4))))
#' View(impfunc(mock_data2,c("col1","col2")))
#' Critically, col1 still had 2.5 imputed and col2 had 5 imputed even though those are not the means of those columns. This indicates the function will work for out of fold data.
#' Now, we test the real function
#' test1<-featengcv(mock_data,c("col1","col2"),"strat",eng_function,5)
#' We now test the imputation
#' testdat<-fold_field(mock_data,5,"strat")
#' fold 5 has a missing value for col2, so it should be the mean of col2 in folds 1-4:
#' mean(testdat[!testdat$fold == 5,]$col2,na.rm=TRUE)
#' [1] 4.931034
#' Indeed, in test1, fold 5, we see the value 4.931034 in what was originally row 2. It works!!!

featengcv<-function(data, cols, stratify, engfunc, numfolds){

  if(!"fold" %in% colnames(data)){
    newdata<-fold_field(data,numfolds,stratify)

  }else {
    newdata<-data
    numfolds<-length(unique(data[,which(colnames(data) == "fold")]))
  }

  engfuncs<-list()

  for(i in 1:numfolds){
    builddat<-newdata[!newdata$fold == i,]
    engfuncs[[i]]<-engfunc(builddat,cols)
  }

  oofengfeats<-list()

  for(i in 1:numfolds){
    oofdat<-newdata[newdata$fold == i,]
    oofengfeats[[i]]<-engfuncs[[i]](oofdat,cols)
  }

  findat<-as.data.frame(rbind(oofengfeats[[1]],oofengfeats[[2]]))

  for(i in 3:numfolds){
    findat<-rbind(findat,oofengfeats[[i]])
  }

  findat

}
