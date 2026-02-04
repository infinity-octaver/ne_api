require 'securerandom'

module NeAPI
  module Testing
    # テスト用レスポンスデータを生成するファクトリ
    #
    # @example 商品データ生成
    #   ResponseFactory.goods(goods_name: "テスト商品A")
    #   ResponseFactory.goods_list(3)
    #
    # @example 受注データ生成
    #   ResponseFactory.receive_order(receive_order_total_amount: 5000)
    #
    class ResponseFactory
      class << self
        # 商品マスタデータを生成
        #
        # @param overrides [Hash] 上書きする属性
        # @return [Hash]
        def goods(overrides = {})
          {
            "goods_id" => SecureRandom.hex(8),
            "goods_name" => "テスト商品",
            "goods_jan_code" => "4912345678901"
          }.merge(stringify_keys(overrides))
        end

        # 商品リストを生成
        #
        # @param count [Integer] 生成数
        # @yield [item, index] 各アイテムをカスタマイズするブロック
        # @return [Array<Hash>]
        def goods_list(count = 3, &block)
          count.times.map do |i|
            item = goods("goods_id" => "GOODS#{format('%03d', i + 1)}", "goods_name" => "テスト商品#{i + 1}")
            block ? block.call(item, i) : item
          end
        end

        # 在庫マスタデータを生成
        #
        # @param overrides [Hash] 上書きする属性
        # @return [Hash]
        def stock(overrides = {})
          {
            "stock_goods_id" => SecureRandom.hex(8),
            "stock_quantity" => 100,
            "stock_allocation_quantity" => 10,
            "stock_defective_quantity" => 0,
            "stock_remaining_order_quantity" => 0,
            "stock_out_quantity" => 0,
            "stock_free_quantity" => 90
          }.merge(stringify_keys(overrides))
        end

        # 在庫リストを生成
        #
        # @param count [Integer] 生成数
        # @return [Array<Hash>]
        def stock_list(count = 3, &block)
          count.times.map do |i|
            item = stock("stock_goods_id" => "GOODS#{format('%03d', i + 1)}")
            block ? block.call(item, i) : item
          end
        end

        # 受注データを生成
        #
        # @param overrides [Hash] 上書きする属性
        # @return [Hash]
        def receive_order(overrides = {})
          {
            "receive_order_id" => SecureRandom.hex(8),
            "receive_order_shop_id" => "1",
            "receive_order_shop_cut_form_id" => "ORD-#{SecureRandom.hex(4).upcase}",
            "receive_order_date" => Time.now.strftime("%Y-%m-%d %H:%M:%S"),
            "receive_order_order_status_id" => "10",
            "receive_order_order_status_name" => "新規受付",
            "receive_order_delivery_id" => "1",
            "receive_order_delivery_name" => "ヤマト運輸",
            "receive_order_payment_method_id" => "1",
            "receive_order_payment_method_name" => "クレジットカード",
            "receive_order_total_amount" => 1000,
            "receive_order_tax_amount" => 100,
            "receive_order_goods_amount" => 900,
            "receive_order_delivery_fee_amount" => 0,
            "receive_order_purchaser_name" => "テスト顧客",
            "receive_order_purchaser_kana" => "テストコキャク",
            "receive_order_purchaser_zip_code" => "100-0001",
            "receive_order_purchaser_address1" => "東京都千代田区",
            "receive_order_purchaser_address2" => "1-1-1",
            "receive_order_purchaser_tel" => "03-1234-5678",
            "receive_order_purchaser_mail_address" => "test@example.com",
            "receive_order_consignee_name" => "テスト顧客",
            "receive_order_consignee_zip_code" => "100-0001",
            "receive_order_consignee_address1" => "東京都千代田区",
            "receive_order_consignee_address2" => "1-1-1",
            "receive_order_consignee_tel" => "03-1234-5678"
          }.merge(stringify_keys(overrides))
        end

        # 受注リストを生成
        #
        # @param count [Integer] 生成数
        # @return [Array<Hash>]
        def receive_order_list(count = 3, &block)
          count.times.map do |i|
            item = receive_order("receive_order_shop_cut_form_id" => "ORD-#{format('%04d', i + 1)}")
            block ? block.call(item, i) : item
          end
        end

        # 受注明細データを生成
        #
        # @param overrides [Hash] 上書きする属性
        # @return [Hash]
        def receive_order_row(overrides = {})
          {
            "receive_order_row_receive_order_id" => SecureRandom.hex(8),
            "receive_order_row_no" => "1",
            "receive_order_row_goods_id" => SecureRandom.hex(8),
            "receive_order_row_goods_name" => "テスト商品",
            "receive_order_row_quantity" => 1,
            "receive_order_row_unit_price" => 1000,
            "receive_order_row_goods_option" => ""
          }.merge(stringify_keys(overrides))
        end

        # 会社情報を生成
        #
        # @param overrides [Hash] 上書きする属性
        # @return [Hash]
        def company_info(overrides = {})
          {
            "company_id" => "12345",
            "company_name" => "テスト会社",
            "company_ne_id" => "NE123456",
            "company_kana" => "テストカイシャ"
          }.merge(stringify_keys(overrides))
        end

        # ユーザー情報を生成
        #
        # @param overrides [Hash] 上書きする属性
        # @return [Hash]
        def user_info(overrides = {})
          {
            "user_id" => "1",
            "user_name" => "テストユーザー",
            "user_mail" => "test@example.com"
          }.merge(stringify_keys(overrides))
        end

        # 店舗データを生成
        #
        # @param overrides [Hash] 上書きする属性
        # @return [Hash]
        def shop(overrides = {})
          {
            "shop_id" => "1",
            "shop_name" => "テスト店舗",
            "shop_kana" => "テストテンポ",
            "shop_abbreviated_name" => "テスト",
            "shop_mall_id" => "1",
            "shop_deleted_flag" => "0"
          }.merge(stringify_keys(overrides))
        end

        # 倉庫在庫データを生成
        #
        # @param overrides [Hash] 上書きする属性
        # @return [Hash]
        def warehouse_stock(overrides = {})
          {
            "warehouse_stock_warehouse_id" => "1",
            "warehouse_stock_goods_id" => SecureRandom.hex(8),
            "warehouse_stock_quantity" => 100,
            "warehouse_stock_allocation_quantity" => 10,
            "warehouse_stock_free_quantity" => 90
          }.merge(stringify_keys(overrides))
        end

        # エラーレスポンスを生成
        #
        # @param code [String] エラーコード
        # @param message [String] エラーメッセージ
        # @return [Hash]
        def error(code: "001001", message: "エラーが発生しました")
          {
            "result" => "error",
            "code" => code,
            "message" => message
          }
        end

        # 混雑エラー（リトライ対象）を生成
        #
        # @return [Hash]
        def busy_error
          error(code: "003001", message: "Next Engineが大変混み合っています")
        end

        # 成功レスポンスを生成（info系API用）
        #
        # @param data [Array] データ配列
        # @param access_token [String] アクセストークン
        # @param refresh_token [String] リフレッシュトークン
        # @return [Hash]
        def success_response(data: [], access_token: "test_access_token", refresh_token: "test_refresh_token")
          {
            "result" => "success",
            "data" => data,
            "count" => data.size.to_s,
            "access_token" => access_token,
            "refresh_token" => refresh_token
          }
        end

        private

        def stringify_keys(hash)
          hash.transform_keys(&:to_s)
        end
      end
    end
  end
end
