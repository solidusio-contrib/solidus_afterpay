# frozen_string_literal: true

module SolidusAfterpay
  class CallbacksController < SolidusAfterpay::BaseController
    before_action :ensure_afterpay_order_token_presence, only: :confirm
    before_action :ensure_order_not_completed, only: :confirm

    def confirm
      authorize! :update, order, order_token

      if ::Spree::OrderUpdateAttributes.new(order, update_params, request_env: request.headers.env).apply
        order.next
      end

      respond_to do |format|
        format.html { redirect_to checkout_state_path(order.state) }
        format.json { render json: { redirect_url: checkout_state_url(order.state) } }
      end
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
            token: afterpay_order_token
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

    def afterpay_order_token
      params[:orderToken] || params[:order_token]
    end

    def ensure_afterpay_order_token_presence
      return if afterpay_order_token

      respond_to do |format|
        format.html {
          redirect_to checkout_state_path(order.state), notice: I18n.t('solidus_afterpay.order_token_not_found')
        }
        format.json { render json: { error: I18n.t('solidus_afterpay.order_token_not_found') }, status: :not_found }
      end
    end

    def ensure_order_not_completed
      return unless order.complete?

      respond_to do |format|
        format.html { redirect_to spree.order_path(order), notice: I18n.t('spree.order_already_completed') }
        format.json { render json: { error: I18n.t('spree.order_already_completed') }, status: :unprocessable_entity }
      end
    end
  end
end
