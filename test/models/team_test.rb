require "test_helper"

class TeamTest < ActiveSupport::TestCase
  test "valid team creation" do
    team = Team.new(
      name: "Test Team FC #{SecureRandom.hex(4)}",
      short_name: "TT#{SecureRandom.hex(2)}"
    )
    assert team.valid?, team.errors.full_messages
  end

  test "name uniqueness" do
    name = "Unique Team #{SecureRandom.hex(4)}"
    Team.create!(name: name, short_name: "UT1")
    team2 = Team.new(name: name, short_name: "UT2")
    assert_not team2.valid?
  end

  test "active scope returns only active teams" do
    active_name = "Active Test #{SecureRandom.hex(4)}"
    inactive_name = "Inactive Test #{SecureRandom.hex(4)}"

    active_team = Team.create!(name: active_name, short_name: "AT#{SecureRandom.hex(2)}", active: true)
    inactive_team = Team.create!(name: inactive_name, short_name: "IT#{SecureRandom.hex(2)}", active: false)

    assert Team.active.where(name: active_name).exists?
    assert_not Team.active.where(name: inactive_name).exists?

    active_team.destroy
    inactive_team.destroy
  end
end
