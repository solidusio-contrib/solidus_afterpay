require 'spec_helper'

RSpec.describe SolidusAfterpay::PaymentSource, type: :model do
  let(:payment_source) { described_class.new }

  describe '#actions' do
    subject { payment_source.actions }

    it 'supports capture, and credit' do
      is_expected.to eq(%w[capture credit])
    end
  end

  describe '#can_void?' do
    subject { payment_source.can_void?(payment) }

    let(:payment) { build(:afterpay_payment) }

    it 'is always false' do
      is_expected.to be(false)
    end
  end
end
