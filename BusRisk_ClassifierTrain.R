library(quanteda)
library(stm)
library(futile.logger)
library(ngram)

BusRisk_ClassifierTrain<- function(raw_text)  {
  
  apiBase = Sys.getenv("API_BASE")
  source(paste(apiBase,"utility/CleanText.R", sep = "/"))
  
  # PREPOCESSING
  print("Preparing Data for Modeling...")
  train<- CleanText(raw_text)
  
  rem<-c(as.character(lexicon::pos_df_pronouns[,1]),
         as.character(lexicon::emojis_sentiment[,1]), as.character(lexicon::pos_interjections),
         as.character(lexicon::sw_python), "data", "security", "information", "also", "said", "tab",
         "raj", "furthermore", "mary", "varied", "new", "japan", "click", "south", "northwest", "see",
         "may", "icon", "eight", "sex", "march", "yahoo", "one", "kelly", "like", "somewhere", 
         "messenger", "par", "june", "tomorrow", "ring", "unlimited", "per", "north", "peace", "movie", 
         "titled", "commentary", "interesting", "west", "mistake")
  
  
  BusRisks<- stringi::stri_extract(raw_text[,1], regex='[A-Za-z_A-Za-z]*')
  
  DFM<- quanteda::dfm(as.character(train), tolower = TRUE, stem = FALSE, select = NULL, remove = rem,
                      dictionary = NULL, thesaurus = NULL, valuetype = "glob", groups = as.factor(BusRisks), 
                      verbose = quanteda::quanteda_options("verbose"))
  
  DFM<- quanteda::convert(DFM, to = "stm", docvars = NULL)
  
  PrepDFM<- stm::prepDocuments(DFM$documents, meta = DFM$meta, vocab = DFM$vocab, lower.thresh = 1,
                               upper.thresh = round(length(as.factor(BusRisks))*0.75), subsample = NULL, verbose = TRUE)

  
  # MODELING
  print("Modeling with STM")
  busrisk_model<- stm::stm(PrepDFM$documents, PrepDFM$vocab, length(PrepDFM$documents), 
                           prevalence = NULL, content = NULL, data = PrepDFM$meta, init.type = "Spectral", 
                           seed = NULL, max.em.its = 500, emtol = 1e-05, verbose = TRUE, reportevery = 5,
                           LDAbeta = TRUE, interactions = TRUE, model = NULL,
                           gamma.prior = "Pooled", sigma.prior = 0, kappa.prior = "Jeffreys")
  
  # SAVING MODEL
  apiBase = Sys.getenv("API_BASE")
  save(busrisk_model, file = paste(apiBase, "models/busrisk_model", sep = "/"))
  
  print("Done. Model saved!")
  
  return(busrisk_model)
}