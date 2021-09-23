# frozen_string_literal: true

module SolidusAfterpay
  class PaymentSource < SolidusSupport.payment_source_parent_class
    self.table_name = 'solidus_afterpay_payment_sources'

    validates :token, presence: true

    def actions
      %w[capture void credit]
    end

    def can_void?(payment)
      payment_method = payment.payment_method

      return false if payment_method.auto_capture

      payment_state = payment_method.gateway.find_payment(order_id: payment.response_code).try(:[], :paymentState)

      ::SolidusAfterpay::Gateway::VOIDABLE_STATUSES.include?(payment_state)
    end
  end
end
