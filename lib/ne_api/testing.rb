# ne_api テスト用スタブ
#
# Railsプロジェクトでの設定:
#
#   # spec/rails_helper.rb
#   require 'ne_api/testing'
#
#   RSpec.configure do |config|
#     config.include NeAPI::Testing::RSpecHelpers
#   end
#
# 使用例:
#
#   RSpec.describe OrderSyncService do
#     it "受注を同期する" do
#       with_fake_ne_api do |fake|
#         fake.stub(:receiveorder_base_search, [
#           ne_receive_order(receive_order_id: "ORDER001")
#         ])
#
#         service = OrderSyncService.new(ne_api: fake)
#         result = service.sync
#
#         expect(result.count).to eq 1
#         expect(fake.called?(:receiveorder_base_search)).to be true
#       end
#     end
#   end

require_relative 'testing/fake_master'
require_relative 'testing/fake_auth'
require_relative 'testing/response_factory'
require_relative 'testing/rspec_helpers'

module NeAPI
  module Testing
    class << self
      # 設定用ブロック（将来の拡張用）
      def configure
        yield self if block_given?
      end
    end
  end
end
