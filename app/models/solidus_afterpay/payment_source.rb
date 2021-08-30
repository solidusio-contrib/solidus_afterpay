# frozen_string_literal: true

module SolidusAfterpay
  class PaymentSource < SolidusSupport.payment_source_parent_class
    self.table_name = 'solidus_afterpay_payment_sources'

    validates :token, presence: true

    def actions
      %w[capture credit]
    end

    def can_void?(_payment)
      false
    end
  end
end
