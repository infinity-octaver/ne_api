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
      @@params = YAML.load_file(File.join(File.dirname(__FILE__),"../config/api.yaml"))
      @access_token = access_token
      @refresh_token = refresh_token
    end

    def post method: nil , model: nil, get_key: nil, params: {}
      raise NeAPIException, "no token!" if @access_token.nil? || @refresh_token.nil?
      if params.key?(:query)
        query=params[:query]
        params.delete(:query)
        res =response(conn.post PATH_PREFIX+model.to_s+ "/" + method, {access_token: @access_token, refresh_token: @refresh_token}.merge(query).merge(params))
      else
        res =response(conn.post PATH_PREFIX+model.to_s+ "/" + method, {access_token: @access_token, refresh_token: @refresh_token}.merge(params))
      end
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
        params = (args[:params].present? ? args[:params] : {})
        params[:wait_flag] = args[:wait_flag] if args[:wait_flag].present?
        case method
        when "info"
        when  "count"
          get_key = "count"
          req= @@params[model]
          params[:query] = (args[:query].present? ? args[:query] : req[:query])
          params[:query] ||= {}
        when "search"
          get_key = "data"
          req= @@params[model]
          params[:query] = (args[:query].present? ? args[:query] : req[:query])
          params[:query] ||= {}
          default_fields = req[:fields].gsub(/^\s*/,req[:prefix]+"_").gsub(/,\s*/,","+@@params[model][:prefix]+"_")
          params[:fields] = (args[:fields].present? ? args[:fields] : default_fields)
          params[:offset] = args[:offset] if args[:offset].present?
          params[:limit] = args[:limit] if args[:limit].present?
        when "update"
          get_key = result
          if(model == receiveorder_base)
            raise NeAPIException, "too few parameters" unless args[:receive_order_id].present? && args[:receive_order_last_modified_date].present? && args[:data].present?
            params[:receive_order_id] = args[:receive_order_id]
            params[:receive_order_last_modified_date] = args[:receive_order_last_modified_date]
            params[:data] = args[:data]
            params[:receive_order_shipped_update_flag] = args[:receive_order_shipped_update_flag] if args[:receive_order_shipped_update_flag].present?
          else
            raise NeAPIException, "too few parameters" unless args[:shop_id].present? && args[:shop_last_modified_date].present? && args[:data].present?
            params[:shop_id] = args[:shop_id]
            params[:shop_last_modified_date] = args[:shop_last_modified_date]
            params[:data] = args[:data]
          end
        when "upload"
          if(model == "receiveorder_base")
            raise NeAPIException, "too few parameters" unless args[:receive_order_upload_pattern_id].present? && args[:data_type_1].present? && args[:data_1].present?
            params[:receive_order_upload_pattern_id] = args[:receive_order_upload_pattern_id]
            params[:data_type_1] = args[:data_type_1]
            params[:data_1] = args[:data_1]
            params[:data_type_2] = args[:data_type_2] if args[:data_type_2].present?
            params[:data_2] = args[:data_2] if args[:data_2].present?
          else
            raise NeAPIException, "too few parameters" unless args[:receive_order_upload_pattern_id].present? && args[:data_type_1].present? && args[:data_1].present?
            params[:data_type] = args[:data_type]
            params[:data] = args[:data]
          end
        when "receipted", "shipped", "labelprinted"
          get_key = "result"
          raise NeAPIException, "too few parameters" unless args[:receive_order_id].present? && args[:receive_order_last_modified_date].present?
          params[:receive_order_id] = args[:receive_order_id]
          params[:receive_order_last_modified_date] = args[:receive_order_last_modified_date]
          params[:receive_order_label_print_flag] = args[:receive_order_label_print_flag] if args[:receive_order_label_print_flag].present?
        when "divide"
          get_key = "receive_order_id"
          raise NeAPIException, "too few parameters" unless args[:receive_order_id].present? && args[:receive_order_last_modified_date].present? && args[:data].present?
          params[:receive_order_id] = args[:receive_order_id]
          params[:receive_order_last_modified_date] = args[:receive_order_last_modified_date]
          params[:data] = args[:data]
          params[:credit_unauthorized_flag] = args[:credit_unauthorized_flag] if args[:credit_unauthorized_flag].present?
        else
          super
        end
        self.post method: method, model: model, get_key: get_key, params: params
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

