class User < ApplicationRecord
  has_secure_password
  
  belongs_to :organization
  has_many :created_transactions, class_name: 'FinancialTransaction', foreign_key: 'created_by_id'
  has_many :audit_entries
  
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, :last_name, presence: true
  validates :role, inclusion: { in: %w[user admin manager compliance_officer] }
  
  scope :authorized_for_high_value, -> { where(authorized_for_high_value: true) }
  scope :admins, -> { where(role: 'admin') }
  scope :compliance_officers, -> { where(role: 'compliance_officer') }
  
  def full_name
    "#{first_name} #{last_name}"
  end
  
  def authorized_for_high_value?
    authorized_for_high_value || admin? || compliance_officer?
  end
  
  def admin?
    role == 'admin'
  end
  
  def compliance_officer?
    role == 'compliance_officer'
  end
  
  def manager?
    role == 'manager'
  end
  
  def can_approve_transactions?
    admin? || manager? || compliance_officer?
  end
  
  def recent_activity_summary
    {
      transactions_created: created_transactions.where(created_at: 1.week.ago..Time.current).count,
      high_value_transactions: created_transactions.where('amount_cents > ?', 1_000_000).where(created_at: 1.week.ago..Time.current).count,
      last_login: updated_at,
      compliance_actions: audit_entries.where(created_at: 1.week.ago..Time.current).count
    }
  end
end