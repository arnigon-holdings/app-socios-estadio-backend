module Api
  module V1
    module Admin
      class SessionsController < BaseController
        skip_before_action :authenticate_admin!, only: [:create]

        def create
          admin = ::Admin.find_by(email: session_params[:email])

          if admin&.authenticate(session_params[:password])
            @current_admin = admin
            admin.last_login_update!

            access_token = JwtService.encode(
              { admin_id: admin.id, role: admin.role, type: "access" },
              exp: 1.hour.from_now
            )

            refresh_token = JwtService.encode(
              { admin_id: admin.id, type: "refresh" },
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

            log_action("login", "admin", admin.id, { email: admin.email })

            render json: { admin: { id: admin.id, email: admin.email, role: admin.role } }
          else
            render json: { error: "Credenciales inválidas" }, status: :unauthorized
          end
        end

        def destroy
          cookies.delete(:access_token)
          cookies.delete(:refresh_token)
          head :no_content
        end

        private

        def session_params
          params.require(:session).permit(:email, :password)
        end
      end
    end
  end
end
