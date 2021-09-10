# frozen_string_literal: true

SolidusAfterpay.configure do |config|
  config.use_solidus_api = false

  # A class that extend SolidusAfterpay::BaseService, respond to .call, accepting a Spree::Order
  # and return an Afterpay shipping rate object (check the Afterpay documentation)
  # config.shipping_rate_builder_service_class = 'SolidusAfterpay::ShippingRateBuilderService'
end
