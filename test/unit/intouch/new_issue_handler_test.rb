require File.expand_path('../../../test_helper', __FILE__)

class NewIssueHandlerTest < ActiveSupport::TestCase
  fixtures :projects

  subject { Intouch::NewIssueHandler.new(issue).call }

  let(:project) { Project.first }
  let(:issue) { Issue.new(project_id: project.id)}

  describe 'without notification' do
    describe 'project without enabled intouch module' do

      before do
        project.stubs(:module_enabled?).with(:intouch).returns(false)
      end

      it { project.module_enabled?(:intouch).must_equal false}
      it { subject.must_equal -1 }
    end

    describe 'inactive project' do

      before do
        project.stubs(:module_enabled?).with(:intouch).returns(true)
        project.stubs(:active?).returns(false)
      end

      it { project.module_enabled?(:intouch).must_equal true}
      it { project.active?.must_equal false}

      it { subject.must_equal -1 }

    end

    describe 'closed issue' do
      before do
        project.stubs(:module_enabled?).with(:intouch).returns(true)
        project.stubs(:active?).returns(true)
        issue.stubs(:closed?).returns(true)
      end

      it { project.module_enabled?(:intouch).must_equal true}
      it { project.active?.must_equal true}
      it { issue.closed?.must_equal true}

      it { subject.must_equal -1 }

    end
  end

end