Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allowed_origins = ENV.fetch("CORS_ORIGINS", "http://localhost:5173,http://localhost:3001").split(",")

  allow do
    origins allowed_origins

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      expose: ["Authorization"]
  end
end
