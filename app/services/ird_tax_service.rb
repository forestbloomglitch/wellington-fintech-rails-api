# IRD (Inland Revenue Department) Tax Calculation Service
# Demonstrates understanding of New Zealand tax system and compliance
class IrdTaxService
  include NzBusinessRules
  
  GST_RATE = 0.15 # 15% GST rate in New Zealand
  GST_THRESHOLD = 60_000_00 # NZD 60,000 in cents (GST registration threshold)
  
  attr_reader :organization, :period_start, :period_end
  
  def initialize(organization, period_start: nil, period_end: nil)
    @organization = organization
    @period_start = period_start || 1.month.ago.beginning_of_month
    @period_end = period_end || 1.month.ago.end_of_month
    
    validate_inputs!
  end
  
  # GST Calculation Methods
  def calculate_gst_return
    {
      organization: organization.name,
      ird_number: organization.ird_number,
      period: {
        start: period_start.strftime('%Y-%m-%d'),
        end: period_end.strftime('%Y-%m-%d'),
        description: format_period_description
      },
      gst_summary: gst_summary,
      detailed_breakdown: detailed_gst_breakdown,
      compliance_status: assess_gst_compliance,
      filing_requirements: determine_filing_requirements,
      calculated_at: Time.current,
      calculator_version: '1.0',
      next_filing_due: calculate_next_filing_date
    }
  end
  
  def gst_summary
    sales_data = calculate_sales_gst
    purchase_data = calculate_purchases_gst
    
    gst_collected = sales_data[:total_gst]
    gst_paid = purchase_data[:total_gst]
    net_gst = gst_collected - gst_paid
    
    {
      total_sales_excl_gst: sales_data[:total_excl_gst] / 100.0,
      total_gst_collected: gst_collected / 100.0,
      total_purchases_excl_gst: purchase_data[:total_excl_gst] / 100.0,
      total_gst_paid: gst_paid / 100.0,
      net_gst_position: net_gst / 100.0,
      gst_to_pay: net_gst > 0 ? net_gst / 100.0 : 0.0,
      gst_refund_due: net_gst < 0 ? (net_gst * -1) / 100.0 : 0.0,
      zero_rated_sales: calculate_zero_rated_sales / 100.0,
      exempt_supplies: calculate_exempt_supplies / 100.0
    }
  end
  
  def detailed_gst_breakdown
    {
      sales_breakdown: sales_by_category,
      purchase_breakdown: purchases_by_category,
      gst_adjustments: calculate_gst_adjustments,
      prior_period_adjustments: prior_period_adjustments,
      bad_debt_adjustments: bad_debt_adjustments
    }
  end
  
  # PAYE Calculation (if applicable)
  def calculate_paye
    return { applicable: false, reason: 'No employees registered' } unless has_employees?
    
    payroll_data = fetch_payroll_data
    
    {
      applicable: true,
      period: format_period_description,
      total_gross_wages: payroll_data[:gross_wages] / 100.0,
      total_paye_deducted: payroll_data[:paye_deducted] / 100.0,
      total_acc_levies: payroll_data[:acc_levies] / 100.0,
      total_kiwisaver_contributions: payroll_data[:kiwisaver] / 100.0,
      net_payment_to_ird: calculate_net_ird_payment(payroll_data) / 100.0,
      due_date: calculate_paye_due_date,
      compliance_status: assess_paye_compliance(payroll_data)
    }
  end
  
  # Compliance Assessment
  def assess_compliance_status
    issues = []
    
    # GST compliance checks
    if organization.annual_turnover_cents >= GST_THRESHOLD && !organization.gst_registered?
      issues << {
        type: 'gst_registration_required',
        severity: 'high',
        description: 'GST registration required - annual turnover exceeds $60,000',
        action_required: 'Register for GST within 21 days'
      }
    end
    
    # Filing frequency check
    if incorrect_filing_frequency?
      issues << {
        type: 'filing_frequency_incorrect',
        severity: 'medium',
        description: 'Filing frequency may need adjustment based on turnover',
        action_required: 'Review filing frequency with IRD'
      }
    end
    
    # Outstanding returns check
    outstanding_returns = check_outstanding_returns
    if outstanding_returns.any?
      issues << {
        type: 'outstanding_returns',
        severity: 'high',
        description: "#{outstanding_returns.count} overdue tax returns",
        action_required: 'File outstanding returns immediately',
        details: outstanding_returns
      }
    end
    
    {
      compliant: issues.empty?,
      issues_count: issues.count,
      compliance_score: calculate_compliance_score(issues),
      issues: issues,
      last_assessed: Time.current,
      next_review_date: 3.months.from_now
    }
  end
  
  # IRD Integration Methods
  def submit_gst_return(return_data, dry_run: true)
    return simulate_submission(return_data) if dry_run
    
    # In production, this would integrate with IRD's digital services
    ird_gateway = IrdGatewayClient.new(organization.ird_credentials)
    
    submission_result = ird_gateway.submit_gst_return({
      ird_number: organization.ird_number,
      period_start: period_start,
      period_end: period_end,
      return_data: format_for_ird_submission(return_data),
      submission_metadata: {
        software_provider: 'Wellington FinTech API',
        submission_time: Time.current,
        user_id: current_user&.id
      }
    })
    
    # Log submission for audit trail
    AuditLogger.log_tax_submission(organization, submission_result)
    
    submission_result
  end
  
  private
  
  def validate_inputs!
    raise ArgumentError, 'Organization must be present' unless organization
    raise ArgumentError, 'Organization must be GST registered' unless organization.gst_registered?
    raise ArgumentError, 'Invalid period dates' if period_start >= period_end
    
    unless organization.ird_number.present?
      raise ArgumentError, 'Organization must have valid IRD number'
    end
  end
  
  def calculate_sales_gst
    sales_transactions = organization.financial_transactions
                                  .where(transaction_type: ['payment_in', 'deposit'])
                                  .where(created_at: period_start..period_end)
    
    total_incl_gst = sales_transactions.sum(:amount_cents)
    total_excl_gst = (total_incl_gst / 1.15).round # Remove GST
    total_gst = total_incl_gst - total_excl_gst
    
    {
      total_incl_gst: total_incl_gst,
      total_excl_gst: total_excl_gst,
      total_gst: total_gst,
      transaction_count: sales_transactions.count
    }
  end
  
  def calculate_purchases_gst
    purchase_transactions = organization.financial_transactions
                                     .where(transaction_type: ['payment_out', 'withdrawal'])
                                     .where(created_at: period_start..period_end)
    
    # Similar calculation for purchases
    total_incl_gst = purchase_transactions.sum(:amount_cents)
    total_excl_gst = (total_incl_gst / 1.15).round
    total_gst = total_incl_gst - total_excl_gst
    
    {
      total_incl_gst: total_incl_gst,
      total_excl_gst: total_excl_gst,
      total_gst: total_gst,
      transaction_count: purchase_transactions.count
    }
  end
  
  def calculate_zero_rated_sales
    # Zero-rated supplies (e.g., exports, going concern sales)
    organization.financial_transactions
               .where(transaction_type: 'payment_in')
               .where(gst_treatment: 'zero_rated')
               .where(created_at: period_start..period_end)
               .sum(:amount_cents)
  end
  
  def calculate_exempt_supplies
    # Exempt supplies (e.g., financial services, residential rent)
    organization.financial_transactions
               .where(transaction_type: 'payment_in')
               .where(gst_treatment: 'exempt')
               .where(created_at: period_start..period_end)
               .sum(:amount_cents)
  end
  
  def sales_by_category
    organization.financial_transactions
               .joins(:transaction_category)
               .where(transaction_type: 'payment_in')
               .where(created_at: period_start..period_end)
               .group('transaction_categories.name')
               .sum(:amount_cents)
               .transform_values { |v| v / 100.0 }
  end
  
  def purchases_by_category
    organization.financial_transactions
               .joins(:transaction_category)
               .where(transaction_type: 'payment_out')
               .where(created_at: period_start..period_end)
               .group('transaction_categories.name')
               .sum(:amount_cents)
               .transform_values { |v| v / 100.0 }
  end
  
  def determine_filing_requirements
    annual_turnover = organization.annual_turnover_cents
    
    case annual_turnover
    when 0..2_000_000_00 # Up to $2M
      { frequency: 'monthly', due_date_offset: 28.days }
    when 2_000_000_00..24_000_000_00 # $2M to $24M
      { frequency: 'monthly', due_date_offset: 28.days }
    else # Over $24M
      { frequency: 'monthly', due_date_offset: 28.days, special_requirements: true }
    end
  end
  
  def calculate_next_filing_date
    filing_requirements = determine_filing_requirements
    case filing_requirements[:frequency]
    when 'monthly'
      (period_end + 1.month).end_of_month + filing_requirements[:due_date_offset]
    when 'bi_monthly'
      (period_end + 2.months).end_of_month + filing_requirements[:due_date_offset]
    else
      (period_end + 6.months).end_of_month + filing_requirements[:due_date_offset]
    end
  end
  
  def format_period_description
    case (period_end - period_start).to_i / 1.day
    when 27..31
      period_start.strftime('%B %Y')
    when 58..62
      "#{period_start.strftime('%B')} - #{period_end.strftime('%B %Y')}"
    else
      "#{period_start.strftime('%d %b %Y')} to #{period_end.strftime('%d %b %Y')}"
    end
  end
  
  def assess_gst_compliance
    issues = []
    
    # Check if returns are filed on time
    last_filing = organization.tax_filings.gst.order(:period_end).last
    if last_filing && last_filing.filed_late?
      issues << 'late_filing_history'
    end
    
    # Check for significant variations
    current_gst = gst_summary[:net_gst_position]
    previous_period_gst = calculate_previous_period_gst
    
    if previous_period_gst && (current_gst - previous_period_gst).abs > 10_000
      issues << 'significant_variation'
    end
    
    {
      status: issues.empty? ? 'compliant' : 'attention_required',
      issues: issues,
      confidence_score: calculate_confidence_score
    }
  end
  
  def simulate_submission(return_data)
    {
      success: true,
      submission_id: "SIM-#{SecureRandom.hex(8).upcase}",
      ird_reference: "IRD-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}",
      submitted_at: Time.current,
      status: 'accepted',
      processing_time: '2-3 business days',
      confirmation_code: SecureRandom.hex(6).upcase,
      simulation_mode: true,
      next_steps: [
        'Return will be processed by IRD',
        'Confirmation will be sent to registered email',
        'Payment due date: ' + calculate_payment_due_date.strftime('%d %B %Y')
      ]
    }
  end
  
  def calculate_payment_due_date
    # IRD payment due date is typically the 28th of the month following the return
    (period_end + 1.month).change(day: 28)
  end
  
  def calculate_confidence_score
    # Simple confidence scoring based on data completeness and consistency
    base_score = 85
    
    # Adjust based on data quality factors
    base_score += 10 if organization.financial_transactions.count > 50
    base_score -= 15 if missing_transaction_categories?
    base_score += 5 if consistent_filing_history?
    
    [base_score, 100].min
  end
  
  def missing_transaction_categories?
    uncategorized = organization.financial_transactions
                               .where(created_at: period_start..period_end)
                               .where(transaction_category: nil)
                               .count
    
    uncategorized > organization.financial_transactions.count * 0.1 # More than 10% uncategorized
  end
  
  def consistent_filing_history?
    organization.tax_filings.gst.where('period_end > ?', 1.year.ago).count >= 12
  end
end