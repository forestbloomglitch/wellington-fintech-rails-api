class TaxFiling < ApplicationRecord
  belongs_to :organization
  
  validates :filing_type, inclusion: { in: %w[gst paye income_tax] }
  validates :period_start, :period_end, :due_date, presence: true
  validates :status, inclusion: { in: %w[pending submitted accepted rejected] }
  
  scope :gst, -> { where(filing_type: 'gst') }
  scope :paye, -> { where(filing_type: 'paye') } 
  scope :overdue, -> { where('due_date < ? AND filed_date IS NULL', Date.current) }
  scope :filed_late, -> { where(filed_late: true) }
  
  def filed?
    filed_date.present?
  end
  
  def overdue?
    due_date < Date.current && !filed?
  end
  
  def filed_late?
    filed_date && filed_date > due_date
  end
  
  def period_description
    "#{period_start.strftime('%b %Y')} - #{period_end.strftime('%b %Y')}"
  end
  
  def parsed_filing_data
    return {} unless filing_data.present?
    
    JSON.parse(filing_data).with_indifferent_access
  rescue JSON::ParserError
    {}
  end
end