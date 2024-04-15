library(stopwords)
library(lexicon)
library(stringr)
library(textclean)
library(tm)


# Input is text and outout is also text

# CleanText() removes by default only common_stopwords 
 #1. if you wish to retain stopwords, use 'rem_stopword = FALSE'
 #2. if you wish to remove words of your own choosing, define 'words2remove'
 ## 'words2remove' should be a list of words. example: c("word", "word")

CleanText<-function(raw_text, #rem_stopwords , 
                    words2remove = NULL ) {
  
  # WORDS TO BE REMOVED FROM CORPUS
  
  common_stopwords = c(stopwords("en"), 
                       as.character(lexicon::pos_df_pronouns[,1])
                       , as.character(lexicon::pos_interjections), 
                       as.character(lexicon::sw_python))
 

  remove_all<- c(common_stopwords, words2remove)
  
  # CLEANING TEXT
  
  cleantext <- stringr::str_replace(raw_text, '(http|https)[^([:blank:]|\\"|<|&|#\n\r)]+', " ") # removes urls
  cleantext <- textclean::replace_symbol (cleantext) #replace symbols like %, &, ... with english words
  cleantext <- tolower(cleantext)
  cleantext <- tm::removeNumbers(cleantext) #remove numbers
  cleantext <- tm::removePunctuation(cleantext) # removes punctuation
  cleantext <- tm::removeWords(cleantext, remove_all) # remove lists of common stopwords
  cleantext <- tm::stripWhitespace(cleantext) #removes extra whitespace
  cleantext <- stringr::str_replace_all(cleantext ,"[^a-zA-Z\\s]", " ")  # removes all non characters
  
  
  return(cleantext)
}
