require File.expand_path('../../../../test_helper', __FILE__)

class RegularMessageTest < ActiveSupport::TestCase
  subject { Intouch::Message::Regular.new(issue) }

  let(:issue) { Object.new }

  describe 'inactive?' do
    before do
      Intouch::Message::Regular.any_instance.stubs(:reminder_active?).returns(true)
      Intouch::Message::Regular.any_instance.stubs(:reminder_interval).returns(1)
    end

    describe 'less than 1 hour ago' do
      before do
        Intouch::Message::Regular.any_instance.stubs(:latest_action_on).returns(59.minutes.ago)
      end

      it { subject.inactive?.must_equal false }
    end

    describe '1 hour ago' do
      before do
        Intouch::Message::Regular.any_instance.stubs(:latest_action_on).returns(60.minutes.ago)
      end

      it { subject.inactive?.must_equal true }
    end

    describe 'more than 1 hour ago' do
      before do
        Intouch::Message::Regular.any_instance.stubs(:latest_action_on).returns(61.minutes.ago)
      end

      it { subject.inactive?.must_equal true }
    end
  end
end
