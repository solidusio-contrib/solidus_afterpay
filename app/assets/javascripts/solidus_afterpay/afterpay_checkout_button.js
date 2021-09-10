$(document).bind("afterpay.loaded", function () {
  function initializeExpressCheckout(selector) {
    AfterPay.initializeForPopup({
      countryCode: "US",
      onCommenceCheckout: function (actions) {
        Spree.ajax({
          method: "POST",
          url: "/solidus_afterpay/checkouts.json",
          data: { order_number: orderNumber, mode: "express" },
        })
          .success(function (response) {
            actions.resolve(response.token);
          })
          .error(function () {
            actions.reject(AfterPay.CONSTANTS.SERVICE_UNAVAILABLE);
          });
      },
      onShippingAddressChange: function (data, actions) {
      },
      onComplete: function (data) {
      },
      target: selector,
      buyNow: false,
      pickup: false,
      shippingOptionRequired: true,
    });
  }

  if ($("#afterpay-button").length > 0) {
    var orderNumber = $("#afterpay-button").data("order-number");

    initializeExpressCheckout("#afterpay-button");
  }
});
