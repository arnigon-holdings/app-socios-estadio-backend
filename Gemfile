source "https://rubygems.org"

ruby "~> 3.4.0"

gem "rails", "~> 8.0.1"
gem "pg", "~> 1.5"
gem "puma", ">= 5.0"
gem "jwt", "~> 2.9"
gem "bcrypt", "~> 3.1"
gem "rack-attack", "~> 6.7"
gem "rack-cors", "~> 2.0"
gem "seedbank", "~> 0.5"
gem "kaminari", "~> 1.2"
gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop", require: false
end

group :development do
  gem "solargraph", require: false
end
