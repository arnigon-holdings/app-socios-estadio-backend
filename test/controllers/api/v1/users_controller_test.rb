require "test_helper"

class Api::V1::UsersControllerTest < ActionDispatch::IntegrationTest
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

  def valid_photo_base64
    "data:image/jpeg;base64,/9j/4KNeXzKFOfDC13kObqzTmseQCRGMr8rvOHAz8063R9c79V3oPTyx7K/zvMraj7Cr2Fx8UBe7VB/LAkIXAXNKYYOXMX4XkiDtoSLYiUB5Zuwyacr/Lj6pksnUCXPh3PG0eQ=="
  end

  setup do
    @headers = { "Content-Type" => "application/json", "Accept" => "application/json" }
  end

  test "POST /api/v1/users creates user" do
    rut = valid_rut

    post "/api/v1/users",
      params: {
        rut: rut,
        phone: "+56991234567",
        birth_month: 6,
        birth_year: 1990,
        photo: valid_photo_base64,
        teams_ids: [],
        consents: { photo: true, privacy: true }
      }.to_json,
      headers: @headers

    assert_response :created
    assert_includes response.parsed_body.keys, "user"
    assert_includes response.parsed_body.keys, "referral_code"
    assert_equal rut.gsub(/[.\-]/, ""), response.parsed_body["user"]["rut"]
  end

  test "POST /api/v1/users fails without photo consent" do
    post "/api/v1/users",
      params: {
        rut: valid_rut,
        phone: "+56991234567",
        birth_month: 6,
        birth_year: 1990,
        photo: valid_photo_base64,
        consents: { photo: false, privacy: true }
      }.to_json,
      headers: @headers

    assert_response :bad_request
  end

  test "POST /api/v1/users fails with invalid rut" do
    post "/api/v1/users",
      params: {
        rut: "123456",
        phone: "+56991234567",
        birth_month: 6,
        birth_year: 1990,
        photo: valid_photo_base64,
        consents: { photo: true, privacy: true }
      }.to_json,
      headers: @headers

    assert_response :unprocessable_entity
  end
end
