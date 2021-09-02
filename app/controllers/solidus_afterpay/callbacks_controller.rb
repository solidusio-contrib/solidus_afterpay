# frozen_string_literal: true

module SolidusAfterpay
  class CallbacksController < ::Spree::BaseController
    protect_from_forgery except: [:confirm, :cancel]

    rescue_from ::ActiveRecord::RecordNotFound, with: :resource_not_found

    def confirm
      if !order_token
        return redirect_to checkout_state_path(order.state), notice: I18n.t('solidus_afterpay.order_token_not_found')
      end

      if order.complete?
        return redirect_to spree.order_path(order), notice: I18n.t('spree.order_already_completed')
      end

      if ::Spree::OrderUpdateAttributes.new(order, update_params, request_env: request.headers.env).apply
        order.next
      end

      redirect_to checkout_state_path(order.state)
    end

    def cancel
      redirect_to checkout_state_path(order.state)
    end

    private

    def update_params
      {
        payments_attributes: [{
          payment_method: payment_method,
          amount: order.total,
          source_attributes: {
            token: order_token
          }
        }]
      }
    end

    def order
      @order ||= ::Spree::Order.find_by!(number: params[:order_number])
    end

    def payment_method
      @payment_method ||= SolidusAfterpay::PaymentMethod.active.find(params[:payment_method_id])
    end

    def order_token
      params[:orderToken]
    end

    def resource_not_found
      redirect_to spree.cart_path, notice: I18n.t('solidus_afterpay.resource_not_found')
    end
  end
end
