class ApiInfoController < ActionController::API
  # Skip authentication and database dependencies for this simple endpoint
  
  def index
    render json: {
      name: "Wellington FinTech Rails API",
      version: "1.0.0",
      description: "NZ Regulatory Compliant Financial Services API",
      status: "operational",
      environment: Rails.env,
      ruby_version: RUBY_VERSION,
      rails_version: Rails.version,
      compliance: {
        rbnz: "Reserve Bank of New Zealand compliant",
        ird: "Inland Revenue Department integrated",
        fma: "Financial Markets Authority aligned"
      },
      endpoints: {
        health: "/health",
        api_status: "/api/v1/status",
        financial_transactions: "/api/v1/financial_transactions",
        tax_gst: "/api/v1/tax/gst_calculation",
        compliance_audit: "/api/v1/compliance/audit_logs"
      },
      purpose: "Code demonstration for New Zealand immigration portfolio",
      contact: "support@terminaldrift.digital",
      timestamp: Time.current.iso8601
    }
  end
end
