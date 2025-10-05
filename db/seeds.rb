# Wellington FinTech Rails API - Seed Data
# Realistic New Zealand business scenarios for demonstration

puts "🏦 Creating Wellington FinTech demo data..."

# Clear existing data in development
if Rails.env.development?
  puts "Clearing existing data..."
  [FinancialTransaction, Account, User, Organization].each(&:delete_all)
end

# Create realistic NZ organizations
organizations = []

puts "Creating NZ organizations..."

# Wellington Tech Startup
wellington_tech = Organization.create!(
  name: "Wellington Tech Solutions Ltd",
  ird_number: "123456789",
  rbnz_identifier: "WTS2024001",
  gst_registered: true,
  annual_turnover_cents: 2_500_000_00, # $2.5M NZD
  business_type: "company",
  contact_email: "finance@wellingtontech.co.nz",
  address: "Level 12, 123 Lambton Quay, Wellington 6011",
  international_transactions_enabled: true
)
organizations << wellington_tech

# Auckland Consulting Firm  
auckland_consulting = Organization.create!(
  name: "Auckland Business Consultants",
  ird_number: "987654321",
  rbnz_identifier: "ABC2024002", 
  gst_registered: true,
  annual_turnover_cents: 850_000_00, # $850K NZD
  business_type: "partnership",
  contact_email: "accounts@aucklandbiz.co.nz",
  address: "Suite 5, Queen Street Tower, Auckland 1010",
  international_transactions_enabled: false
)
organizations << auckland_consulting

# Christchurch Manufacturing
christchurch_mfg = Organization.create!(
  name: "South Island Manufacturing Co",
  ird_number: "456789123",
  rbnz_identifier: "SIM2024003",
  gst_registered: true,
  annual_turnover_cents: 5_200_000_00, # $5.2M NZD
  business_type: "company", 
  contact_email: "finance@simfg.co.nz",
  address: "45 Industrial Drive, Christchurch 8041",
  international_transactions_enabled: true
)
organizations << christchurch_mfg

puts "Created #{organizations.count} organizations"

# Create users for each organization
users = []

organizations.each_with_index do |org, index|
  # Admin user
  admin = User.create!(
    email: "admin@#{org.contact_email.split('@').last}",
    first_name: ["Sarah", "Michael", "Emma"][index],
    last_name: ["Wilson", "Thompson", "Clarke"][index],
    password: "demo123!",
    organization: org,
    role: "admin",
    authorized_for_high_value: true
  )
  users << admin
  
  # Compliance officer
  compliance = User.create!(
    email: "compliance@#{org.contact_email.split('@').last}",
    first_name: ["James", "Lisa", "David"][index],
    last_name: ["Brown", "Davis", "Miller"][index], 
    password: "demo123!",
    organization: org,
    role: "compliance_officer",
    authorized_for_high_value: true
  )
  users << compliance
  
  # Regular user
  user = User.create!(
    email: "user@#{org.contact_email.split('@').last}",
    first_name: ["Anna", "Mark", "Sophie"][index],
    last_name: ["Taylor", "Anderson", "Roberts"][index],
    password: "demo123!",
    organization: org,
    role: "user",
    authorized_for_high_value: false
  )
  users << user
end

puts "Created #{users.count} users"

# Create accounts for each organization
accounts = []

organizations.each_with_index do |org, index|
  # Business checking account
  checking = Account.create!(
    name: "Business Checking",
    account_number: "12-3456-#{1000000 + index}-001",
    account_type: "business_checking",
    currency: "NZD", 
    balance_cents: [2_500_000, 850_000, 5_200_000][index] * 100, # Starting balances
    organization: org,
    active: true
  )
  accounts << checking
  
  # Savings account
  savings = Account.create!(
    name: "Business Savings",
    account_number: "12-3456-#{1000000 + index}-002",
    account_type: "savings",
    currency: "NZD",
    balance_cents: [500_000, 200_000, 1_000_000][index] * 100,
    organization: org,
    active: true
  )
  accounts << savings
  
  # USD account for international orgs
  if org.international_transactions_enabled?
    usd_account = Account.create!(
      name: "USD International Account",
      account_number: "12-3456-#{1000000 + index}-003",
      account_type: "business_checking",
      currency: "USD",
      balance_cents: [50_000, 0, 100_000][index] * 100, # USD balances
      organization: org,
      active: true
    )
    accounts << usd_account
  end
