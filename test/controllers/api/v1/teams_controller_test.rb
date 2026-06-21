require "test_helper"

class Api::V1::TeamsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Team.create!(name: "Test Team", short_name: "TT", active: true)
  end

  test "GET /api/v1/teams returns active teams" do
    get "/api/v1/teams"
    assert_response :ok
    assert_includes response.parsed_body.keys, "teams"
    assert response.parsed_body["teams"].is_a?(Array)
  end

  test "GET /api/v1/teams only returns active" do
    Team.create!(name: "Inactive Team", short_name: "IT", active: false)
    get "/api/v1/teams"
    names = response.parsed_body["teams"].map { |t| t["name"] }
    assert_includes names, "Test Team"
    assert_not_includes names, "Inactive Team"
  end
end
