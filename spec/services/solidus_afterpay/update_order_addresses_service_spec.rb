# frozen_string_literal: true

require 'spec_helper'

describe SolidusAfterpay::UpdateOrderAddressesService do
  subject(:service) { described_class.call(order: order, address_params: address_params) }

  let(:order) { create(:order, state: 'payment', ship_address: nil, bill_address: nil) }

  before do
    country = create(:country)
    create(:state, country: country)
  end

  context 'when the address params are valid' do
    let(:address_params) do
      {
        address1: '8125 Centre St',
        address2: '',
        name: 'John Doe',
        suburb: 'Citronelle',
        postcode: '36522-2156',
        phoneNumber: '12345',
        countryCode: 'US',
        state: 'AL'
      }
    end

    it 'returns true' do
      expect(service).to be_truthy
    end

    it 'changes the order state to address' do
      expect { service }.to change { order.reload.state }.from('payment').to('address')
    end

    context 'when the order has an email set' do
      it 'does not change the order email' do
        expect { service }.not_to(change { order.reload.email })
      end
    end

    context 'when the order does not have an email set' do
      # rubocop:disable Rails/SkipsModelValidations
      before { order.update_columns(email: nil) }
      # rubocop:enable Rails/SkipsModelValidations

      it 'changes the order email with a dummy one' do
        expect { service }
          .to change { order.reload.email }
          .to(SolidusAfterpay.configuration.dummy_email)
      end
    end
  end

  context 'when the address params are not valid' do
    let(:address_params) do
      {
        address1: '',
        address2: '',
        name: 'John Doe',
        suburb: '',
        postcode: '36522-2156',
        phoneNumber: '12345',
        countryCode: 'US',
        state: 'AL'
      }
    end

    it 'returns false' do
      expect(service).to be_falsey
    end

    it 'changes the order state to address' do
      expect { service }.not_to(change { order.reload.state })
    end

    it 'does not change the order email' do
      expect { service }.not_to(change { order.reload.email })
    end
  end
end
