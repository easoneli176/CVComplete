#' Outputs a dataset comparing coefficients of models created during cv
#'
#' @param data the dataset
#' @param target the target variable for the model
#' @param stratify the name of the field in the dataset which we wish to use to stratify the cv folds
#' @param preds the predictors for the model
#' @param modelfunc a function that takes the target and dataset with only predictors and creates a model in the desired format. The user is responsible for writing this function and ensuring it outputs the model in the desired format.
#' @param numfolds the number of desired folds for cross validation
#' @return a dataframe with coefficients across models, the mean and std dev of those coeffs, and an indicator as to whether the coefficient switched directions between models, p values of each coefficient, and an indicator of whether all p-values are statistically significant across models
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
#' coeffcomp(mock_data,"target","strat",c("preds1","preds2"),model_function,3)

coeffcomp<-function(data,target,stratify,preds,modelfunc,numfolds){
  modellist<-buildcvmods(data,target,stratify,preds,modelfunc,numfolds)
  cc<-data.frame(mod1Coeff = modellist[[1]]$coefficients)

  for (i in 2:numfolds){
    cc[,i]<-modellist[[i]]$coefficients
    colnames(cc)[i]<-paste0("mod",i,"Coeff")
  }

  cc2<-cc

  cc2$meanCoeff<-rowMeans(cc)
  cc2$stdevCoeff<-1

  for (i in 1:dim(cc)[2]){
    cc2$stdevCoeff[i]<-sd(cc[i,])
  }

  cc2$CoeffSwitch<-"N"

  for (i in 1:dim(cc)[2]){
    posind<-c()
    for (j in 1:numfolds){
      posind[j]<-cc[i,j] > 0
    }
    tot<-sum(posind)
    cc2$CoeffSwitch[i]<-ifelse(tot == 0 | tot == numfolds,"N","Y")
  }

  cc2$mod1CoeffPval<-coef(summary(modellist[[1]]))[,4]

  for (i in 2:numfolds){
    cc2[,i+6]<-coef(summary(modellist[[i]]))[,4]
    colnames(cc2)[i+6]<-paste0("mod",i,"CoeffPval")
  }

  cc2$ConstSigPval<-"N"

  for (i in 1:dim(cc)[2]){
    sigind<-c()
    for (j in 1:numfolds){
      sigind[j]<-cc2[i,j+6] < .05
    }
    cc2$ConstSigPval[i]<-ifelse(sum(sigind) == numfolds,"Y","N")
  }

  cc2$SigPval<-"N"

  for (i in 1:dim(cc)[2]){
    sigind<-c()
    for (j in 1:numfolds){
      sigind[j]<-cc2[i,j+6] < .05
    }
    cc2$SigPval[i]<-ifelse(sum(sigind) > 0,"Y","N")
  }

  cc2
}
