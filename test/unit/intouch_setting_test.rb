require File.expand_path('../../test_helper', __FILE__)

class IntouchSettingTest < ActiveSupport::TestCase
  fixtures :projects

  def test_available_settings
    %w(alarm new wip feedback).each do |notice|
      %w(author assignee watchers).each do |receiver|
        assert IntouchSetting.available_settings["telegram_#{notice}_#{receiver}_enabled"]
      end
      assert IntouchSetting.available_settings["telegram_#{notice}_telegram_groups"]
    end
  end

  def test_boolean_setting
    project = Project.first
    %w(alarm new wip feedback).each do |notice|
      %w(author assignee watchers).each do |receiver|
        IntouchSetting["telegram_#{notice}_#{receiver}_enabled", project.id] = '1'
        assert_equal IntouchSetting["telegram_#{notice}_#{receiver}_enabled", project.id], '1'
      end
    end
  end

  def test_find_or_default
    project = Project.first
    %w(alarm new wip feedback).each do |notice|
      # IntouchSetting["telegram_#{notice}_telegram_groups", project.id] = {'1': '1'}
      p IntouchSetting.find_or_default "telegram_#{notice}_telegram_groups", project.id
      assert IntouchSetting["telegram_#{notice}_telegram_groups", project.id]
    end
  end

  # def test_serialized_settings
  #   project = Project.first
  #   p project
  #   %w(alarm new wip feedback).each do |notice|
  #     IntouchSetting["telegram_#{notice}_telegram_groups", project.id] = {'1': '1'}
  #     assert_equal IntouchSetting["telegram_#{notice}_telegram_groups", project.id]['1'], '1'
  #   end
  #
  # end

  # def test_update
  #   IntouchSetting.app_title = "My title"
  #   assert_equal "My title", IntouchSetting.app_title
  #   # make sure db has been updated (INSERT)
  #   assert_equal "My title", IntouchSetting.find_by_name('app_title').value
  #
  #   IntouchSetting.app_title = "My other title"
  #   assert_equal "My other title", IntouchSetting.app_title
  #   # make sure db has been updated (UPDATE)
  #   assert_equal "My other title", IntouchSetting.find_by_name('app_title').value
  # end
end
