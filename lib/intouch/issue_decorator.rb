class Intouch::IssueDecorator < SimpleDelegator

  def initialize(issue, journal_id)
    super(issue)
    @journal = journals.find_by(id: journal_id)
  end

  def telegram_live_message
    message = "`#{project.title}: #{subject}`"

    message += "\n#{I18n.t('intouch.telegram_message.issue.updated_by')}: #{updated_by}" if updated_by.present?

    message += "\n#{I18n.t('field_assigned_to')}: #{updated_performer_text}" if updated_details.include?('assigned_to')

    message += bold_for_alarm(updated_priority_text) if updated_details.include?('priority')

    message += "\n#{I18n.t('field_status')}: #{updated_status_text}" if updated_details.include?('status')

    message += "\n#{I18n.t('intouch.telegram_message.issue.updated_details')}: #{updated_details_text}" if updated_details_text.present?

    message += "\n#{I18n.t('field_assigned_to')}: #{performer}" unless updated_details.include?('assigned_to')

    message += bold_for_alarm(priority.name) unless updated_details.include?('priority')

    message += "\n#{I18n.t('field_status')}: #{status.name}" unless updated_details.include?('status')

    message += "\n#{Intouch.issue_url(id)}"

    if defined?(telegram_group) && telegram_group&.shared_url.present?
      message += ", [#{I18n.t('intouch.telegram_message.issue.telegram_link')}](#{telegram_group.shared_url})"
    end

    message
  end

  private

  def updated_details
    updated_details = []
    if @journal.present?
      updated_details = @journal.visible_details.map do |detail|
        if detail.property == 'attr'
          detail.prop_key.to_s.gsub(/_id$/, '')
        elsif detail.property == 'cf'
          detail.prop_key.to_i
        elsif detail.property == 'attachment'
          'attachment'
        end
      end
      updated_details << 'notes' if @journal.notes.present?
    end
    updated_details
  end

  def updated_details_text
    if updated_details.present?
      (updated_details - %w(priority status assigned_to)).map do |field|
        if field.is_a? String
          if field == 'attachment'
            I18n.t('label_attachment')
          else
            I18n.t(('field_' + field).to_sym)
          end
        elsif field.is_a? Fixnum
          CustomField.find(field).try(:name)
        end
      end.join(', ')
    end
  end

  def updated_by
    @journal.user if journals.present?
  end

  def updated_priority_text
    priority_journal = @journal.details.find_by(prop_key: 'priority_id')
    old_priority = IssuePriority.find(priority_journal.old_value)
    "#{old_priority.name} -> #{priority.name}"
  end

  def updated_performer_text
    performer_journal = @journal.details.find_by(prop_key: 'assigned_to_id')
    if performer_journal.old_value
      old_performer = Principal.find performer_journal.old_value
      "#{old_performer.name} -> #{performer}"
    else
      "#{I18n.t('intouch.telegram_message.issue.performer.unassigned')} -> #{performer}"
    end
  end

  def updated_status_text
    status_journal = @journal.details.find_by(prop_key: 'status_id')
    old_status = IssueStatus.find status_journal.old_value
    "#{old_status.name} -> #{status.name}"
  end
end
