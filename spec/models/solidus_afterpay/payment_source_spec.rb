require 'spec_helper'

RSpec.describe SolidusAfterpay::PaymentSource do
  let(:payment_source) { described_class.new }

  describe '#actions' do
    subject { payment_source.actions }

    it 'supports capture, void, and credit' do
      is_expected.to eq(%w[capture void credit])
    end
  end

  describe '#can_void?' do
    subject { payment_source.can_void?(payment) }

    let(:auto_capture) { true }
    let(:payment_method) { build(:afterpay_payment_method, auto_capture: auto_capture) }
    let(:payment) { build(:afterpay_payment, payment_method: payment_method) }

    context 'with the immediate flow' do
      it 'is always false' do
        is_expected.to be(false)
      end
    end

    context 'with the deferred flow' do
      let(:auto_capture) { false }

      let(:payment_state) { 'AUTH_APPROVED' }
      let(:gateway_response) { { paymentState: payment_state } }
      let(:gateway) { instance_double(SolidusAfterpay::Gateway, find_payment: gateway_response) }

      before do
        allow(payment_method).to receive(:gateway).and_return(gateway)
      end

      context 'when the payment exists and the payment state is voidable' do
        it 'returns true' do
          is_expected.to be(true)
        end
      end

      context 'when the payment exists when the payment state is not voidable' do
        let(:payment_state) { 'NOT_VOIDABLE' }

        it 'returns false' do
          is_expected.to be(false)
        end
      end

      context "when the payment doesn't exist" do
        let(:gateway_response) { nil }

        it 'returns false' do
          is_expected.to be(false)
        end
      end
    end
  end
end
