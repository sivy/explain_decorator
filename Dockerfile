FROM ruby:4.1.0-preview1-slim-trixie

RUN mkdir -p /app

RUN gem install rspec