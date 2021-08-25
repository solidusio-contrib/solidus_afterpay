# frozen_string_literal: true

module SolidusAfterpay
  module Spree
    module CheckoutControllerDecorator
      def self.prepended(base)
        base.helper ::SolidusAfterpay::AfterpayHelper
      end

      ::Spree::CheckoutController.prepend(self) if SolidusSupport.frontend_available?
    end
  end
end
