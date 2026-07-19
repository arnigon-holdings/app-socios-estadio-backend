# frozen_string_literal: true

class LivenessValidator
  Result = Struct.new(:valid, :confidence, :status, :reference_image, :error, keyword_init: true)

  def self.validate(session_id)
    new(session_id).validate
  end

  def initialize(session_id)
    @session_id = session_id
  end

  def validate
    return Result.new(valid: false, error: 'Session ID requerido') if @session_id.blank?

    response = rekognition_client.get_face_liveness_session_results(
      session_id: @session_id
    )

    status = response.data.status
    confidence = response.data.confidence
    reference_bytes = response.data.reference_image&.bytes

    if status == 'SUCCEEDED'
      Result.new(
        valid: true,
        confidence: confidence,
        status: status,
        reference_image: reference_bytes
      )
    else
      error_message = if status == 'EXPIRED'
        'Tu tiempo de registro se acabó. Tenés 3 minutos para completar el proceso desde el inicio de la verificación facial.'
      else
        "Verificación no completada (#{status.downcase})"
      end
      Result.new(
        valid: false,
        confidence: confidence,
        status: status,
        error: error_message
      )
    end
  rescue Aws::Rekognition::Errors::ResourceNotFoundException
    Result.new(valid: false, error: 'Sesión de verificación no encontrada')
  rescue Aws::Rekognition::Errors::InvalidParameterException => e
    Result.new(valid: false, error: "Sesión inválida: #{e.message}")
  rescue Aws::Errors::ServiceError => e
    Rails.logger.error("[LivenessValidator] AWS error: #{e.class}: #{e.message}")
    Result.new(valid: false, error: 'Error al verificar identidad. Intenta de nuevo.')
  rescue StandardError => e
    Rails.logger.error("[LivenessValidator] Unexpected error: #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    Result.new(valid: false, error: 'Error interno. Intenta de nuevo.')
  end

  private

  def rekognition_client
    @rekognition_client ||= Aws::Rekognition::Client.new
  end
end
