module Api
  module V1
    module Admin
      class AuditLogsController < BaseController
        def index
          logs = AuditLog.includes(:admin).order(created_at: :desc)

          if params[:admin_id].present?
            logs = logs.where(admin_id: params[:admin_id])
          end

          if params[:resource_type].present?
            logs = logs.where(resource_type: params[:resource_type])
          end

          if params[:action].present?
            logs = logs.where(action: params[:action])
          end

          logs = logs.page(params[:page] || 1).per(params[:per_page] || 50)

          render json: {
            logs: logs.map { |log| log_response(log) },
            pagination: {
              page: logs.current_page,
              per_page: logs.limit_value,
              total: logs.total_count,
              pages: logs.total_pages
            }
          }
        end

        private

        def log_response(log)
          {
            id: log.id,
            admin_id: log.admin_id,
            admin_email: log.admin&.email,
            action: log.action,
            resource_type: log.resource_type,
            resource_id: log.resource_id,
            metadata: log.metadata,
            ip: log.ip,
            created_at: log.created_at
          }
        end
      end
    end
  end
end
