# frozen_string_literal: true

RSpec.configure do |config|
  def described_class_source_location
    described_class.instance_methods(false).map do |method|
      described_class.instance_method(method).source_location.first
    end.uniq.first
  end

  config.before(:each, use_solidus_api: true) do
    SolidusAfterpay.configure do |c|
      c.use_solidus_api = true
    end

    class_name = described_class.to_s.split('::').last
    source_location = described_class_source_location

    SolidusAfterpay.send(:remove_const, class_name)
    load source_location
  end

  config.after(:each, use_solidus_api: true) do
    SolidusAfterpay.configure do |c|
      c.use_solidus_api = false
    end

    class_name = described_class.to_s.split('::').last
    source_location = described_class_source_location

    SolidusAfterpay.send(:remove_const, class_name)
    load source_location
  end
end
