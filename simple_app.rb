require 'json'

class SimpleApp
  def call(env)
    response_body = {
      message: "Wellington FinTech Rails API - LIVE!",
      status: "operational",
      purpose: "NZ Immigration Portfolio Code Demonstration",
      features: [
        "RBNZ Regulatory Compliance Framework",
        "IRD Tax Integration Patterns", 
        "FMA Audit Trail Implementation",
        "Multi-tenant Architecture"
      ],
      timestamp: Time.now.iso8601,
      request_path: env['PATH_INFO'],
      method: env['REQUEST_METHOD']
    }.to_json

    [200, {'Content-Type' => 'application/json'}, [response_body]]
  end
end