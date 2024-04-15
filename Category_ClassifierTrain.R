library(stm)
library(quanteda)

Category_ClassifierTrain<- function(raw_text)  {
  
  print("Cleaning raw_text...")
  source(paste(apiBase,"utility/CleanText.R", sep = "/"))
  train<- CleanText(raw_text)
  
  #remove extra words that weren't removes during text cleaning
  rem<- c("a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", 
          "v", "w", "x", "y", "z", "in", "use", "used","many", "care", "the", "lso", "alth", "ten", "as", "percent", 
          "this", "new", "number", "may", "us", "for", "it", "come", "work", "aa", "aais", "aas", "ab", "abba", "abc", 
          "abcs", "able", "about", "abuse", "ac", "aachen", "abandon", "abandoned", "abandoning", "abandonment", "abbey",
          "abbreviated", "abbreviation", "abbreviations", "abd", "abide", "absence", "absences", "absent", "yes","no","yr", "yk",
          "yesterday", "yes", "yemen", "yellow", "yearswhen", "yearscitation", "years", "yearround", "yearold", "yearly", 
          "year", "registration", "yards", "yang", "yale", "will", "free", "uc", "quiz", "cvepublished", "xi", "xavier", "wyoming", "wwii",
          "can", "rbac", "learn", "eweek", "dollar", "reviewsget", "open", "managementhidde", "might", "learn",
          "job", "also", "dollar", "best", "using", "must", "security", "top")
  
  print("Creating DFM (Document Feature Matrix)...")
  category<- gsub("_[^_]+$", "\\1", raw_text[,1])
  
  DFM<- quanteda::dfm(as.character(train), tolower = TRUE, stem = FALSE, select = NULL, remove = rem,
                      dictionary = NULL, thesaurus = NULL, valuetype = "glob", groups = as.factor(category),
                      verbose = quanteda::quanteda_options("verbose"))
  
  DFM<- quanteda::convert(DFM, to = "stm", docvars = NULL)
  
  print("Preparing DFM for modeling.. removing noisy words and tokens")
  
  # upper thresh removes words that appear in more than 50% of total training data (rounded)
  PrepDFM<- stm::prepDocuments(DFM$documents, meta = DFM$meta, vocab = DFM$vocab, lower.thresh = 1,
                               upper.thresh = round(length(as.factor(category))/2), subsample = NULL, verbose = TRUE)
  
  print("Modeling with stm algorithm...")
  
  # MODEL
  
  category_model<- stm::stm(PrepDFM$documents, PrepDFM$vocab, length(PrepDFM$documents), 
                            prevalence = NULL, content = NULL, data = PrepDFM$meta, init.type = "Spectral", 
                            seed = NULL, max.em.its = 500, emtol = 1e-05, verbose = TRUE, reportevery = 5,
                            LDAbeta = TRUE, interactions = TRUE, model = NULL,
                            gamma.prior = "Pooled", sigma.prior = 0, kappa.prior = "Jeffreys")
  
  # SAVE MODEL
  apiBase = Sys.getenv("API_BASE")
  save(category_model, file = paste(apiBase, "models/category_model", sep = "/"))
  
  print("Done. Model saved!")
  
  return(category_model)
}

