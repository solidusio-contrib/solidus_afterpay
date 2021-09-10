# frozen_string_literal: true

module SolidusAfterpay
  class ShippingRatePresenter
    def initialize(shipping_rate:)
      @shipping_rate = shipping_rate
    end

    def order_amount
      shipping_rate.order.item_total.to_f +
        shipping_rate.cost +
        shipping_rate.taxes.sum(&:amount) +
        order_presenter.line_items_tax_amount
    end

    def amount_with_taxes
      shipping_rate.cost.to_f + shipping_rate.taxes.sum(&:amount)
    end

    private

    def order_presenter
      @order_presenter ||= SolidusAfterpay::OrderPresenter.new(order: shipping_rate.order)
    end

    attr_reader :shipping_rate
  end
end
