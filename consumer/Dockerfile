FROM ruby:2.6.0-rc2-stretch

RUN apt-get update -qq && apt-get install -y libpq-dev

ENV APP_HOME /app

COPY . $APP_HOME
WORKDIR $APP_HOME

RUN bundle install

CMD ruby consumer.rb
