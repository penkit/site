FROM dhumphreys88/ruby:2.3

MAINTAINER Sam Lachance <slachance@gmail.com>

# Install gems
COPY Gemfile* /opt/ruby/
RUN bundle install
COPY . /opt/ruby/

# Upload source
COPY . $APP_HOME

# Start server
ENV PORT 8080
EXPOSE PORT
CMD ["rackup", "-o", "0.0.0.0", "-p", PORT]