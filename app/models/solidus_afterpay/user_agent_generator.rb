# frozen_string_literal: true

module SolidusAfterpay
  class UserAgentGenerator
    def initialize(merchant_id:)
      @merchant_id = merchant_id
    end

    def generate
      "#{afterpay_plugin} (#{platform}; #{system_information}; #{merchant_id}) #{merchant_website_url}"
    end

    private

    def afterpay_plugin
      "SolidusAfterpay/#{SolidusAfterpay::VERSION}"
    end

    def platform
      "Solidus/#{::Spree.solidus_gem_version}"
    end

    def system_information
      "Ruby/#{RUBY_VERSION}"
    end

    def merchant_id
      "Merchant/#{@merchant_id}"
    end

    def merchant_website_url
      "https://#{::Spree::Store.default.url}"
    end
  end
end
