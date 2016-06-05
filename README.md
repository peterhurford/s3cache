## S3Cache

**S3Cache** is a persistant, cross-computer caching layer backed by the [s3mpi](https://github.com/robertzk/s3mpi) package. It supports a key-value store and an optional time to live.

```R
# Store any R object at a particular key.
s3cache::set("key", "this is the value")
s3cache::set("iris", iris)

# Read it back out later
s3cache::get("key")
[1] "this is your value"

dim(s3cache::get("iris"))
[1] 150  5

# Check for existence
s3cache::exists("iris")
[1] TRUE

# Drop a cache (use carefully)
s3cache::forget("iris")
s3cache::exists("iris")
[1] FALSE

# Specify a time-to-live when caching and it will disappear later.
s3cache::set("key2", "I only exist for one day", expires_in = "1 day from now")
s3cache::exists("key2")
[1] TRUE
s3cache::exists("key2")  # ...one day later.
[1] FALSE
```
