require "http"
require "log"

require "./utils"

module Cors
  # TODO: Handle wildcard origins (*.example.com) in configuration
  class Handler
    include HTTP::Handler

    ALLOWED_HEADERS_DEFAULT = ["origin", "accept", "content-type", "x-requested-with"]
    ALLOWED_METHODS_DEFAULT = ["GET", "POST", "PUT"]

    VARY_HEADERS = [
      "Origin",
      "Access-Control-Request-Method",
      "Access-Control-Request-Headers"
    ]

    @log                 : Log
    @exposed_headers     : Array(String)
    @allowed_origins_all : Bool
    @allowed_headers_all : Bool

    def initialize(
      @respond_ok        : Proc(HTTP::Server::Context, Nil),
      @max_age           : Int32 = 0,
      @allow_credentials : Bool = false,
      @log_prefix        : Proc(HTTP::Server::Context, String)? = nil,
      log                : Proc(Log) = ->() do
        Log.builder.bind(
          "cors",
          Log::Severity::Info,
          Log::IOBackend.new(STDOUT)
        )

        Log.for("cors", Log::Severity::Info)
      end,
      allowed_origins    : Array(String) = [] of String,
      allowed_methods    : Array(String) = [] of String,
      allowed_headers    : Array(String) = [] of String,
      exposed_headers    : Array(String) = [] of String,
    )
      @log = log.call

      @exposed_headers = exposed_headers.clone

      # NOTE: Normalize allowed origins
      @allowed_origins_all = false
      @allowed_origins = [] of String

      if allowed_origins.empty?
        @allowed_origins_all = true
      else
        allowed_origins.each do |origin|
          if origin == "*"
            @allowed_origins_all = true

            break
          end

          @allowed_origins.push(origin.downcase)
        end
      end

      # NOTE: Normalize allowed headers
      @allowed_headers_all = false
      @allowed_headers =
        if allowed_headers.empty?
          ALLOWED_HEADERS_DEFAULT
        else
          ["origin"].tap do |_allowed_headers|
            allowed_headers.each do |header|
              if header == "*"
                @allowed_headers_all = true

                break
              end

              _allowed_headers.push(Utils.normalize_header(header))
            end
          end
        end

      # NOTE: Normalize allowed methods
      @allowed_methods =
        if allowed_methods.empty?
          ALLOWED_METHODS_DEFAULT
        else
          allowed_methods.map(&.upcase)
        end
    end

    def call(ctx : HTTP::Server::Context)
      log_prefix = @log_prefix.try(&.call(ctx))

      # NOTE: Process preflight request
      if ctx.request.method.upcase == "OPTIONS" &&
        ctx.request.headers["Access-Control-Request-Method"]?
        @log.debug { "#{log_prefix}Preflight request" }

        process_preflight(ctx)

        return @respond_ok.call(ctx)
      end

      # NOTE: Process actual request
      @log.debug { "#{log_prefix}Actual request" }

      process_actual_request(ctx)

      call_next(ctx)
    end

    private def process_preflight(ctx : HTTP::Server::Context)
      log_prefix = @log_prefix.try(&.call(ctx))

      # NOTE: Always set Vary headers
      ctx.response.headers.add("Vary", VARY_HEADERS)

      unless origin = ctx.request.headers["Origin"]?.as?(String)
        @log.debug { "#{log_prefix}Preflight aborted: Origin is not provided" }

        return
      end

      unless origin_allowed?(origin)
        @log.debug { "#{log_prefix}Preflight aborted: Origin #{origin} is not allowed" }

        return
      end

      req_method = ctx.request.headers["Access-Control-Request-Method"].as(String)

      unless method_allowed?(req_method)
        @log.debug { "#{log_prefix}Preflight aborted: Method #{req_method} is not allowed" }

        return
      end

      req_headers =
        if _req_headers = ctx.request.headers["Access-Control-Request-Headers"]?.as?(String)
          Utils.parse_headers(_req_headers)
        else
          [] of String
        end

      unless headers_allowed?(req_headers)
        @log.debug { "#{log_prefix}Preflight aborted: Headers #{req_headers} are not allowed" }

        return
      end

      if @allowed_origins_all
        ctx.response.headers["Access-Control-Allow-Origin"] = "*"
      else
        ctx.response.headers["Access-Control-Allow-Origin"] = origin
      end

      # NOTE: Spec says: Since the list of methods can be unbounded,
      # simply returning the method indicated by
      # Access-Control-Request-Method (if supported) can be enough
      ctx.response.headers["Access-Control-Allow-Methods"] = req_method.upcase

      unless req_headers.empty?
        # NOTE: Spec says: Since the list of headers can be unbounded,
        # simply returning supported headers from
        # Access-Control-Request-Headers can be enough
        ctx.response.headers["Access-Control-Allow-Headers"] =
          req_headers.map { |h| Utils.prettify_header(h) }.join(',')
      end

      if @allow_credentials
        ctx.response.headers["Access-Control-Allow-Credentials"] = "true"
      end

      if @max_age > 0
        ctx.response.headers["Access-Control-Max-Age"] = @max_age.to_s
      end
    end

    private def process_actual_request(ctx : HTTP::Server::Context)
      log_prefix = @log_prefix.try(&.call(ctx))

      ctx.response.headers.add("Vary", "Origin")

      unless origin = ctx.request.headers["Origin"]?.as?(String)
        @log.debug { "#{log_prefix}No CORS headers added: Origin is not provided" }

        return
      end

      unless origin_allowed?(origin)
        @log.debug { "#{log_prefix}No CORS headers added: Origin #{origin} is not allowed" }

        return
      end

      # NOTE: Spec does define a way to specifically disallow a simple method
      # like GET or POST. Access-Control-Allow-Methods is only used for
      # pre-flight requests and the spec doesn't instruct to check the allowed
      # methods for simple cross-origin requests.
      # We think it's a nice feature to be able to have control on those
      # methods though.
      unless method_allowed?(ctx.request.method)
        @log.debug { "#{log_prefix}No CORS headers added: Method #{ctx.request.method.upcase} is not allowed" }

        return
      end

      if @allowed_origins_all
        ctx.response.headers["Access-Control-Allow-Origin"] = "*"
      else
        ctx.response.headers["Access-Control-Allow-Origin"] = origin
      end

      unless @exposed_headers.empty?
        ctx.response.headers["Access-Control-Expose-Headers"] = @exposed_headers.join(',')
      end

      if @allow_credentials
        ctx.response.headers["Access-Control-Allow-Credentials"] = "true"
      end
    end

    private def origin_allowed?(origin : String) : Bool
      if @allowed_origins_all
        return true
      end

      @allowed_origins.includes?(origin.downcase)
    end

    private def method_allowed?(method : String) : Bool
      if @allowed_methods.empty?
        # NOTE: If no method allowed, always return false, even for preflight
        # request
        return false
      end

      method = method.upcase

      if method == "OPTIONS"
        # NOTE: Always allow preflight requests
        return true
      end

      @allowed_methods.includes?(method)
    end

    private def headers_allowed?(headers : Array(String)) : Bool
      if @allowed_headers_all || headers.empty?
        return true
      end

      headers.each do |header|
        unless @allowed_headers.includes?(header)
          return false
        end
      end

      true
    end
  end
end
