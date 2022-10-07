
## load dependencies

library(pROC)

pROCBasedTwoWayPartialAUC <- function(df,
                                      sensitivity_bound, 
                                      specificity_bound) {
  ## Inputs:
  ## roc_object: output of the "roc" function from the pROC package
  ## sensitivity_bound: the sensitivity threshold
  ## specificity_bound: the specificity threshold
  ##
  ## Outputs:
  ## tpAUC: estimated two-way partial AUC
  ## pAucSe: estimated partial AUC focusing on sensitivity
  ## pAucSp: estimated partial AUC focusing on specificity
  ## Auc: estimated (full) AUC
  
  ## Compute the ROC object using the pROC package.
  roc_object <- pROC::roc(df$label, df$probability, auc = FALSE, levels = c(0, 1), direction = "<")

  ## Compute the full AUC using the "auc" functin from the pROC package.
  Auc <- pROC::auc(roc_object)[1]
  
  ## Compute the area that will be dropped.
  Arec <- sensitivity_bound * specificity_bound
  
  ## Compute the partial auc focusing on sensitivity.
  pAucSe <- pROC::auc(roc_object, 
                      partial.auc = c(1, sensitivity_bound), 
                      partial.auc.focus = "sensitivity", 
                      partial.auc.correct = FALSE)[1]
  
  ## Compute the partial auc focusing on specificity.
  pAucSp <- pROC::auc(roc_object, 
                      partial.auc = c(1, specificity_bound), 
                      partial.auc.focus = "specificity", 
                      partial.auc.correct = FALSE)[1]
  
  ## In situations where the ROC curve does not cross the
  ## are of interest (the rectangle with sides 1-sensitivity_bound 
  ## and 1-specificity_bound) we set the two-way partial AUC to 0.
  tpAUC <- 0
  
  ## Because the ROC is monotomic increasing function a simple way 
  ## to check whether it crosses the area of interest is to simply
  ## check if the specificity value corresponding to sensitivity
  ## bound is larger than the specificity bound.
  ## The next line uses the "coords" function from the pROC package
  ## to compute the specificity value that corresponds to the 
  ## sensitivity bound.
  spec_at_sens_bound <- pROC::coords(roc_object, 
                                     x = sensitivity_bound, 
                                     input = "sensitivity", 
                                     ret = "specificity")
  
  ## Check the condition and, if it is true, compute the two-way
  ## partial AUC score.
  if (spec_at_sens_bound >= specificity_bound) {
    tpAUC <- pAucSe + pAucSp - (Auc - Arec)
  }
  
  ## Return the outputs.
  l <- list(tpAUC = tpAUC,
       pAucSe = pAucSe, 
       pAucSp = pAucSp)
  DF <- as.data.frame(l)
}


