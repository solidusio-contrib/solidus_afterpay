# frozen_string_literal: true

require 'spec_helper'

describe SolidusAfterpay::ShippingRateBuilderService do
  subject(:service) { described_class.call(order: order) }

  let(:order) { Spree::TestingSupport::OrderWalkthrough.up_to(:delivery) }

  context 'when the order is in a valid state' do
    it 'returns the afterpay compliant shipping rate object' do
      expect(service).to eq(
        [
          {
            id: order.reload.shipments.first.shipping_rates.first.id.to_s,
            name: 'UPS Ground',
            description: '$10.00',
            shipping_amount: '10.0',
            currency: 'USD',
            order_amount: '20.0'
          }
        ]
      )
    end
  end

  context 'when the order is not in a valid state' do
    before { order.shipments = [] }

    it 'returns an empty array' do
      expect(service).to be_empty
    end
  end
end
