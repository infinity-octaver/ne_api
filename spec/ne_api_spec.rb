require 'yaml'
load 'ne_api.rb'
SEARCH_MODEL=["receiveorder_base", "receiveorder_row", "receiveorder_forwardingagent", "receiveorder_confirm", "master_goods", "master_stock", "master_mailtag", "master_goodstag", "master_supplier", "master_wholesale", "master_stockiohistory", "master_pagebase", "master_pagebasevariationoroption", "master_shop", "master_goodsimage", "master_goodsimagetag", "master_goodscategory", "system_que", "system_mall", "system_imagetag", "system_mallcategory"]
INFO_MODEL=["login_user", "login_company", "system_credittype", "system_creditauthorizationcenter", "system_creditapprovaltype", "system_order", "system_ordercondition", "system_delivery", "system_fraction", "system_returnedreason", "system_canceltype", "system_orderstatus", "system_importantcheck", "system_confirmcheck", "system_customertype", "system_deposittype", "system_iotype", "system_select", "system_paymentmethod", "system_payout", "system_socialinsurance", "system_goodstype", "system_goodsstatus", "system_merchandise", "system_importtype", "system_forwardingmethod", "system_tax", "system_itemname", "system_pagestatus", "receiveorder_uploadpattern", "system_authorizationtype", "system_currencyunit"]
ACCESS_TOKEN
REFRESH_TOKEN
describe 'searchについて' do
  before(:all) do
    @params =YAML.load_file("config/api.yaml")
    @master = NeAPI::Master.new access_token: ACCESS_TOKEN, refresh_token: REFRESH_TOKEN
  end
  context '全てのメソッドについて' do
    SEARCH_MODEL.each do |m|
      it m.to_s+'は存在する' do
        expect(@master.send(m.to_s+"_search")).to be_truthy
      end
    end
  end
  SEARCH_MODEL.each do |m|
    context m.to_s+'_searchについて' do
      context 'フィールド指定がない場合' do
        it 'デフォルトで指定したフィールドの情報が返ってくる' do
          ret=true
          @params[m.to_sym][:fields].split(",").each {|f| ret&&=false unless (@master.send(m.to_s+"_search")).first.has_key?(@params[m.to_sym][:prefix]+"_"+f)}
          expect(ret).to be_truthy
        end
      end
      context 'フィールド指定が複数ある場合' do
        context '正しいフィールド名をもつ' do
          it '引数で与えたフィールドの情報が返ってくる' do
            field=@params[m.to_sym][:prefix]+"_last_modified_date,"+@params[m.to_sym][:prefix]+"_creation_date"
            ret=true
            field.split(",").each{|f| ret&&=false unless (@master.send(m.to_s+"_search", {fields: field})).first.has_key?(f)}
            expect(ret).to be_truthy
          end
          context '間違ったフィールド名がまざっている' do
            it 'エラーが返される' do
              field=@params[m.to_sym][:prefix]+"_last_modified_date, invalid_field"
              expect{@master.send(m.to_s+"_search", {fields: field})}.to raise_error(NeAPIException)
            end
          end
        end
        context 'フィールドの検索条件がある場合' do
          context '存在しないフィールドである' do
            it 'エラーが返される' do
              expect{@master.send(m.to_s+"_search", {query: {"invalid_field-like" => "hoge"}})}.to raise_error(NeAPIException)
            end
          end
          context '指定形式が間違っている' do
            it 'エラーが返される' do
              expect{@master.send(m.to_s+"_search", {query: {@params[m.to_sym][:prefix]+"_creation_date_gte"=> Time.now.strftime("%F %T")}})}.to raise_error(NeAPIException)
            end
          end
          context '検索条件が正しい' do
            context '検索の結果が複数件ある' do
              it '複数件のデータが返される' do
                expect(@master.send(m.to_s+"_search", {query: {@params[m.to_sym][:prefix]+"_creation_date-lte"=> Time.now.strftime("%F %T")}}).count).to be >0
              end
              it '返されるデータはデフォルトのフィールドを持つ' do
                ret=true
                @params[m.to_sym][:fields].split(",").each {|f| ret&&=false unless (@master.send(m.to_s+"_search", {query: {@params[m.to_sym][:prefix]+"_creation_date-lte"=> Time.now.strftime("%F %T")}})).first.has_key?(@params[m.to_sym][:prefix]+"_"+f)}
                expect(ret).to be_truthy
              end
            end
            context '検索の結果が複数件あり，フィールド指定もされている' do
              it '返されるデータは指定されたフィールドを持つ' do
                expect((@master.send(m.to_s+"_search", {query: {@params[m.to_sym][:prefix]+"_creation_date-lte"=> Time.now.strftime("%F %T")}, fields: @params[m.to_sym][:prefix]+"_id"})).first.has_key?(@params[m.to_sym][:prefix]+"_id")).to be_truthy
              end
            end
            context '検索の結果が0件' do
              it '空の配列が返される' do
                expect(@master.send(m.to_s+"_search", {query: {@params[m.to_sym][:prefix]+"_creation_date-gte"=> Time.now.strftime("%F %T")}})).to be_empty
              end
            end
          end
        end
      end
    end
  end
