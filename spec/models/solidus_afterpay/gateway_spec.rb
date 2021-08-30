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

    let(:amount) { 1000 }
    let(:payment_source) { build(:afterpay_payment_source) }
    let(:gateway_options) { {} }

    it 'returns a successful response' do
      is_expected.to be_success
    end
  end

  describe '#capture' do
    subject(:response) { gateway.capture(amount, response_code, gateway_options) }

    let(:order_token) { '002.nt7e0ioqj00fh0ua1nbqcj6vcn9obtfsglqvrj9ijpo3edfc' }
    let(:payment_source) { build(:afterpay_payment_source, token: order_token) }
    let(:payment) { build(:afterpay_payment, source: payment_source) }

    let(:amount) { 1000 }
    let(:response_code) { nil }
    let(:gateway_options) { { originator: payment } }

    context 'with valid params', vcr: 'capture/valid' do
      it 'captures the afterpay payment with the order_token' do
        is_expected.to be_success
      end
    end

    context 'with an invalid token', vcr: 'capture/invalid' do
      let(:order_token) { 'INVALID_TOKEN' }

      it 'returns an unsuccesfull response' do
        is_expected.not_to be_success
      end

      it 'returns the error message from Afterpay in the response' do
        expect(response.message).to eq('Cannot complete payment, expired or invalid token.')
      end
    end

    context 'with an invalid credit card', vcr: 'capture/declined_payment' do
      let(:order_token) { '002.kj16plsn63eqfacueg767cp7l34e9ph5tms4ql14o2iid7l1' }

      it 'returns an unsuccesfull response' do
        is_expected.not_to be_success
      end

      it 'returns the error message from Afterpay in the response' do
        expect(response.message).to eq(
          'Payment declined. Please contact the Afterpay Customer Service team for more information.'
        )
      end
    end
  end

  describe '#purchase' do
    subject(:response) { gateway.purchase(amount, payment_source, gateway_options) }

    let(:order_token) { '002.nt7e0ioqj00fh0ua1nbqcj6vcn9obtfsglqvrj9ijpo3edfc' }
    let(:payment) { build(:afterpay_payment, source: payment_source) }

    let(:amount) { 1000 }
    let(:payment_source) { build(:afterpay_payment_source, token: order_token) }
    let(:gateway_options) { { originator: payment } }

    context 'with valid params', vcr: 'capture/valid' do
      it 'authorize and captures the afterpay payment with the order_token' do
        is_expected.to be_success
      end
    end

    context 'with an invalid token', vcr: 'capture/invalid' do
      let(:order_token) { 'INVALID_TOKEN' }

      it 'returns an unsuccesfull response' do
        is_expected.not_to be_success
      end

      it 'returns the error message from Afterpay in the response' do
        expect(response.message).to eq('Cannot complete payment, expired or invalid token.')
      end
    end

    context 'with an invalid credit card', vcr: 'capture/declined_payment' do
      let(:order_token) { '002.kj16plsn63eqfacueg767cp7l34e9ph5tms4ql14o2iid7l1' }

      it 'returns an unsuccesfull response' do
        is_expected.not_to be_success
      end

      it 'returns the error message from Afterpay in the response' do
        expect(response.message).to eq(
          'Payment declined. Please contact the Afterpay Customer Service team for more information.'
        )
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
    end
  end

  describe '#void' do
    subject(:response) { gateway.void(response_code, gateway_options) }

    let(:response_code) { '100101768366' }
    let(:gateway_options) { {} }

    it 'returns an unsuccessful response' do
      is_expected.not_to be_success
    end

    it 'returns the error message from Afterpay in the response' do
      expect(response.message).to eq("Transaction can't be voided")
    end
  end
end
