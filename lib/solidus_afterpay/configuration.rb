# frozen_string_literal: true

module SolidusAfterpay
  class Configuration
    attr_accessor :use_solidus_api

    def dummy_email
      'afterpay@dummy.com'
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    alias config configuration

    def configure
      yield configuration
    end

    def api_base_controller_parent_class
      return ::Spree::Api::BaseController if configuration.use_solidus_api

      SolidusAfterpay::BaseController
    end
  end
end
