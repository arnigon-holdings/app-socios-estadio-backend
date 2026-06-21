FROM ruby:3.4-slim

ENV RUBY_YJIT_ENABLE=1 \
    RAILS_ENV=development \
    NODE_ENV=development

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      libvips \
      libyaml-dev \
      curl \
      file \
      git \
      && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile ./
RUN bundle install

COPY . .

RUN chmod +x bin/rails bin/rake bin/setup

EXPOSE 3000

CMD ["bash", "-c", "bin/rails server -b 0.0.0.0"]
