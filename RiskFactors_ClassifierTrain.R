library(quanteda)
library(stm)

RiskFactors_ClassifierTrain<- function(raw_text)  {
  
  apiBase = Sys.getenv("API_BASE")
  source(paste(apiBase,"utility/CleanText.R", sep = "/"))
  
  # PREPOCESSING
  print("Preparing Data for Modeling...")
  
  rem <- c("a", "b", "c", "d", "e", "f", "g", 
            "h", "i", "j", "k", "l", "m", "n", 
            "o", "p", "q", "r", "s", "t", "u", 
            "v", "w", "x", "y", "z")
           
  train<- CleanText(raw_text, words2remove = rem)
  
  prune<- c("tnttttttttntttttttt", "uedit", "uwho", "uon", "uedit", "uemployee"
            ,"udoi", "uwhats", "uoverview", "ucybersecurity", "uneeds", "ucyber",
            "udecember", "rio", "uaccess", "uphysical", "uare", "uchapter",
            "uxaxa", "ujun", "xaxa", "ucompliance", "ubandwidth", "ucso", "usupport",
            "rnttttt", "ureply", "ureliability", "ubyop", "ukaspersky", "udisaster",
            "uemployee", "xarna", "umagazine", "uinnovative", "uentity", "xarn",
            "usql", "unate", "udomain", "uxaxaxaxaxa", "ubyod", "ujune", "umusic", "uadding", 
            "ufungible", "utech", "deloitte", "uback", "urisk", "umitre", "urn","usystems"
            ,"uacquisition", "ulaunched", "uadding", "ulaunched", "youure", "utargeted",
            "uet", "uvisibility", "usecure", "updf", "untttttttload", "uassess", "uzdnet"
            , "unetwork")

  RiskFactors<- stringi::stri_extract(raw_text[,1], regex='[A-Za-z_A-Za-z]*')
  
  DFM<- quanteda::dfm(as.character(train), tolower = TRUE, stem = FALSE, 
                      select = NULL, remove = prune,
                      dictionary = NULL, thesaurus = NULL, 
                      valuetype = "glob", groups = as.factor(RiskFactors), 
                      verbose = quanteda::quanteda_options("verbose"))
  
  DFM<- quanteda::convert(DFM, to = "stm", docvars = NULL)
  
  PrepDFM<- stm::prepDocuments(DFM$documents, meta = DFM$meta, vocab = DFM$vocab, 
                               lower.thresh = 0, # changed from 1
                               upper.thresh = (length(DFM$documents))*0.80, #changed from 775 then from 70
                               subsample = NULL, verbose = TRUE)
  
  
  # MODELING
  riskfactors_model<- stm::stm(PrepDFM$documents, PrepDFM$vocab, length(PrepDFM$documents), 
                           prevalence = NULL, content = NULL, data = PrepDFM$meta, init.type = "Spectral", 
                           seed = NULL, max.em.its = 500, emtol = 1e-05, verbose = TRUE, reportevery = 5,
                           LDAbeta = TRUE, interactions = TRUE, model = NULL,
                           gamma.prior = "Pooled", sigma.prior = 0, kappa.prior = "Jeffreys")
  
  # SAVING MODEL
  save(riskfactors_model, file = paste(apiBase, "models/riskfactors_model", sep = "/"))
   
  print("Done. Model saved!")
  
  return(riskfactors_model)
}