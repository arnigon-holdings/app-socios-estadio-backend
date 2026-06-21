module Api
  module V1
    class TeamsController < ApplicationController
      def index
        teams = Team.active.order(:name)
        render json: { teams: teams.map { |t| team_response(t) } }
      end

      private

      def team_response(team)
        {
          id: team.id,
          name: team.name,
          short_name: team.short_name,
          logo_url: team.logo_url
        }
      end
    end
  end
end
