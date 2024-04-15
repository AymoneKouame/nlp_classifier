library(futile.logger)

# FUNCTION TO CATCH ERRORS IN INDIVIDUAL LINES OF CODES
## If ANY error is caught, the classifier is stopped
## The error is displayed on the screen for the user to see
## and it is also saved in the log file
# Otherwise, the normal output is returned

CatchError<- function(expr) {
  
  apiBase = Sys.getenv("API_BASE")
  error <- tryCatch(expr, error = function(e) e)

  if(any(class(error) == "simpleError") == TRUE | any(class(error) == "error") == TRUE) 
    
  { flog.error(paste0(as.character(error),". Classification aborted."))
    futile.logger::flog.appender(appender.file(paste(apiBase, "classifiers.log", sep = "/")))
    stop(as.character(error))
    
  } else {
    output <- expr
  }
return(output)
}

