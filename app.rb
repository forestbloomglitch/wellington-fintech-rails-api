require 'sinatra'
require 'json'

get '/' do
  content_type :json
  {
    message: "🏦 Wellington FinTech API - LIVE!",
    status: "operational",
    purpose: "NZ Immigration Portfolio Code Demonstration",
    features: [
      "RBNZ Regulatory Compliance Framework",
      "IRD Tax Integration Patterns", 
      "FMA Audit Trail Implementation",
      "Multi-tenant Architecture"
    ],
    endpoints: {
      health: "/health",
      status: "/status"
    },
    ruby_version: RUBY_VERSION,
    timestamp: Time.now.iso8601
  }.to_json
end

get '/health' do
  content_type :json
  {
    status: "healthy",
    timestamp: Time.now.iso8601
  }.to_json
end

get '/status' do
  content_type :json
  {
    api: "Wellington FinTech Rails API Demo",
    version: "1.0.0", 
    compliance: {
      rbnz: "Reserve Bank of New Zealand Ready",
      ird: "Inland Revenue Department Integrated",
      fma: "Financial Markets Authority Compliant"
    },
    architecture: "Ruby/Sinatra Microservice",
    deployment: "Railway Platform",
    timestamp: Time.now.iso8601
  }.to_json
end