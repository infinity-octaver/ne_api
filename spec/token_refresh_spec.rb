require 'ne_api'

# 実APIには接続せず、Faraday のテストアダプタで応答を差し替える
describe 'トークンの取り込みとエラー' do
  def connection(responses, requests = [])
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post(%r{\A/api_v1_}) do |env|
        requests << Faraday::Utils.parse_query(env.body)
        [200, {}, JSON.generate(responses.shift)]
      end
    end
    Faraday.new { |f| f.request :url_encoded; f.adapter :test, stubs }
  end

  let(:master) do
    NeAPI::Master.new(access_token: "a0", refresh_token: "r0").tap { |m| m.wait_interval = 0; m.retry_num = 3 }
  end
  let(:tokens) { { "access_token" => "a1", "refresh_token" => "r1", "access_token_end_date" => "2026-11-20 00:00:00", "refresh_token_end_date" => "2026-11-22 00:00:00" } }

  after { NeAPI.connection = nil }

  it '成功応答のトークンを取り込み、on_token_refresh を呼ぶ' do
    NeAPI.connection = connection([{ "result" => "success", "data" => [] }.merge(tokens)])
    seen = []
    master.on_token_refresh = ->(m, body) { seen << [m.access_token, body["result"]] }
    expect(master.master_shop_search(fields: "shop_id")).to eq([])
    expect([master.access_token, master.refresh_token, master.refresh_token_end_date]).to eq(["a1", "r1", "2026-11-22 00:00:00"])
    expect(seen).to eq([["a1", "success"]])
  end

  it 'エラー応答でもトークンを取り込んでから例外を上げる' do
    NeAPI.connection = connection([{ "result" => "error", "code" => "020006", "message" => "更新されています" }.merge(tokens)])
    seen = []
    master.on_token_refresh = ->(m, _body) { seen << m.access_token }
    expect { master.receiveorder_base_update(params: { receive_order_id: 1 }) }.to raise_error(NeAPIException) { |e|
      expect(e.code).to eq("020006")
      expect(e.message).to eq("020006:更新されています")
      expect(e.response["message"]).to eq("更新されています")
    }
    expect(master.access_token).to eq("a1")
    expect(seen).to eq(["a1"])
  end

  it '混雑エラーは再試行し、再試行には更新後のトークンを使う' do
    requests = []
    NeAPI.connection = connection([{ "result" => "error", "code" => "003002", "message" => "busy" }.merge(tokens),
                                   { "result" => "success", "count" => "5" }], requests)
    expect(master.master_shop_count).to eq("5")
    expect(requests.map { |r| r["access_token"] }).to eq(["a0", "a1"])
  end

  it '混雑が続いたら 003001 の例外' do
    NeAPI.connection = connection(Array.new(3) { { "result" => "error", "code" => "003002", "message" => "busy" } })
    expect { master.master_shop_count }.to raise_error(NeAPIException) { |e| expect(e.code).to eq("003001") }
  end

  describe '後方互換（既存アプリの呼び出し方）' do
    it 'search は data、count は count、update は result、info はボディ全体を返す' do
      NeAPI.connection = connection([
        { "result" => "success", "data" => [{ "shop_id" => "1" }] },
        { "result" => "success", "count" => "3" },
        { "result" => "success" },
        { "result" => "success", "data" => [{ "company_id" => "c" }] }
      ])
      expect(master.master_shop_search(fields: "shop_id", query: { "shop_deleted_flag-eq" => 0 })).to eq([{ "shop_id" => "1" }])
      expect(master.receiveorder_base_count(query: { "receive_order_id-eq" => 1 })).to eq("3")
      expect(master.receiveorder_base_update(params: { receive_order_id: 1, data: "<root/>" })).to eq("success")
      expect(master.login_company_info["data"].first["company_id"]).to eq("c")
      expect(master.access_token).to eq("a0") # 応答にトークンが無ければ変わらない
    end

    it 'query・fields・params・wait_flag の送り方は変わらない' do
      requests = []
      NeAPI.connection = connection([{ "result" => "success", "data" => [] }], requests)
      master.force_import
      master.receiveorder_base_search(fields: "receive_order_id", query: { "receive_order_id-in" => "1,2" }, params: { offset: 10 })
      expect(requests.first).to eq("access_token" => "a0", "refresh_token" => "r0", "fields" => "receive_order_id",
                                   "receive_order_id-in" => "1,2", "offset" => "10", "wait_flag" => "1")
    end

    it 'フックを設定しなくても動き、例外は従来どおり NeAPIException でメッセージは "コード:メッセージ"' do
      NeAPI.connection = connection([{ "result" => "error", "code" => "004002", "message" => "fieldsが不正です" }])
      expect { master.master_shop_search(fields: "x") }.to raise_error(NeAPIException, "004002:fieldsが不正です")
      expect { raise NeAPIException, "plain" }.to raise_error(NeAPIException, "plain")
      expect { raise NeAPIException }.to raise_error(NeAPIException)
    end

    it 'トークンが無ければ従来どおり no token!' do
      expect { NeAPI::Master.new(access_token: nil, refresh_token: nil).master_shop_count }.to raise_error(NeAPIException, "no token!")
    end

    it 'テスト用スタブ FakeMaster の使い方も変わらない' do
      require 'ne_api/testing'
      fake = NeAPI::Testing::FakeMaster.new.stub(:master_shop_search, [{ "shop_id" => "1" }])
      expect(fake.master_shop_search).to eq([{ "shop_id" => "1" }])
      fake.simulate_error(code: "001001", message: "認証エラー")
      expect { fake.master_shop_search }.to raise_error(NeAPIException, "001001:認証エラー")
    end
  end

  it '従来どおりメッセージだけで生成した例外からもコードを引ける' do
    expect(NeAPIException.new("002004:expired").code).to eq("002004")
    expect(NeAPIException.new("no token!").code).to be_nil
  end
end
