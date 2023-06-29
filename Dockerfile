FROM ruby:3.1.2

RUN apt-get update && apt-get install -y \
  curl \
  build-essential \
  libpq-dev \
  nodejs 

RUN gem install bundler --no-document
WORKDIR /usr/src/notify_confluence

COPY Gemfile* ./
RUN bundle config --global path /bundle/cache
RUN bundle install

COPY . ./
EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
