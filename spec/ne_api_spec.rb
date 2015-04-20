require 'yaml'
require '../ne_api/lib/ne_api.rb'

describe 'searchAPI' do
  before(:all) do
    @methods=["receiveorder_base", "receiveorder_row", "receiveorder_forwardingagent", "receiveorder_confirm", "master_goods", "master_stock", "master_mailtag", "master_goodstag", "master_supplier", "master_wholesale", "master_stockiohistory", "master_pagebase", "master_pagebasevariationoroption", "master_shop", "master_goodsimage", "master_goodsimagetag", "master_goodscategory", "system_que", "system_mall", "system_imagetag", "system_mallcategory"]
    @params =YAML.load_file("config/api.yaml")
    @access_toen="14c8e8a908b77eb7250bcffe2d65df1b78010bea99b285538878bd7c03a74b14a5b6f4d24ec62b3780c03b2f8243df94da8f3b9b0ae1d943c5e5917d37aff5b7"
    @refresh_token="c9de551f7398fb7ed36c6b15bb3de67b263bf38e46532ebfa51f80ddac10fd0e27d40469bceb7661185f88fbc41063dad00afc2a0da0c254cfa4079acfb97cb4"
    #auth = NeAPI::Auth.new
    #auth.sign_in
    #@user=auth.api_neauth
    @master = NeAPI::Master.new 
    @master.access_token=@access_token
    @master.refresh_token=@refresh_token
  end
  context '全てのメソッドについて' do
    it '存在する' do
      ret=true
      @methods.each {|m| ret=false unless @master.send(m.to_s+"_search")}
      expect(ret).to be_true
    end
  end
  context 'master_goods_searchについて' do
    context 'フィールド指定がない場合' do
      it 'デフォルトで指定したフィールドの情報が返ってくる' do
        ret=true
        @params[:master_goods][:fields].each {|f| ret=false unless (@master.send("master_goods_search")).first.has_key?(@params[m][:prefix]+f)}
        expect(ret).to be_true
      end
    end
    context 'フィールド指定がある場合' do
      context 'フィールド名が正しい' do
        it 'デフォルトで指定したフィールドと，引数で与えたフィールドの情報が返ってくる' do
          ret=true
          @params[:master_goods][:fields].push("delete_flag").each {|f| ret=false unless (@master.send("master_goods_search", {fields: "delete_flag"})).first.has_key?(@params[m][:prefix]+f)}
          expect(ret).to be_true
        end
        context 'フィールド名が間違っている' do
          it 'エラーが返される' do
            expect(@master.send("master_goods_search", {fields: "invalid_field"})).to raise_error
          end
        end
      end
      context 'フィールドの検索条件がある場合' do
        context '存在しないフィールドである' do
          it 'エラーが返される' do
            expect(@master.send("master_goods_search", {invalid_field: "hoge"})).to raise_error
          end
        end
        context '検索条件が正しい' do
          context '検索の結果が1件ある' do
            it '1件のデータが返される' do
              expect(@master.send("master_goods_search", {goods_id: "1"})).count.to be(1)
            end
            it 'デフォルトで指定したフィールドの情報が返ってくる' do
              ret=true
              @params[:master_goods][:fields].each {|f| ret=false unless (@master.send("master_goods_search")).first.has_key?(@params[m][:prefix]+f)}
              expect(ret).to be_true
            end
          end
          context '検索の結果が0件' do
            it '空の配列が返される' do
              expect(@master.send("master_goods_search", {goods_name: "invalid name"})).to be_empty
            end
          end
        end
      end
    end
  end
end
describe 'countAPI' do
    @methods=["receiveorder_base", "receiveorder_row", "receiveorder_forwardingagent", "receiveorder_confirm", "master_goods", "master_stock", "master_mailtag", "master_goodstag", "master_supplier", "master_wholesale", "master_stockiohistory", "master_pagebase", "master_pagebasevariationoroption", "master_shop", "master_goodsimage", "master_goodsimagetag", "master_goodscategory", "system_que", "system_mall", "system_imagetag", "system_mallcategory"]
    @params=YAML.load_file("config/api.yaml")
    @access_toen="14c8e8a908b77eb7250bcffe2d65df1b78010bea99b285538878bd7c03a74b14a5b6f4d24ec62b3780c03b2f8243df94da8f3b9b0ae1d943c5e5917d37aff5b7"
    @refresh_token="c9de551f7398fb7ed36c6b15bb3de67b263bf38e46532ebfa51f80ddac10fd0e27d40469bceb7661185f88fbc41063dad00afc2a0da0c254cfa4079acfb97cb4"
    @master = NeAPI::Master.new @access_token, @refresh_token
  context '全てのメソッドについて' do
    it '存在する' do
      ret=true
      @methods.each {|m| ret=false unless @master.send(m.to_s+"_count")}
      expect(ret).to be_true
    end
  end
  context 'master_goods_countについて' do
    context 'フィールドの検索条件がない場合' do
      it '返り値は1以上の数字' do
        expect(@master.send("master_goods_count")).to match(/\d+/)
      end
    end
    context 'フィールドの検索条件がある場合' do
      context '検索条件が正しくて，1件のみを返す' do
        it '返り値は1' do
          expect(@master.send("master_goods_count", {id: 1})).count.to be(1)
        end
        context '検索の結果が0件' do
          it '0が返される' do
            expect(@master.send("master_goods_count", {id: 0})).count.to be(0)
          end
        end
        context '存在しないフィールドである' do
          it 'エラーが返される' do
            expect(@master.send("master_goods_count", {invalid_field: "invalid"})).to raise_error
          end
        end
      end
    end
  end
end
describe 'infoAPI' do
  @methods=["login_user", "login_company", "system_credittype", "system_creditauthorizationcenter", "system_creditapprovaltype", "system_order", "system_ordercondition", "system_delivery", "system_fraction", "system_returnedreason", "system_canceltype", "system_orderstatus", "system_importantcheck", "system_confirmcheck", "system_customertype", "system_deposittype", "system_iotype", "system_select", "system_paymentmethod", "system_payout", "system_socialinsurance", "system_goodstype", "system_goodsstatus", "system_merchandise", "system_importtype", "system_forwardingmethod", "system_tax", "system_itemname", "system_pagestatus", "receiveorder_uploadpattern", "system_authorizationtype", "system_currencyunit"]
  @params=YAML.load_file("config/api.yaml")
  @access_toen="14c8e8a908b77eb7250bcffe2d65df1b78010bea99b285538878bd7c03a74b14a5b6f4d24ec62b3780c03b2f8243df94da8f3b9b0ae1d943c5e5917d37aff5b7"#@user.access_token
  @refresh_token="c9de551f7398fb7ed36c6b15bb3de67b263bf38e46532ebfa51f80ddac10fd0e27d40469bceb7661185f88fbc41063dad00afc2a0da0c254cfa4079acfb97cb4"#@user.refresh_token
  @master = NeAPI::Master.new @access_token, @refresh_token
  context '全てのメソッドについて' do
    it '存在する' do
      ret=true
      @methods.each {|m| ret=false unless @master.send(m.to_s+"_info")}
      expect(ret).to be_true
    end
  end
  context 'system_order_infoについて' do
    it 'resultがsuccess' do
      expect(@master.send("system_order")[:result]).to be("success")
    end
    it 'countがある' do
      expect(@master.send("system_order").has_key?("count")).to be_true
    end
    it 'dataに全フィールドがある' do
      expect(@master.send("system_order")[:data].has_key?(:order_id, :order_name)).to be_true
    end
  end
end
