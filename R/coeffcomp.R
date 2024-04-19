#' Outputs a dataset comparing coefficients of models created during cv. If the dataset already has a column named "fold" then that field will be used for CV, otherwise folds will be created by the function.
#'
#' @param data the dataset
#' @param numfolds optional: the number of desired folds for cross validation if folds are not provided
#' @param stratify optional: the name of the field in the dataset which we wish to use to stratify the folds if folds are not provided and stratification is desired
#' @param modelfunc a function that takes the dataset as input and creates a model in the desired format. The user is responsible for writing this function and ensuring it outputs the model in the desired format.
#' @return a dataframe with coefficients across models, the mean and std dev of those coeffs, and an indicator as to whether the coefficient switched directions between models, p values of each coefficient, and an indicator of whether all p-values are statistically significant across models
#' @examples
#' mock_data <- data.frame(preds1 = rep(1:4,10),preds2 = rep(1:10,4),target=rep(1:5,8),strat=rep(1:2,20),weights = rep(c(2,1),20))
#' model function:
#' model_function<-function(data){
#' targnum<-which(colnames(data) == "target")
#' weightnum<-which(colnames(data) == "weights")
#' moddat<-data[,-c(targnum,weightnum)]
#' targ<-data[,targnum]
#' weights<-data[,weightnum]
#' set.seed(123)
#' mod<-lm(targ~.,data=moddat,weights=weights)
#' mod
#' }
#' test function:
#' model_function(mock_data)
#' compare to:
#' mock_data2 <- mock_data[,-which(colnames(mock_data) == "weights")]
#' lm(target~.,data=mock_data2,weights=mock_data$weights)
#' finally, test function:
#' coeffcomp(mock_data,3,"strat",model_function)
#' test with predefined folds (results should match)
#' mock_data3<-fold_field(mock_data,3,"strat")
#' coeffcomp(mock_data3,modelfunc=model_function)

coeffcomp<-function(data,numfolds,stratify,modelfunc){

  if(!"fold" %in% colnames(data)){
    modellist<-buildcvmods(data,numfolds,stratify,modelfunc)

  }else {
    modellist<-buildcvmods(data,modelfunc=modelfunc)
    numfolds<-length(unique(data[,which(colnames(data) == "fold")]))
  }

  cc<-data.frame(mod1Coeff = modellist[[1]]$coefficients)

  for (i in 2:numfolds){
    cc[,i]<-modellist[[i]]$coefficients
    colnames(cc)[i]<-paste0("mod",i,"Coeff")
  }

  cc2<-cc

  cc2$meanCoeff<-rowMeans(cc)
  cc2$stdevCoeff<-1

  for (i in 1:dim(cc)[1]){
    cc2$stdevCoeff[i]<-sd(cc[i,])
  }

  cc2$CoeffSwitch<-"N"

  for (i in 1:dim(cc)[1]){
    posind<-c()
    for (j in 1:numfolds){
      posind[j]<-cc[i,j] > 0
    }
    tot<-sum(posind)
    cc2$CoeffSwitch[i]<-ifelse(tot == 0 | tot == numfolds,"N","Y")
  }

  cc2$mod1CoeffPval<-coef(summary(modellist[[1]]))[,4]

  for (i in 2:numfolds){
    cc2[,i+numfolds+3]<-coef(summary(modellist[[i]]))[,4]
    colnames(cc2)[i+numfolds+3]<-paste0("mod",i,"CoeffPval")
  }

  cc2$ConstSigPval<-"N"

  for (i in 1:dim(cc)[2]){
    sigind<-c()
    for (j in 1:numfolds){
      sigind[j]<-cc2[i,j+numfolds+3] < .05
    }
    cc2$ConstSigPval[i]<-ifelse(sum(sigind) == numfolds,"Y","N")
  }

  cc2$SigPval<-"N"

  for (i in 1:dim(cc)[2]){
    sigind<-c()
    for (j in 1:numfolds){
      sigind[j]<-cc2[i,j+numfolds+3] < .05
    }
    cc2$SigPval[i]<-ifelse(sum(sigind) > 0,"Y","N")
  }

  cc2
}
