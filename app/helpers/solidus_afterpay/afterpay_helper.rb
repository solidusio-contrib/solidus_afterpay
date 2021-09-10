# frozen_string_literal: true

module SolidusAfterpay
  module AfterpayHelper
    def include_afterpay_js(test_mode: false, merchant_key: nil)
      js_name = merchant_key ? "afterpay.js?merchant_key=#{merchant_key}" : 'afterpay-async.js'
      afterpay_js_url = if test_mode
                          "https://portal.sandbox.afterpay.com/#{js_name}"
                        else
                          "https://portal.afterpay.com/#{js_name}"
                        end

      javascript_include_tag afterpay_js_url, async: true, defer: true, onload: 'initAfterpay()'
    end
  end
end
