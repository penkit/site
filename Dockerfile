FROM dhumphreys88/ruby:2.3

MAINTAINER Sam Lachance <slachance@gmail.com>

RUN apk add --no-cache ruby-dev build-base zlib-dev

# Install gems
COPY Gemfile* /opt/ruby/
RUN bundle install
COPY . /opt/ruby/

RUN chown -R ruby:ruby /opt/ruby/

# Start server
EXPOSE 8080
CMD ["rackup", "-o", "0.0.0.0", "-p", "8080"]