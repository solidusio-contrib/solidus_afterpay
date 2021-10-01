# frozen_string_literal: true

require 'afterpay'

module SolidusAfterpay
  class Gateway
    VOIDABLE_STATUSES = ['AUTH_APPROVED', 'PARTIALLY_CAPTURED'].freeze

    def initialize(options)
      ::Afterpay.configure do |config|
        config.merchant_id = options[:merchant_id]
        config.secret_key = options[:secret_key]
        config.server = 'https://global-api-sandbox.afterpay.com/' if options[:test_mode]
        config.user_agent = SolidusAfterpay::UserAgentGenerator.new(merchant_id: options[:merchant_id]).generate
      end
    end

    def authorize(amount, payment_source, gateway_options)
      result = {}

      unless payment_source.payment_method.auto_capture
        response = ::Afterpay::API::Payment::Auth.call(
          payment: ::Afterpay::Components::Payment.new(
            token: payment_source.token,
            amount: ::Afterpay::Components::Money.new(
              amount: Money.from_cents(amount).amount.to_s,
              currency: gateway_options[:currency]
            )
          )
        )
        result = response.body
      end
      
      ActiveMerchant::Billing::Response.new(true, 'Transaction approved', result, authorization: result[:id])
    rescue ::Afterpay::BaseError => e
      message = e.message
      error_code = e.error_code
      if message == 'Afterpay::PaymentRequiredError'
        message = I18n.t('solidus_afterpay.payment_declined')
        error_code = 'payment_declined'
      end
      ::Afterpay::API::Payment::Reversal.call(token: result[:token])
      ActiveMerchant::Billing::Response.new(false, message, {}, error_code: error_code)
    end

    def capture(amount, response_code, gateway_options)
      payment_method = gateway_options[:originator].payment_method

      response = if payment_method.auto_capture
                   immediate_capture(amount, response_code, gateway_options)
                 else
                   deferred_capture(amount, response_code, gateway_options)
                 end
      result = response.body

      if result.status != 'APPROVED'
        raise ::Afterpay::BaseError.new('payment_declined'), I18n.t('solidus_afterpay.payment_declined')
      end

      ActiveMerchant::Billing::Response.new(true, 'Transaction captured', result, authorization: result.id)
    rescue ::Afterpay::BaseError => e
      ::Afterpay::API::Payment::Reversal.call(token: response.body[:token])
      ActiveMerchant::Billing::Response.new(false, e.message, {}, error_code: e.error_code)
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
      ActiveMerchant::Billing::Response.new(false, e.message, {}, error_code: e.error_code)
    end

    def void(response_code, gateway_options)
      payment_method = gateway_options[:originator].payment_method

      if payment_method.auto_capture
        return ActiveMerchant::Billing::Response.new(false, "Transaction can't be voided", {},
          error_code: 'void_not_allowed')
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
      ActiveMerchant::Billing::Response.new(false, e.message, {}, error_code: e.error_code)
    end

    def create_checkout(order, gateway_options)
      response = ::Afterpay::API::Order::Create.call(
        order: SolidusAfterpay::OrderComponentBuilder.new(
          order: order,
          mode: gateway_options[:mode],
          redirect_confirm_url: gateway_options[:redirect_confirm_url],
          redirect_cancel_url: gateway_options[:redirect_cancel_url],
          popup_origin_url: gateway_options[:popup_origin_url]
        ).call
      )
      result = response.body

      ActiveMerchant::Billing::Response.new(true, 'Checkout created', result)
    rescue ::Afterpay::BaseError => e
      ActiveMerchant::Billing::Response.new(false, e.message, {}, error_code: e.error_code)
    end

    def find_payment(order_id:)
      ::Afterpay::API::Payment::Find.call(order_id: order_id).body
    rescue ::Afterpay::BaseError
      nil
    end

    def find_order(token:)
      ::Afterpay::API::Order::Find.call(token: token).body
    rescue ::Afterpay::BaseError
      nil
    end

    def retrieve_configuration
      ::Afterpay::API::Configuration::Retrieve.call.body
    rescue ::Afterpay::BaseError
      nil
    end

    private

    def immediate_capture(amount, _response_code, gateway_options)
      payment_source = gateway_options[:originator].payment_source

      ::Afterpay::API::Payment::Capture.call(
        payment: ::Afterpay::Components::Payment.new(
          token: payment_source.token,
          amount: ::Afterpay::Components::Money.new(
            amount: Money.from_cents(amount).amount.to_s,
            currency: gateway_options[:currency]
          )
        )
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
