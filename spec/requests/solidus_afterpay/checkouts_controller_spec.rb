# frozen_string_literal: true

require 'spec_helper'

describe SolidusAfterpay::CheckoutsController, type: :request do
  describe 'POST create' do
    subject(:request) { post '/solidus_afterpay/checkouts.json', params: params }

    let(:order) { create(:order_with_totals, state: 'payment', user: user) }
    let(:payment_method) { create(:afterpay_payment_method) }
    let(:user) { create(:user) }

    let(:order_number) { order.number }
    let(:payment_method_id) { payment_method.id }

    let(:params) { { order_number: order_number, payment_method_id: payment_method_id } }

    let(:order_token) { 'ORDER_TOKEN' }
    let(:gateway_response_success?) { true }
    let(:gateway_response_message) { 'Success message' }
    let(:gateway_response_params) { { 'token' => order_token } }

    let(:gateway_response) do
      ActiveMerchant::Billing::Response.new(
        gateway_response_success?,
        gateway_response_message,
        gateway_response_params
      )
    end

    let(:gateway) { instance_double(SolidusAfterpay::Gateway, create_checkout: gateway_response) }

    before do
      allow(SolidusAfterpay::Gateway).to receive(:new).and_return(gateway)
    end

    context 'when the user is logged in', with_signed_in_user: true do
      context 'with valid data' do
        before do
          allow(Spree::Order).to receive(:find_by!).with(number: order.number).and_return(order)
          request
        end

        it 'returns a 201 status code' do
          expect(response).to have_http_status(:created)
        end

        it 'returns the order_token' do
          expect(JSON.parse(response.body)['token']).to eq(order_token)
        end

        it 'returns the correct params' do
          expect(JSON.parse(response.body)).to include('token', 'expires', 'redirectCheckoutUrl')
        end

        context 'when no redirect URLs are passed as params' do
          let(:redirect_confirm_url) do
            "http://www.example.com/solidus_afterpay/callbacks/confirm?order_number=#{order.number}&payment_method_id=#{payment_method.id}"
          end

          let(:redirect_cancel_url) do
            "http://www.example.com/solidus_afterpay/callbacks/cancel?order_number=#{order.number}&payment_method_id=#{payment_method.id}"
          end

          it 'calls the create_checkout with the correct arguments' do
            expect(gateway).to have_received(:create_checkout).with(
              order,
              redirect_confirm_url: redirect_confirm_url,
              redirect_cancel_url: redirect_cancel_url
            )
          end
        end

        context 'when redirect URLs are passed as params' do
          let(:redirect_confirm_url) { 'http://www.example.com/confirm_url' }
          let(:redirect_cancel_url) { 'http://www.example.com/cancel_url' }

          let(:params) do
            { order_number: order_number, payment_method_id: payment_method_id,
              redirect_confirm_url: redirect_confirm_url, redirect_cancel_url: redirect_cancel_url }
          end

          it 'calls the create_checkout with the correct arguments' do
            expect(gateway).to have_received(:create_checkout).with(
              order,
              redirect_confirm_url: redirect_confirm_url,
              redirect_cancel_url: redirect_cancel_url
            )
          end
        end
      end

      context 'when the order_number is invalid' do
        let(:order_number) { 'INVALID_ORDER_NUMBER' }

        before { request }

        it 'returns a 404 status code' do
          expect(response).to have_http_status(:not_found)
        end

        it 'returns a resource not found error message' do
          expect(JSON.parse(response.body)['error']).to eq('The resource you were looking for could not be found.')
        end
      end

      context 'when the payment_method_id is invalid' do
        let(:payment_method_id) { 0 }

        before { request }

        it 'returns a 404 status code' do
          expect(response).to have_http_status(:not_found)
        end

        it 'returns a resource not found error message' do
          expect(JSON.parse(response.body)['error']).to eq('The resource you were looking for could not be found.')
        end
      end

      context 'when the gateway responds with error' do
        let(:gateway_response_success?) { false }
        let(:gateway_response_message) { 'Error message' }

        before { request }

        it 'returns a 422 status code' do
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns a resource not found error message' do
          expect(JSON.parse(response.body)['error']).to eq(gateway_response_message)
        end
      end
    end

    context 'when the user is a guest user', with_guest_session: true do
      it 'returns a 201 status code' do
        request
        expect(response).to have_http_status(:created)
      end
    end

    context 'when the user is not logged in' do
      it 'returns a 401 status code' do
        request
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
