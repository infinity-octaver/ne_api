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

      # path を「モデル名_メソッド名」に分解する。
      # 旧実装は最後の "_" で分割していたが、bundle_candidate_groups のような
      # 複数語メソッドに対応できなかった。登録済みモデル名との前方一致(最長一致優先)で
      # 解決することで、単語数によらず正しい model / method を取り出す。
      # 単一語メソッドでは旧実装と同じ結果になるため後方互換。
      model = nil
      method = nil
      @@params.keys.sort_by { |key| -key.to_s.length }.each do |key|
        prefix = "#{key}_"
        next unless path.to_s.start_with?(prefix)
        candidate = path.to_s[prefix.length..-1]
        next unless @@params[key][:method].include?(candidate)
        model = key
        method = candidate
        break
      end

      if model
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
        when "update", "upload", "receipted", "shipped", "labelprinted", "add", "bulkupdate", "bulkupdatereceipted"
          get_key = "result"
        when "divide"
          get_key = "receive_order_id"
        when "bundle"
          # 受注伝票一括同梱: ジョブ毎の結果配列(results)を返す
          get_key = "results"
        when "bundle_candidate_groups"
          # 同梱候補グループ取得: 同梱可能な受注番号配列の配列(groups)を返す
          get_key = "groups"
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
      Launchy.open NE_SERVER_HOST + SIGN_IN_PATH + "?client_id="+client_id+"&redirect_uri="+@redirect_url
    end
    
    #access_token/企業情報取得
    def ne_auth uid, state, client_id = ENV["CLIENT_ID"], client_secret = ENV["CLIENT_SECRET"]
      @ne_user = response ( conn.post NEAUTH_PATH, {uid: uid, state: state, client_id: client_id, client_secret: client_secret})
      raise NeAPIException, "003001:Next Engineが大変混み合っているようです" if @ne_user == false
      @ne_user
    end
    def tokens
      @ne_user.nil? ?  nil : {access_token: @ne_user["access_token"], refresh_token: @ne_user["refresh_token"]}
    end
  end
end
class NeAPIException  < StandardError
end

