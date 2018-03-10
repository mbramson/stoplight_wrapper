require 'faraday'
require 'stoplight'

class StoplightConnection
  class ConfigurationError < StandardError; end
  class ResponseError < StandardError; end

  def initialize(endpoint, options)
    raise ConfigurationError.new('no endpoint supplied') unless endpoint
    @endpoint = endpoint
    @ssl = options[:ssl]
    @default_timeout = options[:timeout]
    @faraday_adapter = params[:adapter]
    @redis = options[:redis]
    @success_check = nil
    @light_opts = opts.delete(:light_opts) || {}
    @stoplight_name = @light_opts[:name]
    @light = {}

    initialize_stoplight
  end

  def post(path, opts = {})
    execute_request(:post, path, opts)
  end

  def execute_request(verb, path, opts = {})
    resource_id = opts.delete(:resource_id)
    @stoplight_name ||= generate_stoplight_name(verb, path)
    total_path = build_path(path, resource_id)
    @light[@stoplight_name] = Stoplight(@stoplight_name) { call_server(verb, total_path, opts) }
      .with_threshold(@light_opts[:threshold] || 3)
      .with_cool_off_time(@light_opts[:cool_off_time] || 60)
      #TODO add error handler
    @light[@stoplight_name].run
  end

  def call_server(verb, path, opts)
    conn = faraday_connection(opts)
    conn.basic_auth opts[:user], opts[:password] if (opts[:user] && opts[:password])
    response = send_request(verb, path, opts)
    verify_success(response)
    response
  end

  def send_request(verb, path, opts)
    conn.send(verb) do |request|
      request.url path
      request.body = opts[:body] if opts[:body]
      request.headers.merge!(opts[:headers]) if opts[:headers]
      request.params = opts[:params] if opts[:params]
    end
  end

  def verify_success(response)
    if @success_check
      @success_check.call(response)
    else
      unless response.success?
        message = {status: response.status, body: response.body}.to_json
        raise(ResponseError.new(message))
      end
    end
  end

  def set_success_check(lam)
    raise ConfigurationError, "the argument to set_success_check must respond to 'call' (e.g. a Proc, Lambda, or Method)" unless lam.respond_to? :call
    raise ConfigurationError, 'the proc, lambda, or method supplied to set_success_check must have an arity of 1.' unless lam.respond_to? :arity and lam.arity == 1
    @success_check = lam
  end

  def faraday_connection(connection_options)
    Faraday::Connection.new(host, connection_options).tap do |conn|
      # Is it okay to pass in timeout through options
      conn.adapter @adapter
    end
  end

  def initialize_stoplight
    Stoplight::Light.default_data_store = data_store
  end

  def data_store
    if @redis
      Stoplight::DataStore::Redis.new(redis)
    else
      Stoplight::DataStore::Memory.new
    end
  end

  private

  def generate_stoplight_name(verb, path)
    "#{verb}-light-#{host.gsub(/http(s)?:\/\//,'')}-#{path}".gsub(/[.\/]/,'-')
  end

  def build_path(path, resource_id)
    if resource_id
      path << "/" unless path[-1] == "/"
      "#{path}#{resource_id}"
    else
      path
    end
  end
end
