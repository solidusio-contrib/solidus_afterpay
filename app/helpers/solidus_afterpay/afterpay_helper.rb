# frozen_string_literal: true

module SolidusAfterpay
  module AfterpayHelper
    def include_afterpay_js(test_mode: false)
      afterpay_js_url = if test_mode
                          'https://portal.sandbox.afterpay.com/afterpay.js'
                        else
                          'https://portal.afterpay.com/afterpay.js'
                        end

      javascript_include_tag afterpay_js_url
    end
  end
end
