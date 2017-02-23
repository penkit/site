FROM ruby:2.2.1

MAINTAINER Sam Lachance <slachance@gmail.com>

RUN apt-get update
RUN apt-get upgrade -y

# Install gems
ENV APP_HOME /app
ENV HOME /root
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
COPY Gemfile* $APP_HOME/
RUN bundle install

# Upload source
COPY . $APP_HOME

# Start server
ENV PORT 9292
EXPOSE 9292
CMD ["rackup", "-o", "0.0.0.0"]