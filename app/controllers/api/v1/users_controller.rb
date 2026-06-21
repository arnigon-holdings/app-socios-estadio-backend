module Api
  module V1
    class UsersController < ApplicationController
      skip_before_action :verify_authenticity_token, if: :json_request?

      def create
        photo_url = PhotoUploader.upload(params[:photo])

        unless photo_url
          render json: { error: "Foto requerida o formato inválido (JPEG/PNG, máx 5MB)" }, status: :bad_request
          return
        end

        unless validate_consents
          render json: { error: "Consentimiento de foto es obligatorio" }, status: :bad_request
          return
        end

        user = User.new(
          rut: params[:rut],
          phone: format_phone(params[:phone]),
          password: params[:password],
          birth_month: params[:birth_month],
          birth_year: params[:birth_year],
          photo_url: photo_url,
          teams_ids: params[:teams_ids] || [],
          consents: params[:consents] || {},
          referred_by: params[:referred_by]
        )

        if user.teams_ids.present?
          valid_team_ids = Team.active.where(id: user.teams_ids).pluck(:id)
          invalid_ids = user.teams_ids - valid_team_ids
          if invalid_ids.any?
            File.delete(Rails.root.join("storage/uploads", photo_url.split("/").last)) if photo_url.start_with?("/uploads/")
            render json: { error: "Equipos inválidos: #{invalid_ids.join(', ')}" }, status: :bad_request
            return
          end
        end

        if User.exists?(rut: user.rut)
          File.delete(Rails.root.join("storage/uploads", photo_url.split("/").last)) if photo_url.start_with?("/uploads/")
          render json: { error: "RUT ya registrado" }, status: :conflict
          return
        end

        user.metadata = capture_request_metadata
        user.referral_code = generate_referral_code

        if user.save
          render json: {
            user: user_response(user),
            referral_code: user.referral_code
          }, status: :created
        else
          File.delete(Rails.root.join("storage/uploads", photo_url.split("/").last)) if photo_url.start_with?("/uploads/")
          render json: { error: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def validate_consents
        consents = params[:consents] || {}
        consents[:lgpd] == true && consents[:terms] == true && consents[:photo_usage] == true
      end

      def format_phone(phone)
        return nil unless phone.present?

        phone = phone.gsub(/\s/, "")
        phone = "+569#{phone}" unless phone.starts_with?("+569")
        phone
      end

      def user_params
        params.require(:user).permit(:rut, :phone, :birth_month, :birth_year, :photo, teams_ids: [], consents: {})
      end

      def user_response(user)
        {
          id: user.id,
          rut: user.rut,
          phone: user.phone,
          birth_month: user.birth_month,
          birth_year: user.birth_year,
          teams_ids: user.teams_ids,
          referral_code: user.referral_code,
          created_at: user.created_at
        }
      end

      def generate_referral_code
        "REF-#{SecureRandom.alphanumeric(6).upcase}"
      end

      def capture_request_metadata
        {
          ip: request.ip,
          user_agent: request.user_agent,
          accept_language: request.accept_language,
          referrer: request.referrer,
          browser_timezone: request.headers["X-Timezone"],
          device_fingerprint: request.headers["X-Device-Fingerprint"],
          consent_version: "v1",
          registration_source: request.headers["X-App-Source"] || "web"
        }.compact
      end

      def json_request?
        request.format.json?
      end
    end
  end
end
