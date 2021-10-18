require "spec_helper"

RSpec.describe "rendering afterpay express checkout button", type: :view do
  subject(:rendered) { render "solidus_afterpay/afterpay_checkout_button", payment_method: payment_method }

  let(:payment_method) { SolidusAfterpay::PaymentMethod.active.first }
  let(:order) { create(:order) }

  before do
    create(:afterpay_payment_method)
    assign(:order, order)
  end

  context "when order is available for order" do
    before do
      allow(payment_method).to receive(:available_for_order?).with(order).and_return(true)
    end

    it 'displays the afterpay express checkout button' do
      expect(rendered).to match("Checkout with Afterpay")
    end
  end

  context "when order is not available for order" do
    before do
      allow(payment_method).to receive(:available_for_order?).with(order).and_return(false)
    end

    it 'does not display the afterpay express checkout button' do
      expect(rendered).not_to match("Checkout with Afterpay")
    end
  end
end
