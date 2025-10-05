Rails.application.routes.draw do
  # Health check endpoint
  get '/health', to: 'health#show'
  
  # API versioning
  namespace :api do
    namespace :v1 do
      # Status endpoint for API health
      get '/status', to: 'status#show'
      
      # Authentication
      post '/auth/login', to: 'authentication#login'
      post '/auth/refresh', to: 'authentication#refresh'
      delete '/auth/logout', to: 'authentication#logout'
      
      # Financial Transactions (RBNZ compliant)
      resources :financial_transactions, only: [:index, :show, :create] do
        member do
          get :audit_trail
        end
        collection do
          get :compliance_report
        end
      end
      
      # Accounts Management
      resources :accounts do
        member do
          get :balance
          get :transactions
          post :freeze
          post :unfreeze
        end
      end
      
      # IRD Tax Integration
      namespace :tax do
        get :gst_calculation, to: 'gst#calculate'
        post :gst_submission, to: 'gst#submit'
        get :paye_calculation, to: 'paye#calculate'
        get :compliance_status, to: 'compliance#status'
      end
      
      # RBNZ Compliance
      namespace :compliance do
        get :audit_logs, to: 'audit#index'
        get :capital_adequacy, to: 'capital#adequacy'
        get :liquidity_ratios, to: 'liquidity#ratios'
        post :regulatory_report, to: 'reporting#submit'
      end
      
      # Xero Integration (NZ business ecosystem)
      namespace :integrations do
        namespace :xero do
          post :sync_accounts, to: 'accounts#sync'
          post :sync_invoices, to: 'invoices#sync'
          get :connection_status, to: 'connection#status'
        end
      end
      
      # Multi-tenant Organizations
      resources :organizations do
        member do
          get :users
          get :settings
          post :invite_user
        end
      end
    end
  end
end