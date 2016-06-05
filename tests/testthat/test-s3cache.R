library(testthatsomemore)

.cache <- list()

with_mock(
  `s3mpi::s3path`   = function() { "s3://testpath/" },
  `s3mpi::s3store`  = function(value, key, path, safe = TRUE) { .cache[[key]] <<- value },
  `s3mpi::s3read`   = function(key, path) { .cache[[key]] },
  `s3mpi::s3exists` = function(key, path) { key %in% names(.cache) },
  `s3mpi::s3delete` = function(key, path) { .cache[[key]] <<- NULL }, {
    describe("set and get", {
      test_that("get is NULL before an object is set", {
        expect_equal(get("key"), NULL)
      })
      test_that("it can set and get a value at a particular key", {
        set("key", "value")
        expect_equal(get("key"), "value")
      })
      test_that("it errors if the cache is already set", {
        expect_error(set("key", "other value"), "already is a cache")
      })
      test_that("time to live is enforced", {
        set("key2", "value2", expires_in = "1 minute from now")
        expect_equal(get("key2"), "value2")
        pretend_now_is("1 minute from now", {
          expect_equal(get("key2"), NULL)
        })
      })
    })

    describe("exists", {
      test_that("objects don't exist prior to definition", {
        expect_false(exists("key3"))
      })
      test_that("objects exist after definition", {
        set("key3", "value3")
        expect_true(exists("key3"))
      })
      test_that("objects don't exist after they expire", {
        set("key4", "value4", expires_in = "1 minute from now")
        expect_true(exists("key4"))
        pretend_now_is("1 minute from now", {
          expect_false(exists("key4"))
        })
      })
    })

    describe("forget", {
      test_that("a key can be forgotten", {
        set("key5", "value5")
        expect_true(exists("key5"))
        forget("key5")
        expect_false(exists("key5"))
      })
    })
  })
