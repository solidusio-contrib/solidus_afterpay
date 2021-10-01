require "spec_helper"

RSpec.describe "rendering afterpay messaging", type: :view do
  let(:product) { create(:base_product) }
  let(:second_product) { create(:base_product) }
  let(:excluded_product) { create(:base_product) }
  let(:product_array) { [product] }
  let(:payment_method) { SolidusAfterpay::PaymentMethod.active.first }
  let(:amount) { product.price }

  before do
    create(:afterpay_payment_method, preferred_excluded_products: excluded_product.id.to_s)
    render partial: "spree/shared/afterpay_messaging", locals: { min: nil, max: nil, products: product_array,
                                                                 data:
                                                                 { amount: amount, locale: "en_US", currency: "USD" } }
  end

  context "without excluded products" do
    context "when rendering afterpay messaging for a single product" do
      it 'displays afterpay messaging' do
        expect(rendered).to match("19.99" && "afterpay-placement")
      end
    end

    context "when rendering afterpay messaging for multiple products" do
      let(:product_array) { [product, second_product] }
      let(:amount) { (product.price + second_product.price) }

      it 'displays afterpay messaging' do
        expect(rendered).to match("39.98" && "afterpay-placement")
      end
    end
  end

  context "with excluded products" do
    context "when one of the products is excluded" do
      let(:product_array) { [product, second_product, excluded_product] }

      it "does not render the afterpay messaging partial" do
        expect(rendered).not_to match("afterpay-placement")
      end
    end
  end
end
