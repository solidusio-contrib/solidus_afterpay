# frozen_string_literal: true

module SolidusAfterpay
  class PaymentMethod < SolidusSupport.payment_method_parent_class
    preference :merchant_id, :string
    preference :secret_key, :string
    preference :deferred, :boolean
    preference :popup_window, :boolean
    preference :minimum_amount, :decimal
    preference :maximum_amount, :decimal
    preference :currency, :string

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
      available_payment_currency == order.currency && available_payment_range.include?(order.total)
    end

    private

    def available_payment_range
      min = preferred_minimum_amount || configuration&.minimumAmount&.amount.to_f
      max = preferred_maximum_amount || configuration&.maximumAmount&.amount.to_f

      min..max
    end

    def available_payment_currency
      preferred_currency || configuration&.maximumAmount&.currency
    end

    def configuration
      @configuration ||= gateway.retrieve_configuration
    end
  end
end
