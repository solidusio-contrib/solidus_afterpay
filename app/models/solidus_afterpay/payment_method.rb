# frozen_string_literal: true

module SolidusAfterpay
  class PaymentMethod < SolidusSupport.payment_method_parent_class
    preference :merchant_id, :string
    preference :secret_key, :string
    preference :deferred, :boolean
    preference :popup_window, :boolean

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
  end
end
