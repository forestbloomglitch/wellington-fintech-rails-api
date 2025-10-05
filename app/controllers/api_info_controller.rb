class ApiInfoController < ApplicationController
  def index
    render json: {
      name: "Wellington FinTech Rails API",
      version: "1.0.0",
      description: "NZ Regulatory Compliant Financial Services API",
      status: "operational",
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
      documentation: "Built for New Zealand immigration portfolio demonstration",
      contact: "support@terminaldrift.digital",
      timestamp: Time.current.iso8601
    }
  end
end