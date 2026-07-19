# frozen_string_literal: true

module Api
  module V1
    class LivenessController < ApplicationController
      skip_before_action :verify_authenticity_token, if: :json_request?

      def results
        session_id = params[:session_id]
        result = LivenessValidator.validate(session_id)

        if result.valid
          render json: {
            session_id: session_id,
            confidence: result.confidence,
            status: result.status,
            reference_image: result.reference_image ? Base64.strict_encode64(result.reference_image) : nil
          }
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      private

      def json_request?
        request.format.json?
      end
    end
  end
end
