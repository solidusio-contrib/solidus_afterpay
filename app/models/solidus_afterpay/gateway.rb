# frozen_string_literal: true

require 'afterpay'

module SolidusAfterpay
  class Gateway
    def initialize(options)
      ::Afterpay.configure do |config|
        config.merchant_id = options[:merchant_id]
        config.secret_key = options[:secret_key]
        config.server = 'https://api.us-sandbox.afterpay.com/' if options[:test_mode]
        config.user_agent = SolidusAfterpay::UserAgentGenerator.new(merchant_id: options[:merchant_id]).generate
      end
    end

    def authorize(_amount, _payment_source, _gateway_options)
      ActiveMerchant::Billing::Response.new(true, 'Transaction approved')
    end

    def capture(_amount, _response_code, gateway_options)
      payment_source = gateway_options[:originator].payment_source

      response = ::Afterpay::API::Payment::Capture.call(
        payment: ::Afterpay::Components::Payment.new(token: payment_source.token)
      )
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
  end
end
