require File.expand_path('../../../test_helper', __FILE__)

class NewIssueHandlerTest < ActiveSupport::TestCase
  fixtures :projects

  subject { Intouch::NewIssueHandler.new(issue).call }

  let(:project) { Project.first }
  let(:issue) { Issue.new(project: project) }

  describe 'send' do
    before do
      Intouch::Checker::NotificationRequired.any_instance
        .stubs(:call)
        .returns(true)
    end

    it 'private message' do
      Intouch::PrivateMessageSender.expects(:call).with(issue, project)

      subject
    end

    it 'group message' do
      Intouch::GroupMessageSender.expects(:call).with(issue, project)

      subject
    end
  end

  describe 'not send' do
    before do
      Intouch::Checker::NotificationRequired.any_instance
        .stubs(:call)
        .returns(false)
    end

    it 'private message' do
      Intouch::PrivateMessageSender.expects(:call).never

      subject
    end

    it 'group message' do
      Intouch::GroupMessageSender.expects(:call).never

      subject
    end
  end
end
