require 'oauth'
require 'faraday'
require 'yaml'
require 'json'
require 'active_support'
require 'active_support/core_ext'
require 'dotenv'
require 'launchy'


module NeAPI
  class Auth
    include NeAPI
    attr_accessor :redirect_url, :ne_user
    
    def initialize redirect_url: nil
      raise NeAPIException, "リダイレクトURL(redirect_url)が設定されていません" if redirect_url.nil?
      @redirect_url = redirect_url
    end

    #uid/state取得
    def sign_in client_id = ENV["CLIENT_ID"] , client_secret = ENV["CLIENT_SECRET"]
      ::Launchy.open NeAPI.options[:ne_server_host] + NeAPI.options[:sign_in_path] + "?client_id="+client_id+"&client_secret="+client_secret+"&redirect_uri="+@redirect_url
    end
    
    #access_token/企業情報取得
    def ne_auth uid, state
      @ne_user = response ( conn.post NeAPI.options[:ne_auth_path], {uid: uid, state: state})
      raise NeAPIException, "003001:Next Engineが大変混み合っているようです" if @ne_user == false
      @ne_user
    end
    def tokens
      @ne_user.nil? ?  nil : {access_token: @ne_user["access_token"], refresh_token: @ne_user["refresh_token"]}
    end
  end
end
