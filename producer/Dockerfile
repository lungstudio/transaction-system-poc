# Base image
FROM ruby:2.6.0-rc2-stretch

# Setup environment variables that will be available to the instance
ENV APP_HOME /app

# Create a directory for our application
# and set it as the working directory
COPY . $APP_HOME
WORKDIR $APP_HOME

# Install gems
RUN bundle install

# Run the app
CMD ruby producer.rb
