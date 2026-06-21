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
            per_page: users.per_page,
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

      def update_params
        params.require(:user).permit(:phone, :teams_ids, :active)
      end
    end
  end
end
