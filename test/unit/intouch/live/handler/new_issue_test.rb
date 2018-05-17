require File.expand_path('../../../../../test_helper', __FILE__)

class Intouch::Live::Handler::NewIssueTest < ActiveSupport::TestCase
  fixtures :projects

  subject { Intouch::Live::Handler::NewIssue.new(issue).call }

  let(:project) { Project.first }
  let(:issue) { Issue.new(project: project) }
  let(:protocols) { }

  describe 'send' do
    before do
      Intouch::Live::Checker::Base.any_instance
        .stubs(:required?)
        .returns(true)
      @telegram = Intouch::Protocols::Telegram.new
      @slack = Intouch::Protocols::Slack.new
      Intouch.stubs(:active_protocols).returns(telegram: @telegram, slack: @slack)
    end

    it 'private message' do
      @telegram.expects(:handle_update)
      @slack.expects(:handle_update)

      subject
    end

    it 'group message' do
      @telegram.expects(:handle_update)
      @slack.expects(:handle_update)

      subject
    end
  end

  describe 'not send' do
    before do
      Intouch::Live::Checker::Base.any_instance
        .stubs(:required?)
        .returns(false)

      @telegram = Intouch::Protocols::Telegram.new
      @slack = Intouch::Protocols::Slack.new
      Intouch.stubs(:active_protocols).returns(telegram: @telegram, slack: @slack)
    end

    it 'private message' do
      @telegram.expects(:handle_update).never
      @slack.expects(:handle_update).never

      subject
    end

    it 'group message' do
      @telegram.expects(:handle_update).never
      @slack.expects(:handle_update).never

      subject
    end
  end
end
