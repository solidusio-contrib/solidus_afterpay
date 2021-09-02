# frozen_string_literal: true

module SolidusAfterpay
  class CheckoutsController < ::Spree::BaseController
    protect_from_forgery except: [:create]

    rescue_from ::ActiveRecord::RecordNotFound, with: :resource_not_found

    def create
      response = payment_method.gateway.create_checkout(
        order,
        redirect_confirm_url: solidus_afterpay.callbacks_confirm_url(
          order_number: order.number, payment_method_id: payment_method.id
        ),
        redirect_cancel_url: solidus_afterpay.callbacks_cancel_url(
          order_number: order.number, payment_method_id: payment_method.id
        )
      )
      if response.success?
        render json: { token: response.params['token'] }
      else
        render json: { error: response.message }, status: :internal_server_error
      end
    end

    private

    def order
      @order ||= ::Spree::Order.find_by!(number: params[:order_number])
    end

    def payment_method
      @payment_method ||= SolidusAfterpay::PaymentMethod.active.find(params[:payment_method_id])
    end

    def resource_not_found
      render json: { error: I18n.t('solidus_afterpay.resource_not_found') }, status: :not_found
    end
  end
end
