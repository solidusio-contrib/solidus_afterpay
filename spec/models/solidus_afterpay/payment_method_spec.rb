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
end
