library(stm)

TopicLabeller<- function(raw_text, model) {
# AUTOMATIC LABELING PROCESS
# Returns the list of corresponding labels for each of the classifier topics, 
# in the order of topics (from topic 1 to topic n)
  # 'raw_text' MUST be the SAME TRAINING DATA used to train the classifier model
  # Assumes that 'raw_text' is a 2-column dataframe(topic and corresponding text)
  # 'model' is the trained STM model
  
  #LOGIC:
  # 1. Combines all text with same topic name in one row so as to match the number of topics in model
  # 2. Finds the most representative document(s) per topic (stm::findthoughts())
  # Threshold @ 90% (get only the doc with a min topic probablility of 90%)
  # Instead of returning the text of the doc, return the doc_id/feature name

    features<- gsub("_[0-9]+.txt.*","",raw_text[,1])
    trainNfeatures<- cbind(features, raw_text[,2])
    CombinedTrain<- aggregate(V2~ ., trainNfeatures, toString) 
    
    labels<- stm::findThoughts(model, as.character(CombinedTrain$features), 
                             n = 1, thresh =0.9)
    
    for (n in list(CombinedTrain$features)) {
        model_labels= strsplit(as.character(labels$docs[n]), split ="#")
    }
    
    
  return(model_labels)
}