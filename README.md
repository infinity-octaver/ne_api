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

## Testing Support (RSpec)

ne_api provides built-in stub classes for testing in Rails applications.

### Setup

Add to your `spec/rails_helper.rb`:

```ruby
require 'ne_api/testing'

RSpec.configure do |config|
  config.include NeAPI::Testing::RSpecHelpers
end
```

### Basic Usage

#### Using `with_fake_ne_api` block

```ruby
RSpec.describe OrderSyncService do
  it "syncs orders from Next Engine" do
    with_fake_ne_api do |fake|
      # Stub API responses
      fake.stub(:receiveorder_base_search, [
        ne_receive_order(receive_order_id: "ORDER001", receive_order_total_amount: 5000),
        ne_receive_order(receive_order_id: "ORDER002", receive_order_total_amount: 3000)
      ])

      service = OrderSyncService.new
      result = service.sync

      expect(result.count).to eq 2
      expect(fake.called?(:receiveorder_base_search)).to be true
      expect(fake.call_count(:receiveorder_base_search)).to eq 1
    end
  end
end
```

#### Direct injection (recommended for services with DI)

```ruby
RSpec.describe StockService do
  let(:fake_master) { fake_ne_master }

  before do
    fake_master.stub(:master_stock_search, [
      ne_stock(stock_goods_id: "GOODS001", stock_quantity: 100)
    ])
  end

  it "fetches stock data" do
    service = StockService.new(ne_api: fake_master)
    stocks = service.fetch_all

    expect(stocks.first["stock_quantity"]).to eq 100
  end
end
```

### Simulating Errors

```ruby
it "handles API errors" do
  with_fake_ne_api do |fake|
    fake.simulate_error(code: "001001", message: "Authentication failed")

    expect { service.sync }.to raise_error(NeAPIException, /001001/)
  end
end
```

### Authentication Testing

```ruby
RSpec.describe AuthController do
  it "authenticates user" do
    with_fake_ne_auth do |fake_auth|
      fake_auth.stub_auth_response({
        "access_token" => "custom_access_token",
        "refresh_token" => "custom_refresh_token",
        "company_ne_id" => "NE999999"
      })

      post :callback, params: { uid: "test_uid", state: "test_state" }

      expect(session[:access_token]).to eq "custom_access_token"
    end
  end

  it "handles authentication failure" do
    with_fake_ne_auth do |fake_auth|
      fake_auth.stub_auth_failure

      expect {
        post :callback, params: { uid: "test_uid", state: "test_state" }
      }.to raise_error(NeAPIException)
    end
  end
end
```

### Available Factory Methods

| Method | Description |
|--------|-------------|
| `ne_goods(**attrs)` | Generate goods master data |
| `ne_goods_list(count)` | Generate list of goods |
| `ne_stock(**attrs)` | Generate stock data |
| `ne_stock_list(count)` | Generate list of stocks |
| `ne_receive_order(**attrs)` | Generate receive order data |
| `ne_receive_order_list(count)` | Generate list of orders |
| `ne_receive_order_row(**attrs)` | Generate order row data |
| `ne_shop(**attrs)` | Generate shop data |
| `ne_warehouse_stock(**attrs)` | Generate warehouse stock data |
| `ne_company_info(**attrs)` | Generate company info |
| `ne_user_info(**attrs)` | Generate user info |
| `ne_error(code:, message:)` | Generate error response |

### FakeMaster Methods

| Method | Description |
|--------|-------------|
| `stub(method_name, response)` | Stub a specific API method |
| `simulate_error(code:, message:)` | Enable error mode |
| `clear_error` | Disable error mode |
| `reset!` | Clear all stubs and history |
| `called?(method_name)` | Check if method was called |
| `call_count(method_name)` | Get call count |
| `last_call_args(method_name)` | Get last call arguments |

### Service Design for Testability

For best testability, design your services to accept `ne_api` as a dependency:

```ruby
class OrderSyncService
  def initialize(ne_api: nil)
    @ne_api = ne_api || NeAPI::Master.new(
      access_token: Rails.application.credentials.ne_access_token,
      refresh_token: Rails.application.credentials.ne_refresh_token
    )
  end

  def sync
    @ne_api.receiveorder_base_search
  end
end
```

This allows easy injection of `FakeMaster` in tests.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/ne_api/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Update
### ver0.0.18
  * 受注税金内訳取得APIに対応
### ver0.0.17
  * セット在庫系APIに対応
### ver0.0.16
  * セット系APIに対応
### ver0.0.15
  * 商品ページ系APIに対応
### ver0.0.14
  * 受注伝票一括更新・納品書印刷済みの対応の修正

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
