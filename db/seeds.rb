require_relative "../app/models/admin"
require_relative "../app/models/team"
require_relative "../app/models/point_action"

puts "Seeding database..."

puts "Creating admin..."
Admin.find_or_create_by!(email: "admin@arnigon.com") do |a|
  a.password = "Admin.123."
  a.role = "superadmin"
end

puts "Creating teams..."

TEAMS_CHILE_PRIMERA_DIV = [
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
  { name: "Huachipato", short_name: "HUA" },
  { name: "Curico Unido", short_name: "CUR" },
  { name: "Deportes Santa Cruz", short_name: "DSC" }
].freeze

TEAMS_CHILE_PRIMERA_B = [
  { name: "Deportes Copiapo", short_name: "COP" },
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
  { name: "Deportes Recoleta", short_name: "REC" },
  { name: "General Velásquez", short_name: "GVE" },
  { name: "San Antonio Unido", short_name: "SAU" }
].freeze

(TEAMS_CHILE_PRIMERA_DIV + TEAMS_CHILE_PRIMERA_B).each do |team_attrs|
  Team.find_or_create_by!(name: team_attrs[:name]) do |t|
    t.short_name = team_attrs[:short_name]
    t.active = true
  end
end

puts "Creating point actions..."
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

puts "Done! Database seeded successfully."
puts ""
puts "Admin credentials:"
puts "  Email: admin@arnigon.com"
puts "  Password: Admin.123."
puts ""
puts "Teams created: #{Team.count} (#{TEAMS_CHILE_PRIMERA_DIV.size} Primera Division, #{TEAMS_CHILE_PRIMERA_B.size} Primera B)"
puts "Point actions created: #{PointAction.count}"
