require 'oauth'
require 'faraday'
require 'yaml'
require 'json'
require 'active_support'
require 'active_support/core_ext'
require 'dotenv'

module NeAPI
  class Master
    include NeAPI
    attr_accessor :access_token, :refresh_token, :wait_flag, :retry_num, :wait_interval
    PATH_PREFIX="/api_v1_"

    def initialize access_token: "", refresh_token: ""
      @@params = YAML.load_file(File.join(File.dirname(__FILE__),"../../config/api.yaml"))
      @access_token = access_token
      @refresh_token = refresh_token
    end

    def force_import
      @wait_flag = true
    end
    def hoge
      @access_token = "hoge"
    end
    
    def post method: nil , model: nil, query: {}, fields: nil, get_key: nil, params: {}
      raise NeAPIException, "no token!" if @access_token.nil? || @refresh_token.nil?
      params = params.merge({wait_flag: 1}) if @wait_flag
      post_args = {access_token: @access_token, refresh_token: @refresh_token}.merge(query).merge(params)
      post_args = post_args.merge(fields: fields) unless fields.nil?
      res = false
      
      NeAPI.options[:retry_num].times do
        res =response(conn.post PATH_PREFIX+model.to_s+ "/" + method, post_args)
        break if res != false
        sleep(NeAPI.options[:wait_interval])
      end
      if res == false
        raise NeAPIException,  "003001:Next Engineが大変混み合っています。APIの接続を#{NeAPI.options[:retry_num]}回、#{NeAPI.options[:wait_interval]}秒間隔でアクセスを試みましたが、失敗をしました"
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
end
