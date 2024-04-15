library(testthat)

testthat::context("Industry_Classifier")

apiBase = Sys.getenv("API_BASE")
source(paste(apiBase,"classifiers/Industry_Classifier.R", sep = "/"))

testthat::test_that("Test that Industry_Classifier input and output formats are correct and n industries is 23.", {
  
  industry_classifier<- Industry_Classifier("this is some text to classify")
  expect_that(industry_classifier, is.data.frame)
  expect_equal(ncol(industry_classifier), 23)
}
)