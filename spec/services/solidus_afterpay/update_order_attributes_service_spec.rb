# frozen_string_literal: true

require 'spec_helper'

describe SolidusAfterpay::UpdateOrderAttributesService do
  subject(:service) do
    described_class.call(
      order: order,
      afterpay_order_token: afterpay_order_token,
      payment_method: payment_method,
      request_env: 'env'
    )
  end

  let!(:order) { create(:order_with_line_items, line_items_count: 2, state: 'delivery') }
  let!(:payment_method) { create(:afterpay_payment_method) }

  before do
    allow(Spree::ShippingRate).to receive(:find).and_return(Spree::ShippingRate.first)
    allow(order).to receive(:available_payment_methods).and_return(Spree::PaymentMethod.all)
  end

  context 'when the afterpay find order is a success', vcr: 'find_order/valid' do
    let(:afterpay_order_token) { '002.cb9qevbs1o4el3adh817hqkotkbv4b8u1jkekofd3nb2m8lu' }

    it 'returns true' do
      expect(service).to be_truthy
    end

    it 'updates the order email with the Afterpay order email' do
      expect { service }.to change { order.reload.email }.to('andreavassallo@nebulab.com')
    end

    # rubocop:disable RSpec/MultipleExpectations
    it 'updates the payments information with the afterpay payment information' do
      expect { service }.to change { order.payments.reload.count }.from(0).to(1)
      expect(order.payments.first.amount).to eq(53.53)
      expect(order.payments.first.source.token).to eq(afterpay_order_token)
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  context 'when the afterpay find order is a failure', vcr: 'find_order/invalid' do
    let(:afterpay_order_token) { 'INVALID_TOKEN' }

    it 'returns false' do
      expect(service).to be_falsey
    end

    it 'does not change the order email' do
      expect { service }.not_to(change { order.reload.email })
    end

    it 'does not change the payments count' do
      expect { service }.not_to(change { order.payments.reload.count })
    end
  end
end
