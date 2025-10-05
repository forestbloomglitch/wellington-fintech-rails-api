class Account < ApplicationRecord
  belongs_to :organization
  has_many :financial_transactions, dependent: :restrict_with_error
  has_many :counterparty_transactions, class_name: 'FinancialTransaction', foreign_key: 'counterparty_account_id'
  
  validates :name, presence: true
  validates :account_number, presence: true, uniqueness: { scope: :organization_id }
  validates :account_type, inclusion: { 
    in: %w[checking savings investment business_checking term_deposit credit_card loan],
    message: "must be a valid account type"
  }
  validates :currency, inclusion: { in: %w[NZD AUD USD GBP EUR] }
  
  scope :active, -> { where(active: true) }
  scope :frozen, -> { where(frozen: true) }
  scope :by_currency, ->(currency) { where(currency: currency) }
  
  def display_name
    "#{name} (#{account_number})"
  end
  
  def balance_nzd
    balance_cents / 100.0
  end
  
  def can_transact?
    active? && !frozen?
  end
  
  def freeze!
    update!(frozen: true)
  end
  
  def unfreeze!
    update!(frozen: false)
  end
  
  def recent_transactions(limit: 10)
    financial_transactions
      .includes(:created_by, :transaction_category)
      .order(created_at: :desc)
      .limit(limit)
  end
  
  def monthly_transaction_summary
    transactions = financial_transactions.where(created_at: 1.month.ago..Time.current)
    
    {
      total_transactions: transactions.count,
      total_inflow: transactions.where(transaction_type: %w[deposit payment_in]).sum(:amount_cents) / 100.0,
      total_outflow: transactions.where(transaction_type: %w[withdrawal payment_out]).sum(:amount_cents) / 100.0,
      average_transaction: transactions.average(:amount_cents)&.to_f&./(100) || 0.0,
      largest_transaction: transactions.maximum(:amount_cents)&./(100) || 0.0
    }
  end
  
  def compliance_flags
    flags = []
    flags << 'high_volume' if monthly_transaction_summary[:total_transactions] > 100
    flags << 'large_transactions' if monthly_transaction_summary[:largest_transaction] > 50_000
    flags << 'dormant' if financial_transactions.where(created_at: 3.months.ago..Time.current).empty?
    flags
  end
  
  def generate_statement(start_date, end_date)
    transactions = financial_transactions
                    .where(created_at: start_date..end_date)
                    .includes(:created_by, :transaction_category)
                    .order(:created_at)
    
    {
      account: display_name,
      period: { start: start_date, end: end_date },
      opening_balance: calculate_balance_at(start_date),
      closing_balance: calculate_balance_at(end_date),
      transactions: transactions.map(&:statement_summary),
      summary: {
        total_transactions: transactions.count,
        total_deposits: transactions.where(transaction_type: %w[deposit payment_in]).sum(:amount_cents) / 100.0,
        total_withdrawals: transactions.where(transaction_type: %w[withdrawal payment_out]).sum(:amount_cents) / 100.0
      }
    }
  end
  
  private
  
  def calculate_balance_at(date)
    # This would calculate historical balance - simplified for demo
    balance_cents / 100.0
  end
end