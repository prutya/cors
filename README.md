# Crystal CORS handler

CORS is a `HTTP::Handler` handler (middleware) implementing [Cross Origin Resource Sharing W3 specification](http://www.w3.org/TR/cors/) in Crystal.

## Installation
In `shards.yml`:
```yaml
dependencies:
  cors:
    github: prutya/cors
    branch: master # OR: version: x.x.x (Check the releases tab)
```
Then:
```crystal
require "cors"
```

## Getting Started
Add this handler to your `HTTP::Server` initializer call
```crystal
server = HTTP::Server.new([
  SomeHandler.new,
  Cors::Handler.new(
    respond_ok: ->(ctx : HTTP::Server::Context) {
      # Whatever you do when you want to respond with 200 OK
      #
      # e.g.
      ctx.response.status = HTTP::Status::OK
      ctx.response.content_type = "application/json"
      ctx.response.print("{}")
    },
    allowed_origins: ["https://example.com"]
  ),
  SomeOtherHandler.new,
])
```

## Configuration
**respond_ok** (required)
`Proc` with `HTTP::Server::Context` argument. Called when the preflight processing is finished.

**max_age** (optional)
`Int32`, defaults to `0`. If greater than `0`, goes to [Access-Control-Max-Age](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Max-Age) header in the preflight response, otherwise does nothing.

**allow_credentials** (optional)
`Bool`, defaults to `false`
If set to `true`, adds the [Access-Control-Allow-Credentials](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Credentials) header to the response, otherwise does nothing.

**log** (optional)
`Logger`, defaults to a `STDOUT` logger with `info` severity. Your logger 🤷‍♂️

**log_prefix** (optional)
`Proc` with `HTTP::Server::Context` argument, returning a `String` or `Nil`. Defaults to `nil`
If present, adds the result of the function call as a prefix to all log calls, otherwise adds nothing.

**allowed_origins** (optional)
`Array(String)`. Defaults to an empty array.
The list of allowed origins. If the array contains `"*"`, allows all origins. [Access-Control-Allow-Origin](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Origin).

**allowed_methods** (optional)
`Array(String)`. Defaults to `["GET", "POST", "PUT"]`. The list of allowed HTTP methods. If empty, results in all requests being disallowed. [Access-Control-Allow-Methods](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Methods).

**allowed_headers** (optional)
`Array(String)`. Defaults to `["Origin", "Accept", "Content-Type", "X-Requested-With"]`.
If empty, results in only `Origin` header being allowed, otherwise results in `Origin` header and headers provided being allowed. [Access-Control-Allow-Headers](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Headers).

**exposed_headers** (optional)
`Array(String)`. Defaults to and empty array. [Access-Control-Expose-Headers](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Expose-Headers).

## Benchmarks (TBD)
