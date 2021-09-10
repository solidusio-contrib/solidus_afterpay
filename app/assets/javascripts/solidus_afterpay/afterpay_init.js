function initAfterpay() {
  $(function() {
    $(document).trigger('afterpay.loaded');
  });
}

function showError(errorMessage) {
  if (!$("#content").is("*")) return;

  $(".flash").remove();
  $("#content").prepend(`<div class="flash error">${errorMessage}</div>`);
}
