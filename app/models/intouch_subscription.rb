class IntouchSubscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :project

  def active?
    project.assigner_ids.include?(user_id)
  end
end
