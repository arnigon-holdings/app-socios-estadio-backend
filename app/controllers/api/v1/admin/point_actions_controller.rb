module Api
  module V1
    module Admin
      class PointActionsController < BaseController
        def index
          actions = PointAction.order(:action_key)

          render json: { point_actions: actions.map { |pa| point_action_response(pa) } }
        end

        def create
          action = PointAction.new(point_action_params)

          if action.save
            log_action("create_point_action", "point_action", action.id)

            render json: { point_action: point_action_response(action) }, status: :created
          else
            render json: { error: action.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          action = PointAction.find(params[:id])
          action.assign_attributes(point_action_params)

          if action.save
            log_action("update_point_action", "point_action", action.id, { updated_fields: point_action_params.keys })

            render json: { point_action: point_action_response(action) }
          else
            render json: { error: action.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          action = PointAction.find(params[:id])

          log_action("delete_point_action", "point_action", action.id, { action_key: action.action_key })

          action.destroy

          head :no_content
        end

        private

        def point_action_params
          params.require(:point_action).permit(:action_key, :description, :points, :active)
        end

        def point_action_response(action)
          {
            id: action.id,
            action_key: action.action_key,
            description: action.description,
            points: action.points,
            active: action.active,
            created_at: action.created_at
          }
        end
      end
    end
  end
end
