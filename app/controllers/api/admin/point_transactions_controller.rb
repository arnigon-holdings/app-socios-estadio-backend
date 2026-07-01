module Api
  module Admin
    class PointTransactionsController < BaseController
      def index
        transactions = PointTransaction.includes(:user, :point_action).order(created_at: :desc)

        if params[:user_id].present?
          transactions = transactions.where(user_id: params[:user_id])
        end

        if params[:point_action_id].present?
          transactions = transactions.where(point_action_id: params[:point_action_id])
        end

        transactions = transactions.page(params[:page] || 1).per(params[:per_page] || 50)

        render json: {
          transactions: transactions.map { |pt| transaction_response(pt) },
          pagination: {
            page: transactions.current_page,
            per_page: transactions.limit_value,
            total: transactions.total_count,
            pages: transactions.total_pages
          }
        }
      end

      private

      def transaction_response(pt)
        {
          id: pt.id,
          user_id: pt.user_id,
          user_rut: pt.user.rut,
          point_action_id: pt.point_action_id,
          action_key: pt.point_action.action_key,
          amount: pt.amount,
          reference_id: pt.reference_id,
          metadata: pt.metadata,
          created_at: pt.created_at
        }
      end
    end
  end
end
