# frozen-string-literal: true
require 'net/http'
require 'cf/uaa/exceptions'
require 'cf/uaa/json_handler'

class CF::UAA::Client
  attr_reader :domain, :proxy_addr, :proxy_port, :proxy_user, :proxy_password

  def initialize(domain, proxy_addr: nil, proxy_port: nil, proxy_user: nil, proxy_password: nil)
    @domain = domain
    @proxy_addr = proxy_addr
    @proxy_port = proxy_port
    @proxy_user = proxy_user
    @proxy_password = proxy_password
    @interceptors = []
    @observers = []

    register_interceptor(JsonSerializer.new)
    register_observer(ResponseHandler.new)
    register_observer(JsonDeserializer.new)
  end

  def register_interceptor(interceptor)
    @interceptors << interceptor
  end

  def register_observer(observer)
    @observers << observer
  end

  def post_token(body, query: {}, headers: {}, **options)
    request(Net::HTTP::Post, uri('/oauth/token', query), body, headers, options)
  end
  alias create_token post_token

  def authorize(query: {}, headers: {}, **options)
    request(Net::HTTP::Get, uri('/oauth/authorize', query), nil, headers, options)
  end

  def get_userinfo(query: {}, headers: {}, **options)
    request(Net::HTTP::Get, uri('/userinfo', query), nil, headers, options)
  end
  alias find_userinfo get_userinfo

  def get_users(query: {}, headers: {}, **options)
    request(Net::HTTP::Get, uri('/Users', query), nil, headers, options)
  end
  alias find_users get_users

  def get_user(id, query: {}, headers: {}, **options)
    request(Net::HTTP::Get, uri("/Users/#{id}", query), nil, headers, options)
  end
  alias find_user get_user

  def post_user(body, query: {}, headers: {}, **options)
    request(Net::HTTP::Post, uri('/Users', query), body, headers, options)
  end
  alias create_user post_user

  def put_password(id, body, query: {}, headers: {}, **options)
    request(Net::HTTP::Put, uri("/Users/#{id}/password", query), body, headers, options)
  end
  alias update_password put_password

  def autologin(body, query: {}, headers: {}, **options)
    request(Net::HTTP::Post, uri('/autologin', query), body, headers, options)
  end

  private

  DEFAULT_OPTIONS = {
    ca_file: nil,
    ca_path: nil,
    cert: nil,
    cert_store: nil,
    ciphers: nil,
    close_on_empty_response: nil,
    key: nil,
    open_timeout: nil,
    read_timeout: nil,
    ssl_timeout: nil,
    ssl_version: nil,
    use_ssl: nil,
    verify_callback: nil,
    verify_depth: nil,
    verify_mode: nil
  }.freeze

  HTTPS = 'https'.freeze

  def request(request_class, uri, body, headers, options = {})
    uri, body, headers, options = @interceptors.reduce([uri, body, headers, DEFAULT_OPTIONS.merge(options)]) { |r, i| i.before_request(*r) }

    begin
      response = Net::HTTP.start(uri.host, uri.port, proxy_addr, proxy_port, proxy_user, proxy_password, options, use_ssl: (uri.scheme == HTTPS)) do |http|
        http.request request_class.new(uri, headers), body
      end
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
      raise NetworkError, "A network error occurred: #{e.class} (#{e.message})"
    end

    @observers.reduce(response) { |r, o| o.received_response(r) }
  end

  def uri(path, query = {})
    uri = URI.join(domain, path)
    uri.query = URI.encode_www_form(query) unless query.empty?
    uri
  end
end
