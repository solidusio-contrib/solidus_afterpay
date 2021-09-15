require 'spec_helper'

RSpec.describe SolidusAfterpay::AfterpayHelper, type: :helper do
  describe '#include_afterpay_js' do
    subject { helper.include_afterpay_js(test_mode: test_mode) }

    context 'when test_mode is false' do
      let(:test_mode) { false }

      it 'includes the production javascript' do
        is_expected
          .to eq(
            <<-SCRIPT.squish
              <script src="https://portal.afterpay.com/afterpay-async.js"
                async="async"
                defer="defer"
                onload="initAfterpay()"></script>
            SCRIPT
          )
      end
    end

    context 'when test_mode is true' do
      let(:test_mode) { true }

      it 'includes the sandbox javascript' do
        is_expected
          .to eq(
            <<-SCRIPT.squish
              <script src="https://portal.sandbox.afterpay.com/afterpay-async.js"
                async="async"
                defer="defer"
                onload="initAfterpay()"></script>
            SCRIPT
          )
      end
    end
  end
end
