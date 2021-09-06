# frozen_string_literal: true

module SolidusAfterpay
  module Spree
    module OrderDecorator
      def available_payment_methods
        @available_payment_methods ||= super.select do |payment_method|
          !payment_method.respond_to?(:available_for_order?) || payment_method.available_for_order?(self)
        end
      end

      ::Spree::Order.prepend self
    end
  end
end
