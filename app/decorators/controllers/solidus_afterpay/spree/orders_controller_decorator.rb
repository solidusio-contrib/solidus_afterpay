# frozen_string_literal: true

module SolidusAfterpay
  module Spree
    module OrdersControllerDecorator
      def self.prepended(base)
        base.helper ::SolidusAfterpay::AfterpayHelper
      end

      ::Spree::OrdersController.prepend(self) if SolidusSupport.frontend_available?
    end
  end
end