end
describe 'countAPI' do
  before(:all) do
    @params =YAML.load_file("config/api.yaml")
    @master = NeAPI::Master.new access_token: ACCESS_TOKEN, refresh_token: REFRESH_TOKEN
  end
  context '全てのメソッドについて' do
    SEARCH_MODEL.each do |m|
      it m.to_s+'は存在する' do
        expect(@master.send(m.to_s+"_count")).to be_truthy
      end
    end
  end
  SEARCH_MODEL.each do |m|
    context m.to_s+'_countについて' do
      context 'フィールドの検索条件がない場合' do
        it '数字が返ってくる' do
          expect(@master.send(m.to_s+"_count")).to match(/\d+/)
        end
      end
      context '指定形式が間違っている' do
        it 'エラーが返される' do
          expect{@master.send(m.to_s+"_count", {query: {@params[m.to_sym][:prefix]+"_creation_date_gte"=> Time.now.strftime("%F %T")}})}.to raise_error(NeAPIException)
        end
      end
      context '検索条件が正しい' do
        context '検索の結果が複数件ある' do
          it '正の件数が返ってくる' do
            expect(@master.send(m.to_s+"_count", {query: {@params[m.to_sym][:prefix]+"_creation_date-lte"=> Time.now.strftime("%F %T")}}).to_i).to be >0
          end
        end
        context '検索の結果が0件' do
          it '0が返される' do
            expect(@master.send(m.to_s+"_count", {query: {@params[m.to_sym][:prefix]+"_creation_date-gte"=> Time.now.strftime("%F %T")}})).to eq("0")
          end
        end
      end
    end
  end
end
describe 'infoAPI' do
  before(:all) do
  @params =YAML.load_file("config/api.yaml")
  @access_toen = ACCESS_TOKEN
  @refresh_token = REFRESH_TOKEN
  @master = NeAPI::Master.new access_token: @access_toen, refresh_token: @refresh_token
  end
  context '全てのメソッドについて' do
    INFO_MODEL.each do |m|
      it m.to_s+'は存在する' do
        expect(@master.send(m.to_s+"_info")).to be_truthy
      end
    end
  end
  INFO_MODEL.each do |m|
    context m.to_s+'_infoについて' do
      it 'resultがsuccess' do
        expect((@master.send(m.to_s+"_info"))["result"]).to match(/success/)
      end
      it 'countがある' do
        expect(@master.send(m.to_s+"_info").has_key?("count")).to be_truthy
      end
      it 'dataがある' do
        expect(@master.send(m.to_s+"_info").has_key?("data")).to be_truthy
      end
    end
  end
end
