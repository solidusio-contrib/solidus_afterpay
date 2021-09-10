# frozen_string_literal: true

module SolidusAfterpay
  class ExpressCallbacksController < SolidusAfterpay::BaseController
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
  end
end
