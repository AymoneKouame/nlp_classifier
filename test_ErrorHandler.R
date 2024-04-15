library(testthat)

testthat::context("ErrorHandler")

apiBase = Sys.getenv("API_BASE")
source(paste(apiBase,"utility/ErrorHandler.R", sep = "/"))
source(paste(apiBase,"wrapper.R", sep = "/"))

testthat::test_that("Test that ErrorHandler() (1) always returns 'NULL' when an error occurs.", {
  
  text <- NULL
  classifier<- ErrorHandler(classify,text)
  expect_that(classifier, is.list)
  expect_match(classifier[[1]], "NULL", fixed = TRUE)
  expect_match(classifier[[2]], "NULL", fixed = TRUE)
  expect_match(classifier[[3]], "NULL", fixed = TRUE)
  expect_match(classifier[[4]], "NULL", fixed = TRUE)
  expect_match(classifier[[5]], "NULL", fixed = TRUE)
  expect_match(classifier[[6]], "NULL", fixed = TRUE)
                        
  }
)


testthat::test_that("Test that ErrorHandler() (2) always outputs (never stops) the result of a function when no error has occured.", {
                        

text <- "this is some text to classify"
classifier<- ErrorHandler(classify,text)

expect_that(classifier, is.data.frame) 
expect_equal(length(classifier),  length(classify(text)))
}
)

