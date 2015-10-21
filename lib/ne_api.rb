require 'oauth'
require 'faraday'
require 'yaml'
require 'json'
require 'active_support'
require 'active_support/core_ext'
require 'dotenv'

require 'ne_api/master'
require 'ne_api/auth'

module NeAPI
  attr_accessor :options, :logger
  DEFAULTS = {
    api_server_host: "https://api.next-engine.org",
    ne_server_host: "https://base.next-engine.org",
    sign_in_path: "/users/sign_in/",
    neauth_path: "/api_neauth/",
    retry_num: 10,
    wait_interval: 15
  }
  class << self
    def configure
      @options ||= DEFAULTS.dup
      yield self if block_given?
    end
    def options
      @options ||= DEFAULTS.dup
    end

    def options=(opts)
      @options = opts
    end

  end
  
  private
  def conn
    @conn ||= Faraday::Connection.new(url: NeAPI.options[:api_server_host]) do |builder|
      builder.use Faraday::Request::UrlEncoded
      builder.use Faraday::Response::Logger
      builder.use Faraday::Adapter::NetHttp
    end
  end

  def response response
    body = JSON.parse response.body
    if body["result"] != "success"
      if (body["code"] == "003001" || body["code"] == "003002")
        return false
      else
        raise NeAPIException,  sprintf("%s:%s", body["code"], body["message"])
      end
      return false
    end
    body
  end
end
class NeAPIException  < StandardError
end

