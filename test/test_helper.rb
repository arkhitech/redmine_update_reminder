$VERBOSE = nil # for hide ruby warnings

# Load the Redmine helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')
require "minitest/reporters"

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
