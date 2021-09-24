# frozen_string_literal: true

RSpec.configure do |config|
  config.after { Rails.cache.clear }
end
