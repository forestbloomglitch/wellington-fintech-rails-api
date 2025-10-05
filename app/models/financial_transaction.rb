# RBNZ-compliant Financial Transaction Model
# Demonstrates understanding of New Zealand banking regulations
class FinancialTransaction < ApplicationRecord
  # Money-rails would be included in production - simplified for demo
  # monetize :amount_cents, with_model_currency: :currency
  
  # Serialized fields for demo
  serialize :compliance_flags, Array
  
  # Associations
  belongs_to :account
  belongs_to :counterparty_account, class_name: 'Account', optional: true
  belongs_to :created_by, class_name: 'User'
  belongs_to :transaction_category, optional: true
  has_many :audit_entries, as: :auditable, dependent: :restrict_with_error
  
  # Validations - RBNZ requirements
  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :currency, inclusion: { 
    in: Rails.application.config.x.supported_currencies,
    message: "must be a supported currency: #{Rails.application.config.x.supported_currencies.join(', ')}"
  }
  validates :transaction_type, presence: true, inclusion: { 
    in: %w[deposit withdrawal transfer payment_in payment_out fee_charge interest_payment]
  }
  validates :reference, presence: true, uniqueness: true
  validates :description, presence: true, length: { maximum: 500 }
  
  # Custom validations
  validate :validate_high_value_transaction
  validate :validate_international_transaction
  validate :validate_business_hours_for_large_transactions
  
  # Scopes
  scope :high_value, -> { where('amount_cents > ?', 1_000_000) } # NZD 10,000+
  scope :international, -> { where.not(currency: 'NZD') }
  scope :requiring_reporting, -> { 
    where('amount_cents > ? OR created_at > ?', 1_000_000, 24.hours.ago)
  }
  scope :by_date_range, ->(start_date, end_date) { 
    where(created_at: start_date..end_date) 
  }
  
  # Callbacks
  before_validation :generate_reference, if: -> { reference.blank? }
  before_create :perform_compliance_checks
  after_create :log_audit_trail
  after_create :queue_regulatory_reporting, if: :requires_reporting?
  
  # Encrypted fields for PII protection
  encrypts :counterparty_details, :additional_metadata
  blind_index :counterparty_details, :encrypted_counterparty_details_bidx
  
  # Class methods
  def self.generate_compliance_report(start_date, end_date)
    transactions = by_date_range(start_date, end_date)
    
    {
      period: { start: start_date, end: end_date },
      total_transactions: transactions.count,
      total_value_nzd: transactions.sum(:amount_cents) / 100.0,
      high_value_transactions: transactions.high_value.count,
      international_transactions: transactions.international.count,
      currency_breakdown: currency_breakdown(transactions),
      compliance_flags: compliance_flags_summary(transactions),
      generated_at: Time.current,
      retention_until: Time.current + Rails.application.config.x.audit_retention_period
    }
  end
  
  def self.currency_breakdown(transactions)
    transactions.group(:currency).sum(:amount_cents).transform_values { |v| v / 100.0 }
  end
  
  def self.compliance_flags_summary(transactions)
    transactions.where.not(compliance_flags: []).group(:compliance_flags).count
  end
  
  # Instance methods
  def high_value?
    amount_cents > 1_000_000 # NZD 10,000
  end
  
  def international?
    currency != 'NZD'
  end
  
  def requires_reporting?
    high_value? || international? || flagged_for_review?
  end
  
  def flagged_for_review?
    compliance_flags.any?
  end
  
  def audit_trail_summary
    {
      transaction_id: id,
      reference: reference,
      amount: format_amount,
      created_at: created_at,
      created_by: created_by.email,
      compliance_status: compliance_status,
      audit_entries_count: audit_entries.count,
      last_audit_at: audit_entries.maximum(:created_at)
    }
  end
  
  def format_amount
    "#{currency} $#{amount_cents / 100.0}"
  end
  
  def statement_summary
    {
      date: created_at.strftime('%Y-%m-%d'),
      description: description,
      reference: reference,
      amount: format_amount,
      type: transaction_type.humanize,
      balance_impact: transaction_type.in?(%w[deposit payment_in]) ? '+' : '-'
    }
  end
  
  # RBNZ reporting methods
  def to_rbnz_format
    {
      transaction_reference: reference,
      amount_cents: amount_cents,
      currency: currency,
      transaction_type: transaction_type,
      transaction_date: created_at.strftime('%Y-%m-%d'),
      reporting_entity: account.organization.rbnz_identifier,
      compliance_category: determine_compliance_category,
      risk_assessment: calculate_risk_score
    }
  end
  
  private
  
  def generate_reference
    self.reference = "TXN-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(8).upcase}"
  end
  
  def perform_compliance_checks
    self.compliance_flags = []
    
    compliance_flags << 'high_value' if high_value?
    compliance_flags << 'international' if international?
    compliance_flags << 'suspicious_pattern' if detect_suspicious_pattern
    compliance_flags << 'after_hours' if created_outside_business_hours?
    
    self.compliance_status = compliance_flags.any? ? 'flagged' : 'compliant'
  end
  
  def validate_high_value_transaction
    return unless high_value?
    
    if created_by.nil? || !created_by.authorized_for_high_value?
      errors.add(:amount, 'High value transactions require authorized user approval')
    end
  end
  
  def validate_international_transaction
    return unless international?
    
    unless account.organization.international_transactions_enabled?
      errors.add(:currency, 'International transactions not enabled for this organization')
    end
  end
  
  def validate_business_hours_for_large_transactions
    return unless amount_cents > 5_000_000 # NZD 50,000+
    
    unless Time.current.business_time?
      errors.add(:base, 'Large transactions must be processed during business hours')
    end
  end
  
  def detect_suspicious_pattern
    # Implement suspicious pattern detection logic
    # This would typically involve ML models or rule-based systems
    recent_transactions = account.financial_transactions
                                .where(created_at: 24.hours.ago..Time.current)
                                .where.not(id: id)
    
    # Simple rule: More than 5 transactions in 24 hours over NZD 5,000 each
    recent_transactions.where('amount_cents > ?', 500_000).count >= 5
  end
  
  def created_outside_business_hours?
    !created_at.business_time?
  end
  
  def determine_compliance_category
    return 'high_risk' if compliance_flags.include?('suspicious_pattern')
    return 'medium_risk' if high_value? || international?
    'standard'
  end
  
  def calculate_risk_score
    score = 0
    score += 3 if compliance_flags.include?('suspicious_pattern')
    score += 2 if high_value?
    score += 1 if international?
    score += 1 if created_outside_business_hours?
    
    score
  end
  
  def log_audit_trail
    # Create audit entry directly - AuditLogger would be a service in production
    AuditEntry.create!(
      auditable: self,
      action: 'financial_transaction_created',
      audited_changes: {
        amount_cents: amount_cents,
        currency: currency,
        transaction_type: transaction_type,
        compliance_flags: compliance_flags
      }.to_json,
      user: created_by,
      remote_address: '127.0.0.1',
      expires_at: 7.years.from_now
    )
  end
  
  def queue_regulatory_reporting
    RegulatoryReportingJob.perform_later(self) if requires_reporting?
  end
end