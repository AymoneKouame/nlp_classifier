library(quanteda)
library(stm)
library(tidyr)  #new

Cyberdocs_ClassifierTrain<- function(raw_text)  {
  
  apiBase = Sys.getenv("API_BASE")
  source(paste(apiBase,"utility/CleanText.R", sep = "/"))
  
  # PREPOCESSING
  print("Preparing Data for Modeling...")
  train<- CleanText(raw_text)
  
  alldocs<- stringi::stri_extract(raw_text[,1], regex='[A-Za-z_A-Za-z]*')

  
  rem<-c(as.character(lexicon::pos_df_pronouns[,1]),
         as.character(lexicon::emojis_sentiment[,1]), as.character(lexicon::pos_interjections),
         as.character(lexicon::sw_python), "free", "encyclopedia", "," ,"may", "also",  "first", 
         "may", "original")
  
  DFM<- quanteda::dfm(as.character(train), tolower = TRUE, remove = rem, 
                      valuetype = "glob", groups = as.factor(alldocs))
  
  DFM<- quanteda::convert(DFM, to = "stm", docvars = NULL)
  
  PrepDFM<- stm::prepDocuments(DFM$documents, meta = DFM$meta, vocab = DFM$vocab, lower.thresh = 0,
                               upper.thresh = round(length(as.factor(alldocs))*0.75), 
                               subsample = NULL, verbose = TRUE)
  
  # FIX UNBALANCED CLASSIFICATION PROBLEM: aka when one does not have enough representative training data 
 
  # 1. Build a preliminary model in order to extract main keywords Per category
  
  PreModel<- stm::stm(PrepDFM$documents, PrepDFM$vocab, length(PrepDFM$documents), 
                      data = PrepDFM$meta, init.type = "Spectral", 
                      seed = NULL, max.em.its = 500, emtol = 1e-05, verbose = FALSE, 
                      kappa.prior = "L1")

  # 2. Oversampling technique: 
  # Add to the NON_IT category all words from original training data 
  # that are not part of the keywords. This will create more training data for NON_IT 
  # as well as increase the precision of our model
  
  topicWords<- stm::labelTopics(PreModel, n = 1000)
  NotTopicWords <- PreModel$vocab[!PreModel$vocab %in% c(topicWords$prob, topicWords$frex, topicWords$lift,
                                                        topicWords$score)]
  train[49:74] <- paste0(train[49:74], NotTopicWords)
  
  # 3. FINAL MODEL
  
  DFM2<- quanteda::dfm(as.character(train), tolower = TRUE, 
                         remove = rem, valuetype = "glob", groups = as.factor(alldocs))
  
  DFM2<- quanteda::convert(DFM2, to = "stm", docvars = NULL)
   
  PrepDFM2<- stm::prepDocuments(DFM2$documents, meta = DFM$meta, vocab = DFM2$vocab,  
                                 lower.thresh = 0,
                                 upper.thresh = round(length(as.factor(alldocs))*0.75), 
                                 subsample = NULL, verbose = TRUE)
   
  cyberdocs_model3<- stm::stm(PrepDFM2$documents, PrepDFM2$vocab, length(PrepDFM2$documents), 
                        data = PrepDFM2$meta, init.type = "Spectral", 
                        seed = NULL, max.em.its = 500, emtol = 1e-05, verbose = FALSE, 
                        kappa.prior = "Jeffreys")
   
  # SAVE MODEL
  apiBase = Sys.getenv("API_BASE")
  save(cyberdocs_model, file = paste(apiBase, "models/cyberdocs_model3", sep = "/"))
    
  print("Done. Model saved!")
  
  return(cyberdocs_model3)
}