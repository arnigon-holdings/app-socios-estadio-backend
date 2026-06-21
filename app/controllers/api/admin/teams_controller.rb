module Api
  module Admin
    class TeamsController < BaseController
      def index
        teams = Team.order(:name)
        teams = teams.active if params[:active] == "true"

        render json: { teams: teams.map { |t| team_response(t) } }
      end

      def show
        team = Team.find(params[:id])
        render json: { team: team_response(team) }
      end

      def create
        team = Team.new(team_params)

        if team.save
          log_action("create_team", "team", team.id)

          render json: { team: team_response(team) }, status: :created
        else
          render json: { error: team.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        team = Team.find(params[:id])
        team.assign_attributes(team_params)

        if team.save
          log_action("update_team", "team", team.id, { updated_fields: team_params.keys })

          render json: { team: team_response(team) }
        else
          render json: { error: team.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        team = Team.find(params[:id])

        log_action("delete_team", "team", team.id, { name: team.name })

        team.destroy

        head :no_content
      end

      private

      def team_params
        params.require(:team).permit(:name, :short_name, :logo_url, :active)
      end

      def team_response(team)
        {
          id: team.id,
          name: team.name,
          short_name: team.short_name,
          logo_url: team.logo_url,
          active: team.active,
          created_at: team.created_at
        }
      end
    end
  end
end
