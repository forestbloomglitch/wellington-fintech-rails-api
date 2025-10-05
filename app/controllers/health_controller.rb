class HealthController < ApplicationController
  # GET /health
  def show
    health_status = {
      status: 'healthy',
      timestamp: Time.current.iso8601,
      application: {
        name: 'Wellington FinTech Rails API',
        version: '1.0.0',
        environment: Rails.env
      },
      checks: {
        database: check_database,
        time: Time.current.iso8601,
        timezone: Time.zone.name
      }
    }
    
    overall_healthy = health_status[:checks][:database][:connected]
    
    render json: health_status, status: overall_healthy ? :ok : :service_unavailable
  end
  
  private
  
  def check_database
    ActiveRecord::Base.connection.execute('SELECT 1')
    { connected: true, adapter: ActiveRecord::Base.connection.adapter_name }
  rescue => e
    { connected: false, error: e.message }
  end
end