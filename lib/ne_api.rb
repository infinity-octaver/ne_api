require 'oauth'
require 'faraday'
require 'yaml'
require 'json'
require 'active_support'
require 'active_support/core_ext'
require 'dotenv'
require 'recommendify'

module NeAPI
  API_SERVER_HOST = "https://api.next-engine.org"
  NE_SERVER_HOST = "https://base.next-engine.org"

  private

  
  def conn
    @conn ||=  Faraday.new(:url => API_SERVER_HOST) do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      faraday.options[:timeout] =  600
    end
  end

  def response response
    body = JSON.parse response.body
    if body["result"] != "success"
      if ["003001","003002","008003","009005","011007"].include?(body["code"])
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
    attr_accessor :access_token, :refresh_token, :wait_flag, :retry_num, :wait_interval, :access_token_end_date, :refresh_token_end_date
    PATH_PREFIX="/api_v1_"

    def initialize access_token: "", refresh_token: ""
      @@params = YAML.load_file(File.join(File.dirname(__FILE__),"../config/api.yaml"))
      @access_token = access_token
      @refresh_token = refresh_token
      @wait_flag = false
      @retry_num = 10
      @wait_interval = 15
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
      
      self.retry_num.times do
        res =response(conn.post PATH_PREFIX+model.to_s+ "/" + method, post_args)
        break if res != false
        sleep(self.wait_interval)
      end
      if res == false
        raise NeAPIException,  "003001:Next Engineが大変混み合っています。APIの接続を#{self.retry_num}回、#{self.wait_interval}秒間隔でアクセスを試みましたが、失敗をしました"
        return false
      end
      
      @access_token = res["access_token"] if res["access_token"].present?
      @refresh_token = res["refresh_token"] if res["refresh_token"].present?
      @access_token_end_date  = res["access_token_end_date"] if res["access_token_end_date"].present?
      @refresh_token_end_date  = res["refresh_token_end_date"] if res["refresh_token_end_date"].present?

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
      raise NeAPIException, "003001:Next Engineが大変混み合っているようです" if @ne_user == false
      @ne_user
    end
    def tokens
      @ne_user.nil? ?  nil : {access_token: @ne_user["access_token"], refresh_token: @ne_user["refresh_token"]}
    end
  end

  class MyRecommender < Recommendify::Base
      max_neighbors 50
      input_matrix :order_items, {:similarity_func => :jaccard, :weight => 5.0}

    include NeAPI
    def initialize
      Recommendify.redis = Redis.new
      super
    end
    def recommend product_id: product_id, access_token: access_token, refresh_token: refresh_token
      raise NeAPIException, "no product_id" if product_id.nil?
      m=Master.new access_token: access_token, refresh_token: access_token
      orders=m.receiveorder_row_search(fields: "receive_order_row_receive_order_id", "receive_order_row_goods_id-like" => product_id.to_s).collect{|o| o["receive_order_row_receive_order_id"].to_i} #その商品を含む注文全ての伝票番号
      users=m.receiveorder_base_search(fields: "receive_order_customer_id", "receive_order_id-in" => orders.uniq.inspect.delete("[]")).collect{|c| c["receive_order_customer_id"]} #その商品を買った顧客ID
      #users.each {|u| order_items.add_set(u, m.receiveorder_row_search(fields: "receive_order_row_goods_id", "receive_order_row_receive_order_id-in" => (m.receiveorder_base_search(fields: "receive_order_id", "receive_order_customer-like" => u).collect{|g| g["receive_order_id"]}).inspect.delete("[]")))}
      process_item!(product_id.to_s)
      self.for(product_id.to_s)
    end
  end
end
class NeAPIException  < StandardError
end

