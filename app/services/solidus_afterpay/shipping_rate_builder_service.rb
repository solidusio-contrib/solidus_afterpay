# frozen_string_literal: true

module SolidusAfterpay
  class ShippingRateBuilderService < BaseService
    def initialize(order:)
      @order = order

      super()
    end

    def call
      order.shipments.map do |shipment|
        shipment.shipping_rates.map do |rate|
          shipping_rate_presenter = SolidusAfterpay::ShippingRatePresenter.new(shipping_rate: rate)

          {
            id: rate.id.to_s,
            name: rate.name,
            description: rate.display_price,
            shipping_amount: shipping_rate_presenter.amount_with_taxes.round(4).to_s,
            currency: rate.currency,
            order_amount: shipping_rate_presenter.order_amount.round(4).to_s
          }
        end
      end.flatten
    end

    private

    attr_reader :order
  end
end
