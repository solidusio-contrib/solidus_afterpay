# frozen_string_literal: true

RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request

  config.before(:each, :with_signed_in_user) { login_as user }

  config.before(:each, :with_guest_session) do
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(ActionDispatch::Cookies::CookieJar).to(
      receive(:signed).and_return({ guest_token: order.guest_token })
    )
    # rubocop:enable RSpec/AnyInstance
  end
end
