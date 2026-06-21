module Api
  module V1
    class BaseController < ApplicationController
      private

      def authenticate_user!
        token = cookies[:access_token]

        if token.blank?
          render json: { error: "No autenticado" }, status: :unauthorized
          return
        end

        decoded = JwtService.decode(token)

        if decoded.blank?
          render json: { error: "Token inválido o expirado" }, status: :unauthorized
          return
        end

        unless decoded["type"] == "access"
          render json: { error: "Token inválido o expirado" }, status: :unauthorized
          return
        end

        @current_user = User.find_by(id: decoded["user_id"])

        unless @current_user
          render json: { error: "Usuario no encontrado" }, status: :unauthorized
        end
      end
    end
  end
end
