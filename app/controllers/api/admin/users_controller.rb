module Api
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

        log_action("delete_user", "user", user.id, { rut: user.rut })

        user.destroy

        head :no_content
      end

      def face_records
        user = User.find(params[:id])

        records = user.face_records.order(created_at: :asc).map do |record|
          {
            id: record.id,
            rekognition_face_id: record.rekognition_face_id,
            s3_key: record.s3_key,
            face_type: record.s3_key.to_s.include?("/audit/") ? "audit" : "reference",
            photo_url: presigned_face_url(record.s3_bucket, record.s3_key),
            indexed_at: record.indexed_at,
            created_at: record.created_at
          }
        end

        render json: { face_records: records }
      end

      private

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
          phone_verified: user.phone_verified,
          created_at: user.created_at
        }
      end

      def user_response_with_details(user)
        user_response(user).merge(
          consents: user.consents,
          metadata: user.metadata,
          points_balance: user.points_balance,
          updated_at: user.updated_at
        )
      end

      def presigned_face_url(bucket, key)
        return nil if bucket.blank? || key.blank?

        Aws::S3::Presigner.new.presigned_url(
          :get_object,
          bucket: bucket,
          key: key,
          expires_in: 3600
        )
      rescue StandardError => e
        Rails.logger.warn("[face_records] presign failed key=#{key}: #{e.class}: #{e.message}")
        nil
      end

      def update_params
        params.require(:user).permit(:phone, :registration_status, :active, teams_ids: [])
      end
    end
  end
end
