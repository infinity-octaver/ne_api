module NeAPI
  module Testing
    # NeAPI::Auth のスタブクラス
    #
    # @example 基本的な使い方
    #   fake = NeAPI::Testing::FakeAuth.new(redirect_url: "http://localhost:3000/callback")
    #   fake.ne_auth("uid123", "state456")
    #   fake.tokens  #=> { access_token: "...", refresh_token: "..." }
    #
    # @example カスタムレスポンス
    #   fake.stub_auth_response({ "access_token" => "custom_token", ... })
    #   fake.ne_auth("uid", "state")
    #
    # @example 認証失敗のシミュレート
    #   fake.stub_auth_failure
    #   fake.ne_auth("uid", "state")  #=> raises NeAPIException
    #
    class FakeAuth
      attr_accessor :redirect_url, :ne_user, :wait_flag

      def initialize(redirect_url: "http://localhost:3000/callback")
        @redirect_url = redirect_url
        @ne_user = nil
        @wait_flag = false
        @auth_response = nil
        @should_fail = false
      end

      # 認証レスポンスをカスタマイズする
      #
      # @param response [Hash] 認証レスポンス
      # @return [self]
      def stub_auth_response(response)
        @auth_response = response
        self
      end

      # 認証失敗をシミュレートする
      #
      # @return [self]
      def stub_auth_failure
        @should_fail = true
        self
      end

      # スタブをリセットする
      #
      # @return [self]
      def reset!
        @ne_user = nil
        @auth_response = nil
        @should_fail = false
        self
      end

      # ブラウザを開かずにサインインURLを返す
      #
      # @param client_id [String] クライアントID
      # @param client_secret [String] クライアントシークレット
      # @return [String] コールバックURLの例
      def sign_in(client_id = nil, client_secret = nil)
        # 実際のブラウザは開かない
        # テスト用にコールバックURLを返す
        "#{@redirect_url}?uid=test_uid&state=test_state"
      end

      # 認証処理のスタブ
      #
      # @param uid [String] UID
      # @param state [String] State
      # @param client_id [String] クライアントID
      # @param client_secret [String] クライアントシークレット
      # @return [Hash] 認証レスポンス
      # @raise [NeAPIException] 認証失敗時
      def ne_auth(uid, state, client_id = nil, client_secret = nil)
        raise NeAPIException, "003001:認証に失敗しました" if @should_fail

        @ne_user = @auth_response || default_auth_response(uid)
      end

      # トークンを取得する
      #
      # @return [Hash, nil] トークン情報
      def tokens
        return nil if @ne_user.nil?

        {
          access_token: @ne_user["access_token"],
          refresh_token: @ne_user["refresh_token"]
        }
      end

      private

      def default_auth_response(uid)
        {
          "result" => "success",
          "uid" => uid,
          "access_token" => "test_access_token_#{uid}",
          "refresh_token" => "test_refresh_token_#{uid}",
          "access_token_end_date" => (Time.now + 3600).strftime("%Y-%m-%d %H:%M:%S"),
          "refresh_token_end_date" => (Time.now + 86400 * 30).strftime("%Y-%m-%d %H:%M:%S"),
          "company_app_name" => "Test Company",
          "company_ne_id" => "NE123456"
        }
      end
    end
  end
end
