require File.expand_path('../../../test_helper', __FILE__)

class NewIssueHandlerTest < ActiveSupport::TestCase
  fixtures :projects

  let(:instance) { Intouch::NewIssueHandler.new(issue) }

  let(:project) { Project.first }
  let(:issue) { Issue.new(project_id: project.id) }

  describe '.need_notification?' do
    subject { instance.need_notification? }

    describe 'yes' do
      before do
        Project.any_instance.stubs(:module_enabled?).with(:intouch).returns(true)
        Project.any_instance.stubs(:active?).returns(true)
        issue.stubs(:closed?).returns(false)
      end

      it { subject.must_equal true }
    end


    describe 'no' do


      describe 'project without enabled intouch module' do

        before do
          Project.any_instance.stubs(:module_enabled?).with(:intouch).returns(false)
        end

        it { subject.must_equal false }
      end

      describe 'inactive project' do

        before do
          Project.any_instance.stubs(:module_enabled?).with(:intouch).returns(true)
          Project.any_instance.stubs(:active?).returns(false)
        end

        it { subject.must_equal false }

      end

      describe 'closed issue' do
        before do
          Project.any_instance.stubs(:module_enabled?).with(:intouch).returns(true)
          Project.any_instance.stubs(:active?).returns(true)
          issue.stubs(:closed?).returns(true)
        end

        it { subject.must_equal false }

      end

    end
  end


  describe 'notifications' do
    before do
      Intouch::NewIssueHandler.any_instance
        .stubs(:need_notification?)
        .returns(true)
    end

    describe 'private' do
      describe '.need_private_message?' do
        subject { instance.need_private_message? }
        describe 'alarm issue' do
          before { issue.stubs(:alarm?).returns(true)}

          it { subject.must_equal true }
        end

        describe 'work time' do
          before do
            issue.stubs(:alarm?).returns(false)
            Intouch.stubs(:work_time?).returns(true)
          end

          it { subject.must_equal true }
        end

        describe 'private_message_required?' do

        end

      end

    end
  end



end