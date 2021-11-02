# frozen_string_literal: true

module SolidusAfterpay
  class ExpressCallbacksController < SolidusAfterpay.api_base_controller_parent_class
    def create
      authorize! :update, order, order_token

      unless SolidusAfterpay.update_order_attributes_service_class.call(
        order: order,
        afterpay_order_token: params[:token],
        payment_method: payment_method,
        request_env: request.headers.env
      )
        render(
          json: {
            error: I18n.t('solidus_afterpay.express_checkout.errors.unable_place_order'),
            errorCode: :internal_server_error
          },
          status: :internal_server_error
        )
        return
      end

      order.next!
      order.next!

      SolidusAfterpay.config.use_solidus_api ? solidus_api_response : solidus_frontend_response
    end

    def update
      authorize! :update, order, order_token

      unless SolidusAfterpay::UpdateOrderAddressesService.call(order: order, address_params: params[:address])
        render json: { errorCode: :internal_server_error }, status: :internal_server_error
        return
      end

      order.next!
      # rubocop:disable Rails/SkipsModelValidations
      order.update_columns(email: nil) if order.email == SolidusAfterpay.configuration.dummy_email
      # rubocop:enable Rails/SkipsModelValidations

      render(
        json: {
          data: ::SolidusAfterpay.shipping_rate_builder_service_class.call(order: order)
        },
        status: :ok
      )
    end

    private

    def order
      @order ||= ::Spree::Order.find_by!(number: params[:order_number])
    end

    def payment_method
      @payment_method ||= SolidusAfterpay::PaymentMethod.active.find(params[:payment_method_id])
    end

    def solidus_api_response
      respond_with(
        order.reload,
        status: :ok,
        default_template: 'spree/api/orders/show'
      )
    end

    def solidus_frontend_response
      render json: { redirect_url: checkout_state_url(order.state) }, status: :ok
    end
  end
end
