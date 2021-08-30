# frozen_string_literal: true

FactoryBot.define do
  factory :afterpay_payment_method, class: SolidusAfterpay::PaymentMethod do
    name { 'Afterpay' }
  end
end

FactoryBot.define do
  factory :afterpay_payment, parent: :payment do
    association(:payment_method, factory: :afterpay_payment_method)
  end
end

FactoryBot.define do
  factory :afterpay_payment_source, class: SolidusAfterpay::PaymentSource do
    association(:payment_method, factory: :afterpay_payment_method)
    token { "12345678910" }
  end
end
