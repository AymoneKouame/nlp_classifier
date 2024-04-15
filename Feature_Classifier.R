library(quanteda)
library(stm)
library(futile.logger)
library(ngram)
library(R.utils)
library(rlist)
# Feature_Classifier identifies the product features discussed within a text
# based on 93 product features identified by WH on confluence
# INPUT= raw text data; OUTPUT = features + probabilities for all 93 

Feature_Classifier<- function(raw_text) {
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
  
  
  
  #loading model and necessary utilities
  futile.logger::flog.info(msg =paste0("loading ", sys.call(), " model and necessary utilities..."))
  
  source(paste(apiBase,"utility/CatchError.R", sep = "/"))
  CatchError(load(paste(apiBase, "models/features_model", sep = "/")))
  CatchError(source(paste(apiBase,"utility/CleanText.R", sep = "/")))
  features_labels<- CatchError(rlist::list.load
                               (paste(apiBase, "models/features_labels.rdata", sep = "/")))
  
  # preprocessing text
  futile.logger::flog.info(msg = paste0("Processing and preparing text input for ", 
                                        gsub("_Classifier.*","", as.character(sys.call())), " classification..."))
  test<- CatchError(CleanText(raw_text))
  
  initwords<- ngram::wordcount(raw_text, sep = " ", count.function = sum)
  initdocs<- length(raw_text)
  futile.logger::flog.info(msg = paste0("Initial text input has ",initdocs, " document(s) containing ", initwords, " words."))
  
  
  DFM_NEW<- CatchError(quanteda::dfm(as.character(test), tolower = TRUE, stem = FALSE, select = NULL, remove = NULL,
                                     dictionary = NULL, thesaurus = NULL, valuetype = "glob", groups = NULL, 
                                     verbose = quanteda::quanteda_options("verbose")))
  
  DFM_NEW<- quanteda::convert(DFM_NEW, to = "stm", docvars = NULL)
  
  # If text input is empty, classifier will stop running, and issue error + debugging messages
  # Otherwise, classifiication will proceed
  
  alignDFM_NEW<- CatchError(stm::alignCorpus(DFM_NEW, features_model$vocab, verbose = TRUE))
  
  wr<- alignDFM_NEW$tokens.removed
  nwords<- (initwords - wr)
  ndocs<- length(alignDFM_NEW$documents)
  
  flog.info(msg = paste0("Initiating ", sys.call(), "..."))
  
  # Text classification
  futile.logger::flog.info(msg = paste0("Corpus now has ", ndocs, " document(s) and ", nwords," words. ", wr, " tokens have been removed.")) 
  
  new_class<- CatchError(stm::fitNewDocuments(model = features_model, documents =alignDFM_NEW$documents, 
                                              newData = DFM_NEW$meta))
  
  #ADDING LABELS TO TOPICS
  colnames(new_class$theta)<- features_labels

  pred<- data.frame(new_class$theta)
  feature_classifier<-pred[order(names(pred))]     # Order names by alphabetical order
  
  futile.logger::flog.info(msg =paste0("SUCCESS!", gsub("_Classifier.*","", as.character(sys.call())),
                                       " classification completed."))
  
  futile.logger::flog.layout(layout1)
  futile.logger::flog.logger(flog.info(msg ="END OF LOG SESSION"))
  
  
  return(feature_classifier)
}
