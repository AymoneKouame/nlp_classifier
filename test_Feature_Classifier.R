
library(testthat)

testthat::context("Feature_Classifier")

apiBase = Sys.getenv("API_BASE")
source(paste(apiBase,"classifiers/Feature_Classifier.R", sep = "/"))

testthat::test_that("Test that Feature_Classifier input and output formats are correct and n features is 93.", {
    feature_classifier<- Feature_Classifier("this is some text to classify")
    expect_that(feature_classifier, is.data.frame)
    expect_equal(ncol(feature_classifier), 89)
  }
)
