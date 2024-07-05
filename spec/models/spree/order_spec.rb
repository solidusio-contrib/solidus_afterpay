# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spree::Order do
  let(:store) { create(:store) }
  let(:user) { create(:user, email: "solidus@example.com") }
  let(:order) { create(:order, user: user, store: store) }

  describe "#available_payment_methods" do
    it "includes frontend payment methods" do
      payment_method = Spree::PaymentMethod::Check.create!({
        name: "Fake",
        active: true,
        available_to_users: true,
        available_to_admin: false
      })
      expect(order.available_payment_methods).to include(payment_method)
    end

    it "includes 'both' payment methods" do
      payment_method = Spree::PaymentMethod::Check.create!({
        name: "Fake",
        active: true,
        available_to_users: true,
        available_to_admin: true
      })
      expect(order.available_payment_methods).to include(payment_method)
    end

    # rubocop:disable RSpec/MultipleExpectations
    it "does not include a payment method twice" do
      payment_method = Spree::PaymentMethod::Check.create!({
        name: "Fake",
        active: true,
        available_to_users: true,
        available_to_admin: true
      })
      expect(order.available_payment_methods.count).to eq(1)
      expect(order.available_payment_methods).to include(payment_method)
    end
    # rubocop:enable RSpec/MultipleExpectations

    it "does not include inactive payment methods" do
      Spree::PaymentMethod::Check.create!({
        name: "Fake",
        active: false,
        available_to_users: true,
        available_to_admin: true
      })
      expect(order.available_payment_methods.count).to eq(0)
    end

    context "with more than one payment method" do
      subject { order.available_payment_methods }

      let!(:first_method) {
        create(:payment_method, available_to_users: true,
          available_to_admin: true)
      }
      let!(:second_method) {
        create(:payment_method, available_to_users: true,
          available_to_admin: true)
      }

      before do
        second_method.move_to_top
      end

      it "respects the order of methods based on position" do
        is_expected.to eq([second_method, first_method])
      end

      context 'when a payment method responds to #available_for_order?' do
        let(:third_method) {
          FakePaymentMethod.create(name: 'Fake', available_to_users: true, available_to_admin: true)
        }

        before do
          fake_payment_method_class = Class.new(SolidusSupport.payment_method_parent_class)
          stub_const('FakePaymentMethod', fake_payment_method_class)

          third_method
        end

        context 'when it responds with true' do
          before do
            FakePaymentMethod.class_eval { def available_for_order?(_order); true; end }
          end

          it 'includes it in the result' do
            is_expected.to eq([second_method, first_method, third_method])
          end
        end

        context 'when it responds with false' do
          before do
            FakePaymentMethod.class_eval { def available_for_order?(_order); false; end }
          end

          it "doesn't include it in the result" do
            is_expected.to eq([second_method, first_method])
          end
        end
      end
    end

    context 'when the order has a store' do
      let(:order) { create(:order) }

      let!(:store_with_payment_methods) do
        create(:store,
          payment_methods: [payment_method_with_store])
      end
      let!(:payment_method_with_store) { create(:payment_method) }
      let!(:store_without_payment_methods) { create(:store) }
      let!(:payment_method_without_store) { create(:payment_method) }

      context 'when the store has payment methods' do
        before { order.update!(store: store_with_payment_methods) }

        it 'returns only the matching payment methods for that store' do
          expect(order.available_payment_methods).to contain_exactly(payment_method_with_store)
        end

        context 'when the store has an extra payment method unavailable to users' do
          let!(:admin_only_payment_method) do
            create(:payment_method,
              available_to_users: false,
              available_to_admin: true)
          end

          before do
            store_with_payment_methods.payment_methods << admin_only_payment_method
          end

          it 'returns only the payment methods available to users for that store' do
            expect(order.available_payment_methods).to contain_exactly(payment_method_with_store)
          end
        end
      end

      context 'when the store does not have payment methods' do
        before { order.update!(store: store_without_payment_methods) }

        it 'returns all matching payment methods regardless of store' do
          expect(order.available_payment_methods).to contain_exactly(payment_method_with_store,
            payment_method_without_store)
        end
      end
    end
  end
end
