require File.expand_path('../../../../../test_helper', __FILE__)

class Intouch::Live::Checker::PrivateTest < ActiveSupport::TestCase
  subject { Intouch::Live::Checker::Private.new(issue, project).required? }

  let(:project) { Object.new }
  let(:issue) { Object.new }

  let(:always_notify_settings) do
    {
      'always_notify' => {
        'author' => '1'
      }
    }
  end

  let(:empty_settings) { {} }

  describe 'yes' do
    describe 'alarm issue' do
      before do
        issue.stubs(:alarm?).returns(true)

        Intouch.stubs(:work_time?).returns(false)
        project.stubs(:active_intouch_settings).returns(empty_settings)
      end

      it { subject.must_equal true }
    end

    describe 'work time' do
      before do
        Intouch.stubs(:work_time?).returns(true)

        issue.stubs(:alarm?).returns(false)
        project.stubs(:active_intouch_settings).returns(empty_settings)
      end

      it { subject.must_equal true }
    end

    describe 'project with always notify' do
      before do
        project.stubs(:active_intouch_settings).returns(always_notify_settings)

        Intouch.stubs(:work_time?).returns(false)
        issue.stubs(:alarm?).returns(false)
      end

      it { subject.must_equal true }
    end
  end

  describe 'no' do
    before do
      Intouch.stubs(:work_time?).returns(false)
      issue.stubs(:alarm?).returns(false)
      project.stubs(:active_intouch_settings).returns(empty_settings)
    end

    it { subject.must_equal false }
  end
end
