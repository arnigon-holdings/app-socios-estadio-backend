require_relative "../app/models/admin"
require_relative "../app/models/team"
require_relative "../app/models/point_action"
require_relative "../app/models/user"

def generate_valid_rut
  body = rand(10000000..25000000)
  dv = calculate_dv(body)
  "#{body}-#{dv}"
end

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

puts "Seeding database..."

puts "Creating admins..."
admins = [
  { email: ENV.fetch("SEED_ADMIN_EMAIL", "admin@appperfil.cl"),     password: ENV.fetch("SEED_ADMIN_PASSWORD",     "Admin123!"),    role: "superadmin" },
  { email: ENV.fetch("SEED_OPERATOR_EMAIL", "operador@appperfil.cl"), password: ENV.fetch("SEED_OPERATOR_PASSWORD", "Operador123!"), role: "admin" },
  { email: ENV.fetch("SEED_SUPPORT_EMAIL",  "soporte@appperfil.cl"),  password: ENV.fetch("SEED_SUPPORT_PASSWORD",  "Soporte123!"),  role: "admin" }
]

admins.each do |attrs|
  Admin.find_or_create_by!(email: attrs[:email]) do |a|
    a.password = attrs[:password]
    a.role = attrs[:role]
  end
end

puts "Creating teams..."
TEAMS_CHILE = [
  { name: "Colo-Colo", short_name: "COL" },
  { name: "Universidad de Chile", short_name: "UCH" },
  { name: "Universidad Catolica", short_name: "UC" },
  { name: "Audax Italiano", short_name: "AUD" },
  { name: "Palestino", short_name: "PAL" },
  { name: "Everton", short_name: "EVE" },
  { name: "Union Española", short_name: "UNE" },
  { name: "Universidad de Concepcion", short_name: "UDC" },
  { name: "O'Higgins", short_name: "OHI" },
  { name: "Deportes Iquique", short_name: "IQI" },
  { name: "Cobresal", short_name: "COB" },
  { name: "Deportes Antofagasta", short_name: "ANT" },
  { name: "Union La Calera", short_name: "ULC" },
  { name: "Deportes Copiapo", short_name: "COP" },
  { name: "Huachipato", short_name: "HUA" },
  { name: "Curico Unido", short_name: "CUR" },
  { name: "Deportes Santa Cruz", short_name: "DSC" },
  { name: "Santiago Morning", short_name: "SMO" },
  { name: "Magallanes", short_name: "MAG" },
  { name: "San Luis", short_name: "SLU" },
  { name: "Deportes Temuco", short_name: "TEM" },
  { name: "Iberia", short_name: "IBE" },
  { name: "San Marcos de Arica", short_name: "SMA" },
  { name: "Lautaro de Buin", short_name: "LBU" },
  { name: "Rangers", short_name: "RAN" },
  { name: "Deportes Puerto Montt", short_name: "PMT" },
  { name: "Artigas", short_name: "ART" },
  { name: "Brujas", short_name: "BRJ" },
  { name: "Deportes Recoleta", short_name: "REC" },
  { name: "General Velásquez", short_name: "GVE" },
  { name: "San Antonio Unido", short_name: "SAU" },
  { name: "Tierra Felipe", short_name: "TFA" },
  { name: "Rodelindo Romano", short_name: "RRO" }
].freeze

TEAMS_CHILE.each do |team_attrs|
  Team.find_or_create_by!(name: team_attrs[:name]) do |t|
    t.short_name = team_attrs[:short_name]
    t.active = true
  end
end

puts "Creating point actions (Phase 2 ready)..."
point_actions = [
  { action_key: "registration", description: "Registro de usuario", points: 500 },
  { action_key: "team_selection", description: "Seleccion de equipo favorito", points: 50 },
  { action_key: "daily_login", description: "Login diario", points: 10 },
  { action_key: "weekly_checkin", description: "Check-in semanal", points: 75 },
  { action_key: "referral", description: "Referir un amigo", points: 200 }
]

point_actions.each do |pa_attrs|
  PointAction.find_or_create_by!(action_key: pa_attrs[:action_key]) do |pa|
    pa.description = pa_attrs[:description]
    pa.points = pa_attrs[:points]
    pa.active = true
  end
end

puts "Creating fake users for testing..."
if Rails.env.development?
  50.times do |i|
    rut = generate_valid_rut
    phone = "+569#{rand(90000000..99999999)}"
    birth_year = rand(1960..2005)
    birth_month = rand(1..12)
    team_ids = Team.active.pluck(:id).sample(rand(0..3))

    User.find_or_create_by!(rut: rut) do |u|
      u.phone = phone
      u.password = ENV.fetch("SEED_USER_PASSWORD", "Usuario123!")
      u.birth_month = birth_month
      u.birth_year = birth_year
      u.photo_url = "/uploads/placeholder.jpg"
      u.teams_ids = team_ids
      u.consents = { photo: true, sms: false, privacy: true, version: "v1" }
      u.metadata = { ip: "127.0.0.1", registration_source: "seed" }
      u.referral_code = "REF-#{SecureRandom.alphanumeric(6).upcase}"
    end
  end
end

puts "Done! Database seeded successfully."
puts ""
puts "Admin credentials (dev defaults — override via SEED_*_PASSWORD env):"
puts "  Email: #{ENV.fetch('SEED_ADMIN_EMAIL', 'admin@appperfil.cl')}"
puts "  Password: #{ENV.fetch('SEED_ADMIN_PASSWORD', 'Admin123!')}"
puts ""
puts "Teams created: #{Team.count}"
puts "Point actions created: #{PointAction.count}"
puts "Fake users created: #{User.count}" if Rails.env.development?
