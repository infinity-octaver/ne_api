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
      if self.wait_flag && (body["code"] == "003001" || body["code"] == "003002")
        return false
      else
        raise NeAPIException,  sprintf("%s:%s", body["code"], body["message"])
      end
      return false
    end
    body
  end

  class Master
    include NeAPI
    attr_accessor :access_token, :refresh_token, :wait_flag
    PATH_PREFIX="/api_v1_"

    def initialize access_token: access_token, refresh_token: refresh_token
      @@params = YAML.load_file(File.join(File.dirname(__FILE__),"../config/api.yaml"))
      @access_token = access_token
      @refresh_token = refresh_token
      @wait_flag = false
    end

    def force_import
      @wait_flag = true
    end

    def update_token
      
    end
    
    
    def post method: nil , model: nil, query: nil, fields: nil, get_key: nil, params: {}
      raise NeAPIException, "no token!" if @access_token.nil? || @refresh_token.nil?
      params = params.merge({wait_flag: 1}) if @wait_flag
      
      if fields.present? && query.present?
        post_args = {access_token: @access_token, refresh_token: @refresh_token, fields: fields}.merge(query).merge(params)

      elsif fields.present?
        post_args =  {access_token: @access_token, refresh_token: @refresh_token, fields: fields}.merge(params)
      elsif query.present?
        post_args = {access_token: @access_token, refresh_token: @refresh_token}.merge(query).merge(params)
      else
        post_args = {access_token: @access_token, refresh_token: @refresh_token}.merge(params)
      end
      res = false
      
      30.times do
        res =response(conn.post PATH_PREFIX+model.to_s+ "/" + method, post_args)
        break if res != false
        sleep(3)
      end
      if res == false
        raise NeAPIException,  "Next Engineが大変混み合っているようです"
        return false
      end
      
      @access_token = res["access_token"] if res["access_token"].present?
      @refresh_token = res["refresh_token"] if res["refresh_token"].present?

      get_key.present? ? res[get_key]  : res
    end
    def method_missing(path, args={})
      super if @@params.nil? || path.nil?
      unless models = /^(.*)_.*$/.match(path.to_s)
        super
      end
      model = models.captures.first.to_sym
      method = path.to_s.split("_").last

      if @@params.key?(model) && @@params[model][:method].include?(method)
        get_key = nil
        query = (args[:query].present? ? args[:query] : nil)
        fields = (args[:fields].present? ? args[:fields] : nil)
        params = (args[:params].present? ? args[:params] : {})
        case method
        when  "count"
          get_key = "count"
        when "search"
          req= @@params[model]
          query ||= req[:query]
          fields ||= req[:fields].gsub(/^\s*/,req[:prefix]+"_").gsub(/,\s*/,","+@@params[model][:prefix]+"_")
          fields= fields
          get_key = "data"
        when "info"
          query = nil
        when "update", "upload", "receipted", "shipped", "labelprinted"
          get_key = "result"
        when "divide"
          get_key = "receive_order_id"
        when "checkconnect"
          fields = nil
          get_key = nil
        else
          super
        end
        self.post method: method, model: model, query: query, fields: fields, get_key: get_key, params: params
      else
        super
      end
    end
  end

  class Auth
    include NeAPI
    SIGN_IN_PATH = "/users/sign_in/"
    NEAUTH_PATH = "/api_neauth/"
    attr_accessor :redirect_url, :ne_user, :wait_flag
    
    def initialize redirect_url: nil
      raise NeAPIException, "no redirect_url" if redirect_url.nil?
      @wait_flag = false
      @redirect_url = redirect_url
    end

    #uid/state取得
    def sign_in client_id = ENV["CLIENT_ID"] , client_secret = ENV["CLIENT_SECRET"]
      Launchy.open NE_SERVER_HOST + SIGN_IN_PATH + "?client_id="+client_id+"&client_secret="+client_secret+"&redirect_uri="+@redirect_url
    end
    
    #access_token/企業情報取得
    def ne_auth uid, state
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

