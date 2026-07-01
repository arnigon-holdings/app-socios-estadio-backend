module Api
  module V1
    class AuthController < BaseController
      skip_before_action :verify_authenticity_token, if: :json_request?
      before_action :authenticate_user!, only: [:me, :refresh, :verify_phone]

      def refresh
        token = cookies.encrypted[:refresh_token] || params[:refresh_token]

        decoded = JwtService.decode(token)

        if decoded&.dig(:type) == "refresh" && decoded&.dig(:user_id)
          user = User.find_by(id: decoded[:user_id])

          if user
            access_token = JwtService.encode(
              { user_id: user.id, type: "access" },
              exp: 1.hour.from_now
            )

            cookies[:access_token] = {
              value: access_token,
              httponly: true,
              secure: Rails.env.production?,
              same_site: :lax,
              expires: 1.hour.from_now
            }

            render json: { access_token: access_token }
            return
          end
        end

        render json: { error: "Token inválido o expirado" }, status: :unauthorized
      end

      def me
        render json: {
          user: user_response(@current_user),
          points_balance: @current_user.points_balance
        }
      end

      def verify_phone
        token = verify_phone_params[:token]

        if @current_user.phone_verification_token == token
          @current_user.update!(
            phone_verified: true,
            phone_verified_at: Time.current,
            phone_verification_token: nil
          )

          registration_action = PointAction.find_by(action_key: "registration")
          if registration_action&.active && registration_action.points > 0
            PointTransaction.create!(
              user: @current_user,
              point_action: registration_action,
              amount: registration_action.points,
              reference_id: "phone_verification"
            )
          end

          render json: {
            verified: true,
            points_awarded: registration_action&.points || 0,
            points_balance: @current_user.reload.points_balance
          }
        else
          render json: { error: "Token inválido" }, status: :unprocessable_entity
        end
      end

      private

      def verify_phone_params
        params.require(:verify_phone).permit(:token)
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
    end
  end
end