end

puts "Created #{accounts.count} accounts"

# Create realistic financial transactions
puts "Creating financial transactions..."

transactions_created = 0

accounts.each do |account|
  org = account.organization
  admin_user = org.users.find_by(role: 'admin')
  
  # Create 2 months of transaction history
  start_date = 2.months.ago
  
  (0..60).each do |days_ago|
    transaction_date = start_date + days_ago.days
    
    # Skip weekends for business transactions
    next if transaction_date.saturday? || transaction_date.sunday?
    
    # Create 1-5 transactions per business day
    rand(1..5).times do
      transaction_type = ['deposit', 'withdrawal', 'payment_in', 'payment_out', 'transfer'].sample
      
      # Realistic NZ amounts
      amount_cents = case transaction_type
                    when 'deposit', 'payment_in'
                      [150_00, 250_00, 500_00, 1_200_00, 2_500_00, 5_000_00, 12_500_00].sample
                    when 'withdrawal', 'payment_out'  
                      [75_00, 125_00, 350_00, 800_00, 1_500_00, 3_200_00].sample
                    when 'transfer'
                      [500_00, 1_000_00, 2_500_00].sample
                    end
      
      # GST treatment
      gst_treatment = ['standard', 'zero_rated', 'exempt'].sample
      if rand < 0.8 # 80% standard GST
        gst_treatment = 'standard'
      elsif rand < 0.1 # 10% zero-rated (exports)
        gst_treatment = 'zero_rated' 
      else # 10% exempt
        gst_treatment = 'exempt'
      end
      
      # Description based on transaction type and organization
      descriptions = {
        'deposit' => [
          "Customer payment - Invoice ##{rand(1000..9999)}",
          "Retail sales - POS settlement", 
          "Service fees - #{Date.current.strftime('%B')}",
          "Interest payment - term deposit"
        ],
        'withdrawal' => [
          "Office supplies - Warehouse Stationery",
          "Fuel expenses - BP Connect",
          "Staff lunch - Caffe L'affare",
          "Courier services - NZ Post"
        ],
        'payment_in' => [
          "Client consultation fees",
          "Software licensing - monthly",
          "Equipment rental income", 
          "Export sales - #{['Australia', 'USA', 'UK'].sample}"
        ],
        'payment_out' => [
          "Supplier payment - #{['Spark', 'Vodafone', 'ASB Bank'].sample}",
          "Insurance premium - IAG",
          "Legal fees - Wellington Law Firm",
          "Accounting services - KPMG"
        ]
      }
      
      transaction = FinancialTransaction.create!(
        reference: "TXN-#{transaction_date.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}",
        amount_cents: amount_cents,
        currency: account.currency,
        transaction_type: transaction_type,
        description: descriptions[transaction_type]&.sample || "#{transaction_type.humanize} transaction",
        account: account,
        created_by: admin_user,
        gst_treatment: gst_treatment,
        processed_at: transaction_date,
        created_at: transaction_date,
        updated_at: transaction_date
      )
      
      transactions_created += 1
    end
  end
end

puts "Created #{transactions_created} financial transactions"

# Create some high-value transactions for compliance testing
puts "Creating high-value transactions for compliance demonstration..."

high_value_count = 0
accounts.each do |account|
  next unless account.organization.international_transactions_enabled?
  
  admin_user = account.organization.users.find_by(role: 'admin')
  
  # Create a few high-value transactions (>$10,000 NZD)
  2.times do
    amount_cents = [15_000_00, 25_000_00, 50_000_00, 75_000_00].sample
    
    transaction = FinancialTransaction.create!(
      reference: "HVT-#{Date.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}",
      amount_cents: amount_cents,
      currency: account.currency,
      transaction_type: 'payment_out',
      description: "High-value payment - Equipment purchase from #{['Germany', 'Japan', 'USA'].sample}",
      account: account,
      created_by: admin_user,
      gst_treatment: 'standard',
      processed_at: rand(7.days).seconds.ago,
      counterparty_details: "International supplier - #{['Mercedes Equipment GmbH', 'Tokyo Tech Solutions', 'California Software Inc'].sample}"
    )
    
    high_value_count += 1
  end
