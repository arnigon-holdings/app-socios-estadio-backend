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

      def face_records
        user = User.find(params[:id])
        records = user.face_records.order(indexed_at: :desc).map { |r| face_record_response(r) }
        log_action("view_face_records", "user", user.id, { count: records.size })
        render json: { face_records: records }
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
          created_at: user.created_at,
          biometric_status: user.biometric_status,
          indexed_at: user.indexed_at
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

      def update_params
        params.require(:user).permit(:phone, :teams_ids, :active, :registration_status)
      end

      def face_record_response(face_record)
        {
          id: face_record.id,
          rekognition_face_id: face_record.rekognition_face_id,
          s3_bucket: face_record.s3_bucket,
          s3_key: face_record.s3_key,
          indexed_at: face_record.indexed_at,
          created_at: face_record.created_at,
          photo_url: presigned_url(face_record.s3_bucket, face_record.s3_key)
        }
      end

      def presigned_url(bucket, key)
        return nil if bucket.blank? || key.blank?
        region = ENV.fetch('AWS_REGION', 'us-east-1')
        signer = Aws::S3::Presigner.new(client: Aws::S3::Client.new(region: region))
        signer.presigned_url(
          :get_object,
          bucket: bucket,
          key: key,
          expires_in: 3600
        )
      rescue StandardError
        nil
      end
    end
  end
end
