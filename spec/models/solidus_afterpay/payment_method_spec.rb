require 'spec_helper'

RSpec.describe SolidusAfterpay::PaymentMethod, type: :model do
  let(:payment_method) { described_class.new }

  describe "#gateway_class" do
    subject { payment_method.gateway_class }

    it { is_expected.to eq(SolidusAfterpay::Gateway) }
  end

  describe "#payment_source_class" do
    subject { payment_method.payment_source_class }

    it { is_expected.to eq(SolidusAfterpay::PaymentSource) }
  end

  describe "#partial_name" do
    subject { payment_method.partial_name }

    it { is_expected.to eq('afterpay') }
  end

  describe "#try_void" do
    subject { payment_method.try_void(payment) }

    let(:response_code) { 'RESPONSE_CODE' }
    let(:payment_source) { build(:afterpay_payment_source) }
    let(:payment) { build(:afterpay_payment, response_code: response_code, source: payment_source) }

    let(:can_void?) { true }
    let(:gateway_response_success?) { true }
    let(:gateway_response) { ActiveMerchant::Billing::Response.new(gateway_response_success?, '') }

    let(:gateway_options) { { originator: payment, currency: 'USD' } }

    before do
      allow(payment_source).to receive(:can_void?).and_return(can_void?)
      allow(payment_method).to receive(:void).with(response_code, gateway_options).and_return(gateway_response)
    end

    context 'when the void completes successful' do
      it 'returns the void response' do
        is_expected.to eq(gateway_response)
      end
    end

    context 'when the void throws an error' do
      let(:gateway_response_success?) { false }

      it { is_expected.to be(false) }
    end

    context "when the payment can't be voided" do
      let(:can_void?) { false }

      it { is_expected.to be(false) }
    end
  end

  describe "#available_for_order?" do
    subject { payment_method.available_for_order?(order) }

    let(:cache) { Rails.cache }

    let(:payment_method) { described_class.new }

    let(:order) { build(:order, currency: order_currency, total: order_total) }
    let(:order_total) { 5 }
    let(:order_currency) { 'USD' }

    context "with cache" do
      after do
        cache.clear
      end

      context 'when order total is inside the range' do
        before do
          cache.write("solidus_afterpay_configuration_maximumAmount_currency", "USD")
          cache.write("solidus_afterpay_configuration_maximumAmount_amount", 10.0)
          cache.write("solidus_afterpay_configuration_minimumAmount_amount", 1.0)
        end

        it { is_expected.to be(true) }
      end

      context 'when order total is outside the range' do
        before do
          cache.write("solidus_afterpay_configuration_maximumAmount_currency", "USD")
          cache.write("solidus_afterpay_configuration_maximumAmount_amount", 4.0)
          cache.write("solidus_afterpay_configuration_minimumAmount_amount", 1.0)
        end

        it { is_expected.to be(false) }
      end

      context 'when order currency is different from afterpay configuration' do
        before do
          cache.write("solidus_afterpay_configuration_maximumAmount_amount", 10.0)
          cache.write("solidus_afterpay_configuration_minimumAmount_amount", 1.0)
          cache.write("solidus_afterpay_configuration_maximumAmount_currency", "EUR")
        end

        it { is_expected.to be(false) }
      end

      context 'when order currency is the same from afterpay configuration' do
        before do
          cache.write("solidus_afterpay_configuration_maximumAmount_amount", 10.0)
          cache.write("solidus_afterpay_configuration_minimumAmount_amount", 1.0)
          cache.write("solidus_afterpay_configuration_maximumAmount_currency", "USD")
        end

        it { is_expected.to be(true) }
      end
    end

    context 'when there is no cache' do
      let(:configuration) do
        require 'hashie'

        Hashie::Mash.new({
          minimumAmount: { amount: '1', currency: 'USD' },
          maximumAmount: { amount: '10', currency: 'USD' }
        })
      end

      before do
        allow(payment_method.gateway).to receive(:retrieve_configuration).and_return(configuration)
      end

      context 'when order total is inside the range and the currency is the same from afterpay configuration' do
        it { is_expected.to be(true) }
      end

      context 'when order total is outside the range' do
        let(:order_total) { 11 }

        it { is_expected.to be(false) }
      end

      context 'when order currency is different from afterpay configuration' do
        let(:order_currency) { 'EUR' }

        it { is_expected.to be(false) }
      end
    end
  end
end
