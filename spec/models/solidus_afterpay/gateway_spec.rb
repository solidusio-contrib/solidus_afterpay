# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidusAfterpay::Gateway do
  let(:gateway) { described_class.new(options) }
  let(:options) do
    {
      merchant_id: ENV.fetch('AFTERPAY_MERCHANT_ID', 'dummy_merchant_id'),
      secret_key: ENV.fetch('AFTERPAY_SECRET_KEY', 'dummy_secret_key'),
      test_mode: true
    }
  end

  describe '#authorize' do
    subject(:response) { gateway.authorize(amount, payment_source, gateway_options) }

    let(:order_token) { '002.m6d9jkrtv1p0j4jqslklhfq9k4nl54jo2530d58kf6snpqq1' }
    let(:auto_capture) { true }
    let(:payment_method) { build(:afterpay_payment_method, auto_capture: auto_capture) }

    let(:amount) { 1000 }
    let(:payment_source) { build(:afterpay_payment_source, token: order_token, payment_method: payment_method) }
    let(:gateway_options) { {} }

    context 'with the immediate flow' do
      it 'returns a successful response' do
        is_expected.to be_success
      end
    end

    context 'with the deferred flow' do
      let(:auto_capture) { false }

      context 'with valid params', vcr: 'deferred/authorize/valid' do
        it 'authorize the afterpay payment with the order_token' do
          is_expected.to be_success
        end
      end

      context 'with an invalid token', vcr: 'deferred/authorize/invalid' do
        let(:order_token) { 'INVALID_TOKEN' }

        it 'returns an unsuccesfull response' do
          is_expected.not_to be_success
        end

        it 'returns the error message from Afterpay in the response' do
          expect(response.message).to eq('Cannot complete payment, expired or invalid token.')
        end

        it 'returns the error_code from Afterpay in the response' do
          expect(response.error_code).to eq('invalid_token')
        end
      end

      context 'with an invalid credit card', vcr: 'deferred/authorize/declined_payment' do
        let(:order_token) { '002.ijlqnvko1o4ou45uabplrl9pqao8u2v52njs2972r24hje65' }

        it 'returns an unsuccesfull response' do
          is_expected.not_to be_success
        end

        it 'returns the error message from Afterpay in the response' do
          expect(response.message).to eq(
            'Payment declined. Please contact the Afterpay Customer Service team for more information.'
          )
        end

        it 'returns the error_code from Afterpay in the response' do
          expect(response.error_code).to eq('payment_declined')
        end
      end

      context 'with a timeout error' do
        before do
          allow(Afterpay::API::Payment::Auth).to receive(:call).and_raise(
            Afterpay::RequestTimeoutError.new('request_timeout'), 'Request Timeout'
          )
          allow(Afterpay::API::Payment::Reversal).to receive(:call)
        end

        it 'returns an unsuccesfull response' do
          is_expected.not_to be_success
        end

        it 'returns the error message from Afterpay in the response' do
          expect(response.message).to eq('Request Timeout')
        end

        it 'returns the error_code from Afterpay in the response' do
          expect(response.error_code).to eq('request_timeout')
        end

        it 'calls the ::Afterpay::API::Payment::Reversal with order token' do
          response
          expect(Afterpay::API::Payment::Reversal).to have_received(:call).with(token: order_token)
        end
      end
    end
  end

  describe '#capture' do
    subject(:response) { gateway.capture(amount, response_code, gateway_options) }

    let(:order_token) { '002.nt7e0ioqj00fh0ua1nbqcj6vcn9obtfsglqvrj9ijpo3edfc' }
    let(:auto_capture) { true }
    let(:payment_source) { build(:afterpay_payment_source, token: order_token) }
    let(:payment_method) { build(:afterpay_payment_method, auto_capture: auto_capture) }
    let(:payment) { build(:afterpay_payment, source: payment_source, payment_method: payment_method) }

    let(:amount) { 1000 }
    let(:response_code) { '100101782114' }
    let(:gateway_options) { { originator: payment, currency: 'USD' } }

    context 'with the immediate flow' do
      context 'with valid params', vcr: 'immediate/capture/valid' do
        it 'captures the afterpay payment with the order_token' do
          is_expected.to be_success
        end
      end

      context 'with an invalid token', vcr: 'immediate/capture/invalid' do
        let(:order_token) { 'INVALID_TOKEN' }

        it 'returns an unsuccesfull response' do
          is_expected.not_to be_success
        end

        it 'returns the error message from Afterpay in the response' do
          expect(response.message).to eq('Cannot complete payment, expired or invalid token.')
        end

        it 'returns the error_code from Afterpay in the response' do
          expect(response.error_code).to eq('invalid_token')
        end
      end

      context 'with an invalid credit card', vcr: 'immediate/capture/declined_payment' do
        let(:order_token) { '002.kj16plsn63eqfacueg767cp7l34e9ph5tms4ql14o2iid7l1' }

        it 'returns an unsuccesfull response' do
          is_expected.not_to be_success
        end

        it 'returns the error message from Afterpay in the response' do
          expect(response.message).to eq(
            'Payment declined. Please contact the Afterpay Customer Service team for more information.'
          )
        end

        it 'returns the error_code from Afterpay in the response' do
          expect(response.error_code).to eq('payment_declined')
        end
      end
    end

    context 'with the deferred flow' do
      let(:auto_capture) { false }

      context 'with valid params', vcr: 'deferred/capture/valid' do
        it 'captures the afterpay payment with the order_id' do
          is_expected.to be_success
        end
      end

      context 'with an invalid payment ID', vcr: 'deferred/capture/invalid' do
        let(:response_code) { 'INVALID_RESPONSE_CODE' }

        it 'returns an unsuccesfull response' do
          is_expected.not_to be_success
        end

        it 'returns the error message from Afterpay in the response' do
          expect(response.message).to eq('Afterpay payment ID not found.')
        end

        it 'returns the error_code from Afterpay in the response' do
          expect(response.error_code).to eq('not_found')
        end
      end

      context 'with a timeout error' do
        before do
          allow(Afterpay::API::Payment::DeferredCapture).to receive(:call).and_raise(
            Afterpay::RequestTimeoutError.new('request_timeout'), 'Request Timeout'
          )
          allow(Afterpay::API::Payment::Reversal).to receive(:call)
        end

        it 'returns an unsuccesfull response' do
          is_expected.not_to be_success
        end

        it 'returns the error message from Afterpay in the response' do
          expect(response.message).to eq('Request Timeout')
        end

        it 'returns the error_code from Afterpay in the response' do
          expect(response.error_code).to eq('request_timeout')
        end

        it 'calls the ::Afterpay::API::Payment::Reversal with order token' do
          response
          expect(Afterpay::API::Payment::Reversal).to have_received(:call).with(token: order_token)
        end
      end
    end
  end

  describe '#purchase' do
    subject(:response) { gateway.purchase(amount, payment_source, gateway_options) }

    let(:order_token) { '002.nt7e0ioqj00fh0ua1nbqcj6vcn9obtfsglqvrj9ijpo3edfc' }
    let(:auto_capture) { true }
    let(:payment_method) { build(:afterpay_payment_method, auto_capture: auto_capture) }
    let(:payment) { build(:afterpay_payment, source: payment_source, payment_method: payment_method) }

    let(:amount) { 1000 }
    let(:payment_source) { build(:afterpay_payment_source, token: order_token, payment_method: payment_method) }
    let(:gateway_options) { { originator: payment, currency: 'USD' } }

    context 'with the immediate flow' do
      context 'with valid params', vcr: 'immediate/capture/valid' do
        it 'authorize and captures the afterpay payment with the order_token' do
          is_expected.to be_success
        end
      end

      context 'with an invalid token', vcr: 'immediate/capture/invalid' do
        let(:order_token) { 'INVALID_TOKEN' }

        it 'returns an unsuccesfull response' do
          is_expected.not_to be_success
        end

        it 'returns the error message from Afterpay in the response' do
          expect(response.message).to eq('Cannot complete payment, expired or invalid token.')
        end

        it 'returns the error_code from Afterpay in the response' do
          expect(response.error_code).to eq('invalid_token')
        end
      end

      context 'with an invalid credit card', vcr: 'immediate/capture/declined_payment' do
        let(:order_token) { '002.kj16plsn63eqfacueg767cp7l34e9ph5tms4ql14o2iid7l1' }

        it 'returns an unsuccesfull response' do
          is_expected.not_to be_success
        end

        it 'returns the error message from Afterpay in the response' do
          expect(response.message).to eq(
            'Payment declined. Please contact the Afterpay Customer Service team for more information.'
          )
        end

        it 'returns the error_code from Afterpay in the response' do
          expect(response.error_code).to eq('payment_declined')
        end
      end
    end

    context 'with the deferred flow' do
      let(:auto_capture) { false }

      context 'with valid params', vcr: 'deferred/authorize/valid' do
        it 'authorize and captures the afterpay payment with the order_token' do
          VCR.use_cassette('deferred/capture/valid') do
            is_expected.to be_success
          end
        end
      end

      context 'with an invalid token', vcr: 'deferred/authorize/invalid' do
        let(:order_token) { 'INVALID_TOKEN' }

        it 'returns an unsuccesfull response' do
          is_expected.not_to be_success
        end

        it 'returns the error message from Afterpay in the response' do
          expect(response.message).to eq('Cannot complete payment, expired or invalid token.')
        end

        it 'returns the error_code from Afterpay in the response' do
          expect(response.error_code).to eq('invalid_token')
        end
      end

      context 'with an invalid credit card', vcr: 'deferred/authorize/declined_payment' do
        let(:order_token) { '002.kj16plsn63eqfacueg767cp7l34e9ph5tms4ql14o2iid7l1' }

        it 'returns an unsuccesfull response' do
          is_expected.not_to be_success
        end

        it 'returns the error message from Afterpay in the response' do
          expect(response.message).to eq(
            'Payment declined. Please contact the Afterpay Customer Service team for more information.'
          )
        end

        it 'returns the error_code from Afterpay in the response' do
          expect(response.error_code).to eq('payment_declined')
        end
      end
    end
  end

  describe '#credit' do
    subject(:response) { gateway.credit(amount, response_code, gateway_options) }

    let(:payment) { build(:afterpay_payment) }
    let(:refund) { build(:refund, payment: payment) }

    let(:amount) { 1000 }
    let(:response_code) { '100101768366' }
    let(:gateway_options) { { originator: refund } }

    context 'with valid params', vcr: 'credit/valid' do
      it 'refunds the amount using the response_code' do
        is_expected.to be_success
      end
    end

    context 'with an invalid response_code', vcr: 'credit/invalid' do
      let(:response_code) { 'INVALID_RESPONSE_CODE' }

      it 'returns an unsuccesfull response' do
        is_expected.not_to be_success
      end

      it 'returns the error message from Afterpay in the response' do
        expect(response.message).to eq('Afterpay payment ID not found.')
      end

      it 'returns the error_code from Afterpay in the response' do
        expect(response.error_code).to eq('not_found')
      end
    end
  end

  describe '#void' do
    subject(:response) { gateway.void(response_code, gateway_options) }

    let(:auto_capture) { true }
    let(:amount) { 10 }
    let(:payment_method) { build(:afterpay_payment_method, auto_capture: auto_capture) }
    let(:payment) { build(:afterpay_payment, payment_method: payment_method, amount: amount) }

    let(:response_code) { '100101785223' }
    let(:gateway_options) { { originator: payment, currency: 'USD' } }

    context 'with the immediate flow' do
      it 'returns an unsuccessful response' do
        is_expected.not_to be_success
      end

      it 'returns the error message from Afterpay in the response' do
        expect(response.message).to eq("Transaction can't be voided")
      end

      it 'returns the error_code from Afterpay in the response' do
        expect(response.error_code).to eq('void_not_allowed')
      end
    end

    context 'with the deferred flow' do
      let(:auto_capture) { false }

      context 'with valid params', vcr: 'deferred/void/valid' do
        it 'voids the payment using the response_code' do
          is_expected.to be_success
        end
      end

      context 'with an invalid response_code', vcr: 'deferred/void/invalid' do
        let(:response_code) { 'INVALID_RESPONSE_CODE' }

        it 'returns an unsuccesfull response' do
          is_expected.not_to be_success
        end

        it 'returns the error message from Afterpay in the response' do
          expect(response.message).to eq('Afterpay payment ID not found.')
        end

        it 'returns the error_code from Afterpay in the response' do
          expect(response.error_code).to eq('not_found')
        end
      end
    end
  end

  describe '#create_checkout' do
    subject(:response) { gateway.create_checkout(order, gateway_options) }

    let(:redirect_confirm_url) { 'https://merchantsite.com/confirm' }
    let(:redirect_cancel_url) { 'https://merchantsite.com/cancel' }

    let(:order) { build(:order_with_line_items) }
    let(:gateway_options) { { redirect_confirm_url: redirect_confirm_url, redirect_cancel_url: redirect_cancel_url } }

    context 'with valid params', vcr: 'create_checkout/valid' do
      it 'creates the checkout' do
        is_expected.to be_success
      end

      it 'returns the order_token' do
        expect(response.params).to include('token')
      end
    end

    context 'with an invalid params', vcr: 'create_checkout/invalid' do
      let(:redirect_confirm_url) { 'INVALID_URL' }

      it 'returns an unsuccesfull response' do
        is_expected.not_to be_success
      end

      it 'returns the error message from Afterpay in the response' do
        expect(response.message).to eq('merchant.redirectConfirmUrl must be a valid URL')
      end

      it 'returns the error_code from Afterpay in the response' do
        expect(response.error_code).to eq('invalid_object')
      end
    end
  end

  describe '#find_payment' do
    subject(:response) { gateway.find_payment(order_id: order_id) }

    let(:order_id) { '100101785223' }

    context 'with valid params', vcr: 'find_payment/valid' do
      it 'retrieves the Afterpay payment' do
        expect(response).to include('id' => order_id)
      end
    end

    context 'with an invalid params', vcr: 'find_payment/invalid' do
      let(:order_id) { 'INVALID_ORDER_ID' }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end
  end

  describe '#find_order' do
    subject(:response) { gateway.find_order(token: token) }

    let(:token) { '002.cb9qevbs1o4el3adh817hqkotkbv4b8u1jkekofd3nb2m8lu' }

    context 'with valid params', vcr: 'find_order/valid' do
      it 'retrieves the Afterpay order' do
        expect(response).to include(token: token)
      end
    end

    context 'with an invalid params', vcr: 'find_order/invalid' do
      let(:token) { 'INVALID_TOKEN' }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end
  end

  describe '#retrieve_configuration' do
    subject(:response) { gateway.retrieve_configuration }

    context 'with valid response', vcr: 'retrieve_configuration/valid' do
      it 'retrieves the afterpay configuration' do
        expect(response).to include('minimumAmount', 'maximumAmount')
      end
    end

    context 'with invalid response' do
      before do
        allow(Afterpay::API::Configuration::Retrieve).to receive(:call).and_raise(Afterpay::BaseError.new(nil))
      end

      it 'retrieves the afterpay configuration' do
        expect(response).to be_nil
      end
    end
  end
end
