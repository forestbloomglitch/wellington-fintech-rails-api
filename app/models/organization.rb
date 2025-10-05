class Organization < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :accounts, dependent: :destroy
  has_many :financial_transactions, through: :accounts
  has_many :tax_filings, dependent: :destroy
  
  validates :name, presence: true
  validates :ird_number, presence: true, format: { with: /\A\d{8,9}\z/, message: "must be 8 or 9 digits" }
  validates :contact_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :business_type, inclusion: { 
    in: %w[sole_trader partnership company trust other],
    message: "must be a valid business type"
  }
  
  scope :gst_registered, -> { where(gst_registered: true) }
  scope :requiring_gst_registration, -> { where('annual_turnover_cents >= ? AND gst_registered = ?', 6_000_000, false) }
  
  def gst_registered?
    gst_registered
  end
  
  def requires_gst_registration?
    annual_turnover_cents >= 6_000_000 && !gst_registered?
  end
  
  def total_balance_nzd
    accounts.active.sum(:balance_cents) / 100.0
  end
  
  def monthly_transaction_volume
    financial_transactions
      .where(created_at: 1.month.ago..Time.current)
      .sum(:amount_cents) / 100.0
  end
  
  def compliance_score
    score = 100
    score -= 20 if requires_gst_registration?
    score -= 10 if tax_filings.where('due_date < ? AND filed_date IS NULL', Date.current).any?
    score -= 5 if financial_transactions.where(compliance_status: 'flagged').count > 5
    [score, 0].max
  end
  
  def display_name
    "#{name} (IRD: #{ird_number})"
  end
end