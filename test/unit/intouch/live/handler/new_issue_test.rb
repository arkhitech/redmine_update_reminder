require File.expand_path('../../../../../test_helper', __FILE__)

class Intouch::Live::Handler::NewIssueTest < ActiveSupport::TestCase
  fixtures :projects

  subject { Intouch::Live::Handler::NewIssue.new(issue).call }

  let(:project) { Project.first }
  let(:issue) { Issue.new(project: project) }

  describe 'send' do
    before do
      Intouch::Live::Checker::Base.any_instance
        .stubs(:required?)
        .returns(true)
    end

    it 'private message' do
      Intouch::Live::Message::Private.any_instance.expects(:send)

      subject
    end

    it 'group message' do
      Intouch::Live::Message::Group.any_instance.expects(:send)

      subject
    end
  end

  describe 'not send' do
    before do
      Intouch::Live::Checker::Base.any_instance
        .stubs(:required?)
        .returns(false)
    end

    it 'private message' do
      Intouch::Live::Message::Private.any_instance.expects(:send).never

      subject
    end

    it 'group message' do
      Intouch::Live::Message::Group.any_instance.expects(:send).never

      subject
    end
  end
end
