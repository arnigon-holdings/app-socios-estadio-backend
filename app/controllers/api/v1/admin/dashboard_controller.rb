module Api
  module V1
    module Admin
      class DashboardController < BaseController
        def index
          today = Date.current
          week_ago = 7.days.ago

          stats = {
            users_total: User.count,
            users_today: User.where("created_at >= ?", today.beginning_of_day).count,
            users_this_week: User.where("created_at >= ?", week_ago).count,
            teams_total: Team.count,
            teams_active: Team.active.count,
            point_actions_total: PointAction.count,
            point_actions_active: PointAction.active.count
          }

          render json: { stats: stats }
        end
      end
    end
  end
end
