class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session, only: []
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity

  private

  def not_found(exception)
    render json: { error: "No encontrado" }, status: :not_found
  end

  def unprocessable_entity(exception)
    render json: { error: exception.record.errors.full_messages }, status: :unprocessable_entity
  end

  def capture_request_metadata
    {
      ip: request.ip,
      user_agent: request.user_agent,
      accept_language: request.accept_language,
      referrer: request.referrer,
      browser_timezone: request.headers["X-Timezone"],
      device_fingerprint: request.headers["X-Device-Fingerprint"]
    }.compact
  end
end
