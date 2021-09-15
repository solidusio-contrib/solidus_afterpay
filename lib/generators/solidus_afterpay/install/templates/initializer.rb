# frozen_string_literal: true

SolidusAfterpay.configure do |config|
  config.use_solidus_api = false
  # A class that extend SolidusAfterpay::BaseService, respond to .call, accepting a Spree::Order
  # and return an Afterpay shipping rate object (check the Afterpay documentation)
  # config.shipping_rate_builder_service_class = 'SolidusAfterpay::ShippingRateBuilderService'

  # A class that extend SolidusAfterpay::BaseService, respond to .call, accepting a Spree::Order
  # and return true or false
  # config.update_order_attributes_service_class = 'SolidusAfterpay::UpdateOrderAttributesService'

  # There is a cache for retrieving the minimum amount, maximum amount and the currency from Afterpay
  # the default value us set to 1.day, this is also recommended by Afterpay itself. If you prefer a shorter
  # or longer time simply uncomment config.cache_expiry and add the preferred value.
  # config.cache_expiry = 1.day
end
