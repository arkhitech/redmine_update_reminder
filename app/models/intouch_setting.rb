class IntouchSetting < ActiveRecord::Base
  unloadable
  belongs_to :project

  attr_accessible :name, :value, :project_id

  cattr_accessor :available_settings
  self.available_settings ||= {}

  def self.load_available_settings
    %w(alarm new working feedback overdue).each do |notice|
      %w(author assigned_to watchers).each do |receiver|
        define_setting "telegram_#{notice}_#{receiver}"
      end
      define_setting "telegram_#{notice}_telegram_groups", serialized: true, default: {}
      define_setting "telegram_#{notice}_user_groups", serialized: true, default: {}
    end
    define_setting 'email_cc', default: ''
  end


  def self.define_setting(name, options={})
    available_settings[name.to_s] = options
  end
  # Hash used to cache setting values
  @intouch_cached_settings = {}
  @intouch_cached_cleared_on = Time.now

  # Hash used to cache setting values
  @cached_settings = {}
  @cached_cleared_on = Time.now


  validates_uniqueness_of :name, scope: [:project_id]

  def value
    v = read_attribute(:value)
    # Unserialize serialized settings
    if available_settings[name][:serialized] && v.is_a?(String)
      v = YAML::load(v)
      v = force_utf8_strings(v)
    end
    # v = v.to_sym if available_settings[name]['format'] == 'symbol' && !v.blank?
    v
  end

  def value=(v)
    v = v.to_yaml if v && available_settings[name] && available_settings[name][:serialized]
    write_attribute(:value, v.to_s)
  end

  # Returns the value of the setting named name
  def self.[](name, project_id)
    project_id = project_id.id if project_id.is_a?(Project)
    v = @intouch_cached_settings[hk(name, project_id)]
    v ? v : (@intouch_cached_settings[hk(name, project_id)] = find_or_default(name, project_id).value)
  end

  def self.[]=(name, project_id, v)
    project_id = project_id.id if project_id.is_a?(Project)
    setting = find_or_default(name, project_id)
    setting.value = (v ? v : "")
    @intouch_cached_settings[hk(name, project_id)] = nil
    setting.save
    setting.value
  end

  # def self.[]=(name, v)
  #   setting = find_or_default(name)
  #   setting.value = (v ? v : "")
  #   @cached_settings[name] = nil
  #   setting.save
  #   setting.value
  # end

  # Checks if settings have changed since the values were read
  # and clears the cache hash if it's the case
  # Called once per request
  def self.check_cache
    settings_updated_on = IntouchSetting.maximum(:updated_on)
    if settings_updated_on && @intouch_cached_cleared_on <= settings_updated_on
      clear_cache
    end
  end

  # Clears the settings cache
  def self.clear_cache
    @intouch_cached_settings.clear
    @intouch_cached_cleared_on = Time.now
    logger.info "Intouch settings cache cleared." if logger
  end

  load_available_settings


  private

  def self.hk(name, project_id)
    "#{name}-#{project_id.to_s}"
  end

  # Returns the Setting instance for the setting named name
  # (record found in database or new record with default value)
  # def self.find_or_default(name, project_id)
  #   name = name.to_s
  #   setting = find_by_name_and_project_id(name, project_id)
  #   setting ||= new(:name => name, :value => '', :project_id => project_id)
  # end

  def self.find_or_default(name, project_id)
    name = name.to_s
    raise "There's no setting named #{name}" unless available_settings.has_key?(name)
    setting = find_by_name_and_project_id(name, project_id)
    unless setting
      setting = new(name: name, project_id: project_id)
      setting.value = available_settings[name][:default]
    end
    setting
  end

  def force_utf8_strings(arg)
    if arg.is_a?(String)
      arg.dup.force_encoding('UTF-8')
    elsif arg.is_a?(Array)
      arg.map do |a|
        force_utf8_strings(a)
      end
    elsif arg.is_a?(Hash)
      arg = arg.dup
      arg.each do |k,v|
        arg[k] = force_utf8_strings(v)
      end
      arg
    else
      arg
    end
  end
end
