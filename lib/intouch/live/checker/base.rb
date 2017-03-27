module Intouch::Live::Checker
  class Base
    attr_reader :project, :issue

    def initialize(issue, project)
      @issue = issue
      @project = project
    end

    def required?
      project.module_enabled?(:intouch) &&
        project.active? &&
        !issue.closed?
    end
  end
end
