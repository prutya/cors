require "./spec_helper"

IO_DEV_NULL = File.open(File::NULL, "w")

def init_http_context(
  req_method   : String = "GET",
  req_resource : String = "/",
  req_headers  : Hash(String, String) = {} of String => String,
  res_io       : IO = IO_DEV_NULL
)
  HTTP::Server::Context.new(
    HTTP::Request.new(
      req_method,
      req_resource,
      HTTP::Headers.new.tap { |hdrs| hdrs.merge!(req_headers) }
    ),
    HTTP::Server::Response.new(io: res_io)
  )
end

describe Cors::Handler do
  describe "#call" do
    respond_ok = ->(ctx : HTTP::Server::Context) {
      ctx.response << "OK"

      nil
    }

    it "processes the preflight request" do
      instance = Cors::Handler.new(
        respond_ok:        respond_ok,
        max_age:           86400,
        allow_credentials: true,
        allowed_origins:   ["http://localhost:8080"],
        allowed_methods:   ["PATCH", "GET", "POST", "PUT", "DELETE", "HEAD"],
        allowed_headers:   ["Accept", "Content-Type", "Authorization"]
      )
      instance.next = -> (_ctx : HTTP::Server::Context) { nil }
      ctx = init_http_context(
        req_method:  "OPTIONS",
        req_headers: {
          "Origin" => "http://localhost:8080",
          "Access-Control-Request-Method": "PATCH",
          "Access-Control-Request-Headers": "Accept,Content-Type"
        }
      )

      instance.call(ctx)

      ctx.response.headers["Vary"]
        .should eq "Origin,Access-Control-Request-Method,Access-Control-Request-Headers"
      ctx.response.headers["Access-Control-Allow-Origin"]
        .should eq "http://localhost:8080"
      ctx.response.headers["Access-Control-Allow-Methods"]
        .should eq "PATCH"
      ctx.response.headers["Access-Control-Allow-Headers"]
        .should eq "Accept,Content-Type"
      ctx.response.headers["Access-Control-Allow-Credentials"]
        .should eq "true"
      ctx.response.headers["Access-Control-Max-Age"]
        .should eq "86400"
    end

    it "processes the actual request" do
      instance = Cors::Handler.new(
        respond_ok:        respond_ok,
        max_age:           86400,
        allow_credentials: true,
        allowed_origins:   ["http://localhost:8080"],
        allowed_methods:   ["PATCH", "GET", "POST", "PUT", "DELETE", "HEAD"],
        allowed_headers:   ["Accept", "Content-Type", "Authorization"],
        exposed_headers:   ["X-My-Custom-Header-1", "X-My-Custom-Header-2"],
      )
      instance.next = -> (_ctx : HTTP::Server::Context) { nil }
      ctx = init_http_context(
        req_method: "PATCH",
        req_headers: {
          "Origin" => "http://localhost:8080",
          "Accept" => "application/json",
          "Content-Type" => "application/json"
        }
      )

      instance.call(ctx)

      ctx.response.headers["Vary"]
        .should eq "Origin"
      ctx.response.headers["Access-Control-Allow-Origin"]
        .should eq "http://localhost:8080"
      ctx.response.headers["Access-Control-Expose-Headers"]
        .should eq "X-My-Custom-Header-1,X-My-Custom-Header-2"
      ctx.response.headers["Access-Control-Allow-Credentials"]
        .should eq "true"
    end
  end
end
