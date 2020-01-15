# Crystal CORS handler

CORS is a `HTTP::Handler` handler implementing [Cross Origin Resource Sharing W3 specification](http://www.w3.org/TR/cors/) in Crystal.

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

## Configuration (TBD)

## Benchmarks (TBD)
