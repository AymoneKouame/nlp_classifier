library(futile.logger)

# FUNCTION TO HANDLE ERRORS IN WRAPPER

# 1. If ANY error is returned from a classifier (R has two classes of errors: simpleError and error)
## that classifer returns NULL (note that internal errors are handled within each function with CatchErro())
# 2. if no error occurs the classifier returns the normal probabilities
# 3. A major improvement over previous wrapper version is if a classifer stops because of error, 
## the other classifiers will still run
## and The classifers with NULL values will also appear in the final classifier output
# Warnings can be turned on and off: n = -1 to turn OFF and n = 0 to turn ON.

ErrorHandler<- function(Classifier, raw_text, n = -1) {
  
  options(warn = n) 
  
  out <- tryCatch(Classifier(raw_text), error = function(e) e)
  if(any(class(out) == "simpleError") == TRUE | any(class(out) == "error") == TRUE) 
  { 
    flog.error(as.character(out))
    
    classifier <- "NULL"
    
  } else {
    classifier <- Classifier(raw_text)
  }  
  
  return(classifier)
}
