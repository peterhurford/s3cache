#' Store a value in the s3cache at a particular key.
#'
#' @param key character. The key to store at.
#' @param value character. The value to store.
#' @param path character. Path to the s3bucket if you want to define a new cache location.
#' @param expires_in character. A string defining when the cache expires or the time of expiration (POSIXt).
#' @export
set <- checkr::ensure(
  pre = list(
    key %is% simple_string,
    value %is% simple_string,
    path %is% simple_string,
    expires_in %is% simple_string || expires_in %is% POSIXt || expires_in %is% NULL
  ),
  function(key, value, path = default_path(), expires_in = NULL) {
    if (exists(key, path = path)) {
      stop("There already is a cache for ", sQuote(key),
        ". You can use s3cache::forget to overwrite.")
    }
    store_object(key, value, expires_in, path)
  })

#' Retrieve a value in the s3cache at a particular key.
#'
#' @param key character. The key to store at.
#' @param path character. Path to the s3bucket if you want to define a new cache location.
#' @export
get <- checkr::ensure(
  pre = list(
    key %is% simple_string,
    path %is% simple_string
  ),
  function(key, path = default_path()) {
    if (!exists(key, path = path)) {
      NULL
    } else {
      get_object(key, path)
    }
  })

#' Check for the existence of a value in the s3cache at a particular key.
#'
#' @param key character. The key to store at.
#' @param path character. Path to the s3bucket if you want to define a new cache location.
#' @export
exists <- checkr::ensure(
  pre = list(
    key %is% simple_string,
    path %is% simple_string),
  function(key, path = default_path()) {
    expire_if_expired(key, path = path)
    s3mpi::s3exists(paste0(key, "/value"), path = path)
  })

#' Delete the s3cache at a particular key.
#'
#' @param key character. The key to store at.
#' @param path character. Path to the s3bucket if you want to define a new cache location.
#' @export
forget <- checkr::ensure(
  pre = list(
    key %is% simple_string,
    path %is% simple_string),
  function(key, path = default_path()) {
    if (exists(key, path = path)) {
      s3mpi::s3delete(paste0(key, "/value"), path = path)
      s3mpi::s3delete(paste0(key, "/metadata"), path = path)
    }
  })


default_path <- function() {
  paste0(s3mpi::s3path(), "s3cache/")
}

store_object <- function(key, value, expires_in, path) {
  s3mpi::s3store(value, paste0(key, "/value"), path = path, safe = TRUE)
  s3mpi::s3store(list(cached_at = Sys.time(), expires_in = expires_in),
    paste0(key, "/metadata"), path = path, safe = TRUE)
}
get_object <- function(key, path) {
  s3mpi::s3read(paste0(key, "/value"), path = path)
}
get_object_metadata <- function(key, path) {
  s3mpi::s3read(paste0(key, "/metadata"), path = path)
}

expire_if_expired <- function(key, path) {
  metadata <- get_object_metadata(key, path)
  has_expiration <- !is.null(metadata$expires_in)
  if (!has_expiration) { return(NULL) }
  expire_time <- strdate::strdate(metadata$expires_in,
    relative_to = metadata$cached_at)
  if (Sys.time() > expire_time) {
    forget(key, path)
  }
}
