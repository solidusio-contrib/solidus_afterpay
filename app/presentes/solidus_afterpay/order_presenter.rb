# frozen_string_literal: true

module SolidusAfterpay
  class OrderPresenter
    def initialize(order:)
      @order = order
    end

    def line_items_tax_amount
      order.line_item_adjustments.tax.eligible.sum(&:amount)
    end

    private

    attr_reader :order
  end
end
