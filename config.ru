require 'rubygems'
require 'bundler'
require 'slim'

Bundler.require

require './app'
run Sinatra::Application