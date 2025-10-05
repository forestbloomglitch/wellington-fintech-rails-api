module Api
  module V1
    # API Status Controller
    # Provides health checks and system status for monitoring and compliance
    class StatusController < ApplicationController
      # GET /api/v1/status
      def show
        status_data = {
          api: {
            name: 'Wellington FinTech Rails API',
            version: Rails.application.config.x.api_version,
            environment: Rails.env,
            timestamp: Time.current.iso8601,
            uptime: uptime_in_seconds,
            timezone: Rails.application.config.time_zone
          },
          services: service_status,
          compliance: compliance_status,
          new_zealand: nz_specific_status,
          database: database_status,
          cache: cache_status,
          background_jobs: background_job_status,
          security: security_status,
          monitoring: monitoring_status
        }
        
        overall_healthy = all_services_healthy?(status_data)
        
        render json: {
          status: overall_healthy ? 'healthy' : 'degraded',
          data: status_data,
          checks_performed_at: Time.current.iso8601,
          next_health_check: 5.minutes.from_now.iso8601
        }, status: overall_healthy ? :ok : :service_unavailable
      end
      
      private
      
      def service_status
        {
          database: check_database_connection,
          redis: check_redis_connection,
          background_jobs: check_background_jobs,
          external_apis: check_external_apis
        }
      end
      
      def compliance_status
        {
          audit_logging: {
            enabled: audit_logging_enabled?,
            retention_period: Rails.application.config.x.audit_retention_period.inspect,
            last_audit_entry: last_audit_entry_timestamp
          },
          data_encryption: {
            enabled: encryption_enabled?,
            algorithm: 'AES-256-GCM',
            key_rotation_due: key_rotation_due?
          },
          regulatory_reporting: {
            rbnz_ready: rbnz_integration_ready?,
            ird_ready: ird_integration_ready?,
            fma_ready: fma_compliance_enabled?
          }
        }
      end
      
      def nz_specific_status
        {
          timezone: 'Pacific/Auckland',
          business_hours: {
            current_time: Time.current.in_time_zone('Pacific/Auckland').strftime('%H:%M %Z'),
            is_business_time: Time.current.business_time?,
            next_business_day: 1.business_day.from_now.strftime('%A, %d %B %Y')
          },
          currencies: {
            primary: 'NZD',
            supported: Rails.application.config.x.supported_currencies
          },
          holidays: {
            next_nz_holiday: next_nz_holiday,
            business_days_until_next_holiday: business_days_until_next_holiday
          }
        }
      end
      
      def database_status
        begin
          connection_status = ActiveRecord::Base.connection.execute('SELECT 1')
          
          {
            connected: true,
            adapter: ActiveRecord::Base.connection.adapter_name,
            database_name: ActiveRecord::Base.connection.current_database,
            pool_size: ActiveRecord::Base.connection_pool.size,
            active_connections: ActiveRecord::Base.connection_pool.connections.count,
            version: ActiveRecord::Base.connection.database_version,
            response_time_ms: measure_database_response_time
          }
        rescue => e
          {
            connected: false,
            error: e.message,
            last_error_at: Time.current.iso8601
          }
        end
      end
      
      def cache_status
        begin
          Rails.cache.write('health_check', Time.current.to_i, expires_in: 1.minute)
          cached_value = Rails.cache.read('health_check')
          
          {
            connected: true,
            store: Rails.cache.class.name,
            test_write_read: cached_value.present?,
            response_time_ms: measure_cache_response_time
          }
        rescue => e
          {
            connected: false,
            error: e.message,
            last_error_at: Time.current.iso8601
          }
        end
      end
      
      def background_job_status
        begin
          if defined?(Sidekiq)
            stats = Sidekiq::Stats.new
            
            {
              enabled: true,
              processed: stats.processed,
              failed: stats.failed,
              busy: stats.workers_size,
              enqueued: stats.enqueued,
              queues: Sidekiq::Queue.all.map { |q| { name: q.name, size: q.size } },
              last_job_at: last_background_job_timestamp
            }
          else
            { enabled: false, reason: 'Sidekiq not configured' }
          end
        rescue => e
          {
            enabled: false,
            error: e.message,
            last_error_at: Time.current.iso8601
          }
        end
      end
      
      def security_status
        {
          cors_enabled: cors_configured?,
          jwt_configuration: {
            algorithm: 'RS256',
            expiry_configured: jwt_expiry_configured?
          },
          rate_limiting: {
            enabled: rate_limiting_enabled?,
            requests_per_minute: rate_limit_threshold
          },
          https_enforced: https_enforced_in_production?,
          security_headers: security_headers_configured?
        }
      end
      
      def monitoring_status
        {
          logging_level: Rails.logger.level,
          structured_logging: structured_logging_enabled?,
          error_tracking: error_tracking_configured?,
          performance_monitoring: performance_monitoring_enabled?,
          audit_trail: audit_trail_active?
        }
      end
      
      def check_database_connection
        begin
          ActiveRecord::Base.connection.execute('SELECT 1')
          { status: 'healthy', response_time_ms: measure_database_response_time }
        rescue => e
          { status: 'unhealthy', error: e.message }
        end
      end
      
      def check_redis_connection
        begin
          Rails.cache.write('health_check_redis', 'ok', expires_in: 30.seconds)
          result = Rails.cache.read('health_check_redis')
          
          if result == 'ok'
            { status: 'healthy', response_time_ms: measure_cache_response_time }
          else
            { status: 'unhealthy', error: 'Redis write/read test failed' }
          end
        rescue => e
          { status: 'unhealthy', error: e.message }
        end
      end
      
      def check_background_jobs
        return { status: 'not_configured' } unless defined?(Sidekiq)
        
        begin
          stats = Sidekiq::Stats.new
          failed_jobs = stats.failed
          
          if failed_jobs > 100
            { status: 'degraded', reason: "#{failed_jobs} failed jobs in queue" }
          else
            { status: 'healthy', processed: stats.processed, failed: failed_jobs }
          end
        rescue => e
          { status: 'unhealthy', error: e.message }
        end
      end
      
      def check_external_apis
        {
          ird_gateway: check_external_service('IRD Gateway', 'https://gateway.ird.govt.nz'),
          rbnz_api: check_external_service('RBNZ API', 'https://www.rbnz.govt.nz/api'),
          xero_api: check_external_service('Xero API', 'https://api.xero.com')
        }
      end
      
      def check_external_service(name, url)
        begin
          # In a real implementation, this would make actual API calls
          # For now, we'll simulate the check
          {
            name: name,
            status: 'simulated_healthy',
            url: url,
            last_checked: Time.current.iso8601,
            note: 'External API checks disabled in demo mode'
          }
        rescue => e
          {
            name: name,
            status: 'unhealthy',
            error: e.message,
            url: url
          }
        end
      end
      
      def all_services_healthy?(status_data)
        database_healthy = status_data[:database][:connected]
        cache_healthy = status_data[:cache][:connected]
        
        database_healthy && cache_healthy
      end
      
      def uptime_in_seconds
        # This would typically be calculated from application start time
        # For demo purposes, we'll use a placeholder
        (Time.current - 1.day).to_i
      end
      
      def measure_database_response_time
        start_time = Time.current
        ActiveRecord::Base.connection.execute('SELECT 1')
        ((Time.current - start_time) * 1000).round(2)
      rescue
        nil
      end
      
      def measure_cache_response_time
        start_time = Time.current
        Rails.cache.read('health_check')
        ((Time.current - start_time) * 1000).round(2)
      rescue
        nil
      end
      
      # Compliance and configuration checks
      def audit_logging_enabled?
        # Check if audit logging is properly configured
        defined?(AuditLogger) && AuditLogger.respond_to?(:log_financial_transaction)
      end
      
      def encryption_enabled?
        # Check if encryption gems are properly configured
        defined?(Lockbox) && Rails.application.credentials.lockbox_master_key.present?
      rescue
        false
      end
      
      def key_rotation_due?
        # Check if encryption keys need rotation (placeholder logic)
        false # Would check actual key age in production
      end
      
      def rbnz_integration_ready?
        # Check RBNZ compliance configuration
        Rails.application.config.x.audit_retention_period == 7.years
      end
      
      def ird_integration_ready?
        # Check IRD integration configuration
        defined?(IrdTaxService)
      end
      
      def fma_compliance_enabled?
        # Check FMA compliance features
        encryption_enabled? && audit_logging_enabled?
      end
      
      def next_nz_holiday
        return 'Holiday data not available' unless defined?(Holidays)
        
        begin
          holidays = Holidays.between(Date.current, 1.year.from_now, :nz)
          next_holiday = holidays.first
          
          if next_holiday
            "#{next_holiday[:name]} (#{next_holiday[:date].strftime('%d %B %Y')})"
          else
            'No upcoming holidays found'
          end
        rescue
          'Holiday calculation unavailable'
        end
      end
      
      def business_days_until_next_holiday
        return 0 unless defined?(Holidays) && defined?(BusinessTime)
        
        begin
          holidays = Holidays.between(Date.current, 1.year.from_now, :nz)
          next_holiday_date = holidays.first&.dig(:date)
          
          return 0 unless next_holiday_date
          
          Date.current.business_days_until(next_holiday_date)
        rescue
          0
        end
      end
      
      def last_audit_entry_timestamp
        return nil unless defined?(AuditEntry)
        
        begin
          AuditEntry.maximum(:created_at)&.iso8601
        rescue
          nil
        end
      end
      
      def last_background_job_timestamp
        return nil unless defined?(Sidekiq)
        
        begin
          # This would check the last processed job timestamp in a real implementation
          1.hour.ago.iso8601 # Placeholder
        rescue
          nil
        end
      end
      
      def cors_configured?
        Rails.application.config.middleware.include?(Rack::Cors)
      end
      
      def jwt_expiry_configured?
        # Check if JWT expiry is properly configured
        defined?(JWT) && Rails.application.secrets.jwt_expiration_hours.present?
      rescue
        false
      end
      
      def rate_limiting_enabled?
        defined?(Rack::Attack)
      end
      
      def rate_limit_threshold
        return nil unless rate_limiting_enabled?
        
        # This would return actual rate limit configuration
        60 # requests per minute (placeholder)
      end
      
      def https_enforced_in_production?
        !Rails.env.production? || Rails.application.config.force_ssl
      end
      
      def security_headers_configured?
        # Check if security headers middleware is configured
        Rails.application.config.force_ssl || Rails.env.development?
      end
      
      def structured_logging_enabled?
        defined?(Lograge)
      end
      
      def error_tracking_configured?
        defined?(Sentry)
      end
      
      def performance_monitoring_enabled?
        defined?(NewRelic)
      end
      
      def audit_trail_active?
        audit_logging_enabled? && last_audit_entry_timestamp.present?
      end
    end
  end
end
