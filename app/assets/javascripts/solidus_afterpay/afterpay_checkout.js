$(function() {
  function enableSubmit() {
    /* If we're using jquery-ujs on the frontend, it will automatically disable
      * the submit button, but do so in a setTimeout here:
      * https://github.com/rails/jquery-rails/blob/master/vendor/assets/javascripts/jquery_ujs.js#L517
      * The only way we can re-enable it is by delaying longer than that timeout
      * or stopping propagation so their submit handler doesn't run. */
    if($.rails && typeof $.rails.enableFormElement !== 'undefined') {
      setTimeout(function() {
        $.rails.enableFormElement($submitButton);
        $submitButton.attr("disabled", false).removeClass("disabled").addClass("primary");
      }, 100);
    } else if(typeof Rails !== 'undefined' && typeof Rails.enableElement !== 'undefined') {
      /* Indicates that we have rails-ujs instead of jquery-ujs. Rails-ujs was added to rails
        * core in Rails 5.1.0 */
      setTimeout(function() {
        Rails.enableElement($submitButton[0]);
        $submitButton.attr("disabled", false).removeClass("disabled").addClass("primary");
      }, 100);
    } else {
      $submitButton.attr("disabled", false).removeClass("disabled").addClass("primary");
    }
  }

  function disableSubmit() {
    $submitButton.attr("disabled", true).removeClass("primary").addClass("disabled");
  }

  function addFormHook() {
    $paymentForm.on('submit', function(event) {
      var selectedPaymentMethodId = parseInt($("#payment-method-fields input[type='radio']:checked").val());

      if(paymentMethodId === selectedPaymentMethodId) {
        event.preventDefault();
        disableSubmit();

        Spree.ajax({
          method: 'POST',
          url: '/solidus_afterpay/checkouts.json',
          data: { order_number: orderNumber, payment_method_id: paymentMethodId }
        }).success(function(response) {
          onSuccess(response);
        }).error(function(response) {
          onError(response);
        });
      }
    });
  }

  function onSuccess(response) {
    AfterPay.initialize({ countryCode: 'US' });
    AfterPay.redirect({ token: response.token });
  }

  function onError(response) {
    enableSubmit();
  }

  if($('#afterpay_checkout_payload').length > 0) {
    var $paymentForm = $("#checkout_form_payment");
    var $submitButton = $("input[type='submit']", $paymentForm);

    var paymentMethodId = $('#afterpay_checkout_payload').data('payment-method-id');
    var orderNumber = $('#afterpay_checkout_payload').data('order-number');

    addFormHook();
  }
});
