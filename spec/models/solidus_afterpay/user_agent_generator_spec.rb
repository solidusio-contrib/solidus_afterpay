require 'spec_helper'

RSpec.describe SolidusAfterpay::UserAgentGenerator do
  describe '#generate' do
    subject { user_agent_generator.generate }

    let(:user_agent_generator) { described_class.new(merchant_id: merchant_id) }
    let(:merchant_id) { 'MERCHANT_ID' }
    let(:default_store) { build(:store, url: 'test.com') }

    before do
      stub_const('SolidusAfterpay::VERSION', '0.1.0')
      allow(Spree).to receive(:solidus_gem_version).and_return('3.0.1')
      stub_const('RUBY_VERSION', '2.6.6')
      allow(Spree::Store).to receive(:default).and_return(default_store)
    end

    it 'includes the production javascript' do
      is_expected.to eq('SolidusAfterpay/0.1.0 (Solidus/3.0.1; Ruby/2.6.6; Merchant/MERCHANT_ID) https://test.com')
    end
  end
end
