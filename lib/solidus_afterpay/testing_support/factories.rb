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

FactoryBot.define do
  factory :order_with_variant_property, class: "Spree::Order", parent: :order_with_line_items do
    after(:build) do |order|
      variant_property_rule_value = create(:variant_property_rule_value, value: "2021-09-19",
        property: create(:property, name: "estimatedShipmentDate"))
      order.line_items.first.variant.product.variant_property_rules << variant_property_rule_value.variant_property_rule
      order.line_items.first.variant.option_values << variant_property_rule_value.variant_property_rule
                                                                                 .option_values.first
    end
  end
end

FactoryBot.define do
  factory :order_with_product_property, class: "Spree::Order", parent: :order_with_line_items do
    after(:build) do |order|
      order.line_items.first.product.set_property("estimatedShipmentDate", "2025-10-25")
    end
  end
end
