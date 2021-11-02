require 'spree/testing_support/order_walkthrough'
require 'spree/api/testing_support/helpers'

RSpec.configure do |config|
  config.include Spree::Api::TestingSupport::Helpers, type: :request
end
