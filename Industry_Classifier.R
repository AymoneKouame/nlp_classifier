library(quanteda)
library(stm)
library(futile.logger)
library(ngram)
library(R.utils)


Industry_Classifier<- function(raw_text) {
  
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

  source(paste(apiBase,"utility/CatchError.R", sep = "/"))
  CatchError(load(paste(apiBase, "models/industry_model", sep = "/")))
  CatchError(source(paste(apiBase,"utility/CleanText.R", sep = "/")))
  
  industry_model<- stm_model
  
  # preprocessing text
  futile.logger::flog.info(msg = paste0("Processing and preparing text input for ", 
                                        gsub("_Classifier.*","", as.character(sys.call())), " classification..."))
  
  test<- CatchError(CleanText(raw_text))
  
  initwords<- ngram::wordcount(raw_text, sep = " ", count.function = sum)
  initdocs<- length(raw_text)
  futile.logger::flog.info(msg = paste0("Initial text input has ",initdocs, " document(s) containing ", initwords, " words."))

  #source(paste(apiBase,"utility/CleanText.R", sep = "/"))
  
  prune<- c("a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", 
          "v", "w", "x", "y", "z", "in", "use", "used","many", "care", "the", "lso", "alth", "ten", "as", "percent", 
          "this", "new", "number", "may", "us", "for", "it", "come", "work", "aa", "aais", "aas", "ab", "abba", 
          "abc", "abcs", "able", "about", "abuse", "ac", "encyclopedia", "free", "(", ")", ",", "top", "industry", 
          "aaa", "aaa", "aaddhaar", "aafm","aafmaa", "aafp", "aais", "aami", "aanciam", "anen", "aap", "aarhus", "aas", "aauthor", "ab", 
          "abba", "abbey", "abc", "abcs", "abd", "will", "can", "II", "facebook","twitter","linkedin","google","youtube", 
          "pinterest", "instagram", "tumblr", "filckr", "reddit", "snapchat", "ibm","pwc", "google", "wikipedia", "wiki")
  
  print("CREATING DFM (DOCUMENT FEATURE MATRIX) AND PRUNING VOCABULARY...")

  DFM_NEW<- CatchError(quanteda::dfm(as.character(test), tolower = TRUE, stem = FALSE, select = NULL, remove = prune,
                          dictionary = NULL, thesaurus = NULL, valuetype = "glob", groups = NULL
                          , verbose = quanteda::quanteda_options("verbose")))
  
  DFM_NEW<- quanteda::convert(DFM_NEW, to = "stm", docvars = NULL)
  
  # If text input is empty, classifier will stop running, and issue error + debugging messages
  # Otherwise, classification will proceed
  alignDFM_NEW<- CatchError(stm::alignCorpus(DFM_NEW, industry_model$vocab, verbose = TRUE))
  
  wr<- alignDFM_NEW$tokens.removed
  nwords<- (initwords - wr)
  ndocs<- length(alignDFM_NEW$documents)
    
  flog.info(msg = paste0("Initiating ", sys.call(), "..."))
  
  # Text Classification
  flog.info(msg = paste0("Corpus now has ", ndocs, " document(s) and ", nwords," words. ", wr, " tokens have been removed.")) 
  
  new_class<- CatchError(stm::fitNewDocuments(model = industry_model, documents =alignDFM_NEW$documents, 
                                   newData = DFM_NEW$meta, verbose = TRUE))

  #labelling
  colnames(new_class$theta) <-  c("PUBLIC", "WHOLESALE",
                                "INSURANCE","PROFESSIONAL",
                                "EDUCATION", "REAL_ESTATE", 
                                "LEGAL", "SUPPORT",
                                "FINANCE", "DEFENSE", 
                                "CONSTRUCTION", 
                                "HEALTH_CARE","SERVICES", 
                                "INFORMATION", "MINING", 
                                "MANAGEMENT", "ACCOMMODATION", 
                                "UTILITIES", "RETAIL",  
                                "AGRICULTURE", "MANUFACTURING", 
                                "TRANSPORTATION", "ARTS")
  
  pred<- data.frame(new_class$theta)
  pred<- pred[order(names(pred))]  # order names alphabetically 
  
  industry_classifier<- pred
  
  futile.logger::flog.info(msg =paste0("SUCCESS!", gsub("_Classifier.*","", as.character(sys.call())),
                                        " classification completed."))
  
  futile.logger::flog.layout(layout1)
  futile.logger::flog.logger(flog.info(msg ="END OF LOG SESSION"))
  
  return(industry_classifier)
}

