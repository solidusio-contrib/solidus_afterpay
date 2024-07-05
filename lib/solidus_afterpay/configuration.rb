# frozen_string_literal: true

module SolidusAfterpay
  class Configuration
    attr_accessor :use_solidus_api
    attr_writer :shipping_rate_builder_service_class, :cache_expiry

    def dummy_email
      'afterpay@dummy.com'
    end

    def shipping_rate_builder_service_class
      @shipping_rate_builder_service_class ||= 'SolidusAfterpay::ShippingRateBuilderService'
      @shipping_rate_builder_service_class.constantize
    end

    def update_order_attributes_service_class
      @update_order_attributes_service_class ||= 'SolidusAfterpay::UpdateOrderAttributesService'
      @update_order_attributes_service_class.constantize
    end

    def cache_expiry
      @cache_expiry ||= 1.day
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

    # rubocop:disable Rails/Delegate
    def shipping_rate_builder_service_class
      configuration.shipping_rate_builder_service_class
    end

    def update_order_attributes_service_class
      configuration.update_order_attributes_service_class
    end
    # rubocop:enable Rails/Delegate
  end
end
