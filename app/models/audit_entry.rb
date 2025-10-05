class AuditEntry < ApplicationRecord
  belongs_to :auditable, polymorphic: true
  belongs_to :user, optional: true
  
  validates :action, presence: true
  validates :auditable_type, :auditable_id, presence: true
  
  scope :recent, -> { where('created_at > ?', 30.days.ago) }
  scope :for_retention, -> { where('expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at < ?', Time.current) }
  scope :by_action, ->(action) { where(action: action) }
  
  def parsed_changes
    return {} unless audited_changes.present?
    
    JSON.parse(audited_changes).with_indifferent_access
  rescue JSON::ParserError
    {}
  end
  
  def expired?
    expires_at && expires_at < Time.current
  end
  
  def retention_period_remaining
    return nil unless expires_at
    
    (expires_at - Time.current) / 1.year
  end
  
  def summary
    {
      id: id,
      action: action,
      auditable: "#{auditable_type}##{auditable_id}",
      user: user&.email || 'System',
      timestamp: created_at.iso8601,
      ip_address: remote_address&.to_s,
      expires: expires_at&.iso8601
    }
  end
  
  # Clean up expired audit entries (would be run via cron job)
  def self.cleanup_expired!
    expired.delete_all
  end
end