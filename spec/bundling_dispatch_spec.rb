# 同梱系API追加(v0.0.23)に伴う method_missing ディスパッチの検証。
# 実APIには接続せず、post を差し替えて model / method / get_key の解決のみを検証する。
#
# 実行: rspec spec/bundling_dispatch_spec.rb  (bundle exec 不要 / グローバルgem使用)

require_relative "../lib/ne_api"

RSpec.describe NeAPI::Master do
  subject(:master) { described_class.new(access_token: "a", refresh_token: "r") }

  # post を差し替え、method_missing が組み立てた引数をそのまま返させる
  before do
    allow(master).to receive(:post) { |**kwargs| kwargs }
  end

  describe "既存メソッドのディスパッチ(後方互換)" do
    it "receiveorder_base_search は search に解決される" do
      result = master.receiveorder_base_search
      expect(result).to include(model: :receiveorder_base, method: "search", get_key: "data")
    end

    it "件数取得は count / get_key=count に解決される" do
      expect(master.receiveorder_base_count).to include(method: "count", get_key: "count")
    end

    it "info系は info / get_key=nil に解決される" do
      expect(master.login_company_info).to include(model: :login_company, method: "info", get_key: nil)
    end

    it "一括更新は bulkupdate / get_key=result に解決される" do
      expect(master.receiveorder_base_bulkupdate).to include(method: "bulkupdate", get_key: "result")
    end
  end

  describe "モデル名の前方一致が曖昧なケースの解決" do
    it "master_goods_search は master_goods に解決される" do
      expect(master.master_goods_search).to include(model: :master_goods, method: "search")
    end

    it "master_goods_page_search はより長い master_goods_page に解決される" do
      expect(master.master_goods_page_search).to include(model: :master_goods_page, method: "search")
    end

    it "master_goods_page_variation_search は最長一致の master_goods_page_variation に解決される" do
      expect(master.master_goods_page_variation_search)
        .to include(model: :master_goods_page_variation, method: "search")
    end
  end

  describe "同梱系API(v0.0.23 で追加)" do
    it "receiveorder_base_bundle は bundle / get_key=results に解決される" do
      result = master.receiveorder_base_bundle(params: { data: "[]", receive_order_recalculate_flag: 1 })
      expect(result).to include(model: :receiveorder_base, method: "bundle", get_key: "results")
    end

    it "bundle は params をそのまま post へ渡す" do
      params = { data: "[{\"receive_order_id\":\"1\"}]", receive_order_recalculate_flag: 1 }
      expect(master.receiveorder_base_bundle(params: params)).to include(params: params)
    end

    it "複数語メソッド bundle_candidate_groups が groups に解決される" do
      result = master.receiveorder_base_bundle_candidate_groups(params: { target_receive_order_ids: "1,2,3" })
      expect(result).to include(
        model: :receiveorder_base,
        method: "bundle_candidate_groups",
        get_key: "groups"
      )
    end

    it "receiveorder_groupingtag_search は新規モデルとして search に解決される" do
      result = master.receiveorder_groupingtag_search
      expect(result).to include(model: :receiveorder_groupingtag, method: "search", get_key: "data")
    end

    it "groupingtag_search はデフォルトfieldsに grouping_tag_ プレフィックスを付与する" do
      expect(master.receiveorder_groupingtag_search[:fields]).to start_with("grouping_tag_id,")
    end
  end

  describe "未定義メソッド" do
    it "存在しないAPIは NoMethodError を送出する" do
      expect { master.nonexistent_foo }.to raise_error(NoMethodError)
    end

    it "存在するモデルでも未定義のメソッドは NoMethodError を送出する" do
      # receiveorder_groupingtag は search のみ。update は未定義。
      expect { master.receiveorder_groupingtag_update }.to raise_error(NoMethodError)
    end
  end
end
