require "uri"
require "json"
require "http/client"

SESSION_ID_KEY = "x-transmission-session-id"

class Client
  class Request
    include JSON::Serializable

    property arguments : JSON::Any?
    property method : String
    property tag : Int32? = nil
  end

  class Response
    include JSON::Serializable

    property arguments : JSON::Any
    property result : String
    property tag : Int32? = nil
  end

  getter headers : HTTP::Headers = HTTP::Headers.new
  getter session_id : String = ""
  getter http_client : HTTP::Client

  def initialize(uri : String, port : Int32? = 9091, user : String? = nil, pass : String? = nil)
    @uri = URI.parse(uri)
    @uri.port = port if @uri.port.nil?
    @uri.user = user if @uri.user.nil?
    @uri.password = pass if @uri.password.nil?

    @http_client = HTTP::Client.new(@uri)
    @http_client.basic_auth(@uri.user, @uri.password) unless @uri.user.nil? || @uri.password.nil?
  end

  def initialize(uri : URI)
    @uri = uri

    @http_client = HTTP::Client.new(@uri)
    @http_client.basic_auth(@uri.user, @uri.password) unless @uri.user.nil? || @uri.password.nil?
  end

  def post(request : Request, rep : Int32 = 0) : Response?
    response = @http_client.post("/transmission/rpc", headers: @headers, body: request.to_json)

    if response.status_code == 409
      @headers[SESSION_ID_KEY] = response.headers[SESSION_ID_KEY] if response.headers.has_key?(SESSION_ID_KEY)
      return if rep == 25

      return self.post(request, rep + 1)
    end

    if response.status_code == 409
      raise "Auth wrong or missing"
    end

    return unless response.status_code == 200

    begin
      Response.from_json(response.body)
    rescue
    end
  end

  def post(method : String, arguments : String? = nil, tag : Int32? = nil)
    request = Request.from_json(%({"method": "#{method}"#{arguments ? ", \"arguments\": #{arguments}" : ""}#{tag ? ", \"tag\": #{tag}" : ""}}))
    post(request)
  end
end
