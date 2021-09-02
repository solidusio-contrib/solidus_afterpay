class CreateSolidusAfterpayPaymentSources < SolidusSupport::Migration[4.2]
  def change
    create_table :solidus_afterpay_payment_sources do |t|
      t.string :token
      t.references :payment_method, index: true

      t.timestamps
    end

    add_foreign_key :solidus_afterpay_payment_sources, :spree_payment_methods, column: :payment_method_id
  end
end
