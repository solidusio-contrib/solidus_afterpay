require "spec_helper"

RSpec.describe "rendering afterpay express checkout button", type: :view do
  let(:product) { create(:base_product) }
  let(:second_product) { create(:base_product) }
  let(:excluded_product) { create(:base_product) }
  let(:payment_method) { SolidusAfterpay::PaymentMethod.active.first }
  let(:amount) { product.price }
  let(:product_array) { [product] }

  before do
    create(:afterpay_payment_method, preferred_excluded_products: excluded_product.id.to_s)
    assign(:order, create(:order))
    render "solidus_afterpay/afterpay_checkout_button", products: product_array
  end

  context "when rendering afterpay express checkout button for a single product" do
    it 'displays the afterpay express checkout button' do
      expect(rendered).to match("Checkout with Afterpay")
    end
  end

  context "when rendering afterpay express checkout button for multiple products" do
    let(:product_array) { [product, second_product] }

    it 'displays the afterpay express checkout button' do
      expect(rendered).to match("Checkout with Afterpay")
    end
  end

  context "when rendering afterpay express checkout button with an excluded product" do
    let(:product_array) { [product, second_product, excluded_product] }

    it 'does not display the afterpay express checkout button' do
      expect(rendered).not_to match("Checkout with Afterpay")
    end
  end
end
