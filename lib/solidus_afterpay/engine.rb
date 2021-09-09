# frozen_string_literal: true

require 'solidus_core'
require 'solidus_support'

module SolidusAfterpay
  class Engine < Rails::Engine
    include SolidusSupport::EngineExtensions

    isolate_namespace ::Spree

    engine_name 'solidus_afterpay'

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    initializer "spree.payment_methods.register_afterpay_payment_method",
      after: "spree.register.payment_methods" do |app|
      app.config.spree.payment_methods << "SolidusAfterpay::PaymentMethod"
      Spree::PermittedAttributes.source_attributes.concat [:token]
    end
  end
end
