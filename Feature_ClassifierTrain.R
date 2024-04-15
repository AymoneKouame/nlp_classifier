library(quanteda)
library(lexicon)
library(stm)
library(rlist)

Feature_ClassifierTrain<- function(raw_text)  {
  
  # PREPOCESSING
  print("Preparing Data for Modeling...")
  train<- CleanText(raw_text)
  rem<-c("of", "the", "in", "you", "can", "a", "b", "c", "d", "e", "f", 
         "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", 
         "v", "w", "x", "y", "z", "percent", "view", "us", "free", "must", 
         "en", "used", "see", "using", "include", "use", "pecent", "fk")
  
  features<- gsub("_[^_]+$", "\\1", raw_text[,1])
  
  DFM<- quanteda::dfm(as.character(train), tolower = TRUE, stem = FALSE, select = NULL, remove = rem,
                      dictionary = NULL, thesaurus = NULL, valuetype = "glob", groups = as.factor(features),
                      verbose = quanteda::quanteda_options("verbose"))
  
  DFM<- quanteda::convert(DFM, to = "stm", docvars = NULL)
  
  # upper thresh removes words that appear in more than 50% of total training data (rounded)
  PrepDFM<- stm::prepDocuments(DFM$documents, meta = DFM$meta, vocab = DFM$vocab, lower.thresh = 1,
                               upper.thresh = round(length(as.factor(features))/2), subsample = NULL, verbose = TRUE)
  
  print("Modeling with stm algorithm...")
  
  # MODELING
  print("Modeling with STM")
  features_model<- stm::stm(PrepDFM$documents, PrepDFM$vocab, length(PrepDFM$documents), 
                            prevalence = NULL, content = NULL, data = PrepDFM$meta, init.type = "Spectral", 
                            seed = NULL, max.em.its = 500, emtol = 1e-05, verbose = TRUE, reportevery = 5,
                            LDAbeta = TRUE, interactions = TRUE, model = NULL,
                            gamma.prior = "Pooled", sigma.prior = 0, kappa.prior = "Jeffreys")
  
  # SAVING MODEL
  apiBase = Sys.getenv("API_BASE")
  save(features_model, file = paste(apiBase, "models/features_model", sep = "/"))
  print("Done. Model saved!")
  
  # CREATING LABELS
  source(paste(apiBase,"utility/TopicLabeller.R", sep = "/"))
  features_labels<- TopicLabeller(raw_text = raw_text, model = features_model)
  rlist::list.save(features_labels, "models/features_labels.rdata")
  
  return(features_model)
}