# frozen_string_literal: true

require 'spec_helper'

describe SolidusAfterpay::OrderPresenter do
  describe '#line_items_tax_amount' do
    subject(:line_items_tax_amount) { described_class.new(order: order).line_items_tax_amount }

    describe '#line_items_tax_amount' do
      before do
        country = create(:country)
        state = create(:state, country: country)
        zone = create(:zone, country_ids: [country.id], state_ids: [state.id])
        create(:tax_rate, zone: zone)
      end

      context 'when the order has line items' do
        let(:order) { create(:order_with_line_items, line_items_count: 2) }

        it 'returns the line items tax total amout' do
          expect(line_items_tax_amount).to eq(2.0)
        end
      end

      context 'when the order does not have line items' do
        let(:order) { create(:order) }

        it 'returns 0' do
          expect(line_items_tax_amount).to eq(0)
        end
      end
    end
  end
end
