FROM ruby:2.6.0-rc2-stretch

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs

RUN mkdir /app
WORKDIR /app
COPY . /app

RUN bundle install

EXPOSE 3000

RUN ["chmod", "+x", "/app/docker-entrypoint.sh"]
ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD bundle exec rails s -p $PORT -b 0.0.0.0
