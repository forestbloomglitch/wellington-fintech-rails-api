class ApplicationController < ActionController::API
  # CORS headers for API access
  before_action :set_cors_headers
  
  # Error handling for API responses
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
  rescue_from ArgumentError, with: :bad_request
  
  protected
  
  def record_not_found(exception)
    render json: {
      error: 'Record not found',
      message: exception.message,
      status: 404
    }, status: :not_found
  end
  
  def record_invalid(exception)
    render json: {
      error: 'Validation failed',
      message: exception.record.errors.full_messages,
      status: 422
    }, status: :unprocessable_entity
  end
  
  def bad_request(exception)
    render json: {
      error: 'Bad request',
      message: exception.message,
      status: 400
    }, status: :bad_request
  end
  
  def render_success(data, message: 'Success', status: :ok)
    render json: {
      success: true,
      message: message,
      data: data,
      timestamp: Time.current.iso8601
    }, status: status
  end
  
  def render_error(message, status: :bad_request, details: nil)
    error_response = {
      success: false,
      error: message,
      status: Rack::Utils::SYMBOL_TO_STATUS_CODE[status],
      timestamp: Time.current.iso8601
    }
    
    error_response[:details] = details if details
    
    render json: error_response, status: status
  end
  
  private
  
  def set_cors_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD'
    headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
    headers['Access-Control-Max-Age'] = '1728000'
  end
  
  # Placeholder for authentication (would integrate with JWT in production)
  def current_user
    # Demo mode - would use JWT token in production
    # Skip database lookup to avoid startup issues
    nil
  end
  
  def current_organization
    current_user&.organization
  end
  
  def require_authentication
    render_error('Authentication required', status: :unauthorized) unless current_user
  end
  
  def require_admin
    render_error('Admin access required', status: :forbidden) unless current_user&.admin?
  end
  
  def require_compliance_officer
    unless current_user&.compliance_officer? || current_user&.admin?
      render_error('Compliance officer access required', status: :forbidden)
    end
  end
end