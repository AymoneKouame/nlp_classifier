library(testthat)

testthat::context("Category Classifier")

source(paste(apiBase,"classifiers/Category_Classifier.R", sep = "/"))

testthat::test_that("Test that Category_Classifier outputs 39 categories.", {
  category_classifier<- Category_Classifier("this is some text to classify")
  expect_that(category_classifier, is.data.frame)
  expect_equal(ncol(category_classifier), 39)
}
)