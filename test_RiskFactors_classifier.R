library(testthat)

testthat::context("Risk Factors Classifier")

source(paste(apiBase,"classifiers/RiskFactors_Classifier.R", sep = "/"))

testthat::test_that("Test that RiskFactors_Classifier outputs xx categories.", {
  riskfactors_classifier<- RiskFactors_Classifier("this is some text to classify")
  expect_that(riskfactors_classifier, is.data.frame)
  expect_equal(ncol(riskfactors_classifier), 19)
}
)