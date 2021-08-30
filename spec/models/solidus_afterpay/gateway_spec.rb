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
end
