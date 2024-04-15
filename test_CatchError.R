library(testthat)

testthat::context("CatchError")

apiBase = Sys.getenv("API_BASE")
source(paste(apiBase,"utility/CatchError.R", sep = "/"))
source(paste(apiBase,"wrapper.R", sep = "/"))

testthat::test_that("Test that CatchError(): always stops the execution of a function when an error occurs", {
  
  text<- NULL
  expect_error(CatchError(Industry_Classifier(text)))
  expect_error(CatchError(Feature_Classifier(text)))
  expect_error(CatchError(Category_Classifier(text)))
  expect_error(CatchError(BusRisk_Classifier(text)))
  expect_error(CatchError(RiskFactors_Classifier(text)))
  expect_error(CatchError(Cyberdocs_Classifier(text)))
  }
)

testthat::test_that("Test that CatchError(): always outputs (never stops) the result of a function when no error has occured.", {
                      
  text<-  "this is some text to classify"
  output<- CatchError(classify(text))                  
  expect_that(output, is.data.frame) 
  expect_equal(length(output),  length(classify(text)))
  }
)
