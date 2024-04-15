library(testthat)

testthat::context("Cyberdocs Classifier")

source(paste(apiBase,"classifiers/Cyberdocs_Classifier.R", sep = "/"))

testthat::test_that("Test that Cyberdocs_Classifier outputs 3 categories.", {
  cyberdocs_classifier<- Cyberdocs_Classifier("this is some text to classify")
  expect_that(cyberdocs_classifier, is.data.frame)
  expect_equal(ncol(cyberdocs_classifier), 3)
}
)
