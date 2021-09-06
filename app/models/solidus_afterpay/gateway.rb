# frozen_string_literal: true

require 'afterpay'

module SolidusAfterpay
  class Gateway
    VOIDABLE_STATUSES = ['AUTH_APPROVED', 'PARTIALLY_CAPTURED'].freeze

    def initialize(options)
      ::Afterpay.configure do |config|
        config.merchant_id = options[:merchant_id]
        config.secret_key = options[:secret_key]
        config.server = 'https://api.us-sandbox.afterpay.com/' if options[:test_mode]
        config.user_agent = SolidusAfterpay::UserAgentGenerator.new(merchant_id: options[:merchant_id]).generate
      end
    end

    def authorize(_amount, payment_source, _gateway_options)
      result = {}

      if payment_source.payment_method.preferred_deferred
        response = ::Afterpay::API::Payment::Auth.call(
          payment: ::Afterpay::Components::Payment.new(token: payment_source.token)
        )
        result = response.body
      end

      ActiveMerchant::Billing::Response.new(true, 'Transaction approved', result, authorization: result[:id])
    rescue ::Afterpay::BaseError => e
      message = e.message
      message = I18n.t('solidus_afterpay.payment_declined') if message == 'Afterpay::PaymentRequiredError'
      ActiveMerchant::Billing::Response.new(false, message)
    end

    def capture(amount, response_code, gateway_options)
      payment_method = gateway_options[:originator].payment_method

      response = if payment_method.preferred_deferred
                   deferred_capture(amount, response_code, gateway_options)
                 else
                   immediate_capture(amount, response_code, gateway_options)
                 end
      result = response.body

      raise ::Afterpay::BaseError, I18n.t('solidus_afterpay.payment_declined') if result.status != 'APPROVED'

      ActiveMerchant::Billing::Response.new(true, 'Transaction captured', result, authorization: result.id)
    rescue ::Afterpay::BaseError => e
      ActiveMerchant::Billing::Response.new(false, e.message)
    end

    def purchase(amount, payment_source, gateway_options)
      result = authorize(amount, payment_source, gateway_options)
      return result unless result.success?

      capture(amount, result.authorization, gateway_options)
    end

    def credit(amount, response_code, gateway_options)
      response = ::Afterpay::API::Payment::Refund.call(
        order_id: response_code,
        refund: ::Afterpay::Components::Refund.new(
          amount: ::Afterpay::Components::Money.new(
            amount: Money.from_cents(amount).amount.to_s,
            currency: gateway_options[:originator].payment.currency
          ),
          merchant_reference: gateway_options[:originator].payment.id
        )
      )
      result = response.body

      ActiveMerchant::Billing::Response.new(true, "Transaction Credited with #{amount}", result,
        authorization: result.refundId)
    rescue ::Afterpay::BaseError => e
      ActiveMerchant::Billing::Response.new(false, e.message)
    end

    def void(response_code, gateway_options)
      payment_method = gateway_options[:originator].payment_method

      unless payment_method.preferred_deferred
        return ActiveMerchant::Billing::Response.new(false, "Transaction can't be voided")
      end

      response = ::Afterpay::API::Payment::Void.call(
        order_id: response_code,
        payment: ::Afterpay::Components::Payment.new(
          amount: ::Afterpay::Components::Money.new(
            amount: gateway_options[:originator].amount.to_s,
            currency: gateway_options[:currency]
          )
        )
      )
      result = response.body

      ActiveMerchant::Billing::Response.new(true, 'Transaction voided', result, authorization: result.id)
    rescue ::Afterpay::BaseError => e
      ActiveMerchant::Billing::Response.new(false, e.message)
    end

    def create_checkout(order, gateway_options)
      response = ::Afterpay::API::Order::Create.call(
        order: SolidusAfterpay::OrderComponentBuilder.new(
          order: order,
          redirect_confirm_url: gateway_options[:redirect_confirm_url],
          redirect_cancel_url: gateway_options[:redirect_cancel_url]
        ).call
      )
      result = response.body

      ActiveMerchant::Billing::Response.new(true, 'Checkout created', result)
    rescue ::Afterpay::BaseError => e
      ActiveMerchant::Billing::Response.new(false, e.message)
    end

    def find_payment(order_id:)
      ::Afterpay::API::Payment::Find.call(order_id: order_id).body
    rescue ::Afterpay::BaseError
      nil
    end

    def retrieve_configuration
      ::Afterpay::API::Configuration::Retrieve.call.body
    rescue ::Afterpay::BaseError
      nil
    end

    private

    def immediate_capture(_amount, _response_code, gateway_options)
      payment_source = gateway_options[:originator].payment_source

      ::Afterpay::API::Payment::Capture.call(
        payment: ::Afterpay::Components::Payment.new(token: payment_source.token)
      )
    end

    def deferred_capture(amount, response_code, gateway_options)
      ::Afterpay::API::Payment::DeferredCapture.call(
        order_id: response_code,
        payment: ::Afterpay::Components::Payment.new(
          amount: ::Afterpay::Components::Money.new(
            amount: Money.from_cents(amount).amount.to_s,
            currency: gateway_options[:currency]
          )
        )
      )
    end
  end
end
