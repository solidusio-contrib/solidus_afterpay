require 'spec_helper'

describe SolidusAfterpay::CheckoutsController, type: :request do
  describe 'POST create' do
    subject(:request) { post '/solidus_afterpay/checkouts', params: params }

    let(:order) { create(:order_with_totals, state: 'payment') }
    let(:payment_method) { create(:afterpay_payment_method) }

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

    context 'with valid data' do
      before do
        allow(Spree::Order).to receive(:find_by!).with(number: order.number).and_return(order)
        request
      end

      it 'calls the create_checkout with the correct arguments' do
        expect(gateway).to have_received(:create_checkout).with(
          order,
          redirect_confirm_url: "http://www.example.com/solidus_afterpay/callbacks/confirm?order_number=#{order.number}&payment_method_id=#{payment_method.id}",
          redirect_cancel_url: "http://www.example.com/solidus_afterpay/callbacks/cancel?order_number=#{order.number}&payment_method_id=#{payment_method.id}"
        )
      end

      it 'returns a 200 status code' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the order_token' do
        expect(JSON.parse(response.body)['token']).to eq(order_token)
      end

      it 'returns the corrent params' do
        expect(JSON.parse(response.body)).to include('token', 'expires', 'redirectCheckoutUrl')
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

      it 'returns a 500 status code' do
        expect(response).to have_http_status(:internal_server_error)
      end

      it 'returns a resource not found error message' do
        expect(JSON.parse(response.body)['error']).to eq(gateway_response_message)
      end
    end
  end
end
