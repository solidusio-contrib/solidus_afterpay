# frozen_string_literal: true

require 'spec_helper'

describe SolidusAfterpay::ExpressCallbacksController, type: :request do
  describe 'PATCH update' do
    subject(:request) { patch "/solidus_afterpay/express_callbacks/#{order.number}.json", params: params }

    let(:user) { create(:user) }
    let(:order) { create(:order_with_line_items, state: 'address', line_items_count: 2, user: user) }

    let(:params) do
      {
        address: {
          name: 'John Doe',
          address1: '8125 Centre St',
          address2: '',
          suburb: 'Citronelle',
          postcode: '36522-2156',
          phoneNumber: '1234567',
          countryCode: 'US',
          state: 'AL'
        }
      }
    end

    context 'when the user is not authorized' do
      it 'returns 401 status code' do
        request
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the user is a guest user', with_guest_session: true do
      it 'returns 200 status code' do
        request
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the user is logged in', with_signed_in_user: true do
      let(:update_order_address_service_result) { true }

      before do
        allow(SolidusAfterpay::UpdateOrderAddressesService)
          .to receive(:call)
          .and_return(update_order_address_service_result)

        allow(SolidusAfterpay.shipping_rate_builder_service_class)
          .to receive(:call)
      end

      it 'returns 200 status code' do
        request
        expect(response).to have_http_status(:ok)
      end

      it 'calls the update order addresses service' do
        request
        expect(SolidusAfterpay::UpdateOrderAddressesService)
          .to have_received(:call)
          .with(order: order, address_params: ActionController::Parameters.new(params[:address]))
      end

      it 'changes the order status' do
        expect { request }.to change { order.reload.state }.from('address').to('delivery')
      end

      it 'changes the order email if it has a dummy email' do
        order.update!(email: SolidusAfterpay.configuration.dummy_email)
        expect { request }.to change { order.reload.email }.from(SolidusAfterpay.configuration.dummy_email).to(nil)
      end

      it 'calls the shipping rate builder service class' do
        request
        expect(SolidusAfterpay.shipping_rate_builder_service_class)
          .to have_received(:call)
          .with(order: order)
      end

      context 'when the update order addresses service returns false' do
        let(:update_order_address_service_result) { false }

        it 'retuns an internal server error' do
          request
          expect(response).to have_http_status(:internal_server_error)
        end
      end
    end
  end
end