end

puts "Created #{high_value_count} high-value transactions"

# Create some tax filing records
puts "Creating tax filing records..."

organizations.each do |org|
  # Create GST returns for the last 6 months
  (1..6).each do |months_ago|
    period_start = months_ago.months.ago.beginning_of_month
    period_end = months_ago.months.ago.end_of_month
    due_date = (period_end + 28.days).change(day: 28)
    
    # Some filed, some pending
    status = months_ago > 2 ? 'accepted' : ['pending', 'submitted'].sample
    filed_date = status == 'accepted' ? due_date - rand(5).days : nil
    
    TaxFiling.create!(
      organization: org,
      filing_type: 'gst',
      period_start: period_start,
      period_end: period_end,
      due_date: due_date,
      filed_date: filed_date,
      status: status,
      filing_data: {
        total_sales: rand(100_000..500_000),
        total_gst_collected: rand(15_000..75_000),
        total_purchases: rand(50_000..250_000),
        total_gst_paid: rand(7_500..37_500),
        net_gst_position: rand(-5_000..20_000)
      }.to_json,
      ird_reference: status == 'accepted' ? "IRD-#{period_end.strftime('%Y%m')}-#{SecureRandom.hex(4).upcase}" : nil,
      filed_late: filed_date && filed_date > due_date
    )
  end
end

puts "Created tax filing records"

# Create some audit entries for compliance demonstration
puts "Creating audit entries..."

audit_count = 0
FinancialTransaction.where('amount_cents > ?', 1_000_000).each do |transaction|
  AuditEntry.create!(
    auditable: transaction,
    action: 'high_value_transaction_created',
    audited_changes: {
      amount_cents: transaction.amount_cents,
      currency: transaction.currency,
      compliance_flags: transaction.compliance_flags
    }.to_json,
    user: transaction.created_by,
    remote_address: '127.0.0.1',
    expires_at: 7.years.from_now # RBNZ requirement
  )
  audit_count += 1
end

puts "Created #{audit_count} audit entries"

# Display summary
puts "\n🎉 Wellington FinTech demo data created successfully!"
puts "\n📊 Summary:"
puts "  Organizations: #{Organization.count}"
puts "  Users: #{User.count}"
puts "  Accounts: #{Account.count}"
puts "  Financial Transactions: #{FinancialTransaction.count}"
puts "  High-value Transactions: #{FinancialTransaction.where('amount_cents > ?', 1_000_000).count}"
puts "  International Transactions: #{FinancialTransaction.where.not(currency: 'NZD').count}"
puts "  Tax Filings: #{TaxFiling.count}"
puts "  Audit Entries: #{AuditEntry.count}"

puts "\n🏦 Demo Organizations:"
Organization.all.each do |org|
  puts "  #{org.name}"
  puts "    IRD: #{org.ird_number} | GST: #{org.gst_registered? ? 'Registered' : 'Not registered'}"
  puts "    Turnover: $#{org.annual_turnover_cents / 100}#{org.requires_gst_registration? ? ' (GST registration required!)' : ''}"
  puts "    Accounts: #{org.accounts.count} | Total Balance: $#{org.total_balance_nzd}"
  puts "    Recent Transactions: #{org.financial_transactions.where(created_at: 1.month.ago..Time.current).count}"
  puts "    Compliance Score: #{org.compliance_score}/100"
  puts
end

puts "\n🔐 Demo Users:"
puts "All users have password: demo123!"
User.includes(:organization).each do |user|
  puts "  #{user.email} (#{user.role.humanize}) - #{user.organization.name}"
end

puts "\n🌐 API Endpoints to test:"
puts "  GET /api/v1/status - System status with NZ compliance info"
puts "  GET /api/v1/financial_transactions - List transactions"
puts "  GET /api/v1/tax/gst_calculation - GST calculation demo" 
puts "  GET /api/v1/compliance/audit_logs - Audit trail access"

puts "\nReady for deployment! 🚀"