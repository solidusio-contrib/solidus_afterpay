# frozen_string_literal: true

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

  describe "#excluded_product?" do
    subject { payment_method.excluded_product?(product) }

    let(:product) { create(:base_product) }
    let(:excluded_product_ids) { product.id.to_s }
    let(:payment_method) { described_class.new(preferred_excluded_products: excluded_product_ids) }

    context 'when the product is excluded' do
      it { is_expected.to be_truthy }
    end

    context 'when the product is not excluded' do
      let(:excluded_product_ids) { '' }

      it { is_expected.to be_falsey }
    end
  end

  describe "#available_for_order?" do
    subject { payment_method.available_for_order?(order) }

    let(:product) { create(:base_product) }
    let(:excluded_product_ids) { '' }
    let(:payment_method) { create(:afterpay_payment_method, preferred_excluded_products: excluded_product_ids) }
    let(:order) {
      build(:order_with_line_items, currency: order_currency,
     line_items_attributes: line_items_attributes)
    }
    let(:line_items_attributes) do
      [{ product: product }]
    end
    let(:order_currency) { 'USD' }

    context "with cache" do
      context 'when order total is inside the range' do
        before do
          Rails.cache.write("solidus_afterpay_configuration_maximumAmount_currency", "USD")
          Rails.cache.write("solidus_afterpay_configuration_maximumAmount_amount", 1000.0)
          Rails.cache.write("solidus_afterpay_configuration_minimumAmount_amount", 1.0)
        end

        it { is_expected.to be(true) }
      end

      context 'when order total is outside the range' do
        before do
          Rails.cache.write("solidus_afterpay_configuration_maximumAmount_currency", "USD")
          Rails.cache.write("solidus_afterpay_configuration_maximumAmount_amount", 4.0)
          Rails.cache.write("solidus_afterpay_configuration_minimumAmount_amount", 1.0)
        end

        it { is_expected.to be(false) }
      end

      context 'when order currency is different from afterpay configuration' do
        before do
          Rails.cache.write("solidus_afterpay_configuration_maximumAmount_amount", 1000.0)
          Rails.cache.write("solidus_afterpay_configuration_minimumAmount_amount", 1.0)
          Rails.cache.write("solidus_afterpay_configuration_maximumAmount_currency", "EUR")
        end

        it { is_expected.to be(false) }
      end

      context 'when order currency is the same from afterpay configuration' do
        before do
          Rails.cache.write("solidus_afterpay_configuration_maximumAmount_amount", 1000.0)
          Rails.cache.write("solidus_afterpay_configuration_minimumAmount_amount", 1.0)
          Rails.cache.write("solidus_afterpay_configuration_maximumAmount_currency", "USD")
        end

        it { is_expected.to be(true) }
      end
    end

    context 'when there is no cache' do
      let(:configuration) do
        require 'hashie'

        Hashie::Mash.new({
          minimumAmount: { amount: '1', currency: 'USD' },
          maximumAmount: { amount: '110', currency: 'USD' }
        })
      end

      before do
        allow(payment_method.gateway).to receive(:retrieve_configuration).and_return(configuration)
      end

      context 'when order total is inside the range and the currency is the same from afterpay configuration' do
        it { is_expected.to be(true) }
      end

      context 'when order total is outside the range' do
        it do
          order.update(total: 111)
          is_expected.to be(false)
        end
      end

      context 'when order currency is different from afterpay configuration' do
        let(:order_currency) { 'EUR' }

        it { is_expected.to be(false) }
      end
    end

    context "when the items are excluded from the payment_method" do
      let(:excluded_product_ids) { product.id.to_s }

      context "when the id's of all the products are excluded" do
        it { is_expected.to be_falsey }
      end

      context "when the id of one of the products is excluded" do
        let(:second_product) { create(:base_product) }
        let(:line_items_attributes) do
          [{ product: product }, { product: second_product }]
        end

        it { is_expected.to be(false) }
      end
    end

    context "when none of the items are excluded from the payment_method" do
      let(:configuration) do
        require 'hashie'

        Hashie::Mash.new({
          minimumAmount: { amount: '1', currency: 'USD' },
          maximumAmount: { amount: '1000', currency: 'USD' }
        })
      end

      let(:excluded_product_ids) { '' }

      before do
        Rails.cache.clear
        allow(payment_method.gateway).to receive(:retrieve_configuration).and_return(configuration)
      end

      it "returns true when none of the products are excluded" do
        is_expected.to be(true)
      end
    end
  end
end
