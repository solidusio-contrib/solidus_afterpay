# frozen_string_literal: true

require 'spec_helper'

describe SolidusAfterpay::ShippingRatePresenter do
  let(:order) { create(:order_with_line_items ) }
  let(:shipment) { create(:shipment, order: order) }
  let(:shipping_rate) { create(:shipping_rate, cost: 5, shipment: shipment) }
  let(:shipping_rate_tax) { ::Spree::ShippingRateTax.create(amount: 0.75, shipping_rate: shipping_rate) }

  before { shipping_rate.taxes << shipping_rate_tax }

  describe '#order_amount' do
    subject(:order_amount) { described_class.new(shipping_rate: shipping_rate).order_amount }

    it 'returns the order total including the shipping rate' do
      expect(order_amount.to_f).to eq(15.75)
    end
  end

  describe '#amount_with_taxes' do
    subject(:amount_with_taxes) { described_class.new(shipping_rate: shipping_rate).amount_with_taxes }

    it 'returns the total amount including taxes' do
      expect(amount_with_taxes.to_f).to eq(5.75)
    end
  end
end
