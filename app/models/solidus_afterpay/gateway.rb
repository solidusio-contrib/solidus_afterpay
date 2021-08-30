# frozen_string_literal: true

require 'afterpay'

module SolidusAfterpay
  class Gateway
    def initialize(options)
      ::Afterpay.configure do |config|
        config.merchant_id = options[:merchant_id]
        config.secret_key = options[:secret_key]
        config.server = 'https://api.us-sandbox.afterpay.com/' if options[:test_mode]
      end
    end
  end
end
