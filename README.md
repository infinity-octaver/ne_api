# Next Engine Ruby Gem

A Ruby wrapper for the Next Engine API
<http://api.next-e.jp>


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ne_api'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ne_api

## How to Use

please read [API Document](http://api.next-e.jp/).

## Global Environment

CLIENT_ID ....... Get it from Next-Engine's 「アプリを作る」->「API」->「クライアントID」 page
CLIENT_SECRET ... Get it from Next-Engine's 「アプリを作る」->「API」->「クライアントシークレット」 page

## Sample Application

```ruby
require 'ne_api'
require 'sinatra/base'
class MyApp < Sinatra::Base
  enable :sessions
    CLIENT_ID = "XXX"
    CLIENT_SECRET = "XXXX"
    CALLBACK_URI = "https://localhost:3000/callback"
	get "/" do
	  "<a href=" + NeAPI::NE_SERVER_HOST + NeAPI::Auth::SIGN_IN_PATH + "?client_id="+CLIENT_ID+"&redirect_uri="+ CALLBACK_URI + ">Connect with Next Engine</a>"
	end

  get "/callback" do
    auth = NeAPI::Auth.new redirect_url: CALLBACK_URI
    res = auth.ne_auth params[:uid], params[:state], CLIENT_ID, CLIENT_SECRET
    session[:access_token] =  res["access_token"]
    session[:refresh_token] =  res["refresh_token"]
    redirect "/home"
  end

  get "/home" do
    redirect "/" if session[:access_token].nil? || session[:refresh_token].nil?
    html =
	  """
<h2>sample for ne api call</h2>
<ol>
<li><a href='/login_user/info'>Login User Info</a></li>
<li><a href='/login_company/info'>Login Company Info</a></li>
<li><a href='/receiveorder/search'>Login Receive Order Search</a></li>
</ol>
"""
  end

  get "/receiveorder/search" do
    content_type :text
    result = (NeAPI::Master.new(access_token: session["access_token"], refresh_token: session["refresh_token"]).receiveorder_base_search)
	  result.inspect
  end

  get "/login_user/info" do
    content_type :text
    result = (NeAPI::Master.new(access_token: session["access_token"], refresh_token: session["refresh_token"]).login_user_info)
	  update_token result
	  result["data"].first.inspect
  end

  get "/login_company/info" do
    content_type :text
    result = (NeAPI::Master.new(access_token: session["access_token"], refresh_token: session["refresh_token"]).login_company_info)
	  update_token result
	  result["data"].first.inspect
  end

  def update_token res
    session[:access_token] =  res["access_token"]
    session[:refresh_token] =  res["refresh_token"]
  end

end


MyApp.run! host: 'localhost', port: 3000 do |server|

  ssl_options = {
      :verify_peer => false
  }
  server.ssl = true
  server.ssl_options = ssl_options
end

```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/ne_api/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Update
### ver0.0.12
  * 受注伝票一括更新・納品書印刷済み一括更新に対応

### ver0.0.11
  * NEのログイン認証方式に変更

### ver0.0.9
  * リトライすべきエラーメッセージについてリトライするようにした

### ver0.0.8
  * NextEngineのAPIにあわせて、最新の定義を追加

### ver0.0.6
  * Ruby2.2対応
  * リトライ回数のデフォルト値変更
