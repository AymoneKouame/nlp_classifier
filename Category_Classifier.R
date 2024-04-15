library(quanteda)
library(stm)
library(futile.logger)
library(ngram)
library(R.utils)


Category_Classifier<- function(raw_text) {
  
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

  load(paste(apiBase, "models/category_model", sep = "/"))
  source(paste(apiBase,"utility/CleanText.R", sep = "/"))
  
  # preprocessing text
  futile.logger::flog.info(msg = paste0("Processing and preparing text input for ", 
                                        gsub("_Classifier.*","", as.character(sys.call())), " classification..."))
  
  test<- CleanText(raw_text)
  initwords<- ngram::wordcount(raw_text, sep = " ", count.function = sum)
  initdocs<- length(raw_text)
  futile.logger::flog.info(msg = paste0("Initial text input has ",initdocs, " document(s) containing ", initwords, " words."))
  
  #source(paste(apiBase,"utility/CleanText.R", sep = "/"))
  
  test <- raw_text
  
  prune<- c("a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", 
            "v", "w", "x", "y", "z", "in", "use", "used","many", "care", "the", "lso", "alth", "ten", "as", "percent", 
            "this", "new", "number", "may", "us", "for", "it", "come", "work", "aa", "aais", "aas", "ab", "abba", 
            "abc", "abcs", "able", "about", "abuse", "ac", "encyclopedia", "free", "(", ")", ",", "top", "industry", 
            "aaa", "aaa", "aaddhaar", "aafm","aafmaa", "aafp", "aais", "aami", "aanciam", "anen", "aap", "aarhus", "aas", "aauthor", "ab", 
            "abba", "abbey", "abc", "abcs", "abd", "will", "can", "II", "facebook","twitter","linkedin","google","youtube", 
            "pinterest", "instagram", "tumblr", "filckr", "reddit", "snapchat", "ibm","pwc", "google", "wikipedia", "wiki")
  
  print("CREATING DFM (DOCUMENT FEATURE MATRIX) AND PRUNING VOCABULARY...")
  
  DFM_NEW<- quanteda::dfm(as.character(test), tolower = TRUE, stem = FALSE, select = NULL, remove = prune,
                          dictionary = NULL, thesaurus = NULL, valuetype = "glob", groups = NULL
                          , verbose = quanteda::quanteda_options("verbose"))
  
  DFM_NEW<- quanteda::convert(DFM_NEW, to = "stm", docvars = NULL)
  
  # If text input is empty, classifier will stop running, and issue error + debugging messages
  # Otherwise, classification will proceed
  if (length(DFM_NEW$documents) <= 0){
    flog.error(msg = paste0("Text input has no remaining words. ", gsub("_Classifier.*","", as.character(sys.call())),
                            " classification aborted."))
    
    flog.debug( msg = "Text input probably contained only stopwords.")
    category_classifer <- NULL 
    
  } else if (length(DFM_NEW$documents) >= 1){
    
    flog.info(msg = paste0("Initiating ", sys.call(), "..."))
    
    # Text Classification
    alignDFM_NEW<- stm::alignCorpus(DFM_NEW, category_model$vocab, verbose = TRUE)
    
    
    nwords<- ngram::wordcount(alignDFM_NEW$vocab, sep = " ", count.function = sum)
    ndocs<- length(alignDFM_NEW$documents)
    wr<- alignDFM_NEW$tokens.removed
    futile.logger::flog.info(msg = paste0("Corpus now has ", ndocs, " document(s) and ", nwords," words. ", wr, " tokens have been removed.")) 
    
    new_class<- stm::fitNewDocuments(model = category_model, documents =alignDFM_NEW$documents, 
                                     newData = DFM_NEW$meta, verbose = TRUE)
    
    
    #renaming topics with category names
    
    new_class<- stm::fitNewDocuments(model = category_model, documents =alignDFM_NEW$documents, newData = DFM_NEW$meta)
    
    #labelling
    
    
    label <-c("ACCESS_CONTROL", #1
              "ANTIMALWARE", #2
              "APP_SECURITY", #3
              "ASSET_MANAGEMENT", #4
              "BACKUP", #5
              "COMPLIANCE", #6
              "DDOS_MITIGATION", #7
              "DLP", #8
              "EMAIL_FILTER", #9
              "ENCRYPTED_COMM", #10
              "ENCRYPTED_STORAGE", #11
              "FILE_TRANSFER", #12
              "FORENSICS", #13
              "HIDS", #14
              "HIPS", #15
              "INCIDENT_RESPONSE", #16
              "INSIDER_ANALYTICS", #17
              "MALWARE_ANALYSIS", #18
              "MANAGED_SERVICES", #19
              "MOBILE", #20
              "NETWORK_DISCOVERY", #21
              "NIDS", #22
              "NIPS", #23
              "ORCHESTRATION", #24
              "PATCH_MANAGEMENT", #25
              "PHYSICAL_SECURITY", #26
              "SECURITY_ENGINEERING", #27
              "SERVICE_DISCOVERY", #28
              "SIEM", #29
              "THREAT_INTEL", #30
              "THREAT_MANAGEMENT", #31
              "TRAFFIC_ANALYSIS", #32
              "TRAINING", #33
              "VIRTUALIZATION", #34
              "VPN", #35
              "VULN_ASSESSMENT", #36
              "WEB_FILTER", #37
              "WEB_SECURITY", #38
              "WIRELESS" #39
              )
    
    colnames(new_class$theta)<- c(label[6], 
                                  label[5], 
                                  label[32], 
                                  label[30], 
                                  label[35], 
                                  label[34],
                                  label[9], 
                                  label[4], 
                                  label[20],
                                  label[12],
                                  label[27], #secu engineering; topic 11
                                  label[23], #topic 12 i think its NIPS
                                  label[10],
                                  label[1], 
                                  label[18],
                                  label[25], 
                                  label[8],
                                  label[7],
                                  label[33],
                                  label[28],
                                  label[17], 
                                  label[29], 
                                  label[36],
                                  label[24],
                                  label[14], #network disc topic 25
                                  label[19],
                                  label[21], # topic 27
                                  label[13],
                                  label[26],
                                  label[39],
                                  label[2],
                                  label[15], #HIPS topic 32
                                  label[37], #web filtering , topic 33 
                                  label[38], # network disc
                                  label[16],
                                  label[31],
                                  label[11],
                                  label[3],
                                  label[22])
    
    pred<- data.frame(new_class$theta)
    pred<- pred[order(names(pred))]  # order names alphabetically
    
    category_classifier<- pred
    
    futile.logger::flog.info(msg =paste0("SUCCESS!", gsub("_Classifier.*","", as.character(sys.call())),
                                         " classification completed."))
  }
  
  futile.logger::flog.layout(layout1)
  futile.logger::flog.logger(flog.info(msg ="END OF LOG SESSION"))
  
  return(category_classifier)
}

