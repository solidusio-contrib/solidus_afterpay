# frozen_string_literal: true

require 'spec_helper'

describe SolidusAfterpay::CallbacksController do
  describe 'GET cancel' do
    subject(:request) { get '/solidus_afterpay/callbacks/cancel', params: params }

    let(:order) { create(:order_with_totals, state: 'payment') }

    let(:params) { { order_number: order.number } }

    it 'redirects to the order current checkout state page' do
      request
      expect(response).to redirect_to('/checkout/payment')
    end
  end

  describe 'GET confirm' do
    subject(:request) { get '/solidus_afterpay/callbacks/confirm', params: params }

    let(:order) { create(:order_with_totals, state: 'payment', user: user) }
    let(:payment_method) { create(:afterpay_payment_method) }
    let(:user) { create(:user) }

    let(:order_token) { 'ORDER_TOKEN' }
    let(:order_number) { order.number }
    let(:payment_method_id) { payment_method.id }

    let(:params) { { orderToken: order_token, order_number: order_number, payment_method_id: payment_method_id } }

    context 'when the user is logged in', :with_signed_in_user do
      context 'with valid data' do
        it 'redirects to the order next checkout state page' do
          request
          expect(response).to redirect_to('/checkout/confirm')
        end

        it 'moves the order to its next state' do
          expect { request }.to change { order.reload.state }.from('payment').to('confirm')
        end

        it 'creates a payment' do
          expect { request }.to change { order.payments.count }.from(0).to(1)
        end

        it 'sets the payment total equal to the order total' do
          request
          expect(order.payments.last.amount).to eq(order.total)
        end

        it 'creates a payment source and assigns the order token to it' do
          request
          expect(order.payments.last.payment_source.token).to eq(order_token)
        end
      end

      context 'when the order_token is missing' do
        let(:order_token) { nil }

        it 'redirects to the order current checkout state page' do
          request
          expect(response).to redirect_to('/checkout/payment')
        end
      end

      context 'when the order_number is invalid' do
        let(:order_number) { 'INVALID_ORDER_NUMBER' }

        it 'redirects to the cart page' do
          request
          expect(response).to redirect_to('/cart')
        end

        it 'sets a resource not found flash message' do
          request
          expect(flash[:notice]).to eq('The resource you were looking for could not be found.')
        end
      end

      context 'when the payment_method_id is invalid' do
        let(:payment_method_id) { 0 }

        it 'redirects to the cart page' do
          request
          expect(response).to redirect_to('/cart')
        end

        it 'sets a resource not found flash message' do
          request
          expect(flash[:notice]).to eq('The resource you were looking for could not be found.')
        end
      end

      context 'when the order is already in confirm state' do
        let(:order) { create(:order_with_totals, state: 'confirm') }

        it "doesn't move the order to its next state" do
          expect { request }.not_to(change { order.reload.state })
        end
      end

      context 'when the order is already completed' do
        let(:order) { create(:completed_order_with_totals) }

        it 'redirects to the order detail page' do
          request
          expect(response).to redirect_to("/orders/#{order.number}")
        end
      end
    end

    context 'when the user is a guest user', :with_guest_session do
      it 'redirects to the order next checkout state page' do
        request
        expect(response).to redirect_to('/checkout/confirm')
      end
    end

    context 'when the user is not logged in' do
      it 'redirects the user to vallalah' do
        request
        expect(response).to redirect_to('/cart')
      end
    end
  end
end
