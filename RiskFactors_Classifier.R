library(quanteda)
library(stm)
library(futile.logger)
library(ngram)
library(R.utils)

RiskFactors_Classifier<- function(raw_text) {
  
  # SETTING UP LOGGERS 
  # Manually setting up the logs format and type of info that should be logged
  # This setting logs the log level, timestamp, namespace+calling function, and the message 
  # Save logs to 'classifiers.log' file
  apiBase = Sys.getenv("API_BASE")
  
  layout1 <- layout.format('[~t] ~m: ~n.~f')  
  futile.logger::flog.layout(layout1)
  futile.logger::flog.info(msg = paste0(getUsername.System(), " - START OF LOG SESSION"))
  
  layout2 <- layout.format('[~t] ~l: ~m')
  futile.logger::flog.layout(layout2)
  
  futile.logger::flog.appender(appender.file(paste(apiBase, "classifiers.log", sep = "/"))) 
  futile.logger::flog.threshold(TRACE) # trace level will print the msg for all lower levels, ie INFO, ERROR, DEBUG
  
  
  #loads model from the apiBase environment variable
  futile.logger::flog.info(msg =paste0("loading ", sys.call(), " model and necessary utilities..."))
  
  #loads model from the apiBase environment
  
  source(paste(apiBase,"utility/CatchError.R", sep = "/"))
  CatchError(load(paste(apiBase, "models/riskfactors_model", sep = "/")))
  CatchError(source(paste(apiBase,"utility/CleanText.R", sep = "/")))
  
  # preprocessing text
  futile.logger::flog.info(msg = paste0("Processing and preparing text input for ", 
                                        gsub("_Classifier.*","", as.character(sys.call())), " classification..."))
  
  test<- CatchError(CleanText(raw_text))
  
  initwords<- ngram::wordcount(raw_text, sep = " ", count.function = sum)
  initdocs<- length(raw_text)
  futile.logger::flog.info(msg = paste0("Initial text input has ",initdocs, " document(s) containing ", initwords, " words."))
  
  prune<- NULL
  
  print("CREATING DFM (DOCUMENT FEAUTURE MATRIX) AND PRUNING VOCABULARY...")
  DFM_NEW<- CatchError(quanteda::dfm(as.character(test), tolower = TRUE, stem = FALSE, 
                          select = NULL, remove = prune,
                          dictionary = NULL, thesaurus = NULL, 
                          valuetype = "glob", groups = NULL, 
                          verbose = quanteda::quanteda_options("verbose")))
  
  DFM_NEW<- quanteda::convert(DFM_NEW, to = "stm", docvars = NULL)
  
  # If text input is empty, classifier will stop running, and issue error + debugging messages
  # Otherwise, classifiication will proceed
  
  alignDFM_NEW<- CatchError(stm::alignCorpus(DFM_NEW, riskfactors_model$vocab, verbose = TRUE))
  
  wr<- alignDFM_NEW$tokens.removed
  nwords<- (initwords - wr)
  ndocs<- length(alignDFM_NEW$documents)
  
  flog.info(msg = paste0("Initiating ", sys.call(), "..."))
    
   # Text classification 
  futile.logger::flog.info(msg = paste0("Corpus now has ", ndocs, " document(s) and ", nwords," words. ", wr, " tokens have been removed.")) 
  
  new_class<- CatchError(stm::fitNewDocuments(model = riskfactors_model, documents = alignDFM_NEW$documents, 
                                   newData = DFM_NEW$meta))
  
  #labelling 
  label<- c("AVAILABILITY", #1
            "BYOD", #2
            "COMPLIANCE", #3
            "CONFIDENTIALITY", #4
            "DATA_INTEGRITY", #5
            "EXEC_BUYIN", #6
            "FINANCIAL", #7
            "NETWORK_RESOURCES", #8
            "NETWORK_SECURITY", #9
            "NO_RECOVERY", #10
            "OUTDATED", #11
            "PHYSICAL_SECURITY", #12
            "RAPID_GROWTH", #13
            "SECURITY_STAFF", #14
            "SPECIFICALLY_TARGETED", #15
            "THIRD_PARTIES", #16
            "TURNOVER", #17
            "UNUSUAL", #18
            "VISIBILITY" #19
            )
  
  colnames(new_class$theta)<- c(label[10], label[5], label[17], label[2], label[15],
                                label[13], label[19], label[1], label[7], label[8], 
                                label[16], label[9], label[3], label[6], label[12], 
                                label[11], label[14], label[4], label[18])
  
 
  # ordering by alphabetical names
  pred<- data.frame(new_class$theta)
  
  pred<-pred[order(names(pred))]
  riskfactors_classifier<- pred
  
  futile.logger::flog.info(msg =paste0("SUCCESS!", gsub("_Classifier.*","", as.character(sys.call())),
                                       " classification completed."))
  
  futile.logger::flog.layout(layout1)
  futile.logger::flog.logger(flog.info(msg ="END OF LOG SESSION"))
  
  return(riskfactors_classifier)
}
