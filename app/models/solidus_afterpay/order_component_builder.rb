# frozen_string_literal: true

require 'afterpay'

module SolidusAfterpay
  class OrderComponentBuilder
    attr_reader :order, :mode, :redirect_confirm_url, :redirect_cancel_url, :popup_origin_url

    def initialize(order:, mode:, redirect_confirm_url:, redirect_cancel_url:, popup_origin_url:)
      @order = order
      @mode = mode
      @redirect_confirm_url = redirect_confirm_url
      @redirect_cancel_url = redirect_cancel_url
      @popup_origin_url = popup_origin_url
    end

    def call
      ::Afterpay::Components::Order.new(
        amount: amount,
        mode: mode,
        consumer: consumer,
        billing: address(order.billing_address),
        shipping: address(order.shipping_address),
        merchant: merchant,
        items: items,
        merchant_reference: order.number
      )
    end

    private

    def address(address)
      return unless address

      name = if SolidusSupport.combined_first_and_last_name_in_address?
               address.name
             else
               [address.first_name, address.last_name].join(' ').strip
             end

      ::Afterpay::Components::Contact.new(
        name: name,
        line1: address.address1,
        line2: address.address2,
        area1: address.city,
        region: address.state_text,
        postcode: address.zipcode,
        phone_number: address.phone
      )
    end

    def consumer
      return unless order.billing_address

      if SolidusSupport.combined_first_and_last_name_in_address?
        name_components = ::Spree::Address::Name.new(order.billing_address.name)
        first_name = name_components.first_name
        last_name = name_components.last_name
      else
        first_name = order.billing_address.first_name
        last_name = order.billing_address.last_name
      end

      ::Afterpay::Components::Consumer.new(
        email: order.user&.email || order.email || 'afterpay@guest.com',
        given_names: first_name,
        surname: last_name,
        phone: order.billing_address.phone
      )
    end

    def amount
      ::Afterpay::Components::Money.new(
        amount: order.total.to_s,
        currency: order.currency
      )
    end

    def merchant
      ::Afterpay::Components::Merchant.new(
        redirect_confirm_url: redirect_confirm_url,
        redirect_cancel_url: redirect_cancel_url,
        popup_origin_url: popup_origin_url
      )
    end

    def items
      order.line_items.includes(variant: :product).map do |line_item|
        item(line_item)
      end
    end

    def item(line_item)
      ::Afterpay::Components::Item.new(
        name: line_item.name,
        sku: line_item.sku,
        quantity: line_item.quantity,
        price: ::Afterpay::Components::Money.new(
          amount: line_item.price.to_s,
          currency: line_item.currency
        )
      )
    end
  end
end
