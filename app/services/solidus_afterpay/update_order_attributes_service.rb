# frozen_string_literal: true

module SolidusAfterpay
  class UpdateOrderAttributesService < BaseService
    def initialize(order:, afterpay_order_token:, payment_method:, request_env:)
      @order = order
      @afterpay_order_token = afterpay_order_token
      @payment_method = payment_method
      @request_env = request_env

      super()
    end

    def call
      return false if afterpay_order.nil?

      ::Spree::OrderUpdateAttributes.new(order, update_params, request_env: request_env).apply
    end

    private

    def afterpay_order
      @afterpay_order ||= payment_method.gateway.find_order(token: afterpay_order_token)
    end

    def shipping_rate
      @shipping_rate ||= ::Spree::ShippingRate.find(afterpay_order.shippingOptionIdentifier.to_i)
    end

    def update_params
      {
        email: afterpay_order.consumer.email,
        shipments_attributes: [{
          selected_shipping_rate_id: shipping_rate.id,
          id: shipping_rate.shipment.id
        }],
        payments_attributes: [{
          payment_method_id: payment_method.id,
          amount: afterpay_order.amount.amount,
          source_attributes: {
            token: afterpay_order_token
          }
        }]
      }
    end

    attr_reader :order, :afterpay_order_token, :payment_method, :request_env
  end
end
