require 'oauth'
require 'faraday'
require 'yaml'
require 'json'
require 'active_support'
require 'active_support/core_ext'
require 'dotenv'

module NeAPI
  API_SERVER_HOST = "https://api.next-engine.org"
  NE_SERVER_HOST = "https://base.next-engine.org"

  private
  def conn
    @conn ||= Faraday::Connection.new(url: API_SERVER_HOST) do |builder|
      builder.use Faraday::Request::UrlEncoded
      builder.use Faraday::Response::Logger
      builder.use Faraday::Adapter::NetHttp
    end
  end

  def response response
    body = JSON.parse response.body
    if body["result"] != "success"
      raise NeAPIException,  body["message"]
      return false
    end
    body
  end

  class Master
    include NeAPI
    attr_accessor :access_token, :refresh_token
    PATH_PREFIX="/api_v1_"

    def initialize access_token: access_token, refresh_token: refresh_token
      @@params = YAML.load_file("config/api.yaml")
      @access_token = access_token
      @refresh_token = refresh_token
    end

    def post method: nil , model: nil, query: nil, fields: nil, get_key: nil
      raise NeAPIException, "no token!" if @access_token.nil? || @refresh_token.nil?
      if fields.present?
        res =response(conn.post PATH_PREFIX+model.to_s+ "/" + method, {access_token: @access_token, refresh_token: @refresh_token, fields: fields}.merge(query))
      elsif query.present?
        res =response(conn.post PATH_PREFIX+model.to_s+ "/" + method, {access_token: @access_token, refresh_token: @refresh_token}.merge(query))
      else
        res =response(conn.post PATH_PREFIX+model.to_s+ "/" + method, {access_token: @access_token, refresh_token: @refresh_token})
      end
      get_key.present? ? res[get_key]  : res
    end
    def method_missing(path, query={})
      super if @@params.nil? || path.nil?
      unless models = /^(.*)_.*$/.match(path.to_s)
        super
      end
      model = models.captures.first.to_sym
      method = path.to_s.split("_").last

      if @@params.key?(model) && @@params[model][:method].include?(method)
        get_key = nil
        fields = nil
        case method
        when  "count"
          query = nil
          get_key = "count"
        when "search"
          req= @@params[model]
          query ||= req[:query]
          fields=req[:fields].gsub(/^\s*/,req[:prefix]+"_").gsub(/,\s*/,","+@@params[model][:prefix]+"_")
          get_key = "data"
        when "info"
          query = nil
        when "update", "upload", "receipted", "shipped", "labelprinted"
          get_key = "result"
        when "divide"
          get_key = "receive_order_id"
        else
          super
        end
        self.post method: method, model: model, query: query, fields: fields, get_key: get_key
      else
        super
      end
    end
  end

  class Auth
    include NeAPI
    SIGN_IN_PATH = "/users/sign_in/"
    NEAUTH_PATH = "/api_neauth/"
    attr_accessor :redirect_url, :ne_user
    
    def initialize redirect_url: nil
      Dotenv.load
      raise NeAPIException, "no redirect_url" if redirect_url.nil?
      @redirect_url = redirect_url
    end

    #uid/state取得
    def sign_in client_id = ENV["CLIENT_ID"] , client_secret = ENV["CLIENT_SECRET"]
      Launchy.open NE_SERVER_HOST + SIGN_IN_PATH + "?client_id="+client_id+"&client_secret="+client_secret+"&redirect_uri="+@redirect_url
    end
    
    #access_token/企業情報取得
    def ne_auth client_id = ENV["CLIENT_ID"] , client_secret = ENV["CLIENT_SECRET"]
      @ne_user = response ( conn.post NEAUTH_PATH, {uid: uid, state: state})
      @ne_user
    end
    def tokens
      @ne_user.nil? ?  nil : {access_token: @ne_user["access_token"], refresh_token: @ne_user["refresh_token"]}
    end
  end
end
class NeAPIException  < StandardError
end

