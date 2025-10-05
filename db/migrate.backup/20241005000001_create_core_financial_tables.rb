class CreateCoreFinancialTables < ActiveRecord::Migration[6.1]
  def change
    # Organizations table for multi-tenancy
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :ird_number, limit: 9
      t.string :rbnz_identifier, limit: 20
      t.boolean :gst_registered, default: false
      t.integer :annual_turnover_cents, default: 0
      t.string :business_type
      t.string :contact_email
      t.text :address
      t.boolean :international_transactions_enabled, default: false
      t.timestamps
    end
    
    add_index :organizations, :ird_number, unique: true
    add_index :organizations, :rbnz_identifier, unique: true
    
    # Users table
    create_table :users do |t|
      t.string :email, null: false
      t.string :first_name
      t.string :last_name
      t.string :password_digest
      t.references :organization, null: false, foreign_key: true
      t.boolean :authorized_for_high_value, default: false
      t.string :role, default: 'user'
      t.timestamps
    end
    
    add_index :users, :email, unique: true
    
    # Accounts table
    create_table :accounts do |t|
      t.string :name, null: false
      t.string :account_number, null: false
      t.string :account_type # checking, savings, investment, etc.
      t.string :currency, default: 'NZD'
      t.integer :balance_cents, default: 0
      t.references :organization, null: false, foreign_key: true
      t.boolean :active, default: true
      t.boolean :frozen, default: false
      t.timestamps
    end
    
    add_index :accounts, [:organization_id, :account_number], unique: true
    
    # Financial transactions table
    create_table :financial_transactions do |t|
      t.string :reference, null: false
      t.integer :amount_cents, null: false
      t.string :currency, default: 'NZD'
      t.string :transaction_type, null: false
      t.text :description
      t.references :account, null: false, foreign_key: true
      t.references :counterparty_account, null: true, foreign_key: { to_table: :accounts }
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.text :compliance_flags, default: '[]'
      t.string :compliance_status, default: 'pending'
      t.text :counterparty_details # encrypted
      t.text :encrypted_counterparty_details_bidx # blind index
      t.text :additional_metadata # encrypted
      t.string :gst_treatment, default: 'standard' # standard, zero_rated, exempt
      t.datetime :processed_at
      t.timestamps
    end
    
    add_index :financial_transactions, :reference, unique: true
    add_index :financial_transactions, [:account_id, :created_at]
    add_index :financial_transactions, :compliance_status
    add_index :financial_transactions, :amount_cents
    
    # Audit entries table for compliance
    create_table :audit_entries do |t|
      t.string :auditable_type, null: false
      t.integer :auditable_id, null: false
      t.string :action, null: false
      t.text :audited_changes
      t.references :user, null: true, foreign_key: true
      t.inet :remote_address
      t.datetime :expires_at # for 7-year RBNZ retention
      t.timestamps
    end
    
    add_index :audit_entries, [:auditable_type, :auditable_id]
    add_index :audit_entries, :created_at
    add_index :audit_entries, :expires_at
    
    # Tax filings table for IRD tracking
    create_table :tax_filings do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :filing_type # gst, paye, income_tax
      t.date :period_start
      t.date :period_end
      t.date :due_date
      t.date :filed_date
      t.string :status, default: 'pending' # pending, submitted, accepted, rejected
      t.text :filing_data # JSON
      t.string :ird_reference
      t.boolean :filed_late, default: false
      t.timestamps
    end
    
    add_index :tax_filings, [:organization_id, :filing_type, :period_end]
    add_index :tax_filings, :due_date
    add_index :tax_filings, :status
    
    # Transaction categories for reporting
    create_table :transaction_categories do |t|
      t.string :name, null: false
      t.text :description
      t.string :category_type # income, expense, asset, liability
      t.string :gst_treatment, default: 'standard'
      t.boolean :active, default: true
      t.timestamps
    end
    
    add_index :transaction_categories, :name, unique: true
    
    # Add foreign key for transaction categories
    add_reference :financial_transactions, :transaction_category, foreign_key: true
  end
end