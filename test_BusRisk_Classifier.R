library(testthat)

testthat::context("Business Risk Classifier")

apiBase = Sys.getenv("API_BASE")
source(paste(apiBase,"classifiers/BusRisk_Classifier.R", sep = "/"))

testthat::test_that("Test that BusRisk_Classifier outputs 11 categories.", {
  busrisk_classifier<- BusRisk_Classifier("this is some text to classify")
  expect_that(busrisk_classifier, is.data.frame)
  expect_equal(ncol(busrisk_classifier), 11)
}
)

