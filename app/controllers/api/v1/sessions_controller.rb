module Api
  module V1
    class SessionsController < ApplicationController
      skip_before_action :verify_authenticity_token, if: :json_request?
      before_action :authenticate_user!, only: [:destroy]

      def create
        user = User.find_by(rut: normalize_rut(session_params[:rut]))

        if user&.authenticate(session_params[:password])
          access_token = JwtService.encode(
            { user_id: user.id, type: "access" },
            exp: 1.hour.from_now
          )

          refresh_token = JwtService.encode(
            { user_id: user.id, type: "refresh" },
            exp: 30.days.from_now
          )

          cookies[:access_token] = {
            value: access_token,
            httponly: true,
            secure: Rails.env.production?,
            same_site: :lax,
            expires: 1.hour.from_now
          }

          cookies[:refresh_token] = {
            value: refresh_token,
            httponly: true,
            secure: Rails.env.production?,
            same_site: :lax,
            expires: 30.days.from_now
          }

          render json: {
            user: user_response(user),
            points_balance: user.points_balance
          }
        else
          render json: { error: "RUT o contraseña inválidos" }, status: :unauthorized
        end
      end

      def destroy
        cookies.delete(:access_token)
        cookies.delete(:refresh_token)
        head :no_content
      end

      private

      def session_params
        params.require(:session).permit(:rut, :password)
      end

      def normalize_rut(rut)
        return nil unless rut.present?
        rut.gsub(/[.\-]/, "").upcase
      end

      def user_response(user)
        {
          id: user.id,
          rut: user.rut,
          phone: user.phone,
          phone_verified: user.phone_verified,
          birth_month: user.birth_month,
          birth_year: user.birth_year,
          teams_ids: user.teams_ids,
          referral_code: user.referral_code,
          created_at: user.created_at
        }
      end

      def json_request?
        request.format.json?
      end
    end
  end
end
