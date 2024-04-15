library(testthat)

context("Wrapper tests")

apiBase = Sys.getenv("API_BASE")

source(paste(apiBase,"wrapper.R", sep = "/"))

test_that("wrapper returns elements.", {
  req <- structure(
    list(
      method = "POST",
      url = "http://127.0.0.1:5377/classifications",
      headers = list("Content-Type"="application/x-www-form-urlencoded"),
      fields = NULL,
      options = NULL,
      auth_token = NULL,
      output = NULL,
      postBody = "This is some sample text to classify. Please classifiy this"
    ),
    class = "request"
  )
  result <- classify(req$postBody)
  expect_gte(length(result), 1)
  expect_equal(NCOL(result[["Feature"]]), 89)
  expect_equal(NCOL(result[["Industry"]]), 23)
  expect_equal(NCOL(result[["Category"]]), 39)
  expect_equal(NCOL(result[["BusRisk"]]), 11)
  expect_equal(NCOL(result[["Cyberdoc"]]), 3)
  expect_equal(NCOL(result[["RiskFactor"]]), 19)
})

