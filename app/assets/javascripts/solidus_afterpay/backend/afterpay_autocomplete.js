Spree.ready(function () {
  if (
    $(
      'form#edit_payment_method option[value="SolidusAfterpay::PaymentMethod"]:selected'
    ).length > 0
  ) {
    $("#payment_method_preferred_excluded_products").productAutocomplete();
  }
});
