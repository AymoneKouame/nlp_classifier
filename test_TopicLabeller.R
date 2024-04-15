library(testthat)
library(quanteda)
library(stm)

testthat::context("Topic Labeller")

apiBase = Sys.getenv("API_BASE")
source(paste(apiBase,"utility/TopicLabeller.R", sep = "/"))

testthat::test_that("Tests the critical inputs and outputs of Topic Labeller:
                    test that it gets the correct inputs' format and outputs 
                    the correct type and dimensions of labels. ", {
  
  trainingdata<- data.frame(doc_id = c("ACCOUNT_MANAGEMENT_1.txt", "BACK_UP_2.txt", "COMPLIANCE_4.txt"), text = c("account management is crucial for information systems security",
                          "backpup files periodically. This will avoid loss if you are ever victim of a security breach",
                          "Compliance with company security policies, security framework, laws and regulations"))
  
  ntopics = 3
  a<-convert(dfm(as.character(trainingdata[,2])), to = "stm")
  samplemodel<- stm(a$documents, a$vocab, ntopics)
  
  model_labels<- TopicLabeller(trainingdata, model = samplemodel)
    expect_is(samplemodel, "STM")
    expect_that(trainingdata, is.data.frame)
    expect_equal(ncol(trainingdata), 2) 
    expect_that(model_labels, is.character)
    expect_equal(length(model_labels), ntopics)
  }
)