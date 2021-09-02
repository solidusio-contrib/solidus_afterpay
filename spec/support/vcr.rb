# frozen_string_literal: true

require 'vcr'

VCR.configure do |config|
  config.ignore_localhost = true
  config.cassette_library_dir = "spec/fixtures/vcr_casettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = false

  config.filter_sensitive_data('<ENCODED_AUTH_HEADER>') do
    Base64.strict_encode64(
      "#{ENV.fetch('AFTERPAY_MERCHANT_ID',
        'dummy_merchant_id')}:#{ENV.fetch('AFTERPAY_SECRET_KEY', 'dummy_secret_key')}"
    )
  end
end
