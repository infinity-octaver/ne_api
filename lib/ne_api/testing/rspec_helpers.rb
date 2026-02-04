module NeAPI
  module Testing
    # RSpec用ヘルパーメソッド
    #
    # @example spec/rails_helper.rb での設定
    #   require 'ne_api/testing'
    #
    #   RSpec.configure do |config|
    #     config.include NeAPI::Testing::RSpecHelpers
    #   end
    #
    # @example テストコードでの使用
    #   RSpec.describe OrderService do
    #     it "受注を取得する" do
    #       with_fake_ne_api do |fake|
    #         fake.stub(:receiveorder_base_search, [ne_receive_order])
    #         # ...
    #       end
    #     end
    #   end
    #
    module RSpecHelpers
      # FakeMasterインスタンスを生成
      #
      # @param options [Hash] 初期化オプション
      # @return [FakeMaster]
      def fake_ne_master(**options)
        NeAPI::Testing::FakeMaster.new(**options)
      end

      # FakeAuthインスタンスを生成
      #
      # @param options [Hash] 初期化オプション
      # @return [FakeAuth]
      def fake_ne_auth(**options)
        NeAPI::Testing::FakeAuth.new(**options)
      end

      # NeAPI::Master.newをFakeMasterに差し替えてブロックを実行
      #
      # @yield [FakeMaster] FakeMasterインスタンス
      # @return [Object] ブロックの戻り値
      #
      # @example
      #   with_fake_ne_api do |fake|
      #     fake.stub(:master_goods_search, [ne_goods])
      #     service = MyService.new  # 内部でNeAPI::Master.newを呼ぶ
      #     service.call
      #   end
      def with_fake_ne_api(**options)
        fake = fake_ne_master(**options)
        allow(NeAPI::Master).to receive(:new).and_return(fake)
        yield fake
      end

      # NeAPI::Auth.newをFakeAuthに差し替えてブロックを実行
      #
      # @yield [FakeAuth] FakeAuthインスタンス
      # @return [Object] ブロックの戻り値
      def with_fake_ne_auth(**options)
        fake = fake_ne_auth(**options)
        allow(NeAPI::Auth).to receive(:new).and_return(fake)
        yield fake
      end

      # --- ResponseFactoryへのショートカット ---

      # 商品データを生成
      # @see ResponseFactory.goods
      def ne_goods(**attrs)
        NeAPI::Testing::ResponseFactory.goods(attrs)
      end

      # 商品リストを生成
      # @see ResponseFactory.goods_list
      def ne_goods_list(count = 3, &block)
        NeAPI::Testing::ResponseFactory.goods_list(count, &block)
      end

      # 在庫データを生成
      # @see ResponseFactory.stock
      def ne_stock(**attrs)
        NeAPI::Testing::ResponseFactory.stock(attrs)
      end

      # 在庫リストを生成
      # @see ResponseFactory.stock_list
      def ne_stock_list(count = 3, &block)
        NeAPI::Testing::ResponseFactory.stock_list(count, &block)
      end

      # 受注データを生成
      # @see ResponseFactory.receive_order
      def ne_receive_order(**attrs)
        NeAPI::Testing::ResponseFactory.receive_order(attrs)
      end

      # 受注リストを生成
      # @see ResponseFactory.receive_order_list
      def ne_receive_order_list(count = 3, &block)
        NeAPI::Testing::ResponseFactory.receive_order_list(count, &block)
      end

      # 受注明細データを生成
      # @see ResponseFactory.receive_order_row
      def ne_receive_order_row(**attrs)
        NeAPI::Testing::ResponseFactory.receive_order_row(attrs)
      end

      # 会社情報を生成
      # @see ResponseFactory.company_info
      def ne_company_info(**attrs)
        NeAPI::Testing::ResponseFactory.company_info(attrs)
      end

      # ユーザー情報を生成
      # @see ResponseFactory.user_info
      def ne_user_info(**attrs)
        NeAPI::Testing::ResponseFactory.user_info(attrs)
      end

      # 店舗データを生成
      # @see ResponseFactory.shop
      def ne_shop(**attrs)
        NeAPI::Testing::ResponseFactory.shop(attrs)
      end

      # 倉庫在庫データを生成
      # @see ResponseFactory.warehouse_stock
      def ne_warehouse_stock(**attrs)
        NeAPI::Testing::ResponseFactory.warehouse_stock(attrs)
      end

      # エラーレスポンスを生成
      # @see ResponseFactory.error
      def ne_error(**attrs)
        NeAPI::Testing::ResponseFactory.error(**attrs)
      end

      # 成功レスポンスを生成
      # @see ResponseFactory.success_response
      def ne_success_response(**attrs)
        NeAPI::Testing::ResponseFactory.success_response(**attrs)
      end
    end
  end
end

# RSpecが読み込まれていれば自動設定
if defined?(RSpec)
  RSpec.configure do |config|
    config.include NeAPI::Testing::RSpecHelpers
  end
end
