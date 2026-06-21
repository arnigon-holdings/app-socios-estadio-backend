require "test_helper"

class UserTest < ActiveSupport::TestCase
  def calculate_dv(body)
    sum = body.to_s.chars.reverse.each_with_index.sum do |digit, i|
      digit.to_i * (i + 2)
    end
    remainder = sum % 11
    case 11 - remainder
    when 10 then "K"
    when 11 then "0"
    else (11 - remainder).to_s
    end
  end

  def valid_rut
    body = rand(10000000..25000000)
    dv = calculate_dv(body)
    "#{body}-#{dv}"
  end

  test "valid rut passes validation" do
    user = User.new(
      rut: valid_rut,
      phone: "+56912345678",
      birth_month: 6,
      birth_year: 1990,
      photo_url: "/uploads/test.jpg"
    )
    assert user.valid?, user.errors.full_messages
  end

  test "invalid rut format fails" do
    user = User.new(
      rut: "12345",
      phone: "+56912345678",
      birth_month: 6,
      birth_year: 1990,
      photo_url: "/uploads/test.jpg"
    )
    assert_not user.valid?
    assert_includes user.errors[:rut], "formato inválido"
  end

  test "invalid rut checksum fails" do
    user = User.new(
      rut: "12345670-5",
      phone: "+56912345678",
      birth_month: 6,
      birth_year: 1990,
      photo_url: "/uploads/test.jpg"
    )
    assert_not user.valid?
    assert user.errors[:rut].any?
  end

  test "phone required" do
    user = User.new(
      rut: valid_rut,
      phone: nil,
      birth_month: 6,
      birth_year: 1990,
      photo_url: "/uploads/test.jpg"
    )
    assert_not user.valid?
  end

  test "birth_year must be reasonable" do
    user = User.new(
      rut: valid_rut,
      phone: "+56912345678",
      birth_month: 6,
      birth_year: 1800,
      photo_url: "/uploads/test.jpg"
    )
    assert_not user.valid?
    assert_includes user.errors[:birth_year], "año inválido"
  end

  test "teams_ids max 5" do
    user = User.new(
      rut: valid_rut,
      phone: "+56912345678",
      birth_month: 6,
      birth_year: 1990,
      photo_url: "/uploads/test.jpg",
      teams_ids: [1, 2, 3, 4, 5, 6]
    )
    assert_not user.valid?
  end

  test "points_balance sums transactions" do
    user = User.create!(
      rut: valid_rut,
      phone: "+56912345678",
      birth_month: 6,
      birth_year: 1990,
      photo_url: "/uploads/test.jpg"
    )
    action = PointAction.create!(
      action_key: "test_action_#{SecureRandom.hex(4)}",
      description: "Test",
      points: 100
    )
    PointTransaction.create!(
      user: user,
      point_action: action,
      amount: 100
    )
    PointTransaction.create!(
      user: user,
      point_action: action,
      amount: 50
    )
    assert_equal 150, user.points_balance
    user.destroy
    action.destroy
  end
end
