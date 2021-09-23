# frozen_string_literal: true

module SolidusAfterpay
  class PaymentMethod < SolidusSupport.payment_method_parent_class
    preference :merchant_id, :string
    preference :secret_key, :string
    preference :popup_window, :boolean
    preference :merchant_key, :string
    preference :excluded_products, :string

    def gateway_class
      SolidusAfterpay::Gateway
    end

    def payment_source_class
      SolidusAfterpay::PaymentSource
    end

    def partial_name
      'afterpay'
    end

    def try_void(payment)
      return false unless payment.payment_source.can_void?(payment)

      response = void(payment.response_code, { originator: payment, currency: payment.currency })

      return false unless response.success?

      response
    end

    def available_for_order?(order)
      return false if order.line_items.any?{ |item| excluded_product_ids.include? item.variant.product_id }

      available_payment_currency == order.currency && available_payment_range.include?(order.total)
    end

    private

    def excluded_product_ids
      return [] if preferred_excluded_products.nil?

      preferred_excluded_products.split(",").map(&:to_i)
    end

    def available_payment_range
      minimum_amount..maximum_amount
    end

    def configuration
      @configuration ||= gateway.retrieve_configuration
    end

    def minimum_amount
      @minimum_amount ||= fetch_configuration(:minimumAmount, :amount).to_f
    end

    def maximum_amount
      @maximum_amount ||= fetch_configuration(:maximumAmount, :amount).to_f
    end

    def available_payment_currency
      @available_payment_currency = fetch_configuration(:maximumAmount, :currency)
    end

    def fetch_configuration(*keys)
      cache_key = "solidus_afterpay_configuration_#{keys.join('_')}"

      return Rails.cache.read(cache_key) if Rails.cache.exist?(cache_key)

      value = configuration&.dig(*keys)

      unless configuration.nil?
        Rails.cache.write(
          cache_key,
          value,
          expires_in: SolidusAfterpay.config.cache_expiry
        )
      end

      value
    end
  end
end
