module Api
  module V1
    module Frontend
      class FacePosesController < BaseController
        def validate
          image_data = params[:image]
          pose_variant = params[:pose_variant]

          if image_data.blank?
            render json: { valid: false, message: "Imagen requerida" }, status: :bad_request
            return
          end

          if pose_variant.blank?
            render json: { valid: false, message: "Pose requerida" }, status: :bad_request
            return
          end

          valid_poses = %w[frontal left_profile right_profile up down]
          unless valid_poses.include?(pose_variant)
            render json: { valid: false, message: "Pose inválida" }, status: :bad_request
            return
          end

          render json: { valid: true }
        end
      end
    end
  end
end
