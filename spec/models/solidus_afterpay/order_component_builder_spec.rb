require 'spec_helper'

RSpec.describe SolidusAfterpay::OrderComponentBuilder do
  let(:order) { create(:order_with_product_property) }
  let(:redirect_confirm_url) { 'https://merchantsite.com/confirm' }
  let(:redirect_cancel_url) { 'https://merchantsite.com/cancel' }

  let(:builder) do
    described_class.new(
      order: order,
      redirect_confirm_url: redirect_confirm_url,
      redirect_cancel_url: redirect_cancel_url,
      mode: nil,
      popup_origin_url: nil
    )
  end

  describe '#call' do
    subject(:result) { builder.call }

    let(:expected_result_not_combined) do
      Afterpay::Components::Order.new(
        amount: Afterpay::Components::Money.new(amount: '110.0', currency: 'USD'),
        billing: Afterpay::Components::Contact.new(
          area1: 'Herndon',
          area2: nil,
          country_code: nil,
          line1: 'PO Box 1337',
          line2: 'Northwest',
          name: 'John',
          phone_number: '555-555-0199',
          postcode: order.billing_address.zipcode,
          region: 'AL'
        ),
        consumer: Afterpay::Components::Consumer.new(
          email: order.user.email,
          given_names: 'John',
          phone_number: nil,
          surname: nil
        ),
        courier: nil,
        discounts: nil,
        items: [
          Afterpay::Components::Item.new(
            preorder: true,
            estimated_shipment_date: "2025-10-25",
            name: order.line_items.first.name,
            price: Afterpay::Components::Money.new(
              amount: '10.0',
              currency: 'USD'
            ),
            quantity: 1,
            sku: order.line_items.first.sku
          )
        ],
        merchant: Afterpay::Components::Merchant.new(
          redirect_confirm_url: 'https://merchantsite.com/confirm',
          redirect_cancel_url: 'https://merchantsite.com/cancel'
        ),
        merchant_reference: order.number,
        payment_type: nil,
        shipping: Afterpay::Components::Contact.new(
          area1: 'Herndon',
          area2: nil,
          country_code: nil,
          line1: 'A Different Road',
          line2: 'Northwest',
          name: 'John',
          phone_number: '555-555-0199',
          postcode: order.shipping_address.zipcode,
          region: 'AL'
        ),
        shipping_amount: nil,
        tax_amount: nil
      )
    end

    let(:expected_result_combined) do
      Afterpay::Components::Order.new(
        amount: Afterpay::Components::Money.new(amount: '110.0', currency: 'USD'),
        billing: Afterpay::Components::Contact.new(
          area1: 'Herndon',
          area2: nil,
          country_code: nil,
          line1: 'PO Box 1337',
          line2: 'Northwest',
          name: 'John Von Doe',
          phone_number: '555-555-0199',
          postcode: order.billing_address.zipcode,
          region: 'AL'
        ),
        consumer: Afterpay::Components::Consumer.new(
          email: order.user.email,
          given_names: 'John',
          phone_number: nil,
          surname: 'Von Doe'
        ),
        courier: nil,
        discounts: nil,
        items: [
          Afterpay::Components::Item.new(
            estimated_shipment_date: "2025-10-25",
            preorder: true,
            name: order.line_items.first.name,
            price: Afterpay::Components::Money.new(
              amount: '10.0',
              currency: 'USD'
            ),
            quantity: 1,
            sku: order.line_items.first.sku
          )
        ],
        merchant: Afterpay::Components::Merchant.new(
          redirect_confirm_url: 'https://merchantsite.com/confirm',
          redirect_cancel_url: 'https://merchantsite.com/cancel'
        ),
        merchant_reference: order.number,
        payment_type: nil,
        shipping: Afterpay::Components::Contact.new(
          area1: 'Herndon',
          area2: nil,
          country_code: nil,
          line1: 'A Different Road',
          line2: 'Northwest',
          name: 'John Von Doe',
          phone_number: '555-555-0199',
          postcode: order.shipping_address.zipcode,
          region: 'AL'
        ),
        shipping_amount: nil,
        tax_amount: nil
      )
    end

    context 'when solidus combines first and last name' do
      before do
        allow(SolidusSupport)
          .to receive(:combined_first_and_last_name_in_address?)
          .and_return(true)
      end

      it 'returns the correct payload' do
        expect(result.as_json).to eq(expected_result_combined.as_json)
      end
    end

    context 'when solidus does not combine first and last name' do
      before do
        allow(SolidusSupport)
          .to receive(:combined_first_and_last_name_in_address?)
          .and_return(false)

        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Spree::Address)
          .to receive(:first_name)
          .and_return('John')

        allow_any_instance_of(Spree::Address)
          .to receive(:last_name)
          .and_return(nil)
        # rubocop:enable RSpec/AnyInstance
      end

      it 'returns the correct payload' do
        expect(result.as_json).to eq(expected_result_not_combined.as_json)
      end
    end

    context "when provided an estimated shipment date" do
      context "when provided a product estimated shipment date" do
        it "returns the correct estimated shipment date" do
          expect(result.items.first.estimated_shipment_date).to match("2025-10-25")
        end

        it "returns true if the estimated shipping date didn't pass yet" do
          expect(result.items.first.preorder).to be_truthy
        end
      end

      context "when provided a variant estimated shipment date" do
        let(:order) { create(:order_with_variant_property) }

        it 'contains the correct estimated shipment date' do
          expect(result.items.first.estimated_shipment_date).to match("2021-09-19")
        end

        it 'returns the variant estimated shipment date when product and variant properties are set' do
          order.line_items.first.product.set_property("estimatedShipmentDate", "2025-10-25")
          expect(result.items.first.estimated_shipment_date).to match("2021-09-19")
        end

        it "returns false when the estimated shipping date passed" do
          expect(result.items.first.preorder).to be_falsey
        end
      end
    end
  end
end
