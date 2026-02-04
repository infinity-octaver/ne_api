module NeAPI
  module Testing
    # NeAPI::Master のスタブクラス
    #
    # @example 基本的な使い方
    #   fake = NeAPI::Testing::FakeMaster.new
    #   fake.stub(:master_goods_search, [{ "goods_id" => "001" }])
    #   fake.master_goods_search  #=> [{ "goods_id" => "001" }]
    #
    # @example エラーのシミュレート
    #   fake.simulate_error(code: "001001", message: "認証エラー")
    #   fake.master_goods_search  #=> raises NeAPIException
    #
    class FakeMaster
      attr_accessor :access_token, :refresh_token, :wait_flag, :retry_num, :wait_interval
      attr_accessor :access_token_end_date, :refresh_token_end_date
      attr_reader :call_history

      def initialize(access_token: "test_access_token", refresh_token: "test_refresh_token")
        @access_token = access_token
        @refresh_token = refresh_token
        @wait_flag = false
        @retry_num = 10
        @wait_interval = 15
        @stubbed_responses = {}
        @call_history = []
        @error_mode = false
        @error_code = nil
        @error_message = nil
      end

      # 特定メソッドのレスポンスをスタブする
      #
      # @param method_name [Symbol, String] スタブするメソッド名
      # @param response [Object] 返却するレスポンス（ブロックも可）
      # @return [self]
      def stub(method_name, response = nil, &block)
        @stubbed_responses[method_name.to_sym] = block || -> (_) { response }
        self
      end

      # エラーモードを有効にする
      #
      # @param code [String] エラーコード
      # @param message [String] エラーメッセージ
      # @return [self]
      def simulate_error(code: "001001", message: "API Error")
        @error_mode = true
        @error_code = code
        @error_message = message
        self
      end

      # エラーモードを解除する
      #
      # @return [self]
      def clear_error
        @error_mode = false
        @error_code = nil
        @error_message = nil
        self
      end

      # 全スタブと呼び出し履歴をクリアする
      #
      # @return [self]
      def reset!
        @stubbed_responses.clear
        @call_history.clear
        @error_mode = false
        @error_code = nil
        @error_message = nil
        self
      end

      # 指定メソッドが呼び出されたかチェック
      #
      # @param method_name [Symbol, String] メソッド名
      # @return [Boolean]
      def called?(method_name)
        @call_history.any? { |c| c[:method] == method_name.to_sym }
      end

      # 指定メソッドの呼び出し回数を取得
      #
      # @param method_name [Symbol, String] メソッド名
      # @return [Integer]
      def call_count(method_name)
        @call_history.count { |c| c[:method] == method_name.to_sym }
      end

      # 指定メソッドの最後の呼び出し引数を取得
      #
      # @param method_name [Symbol, String] メソッド名
      # @return [Hash, nil]
      def last_call_args(method_name)
        @call_history.reverse.find { |c| c[:method] == method_name.to_sym }&.[](:args)
      end

      # 強制インポートモード（本物と同じインターフェース）
      def force_import
        @wait_flag = true
      end

      def method_missing(method_name, args = {})
        @call_history << { method: method_name.to_sym, args: args, time: Time.now }

        if @error_mode
          raise NeAPIException, "#{@error_code}:#{@error_message}"
        end

        if @stubbed_responses.key?(method_name.to_sym)
          result = @stubbed_responses[method_name.to_sym].call(args)
          wrap_response(result, method_name)
        else
          default_response(method_name, args)
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        true
      end

      private

      def wrap_response(data, method_name)
        # 既にHash形式でresultキーがある場合はそのまま返す
        return data if data.is_a?(Hash) && data.key?("result")

        method_type = method_name.to_s.split("_").last
        case method_type
        when "search"
          # searchはdataキーの値を直接返す
          data
        when "count"
          data.is_a?(Integer) ? data.to_s : data
        else
          data
        end
      end

      def default_response(method_name, args)
        method_type = method_name.to_s.split("_").last
        case method_type
        when "search"
          []
        when "count"
          "0"
        when "info"
          {
            "result" => "success",
            "data" => [],
            "count" => "0",
            "access_token" => @access_token,
            "refresh_token" => @refresh_token
          }
        when "update", "upload", "receipted", "shipped", "labelprinted", "add", "bulkupdate", "bulkupdatereceipted"
          "success"
        when "divide"
          "new_receive_order_id"
        when "checkconnect"
          {
            "result" => "success",
            "access_token" => @access_token,
            "refresh_token" => @refresh_token
          }
        else
          {
            "result" => "success",
            "access_token" => @access_token,
            "refresh_token" => @refresh_token
          }
        end
      end
    end
  end
end
