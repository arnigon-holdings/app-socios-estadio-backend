module Api
  module V1
    module Admin
      class BaseController < ApplicationController
        before_action :authenticate_admin!

        private

        def authenticate_admin!
          token = extract_token_from_cookie

          if token.blank?
            render json: { error: "No autenticado" }, status: :unauthorized
            return
          end

          decoded = JwtService.decode(token)

          if decoded.blank?
            render json: { error: "Token inválido o expirado" }, status: :unauthorized
            return
          end

          unless decoded["type"] == "access" && ["admin", "superadmin"].include?(decoded["role"])
            render json: { error: "Token inválido o expirado" }, status: :unauthorized
            return
          end

          @current_admin = ::Admin.find_by(id: decoded["admin_id"])

          unless @current_admin
            render json: { error: "Admin no encontrado" }, status: :unauthorized
          end
        end

        def extract_token_from_cookie
          cookies[:access_token]
        end

        def log_action(action, resource_type, resource_id, extra_metadata = {})
          AuditLog.create!(
            admin_id: @current_admin.id,
            action: action,
            resource_type: resource_type,
            resource_id: resource_id,
            metadata: extra_metadata,
            ip: request.ip
          )
        end
      end
    end
  end
end
