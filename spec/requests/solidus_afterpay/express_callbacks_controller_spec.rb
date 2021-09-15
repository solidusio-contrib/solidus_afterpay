# frozen_string_literal: true

require 'spec_helper'

describe SolidusAfterpay::ExpressCallbacksController, type: :request do
  describe 'PATCH update' do
    subject(:request) do
      patch "/solidus_afterpay/express_callbacks/#{order.number}.json", params: params, headers: headers
    end

    let(:user) { create(:user, :with_api_key) }
    let(:order) { create(:order_with_line_items, state: 'address', line_items_count: 2, user: user) }

    let(:headers) { {} }
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

    context 'when the use solidus api config is set to false' do
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

    context 'when the use solidus api config is set to true', use_solidus_api: true do
      context 'when the user is not authorized' do
        it 'returns 401 status code' do
          request
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context 'when the user is a guest user' do
        let(:headers) { { 'X-Spree-Order-Token': order.guest_token } }

        it 'returns 200 status code' do
          request
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when the user is logged in' do
        let(:headers) { { Authorization: "Bearer #{user.spree_api_key}" } }

        it 'returns 200 status code' do
          request
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe 'POST create' do
    subject(:request) do
      post "/solidus_afterpay/express_callbacks/#{order.number}.json", params: params, headers: headers
    end

    let(:user) { create(:user, :with_api_key) }
    let(:order) { create(:order_with_line_items, state: 'delivery', line_items_count: 2, user: user) }
    let(:payment_method) { create(:afterpay_payment_method) }

    let(:order_token) { 'TOKEN' }
    let(:update_order_attributes_service_result) { true }

    let(:headers) { {} }
    let(:params) do
      {
        token: order_token,
        order_number: order.number,
        payment_method_id: payment_method.id,
      }
    end

    before do
      allow(SolidusAfterpay.update_order_attributes_service_class)
        .to receive(:call)
        .and_return(update_order_attributes_service_result)
    end

    context 'when the use solidus api config is set to false' do
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
        it 'returns 200 status code' do
          request
          expect(response).to have_http_status(:ok)
        end

        it 'calls the update order attributes service class' do
          request
          expect(SolidusAfterpay.update_order_attributes_service_class)
            .to have_received(:call)
            .with(
              order: order,
              afterpay_order_token: order_token,
              payment_method: payment_method,
              request_env: an_instance_of(Hash)
            )
        end

        it 'changes the order state to confirm' do
          expect { request }.to change { order.reload.state }.from('delivery').to('confirm')
        end

        it 'redirects the user to the checkout confirm step' do
          request
          expect(json_response['redirect_url']).to eq('http://www.example.com/checkout/confirm')
        end

        context 'when the update order attributes service fails' do
          let(:update_order_attributes_service_result) { false }

          it 'returns 500 status code' do
            request
            expect(response).to have_http_status(:internal_server_error)
          end
        end
      end

      context 'when the use solidus api config is set to true', use_solidus_api: true do
        context 'when the user is not authorized' do
          it 'returns 401 status code' do
            request
            expect(response).to have_http_status(:unauthorized)
          end
        end

        context 'when the user is a guest user' do
          let(:headers) { { 'X-Spree-Order-Token': order.guest_token } }

          it 'returns 200 status code' do
            request
            expect(response).to have_http_status(:ok)
          end
        end

        context 'when the user is logged in' do
          let(:headers) { { Authorization: "Bearer #{user.spree_api_key}" } }

          it 'returns 200 status code' do
            request
            expect(response).to have_http_status(:ok)
          end
        end
      end
    end
  end
end
