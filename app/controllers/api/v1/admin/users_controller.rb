module Api
  module V1
    module Admin
      class UsersController < BaseController
        def index
          users = User.order(created_at: :desc)

          if params[:rut].present?
            users = users.where("rut LIKE ?", "%#{params[:rut]}%")
          end

          users = users.page(params[:page] || 1).per(params[:per_page] || 20)

          render json: {
            users: users.map { |u| user_response(u) },
            pagination: {
              page: users.current_page,
              per_page: users.limit_value,
              total: users.total_count,
              pages: users.total_pages
            }
          }
        end

        def show
          user = User.find(params[:id])

          log_action("view_user", "user", user.id, { viewed_fields: ["profile"] })

          render json: { user: user_response_with_details(user) }
        end

        def update
          user = User.find(params[:id])
          user.assign_attributes(update_params)

          if user.save
            log_action("update_user", "user", user.id, { updated_fields: update_params.keys })

            render json: { user: user_response(user) }
          else
            render json: { error: user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          user = User.find(params[:id])

          log_action("unlink_user", "user", user.id, { rut: user.rut, face_records_count: user.face_records.count })

          user.update!(rut: nil)

          head :no_content
        rescue => e
          Rails.logger.error "Unlink user error: #{e.class} - #{e.message}"
          Rails.logger.error e.backtrace.first(5).join("\n")
          render json: { error: "Error al desvincular usuario: #{e.message}" }, status: :internal_server_error
        end

        def face_records
          user = User.find(params[:id])
          records = user.face_records.order(indexed_at: :desc).map { |r| face_record_response(r) }

          log_action("view_face_records", "user", user.id, { count: records.size })

          render json: { face_records: records }
        end

        private

        def face_record_response(record)
          {
            id: record.id,
            rekognition_face_id: record.rekognition_face_id,
            s3_bucket: record.s3_bucket,
            s3_key: record.s3_key,
            face_type: infer_face_type(record.s3_key),
            indexed_at: record.indexed_at,
            photo_url: presign_s3_url(record.s3_bucket, record.s3_key)
          }.compact
        end

        def infer_face_type(s3_key)
          return nil if s3_key.blank?

          s3_key.include?("/audit/") ? "audit" : "reference"
        end

        def presign_s3_url(bucket, key)
          return nil if bucket.blank? || key.blank?

          Aws::S3::Presigner.new.presigned_url(
            :get_object,
            bucket: bucket,
            key: key,
            expires_in: 600
          )
        rescue Aws::Errors::ServiceError, StandardError => e
          Rails.logger.warn("[face_records] presign failed bucket=#{bucket} key=#{key} error=#{e.class}: #{e.message}")
          nil
        end

        def user_response(user)
          {
            id: user.id,
            rut: user.rut,
            phone: user.phone,
            birth_month: user.birth_month,
            birth_year: user.birth_year,
            teams_ids: user.teams_ids,
            photo_url: user.photo_url,
            referral_code: user.referral_code,
            registration_status: user.registration_status,
            created_at: user.created_at
          }
        end

        def user_response_with_details(user)
          user_response(user).merge(
            consents: user.consents,
            metadata: user.metadata,
            points_balance: user.points_balance,
            phone_verified: user.phone_verified,
            biometric_status: user.biometric_status,
            updated_at: user.updated_at
          )
        end

        def update_params
          params.require(:user).permit(:phone, :teams_ids, :active, :registration_status)
        end
      end
    end
  end
end
